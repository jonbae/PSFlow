// Bundles the driver — the same source, once per side.
//
// The two sides differ in exactly one thing: what `@xyflow/react` resolves to.
//
//   * `--side psflow` (the default) aliases it to ps-flow's `index.js`, the
//     door the audience comes through. This is the bundle the conformance
//     suite runs, and it is the first time any gate crosses that door.
//   * `--side upstream` aliases it to the vendored upstream source. That is
//     the net's other run; system parity runs vendored source rather than the
//     published package, so the baseline stays `rm -rf` and re-vendor.
//
// Why the alias cannot be applied selectively, why the fixtures are globbed
// rather than copied, and why `dist/psflow.js` is committed: `README.md`, next
// to this file. What is here is the doing.
//
// Usage: node parity/driver/build.mjs [--side psflow|upstream]
//        npm run build:driver

import { build } from "esbuild";
import { readFileSync, statSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

import { CallbackDerivationError, observedCallbacks } from "./callbacks.mjs";
import { RegistryError, collectFixtures, fixtureRoots } from "./registry.mjs";
import { SIDES } from "./sides.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");

// ── The side ────────────────────────────────────────────────────────────

// `provenance` is what proves the alias was actually applied. esbuild writes a
// `// <path>` comment above every module it inlines, so the bundle says where
// its library came from — ps-flow's compiled output, or the vendored upstream
// package sources. The fixtures come from `xyflow/examples/`, which is why the
// upstream marker is `xyflow/packages/` and not `xyflow/`.
//
// Both sides reject `node_modules/@xyflow/`. The published package is *not* an
// acceptable stand-in for the vendored source on either side — the spike ran
// `node_modules` and violated the repo's own baseline invariant — and it would
// otherwise arrive unnoticed, since it satisfies neither side's marker.
const PUBLISHED = "// node_modules/@xyflow/";

const sides = {
  psflow: {
    react: resolve(repoRoot, "index.js"),
    provenance: { wants: "// output/Boundary/", rejects: ["// xyflow/packages/", PUBLISHED] },
  },
  upstream: {
    react: resolve(repoRoot, "xyflow/packages/react/src/index.ts"),
    // The vendored react package imports the system package by its published
    // name, the same redirection `oracle/esbuild.mjs` makes.
    system: resolve(repoRoot, "xyflow/packages/system/src/index.ts"),
    provenance: { wants: "// xyflow/packages/react/src/", rejects: ["// output/Boundary/", PUBLISHED] },
  },
};

// `sides.mjs` is the list; this file is the configuration for each. A side that
// gained a bundle here without the page learning to load it would build fine
// and be unreachable.
if (Object.keys(sides).sort().join() !== [...SIDES].sort().join()) {
  console.error(
    `the side configurations here (${Object.keys(sides).join(", ")}) are not the sides in ` +
      `sides.mjs (${SIDES.join(", ")}).`
  );
  process.exit(2);
}

const sideFlag = process.argv.indexOf("--side");
const side = sideFlag === -1 ? SIDES[0] : process.argv[sideFlag + 1];
if (!Object.hasOwn(sides, side)) {
  console.error(`unknown side ${JSON.stringify(side)} — expected ${SIDES.join(" or ")}`);
  process.exit(2);
}

// ── The fixture registry ────────────────────────────────────────────────
//
// Two roots, globbed into one flat route space by `registry.mjs`, which also
// names them — the net's corpus derives a mount-only baseline per fixture from
// the same list, and two lists would drift into a fixture the page serves and
// the net never mounts.
//
// PSFlow's root is legitimately empty until the corpus lands (#55). Emptiness
// only fails in the aggregate — see `registry.mjs`, which also refuses a route
// two roots both claim.

let fixtures;
try {
  fixtures = collectFixtures(fixtureRoots(repoRoot));
} catch (e) {
  if (!(e instanceof RegistryError)) throw e;
  console.error(e.message);
  process.exit(2);
}

// ── Directly mounted component registry ────────────────────────────────
//
// The second kind of route. A **fixture** is data that `src/Flow.tsx` mounts;
// these components are mounted directly. The conformance suite's ColorMode
// **example driver** is imported unmodified from upstream; PSFlow's smoke and
// NodeProps components live here because they are project-specific contracts.
// `generic-props.spec.ts` needs the upstream page:
// upstream's own props spec drives `examples/color-mode` rather than a
// generic-test fixture, because there is no props fixture to twin — upstream's
// `generic-tests/` holds exactly `edges`, `node-toolbar`, `nodes` and `pane`.
//
// Written down rather than globbed, unlike the fixtures — `README.md`, next to
// this file, says why. The count it turns on: upstream ships 65 example
// directories, and a glob would bundle all 65.
const directComponents = [
  {
    route: "#/examples/color-mode",
    file: resolve(repoRoot, "xyflow/examples/react/src/examples/ColorMode/index.tsx"),
  },
  {
    route: "#/smoke",
    file: resolve(here, "src/Smoke.tsx"),
  },
  {
    route: "#/examples/node-props",
    file: resolve(here, "src/NodePropsGuard.tsx"),
  },
];

