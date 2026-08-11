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
import { readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join, posix, relative, resolve, sep } from "node:path";

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

const sideFlag = process.argv.indexOf("--side");
const side = sideFlag === -1 ? "psflow" : process.argv[sideFlag + 1];
if (!Object.hasOwn(sides, side)) {
  console.error(`unknown side ${JSON.stringify(side)} — expected ${Object.keys(sides).join(" or ")}`);
  process.exit(2);
}

// ── The fixture registry ────────────────────────────────────────────────
//
// Upstream's `index.tsx` reaches its fixtures with vite's `import.meta.glob`,
// which structurally cannot see a file outside the vendored tree. This is the
// same glob, done at build time, over roots this repo chooses — so a fixture
// ps-flow authors can join the corpus without the vendored copy being touched.
//
// `.ts` only, exactly as upstream's glob: a fixture's `components/*.tsx` are
// imported *by* the fixture and are not routes of their own.

const fixtureRoots = [resolve(repoRoot, "xyflow/examples/react/src/generic-tests")];

function walk(dir) {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) return walk(path);
    return name.endsWith(".ts") && !name.endsWith(".d.ts") ? [path] : [];
  });
}

const fixtures = fixtureRoots.flatMap((root) => {
  if (!statSync(root, { throwIfNoEntry: false })?.isDirectory()) {
    console.error(
      `no fixture root at ${root} — the vendored upstream tree is missing, and the ` +
        `driver has nothing to mount. Re-vendor \`xyflow/\` and try again.`
    );
    process.exit(2);
  }
  return walk(root).map((file) => ({
    route: `./${relative(root, file).split(sep).join(posix.sep)}`,
    file,
  }));
});

// An empty registry would build a page that answers every route with a 404 —
// a green build and a suite that fails everywhere, blaming the library.
if (fixtures.length === 0) {
  console.error(`found no fixtures under ${fixtureRoots.join(", ")}`);
  process.exit(2);
}

// ── The example-driver registry ─────────────────────────────────────────
//
// The second kind of route. A **fixture** is data that `src/Flow.tsx` mounts;
// an **example driver** is a whole component of upstream's, imported
// unmodified and mounted as it stands. `generic-props.spec.ts` needs one:
// upstream's own props spec drives `examples/color-mode` rather than a
// generic-test fixture, because there is no props fixture to twin — upstream's
// `generic-tests/` holds exactly `edges`, `node-toolbar`, `nodes` and `pane`.
//
// Written down rather than globbed, unlike the fixtures. `examples/` holds 65
// directories, most of them importing exports that have not crossed; a glob
// would bundle all 65, and one unresolved import is an esbuild link error that
// stops the page building for every route at once. Adding an entry here is
// what pulls its imports into the crossing set, which is a decision and not a
// discovery.
const exampleDrivers = [
  {
    route: "#/examples/color-mode",
    file: resolve(repoRoot, "xyflow/examples/react/src/examples/ColorMode/index.tsx"),
  },
];

for (const { route, file } of exampleDrivers) {
  if (!statSync(file, { throwIfNoEntry: false })?.isFile()) {
    console.error(
      `no example driver at ${file} for route ${route} — either the vendored ` +
        `\`xyflow/\` tree is missing, or a baseline bump moved the example. ` +
        `Re-vendor, or update the list in parity/driver/build.mjs.`
    );
    process.exit(2);
  }
}

const moduleRegistry = (entries) =>
  entries.map(({ file }, i) => `import m${i} from ${JSON.stringify(file)};`).join("\n") +
  `\nexport default {\n` +
  entries.map(({ route }, i) => `  ${JSON.stringify(route)}: m${i},`).join("\n") +
  `\n};\n`;

const virtualModules = {
  "psflow:fixtures": moduleRegistry(fixtures),
  "psflow:drivers": moduleRegistry(exampleDrivers),
};

const registryPlugin = {
  name: "psflow-registries",
  setup(b) {
    b.onResolve({ filter: /^psflow:(fixtures|drivers)$/ }, (args) => ({
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

const alias = { "@xyflow/react": sides[side].react };
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
      `// Side: ${side}. Fixtures: ${fixtures.length}, example drivers: ${exampleDrivers.length}, ` +
      `from the vendored @xyflow/react ${baseline}.\n` +
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
  `driver [${side}]: ${fixtures.length} fixtures + ${exampleDrivers.length} example driver(s), ` +
    `library from \`${wants}\` → dist/${side}.js`
);