for (const { route, file } of directComponents) {
  if (!statSync(file, { throwIfNoEntry: false })?.isFile()) {
    console.error(
      `no direct component at ${file} for route ${route} — restore the local file, ` +
        `or re-vendor \`xyflow/\` if a baseline bump moved the upstream example.`
    );
    process.exit(2);
  }
}

// ── The callback props the driver installs ──────────────────────────────
//
// Derived from the vendored `ReactFlowProps` rather than listed — `callbacks.mjs`
// says why at length, and the short of it is that a handler missing from the
// list is installed on *neither* side, so it fires on neither, so the two traces
// agree about it forever. That is the one mistake the dual-run design cannot
// see through, and it is why this is the driver's single derived list.
//
// The same failure treatment as the fixture registry: a derivation that cannot
// be trusted exits 2 rather than building a page that observes nothing.

let callbacks;
try {
  callbacks = observedCallbacks(repoRoot);
} catch (e) {
  if (!(e instanceof CallbackDerivationError)) throw e;
  console.error(e.message);
  process.exit(2);
}

const moduleRegistry = (entries) =>
  entries.map(({ file }, i) => `import m${i} from ${JSON.stringify(file)};`).join("\n") +
  `\nexport default {\n` +
  entries.map(({ route }, i) => `  ${JSON.stringify(route)}: m${i},`).join("\n") +
  `\n};\n`;

const virtualModules = {
  "psflow:fixtures": moduleRegistry(fixtures),
  "psflow:components": moduleRegistry(directComponents),
  "psflow:callbacks": `export default ${JSON.stringify(callbacks, null, 2)};\n`,
};

const registryPlugin = {
  name: "psflow-registries",
  setup(b) {
    b.onResolve({ filter: /^psflow:(fixtures|components|callbacks)$/ }, (args) => ({
      path: args.path,
      namespace: "psflow-registry",
    }));
    b.onLoad({ filter: /.*/, namespace: "psflow-registry" }, (args) => ({
      contents: virtualModules[args.path],
      loader: "tsx",
      resolveDir: repoRoot,
    }));
  },
};

// ── The build ───────────────────────────────────────────────────────────

const readJson = (p) => JSON.parse(readFileSync(p, "utf8"));
const baseline = readJson(resolve(repoRoot, "xyflow/packages/react/package.json")).version;

// The vendored tree may be a link to another checkout. Resolve React from this
// checkout explicitly so linked source cannot pull in a second runtime from
// the checkout that owns the link target (which makes hooks fail at runtime).
const alias = {
  "@xyflow/react": sides[side].react,
  react: resolve(repoRoot, "node_modules/react"),
  "react-dom": resolve(repoRoot, "node_modules/react-dom"),
};
if (sides[side].system) alias["@xyflow/system"] = sides[side].system;

const outfile = resolve(here, `dist/${side}.js`);

// `write: false` so the provenance check below runs *before* anything lands on
// disk. A bundle that failed it must not exist to be served by accident.
const result = await build({
  entryPoints: [resolve(here, "src/entry.tsx")],
  bundle: true,
  write: false,
  format: "esm",
  platform: "browser",
  jsx: "automatic",
  alias,
  plugins: [registryPlugin],
  banner: {
    js:
      `// ps-flow conformance driver — GENERATED by parity/driver/build.mjs. DO NOT EDIT.\n` +
      `// Side: ${side}. Fixtures: ${fixtures.length}, direct components: ${directComponents.length}, ` +
      `observed callback props: ${callbacks.props.length}, from the vendored @xyflow/react ${baseline}.\n` +
      `// Rebuild: npm run build:driver (re-run on every xyflow/ bump and every src/ change).`,
  },
  outfile,
  logLevel: "info",
});

// ── Provenance ──────────────────────────────────────────────────────────
//
// The alias is the entire gate. Lose it — a rename, a stray `paths` entry, a
// bundler default — and every conformance spec still passes, against upstream,
// while reporting green about ps-flow. That is this ticket's own version of
// the failure the whole effort exists to remove: a check that cannot see the
// thing it is checking. So the bundle is read back and asked which library it
// actually contains.

const bundle = result.outputFiles[0].text;
const { wants, rejects } = sides[side].provenance;

if (!bundle.includes(wants)) {
  console.error(
    `the ${side} bundle contains no \`${wants}\` module — \`@xyflow/react\` did not ` +
      `resolve to ${alias["@xyflow/react"]}, so this bundle proves nothing about it.`
  );
  process.exit(2);
}
for (const marker of rejects) {
  if (bundle.includes(marker)) {
    console.error(
      `the ${side} bundle contains \`${marker}\` modules alongside its own — a passing ` +
        `run could not say which library rendered.`
    );
    process.exit(2);
  }
}

writeFileSync(outfile, bundle);

console.log(
  `driver [${side}]: ${fixtures.length} fixtures + ${directComponents.length} direct component(s), ` +
    `${callbacks.props.length} observed callback props, library from \`${wants}\` → dist/${side}.js`
);
