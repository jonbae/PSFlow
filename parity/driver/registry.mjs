// The driver page's route space — the fixtures it can mount, and the components
// it mounts directly.
//
// Upstream's `generic-tests/index.tsx` reaches its fixtures with vite's
// `import.meta.glob`, which structurally cannot see a file outside the vendored
// tree. This is the same glob, done at build time, over roots this repo
// chooses — which is what lets a PSFlow-authored fixture join the corpus
// without the vendored copy being touched.
//
// `.ts` only, exactly as upstream's glob: a fixture's `components/*.tsx` are
// imported *by* the fixture and are not routes of their own.
//
// Split out of `build.mjs` because two roots share one flat route space, and
// the collision that creates is worth a test — and because the net's corpus
// needs the same two answers the build needs, which two lists would drift on.

import { readdirSync, statSync } from "node:fs";
import { join, posix, relative, resolve, sep } from "node:path";

export class RegistryError extends Error {
  constructor(message) {
    super(message);
    this.name = "RegistryError";
  }
}

/**
 * The two roots, named here rather than in `build.mjs` because two callers now
 * need the same answer: the build, which turns them into routes the page can
 * serve, and the net's corpus, which mounts one scenario per fixture. Two lists
 * would drift, and the drift would be a fixture the page serves and the net
 * never mounts — a hole nothing would report, since neither side would know the
 * other was missing it.
 *
 * The vendored root holds upstream's `generic-tests` fixtures; the second is
 * where ps-flow authors its own, so the vendored copy stays byte-identical and a
 * baseline bump is `rm -rf` and re-vendor with no merge. The two `missing`
 * messages differ because their absences mean different things.
 */
export const fixtureRoots = (repoRoot) => {
  const vendored = resolve(repoRoot, "xyflow/examples/react/src/generic-tests");
  const own = resolve(repoRoot, "parity/system/fixtures");

  return [
    {
      dir: vendored,
      missing:
        `no vendored fixture root at ${vendored} — the vendored upstream tree is missing, and the ` +
        `driver has nothing to mount. Re-vendor \`xyflow/\` and try again.`,
    },
    {
      dir: own,
      missing:
        `no ps-flow fixture root at ${own} — this one is this repo's own and is committed, so its ` +
        `absence is a lost directory rather than a missing checkout. Restore it from git.`,
    },
  ];
};

const walk = (dir) =>
  readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) return walk(path);
    return name.endsWith(".ts") && !name.endsWith(".d.ts") ? [path] : [];
  });

/**
 * Collects `{ route, file }` entries from every root, in root order.
 *
 * `roots` are `{ dir, missing }`: `missing` is what to say when the directory
 * is not there, because the two roots are absent for different reasons — one
 * means the vendored tree needs re-vendoring, the other that this repo lost a
 * directory of its own.
 *
 * Throws `RegistryError` on a missing root, on a route two roots both claim,
 * and on a registry that came out empty.
 */
export const collectFixtures = (roots) => {
  const claimed = new Map();
  const fixtures = [];

  for (const { dir, missing } of roots) {
    if (!statSync(dir, { throwIfNoEntry: false })?.isDirectory()) {
      throw new RegistryError(missing ?? `no fixture root at ${dir}`);
    }

    for (const file of walk(dir)) {
      const route = `./${relative(dir, file).split(sep).join(posix.sep)}`;

      // Two roots, one flat route space. A PSFlow fixture landing on a vendored
      // fixture's path would shadow it, and every spec driving that route would
      // keep passing against something else — a silent swap, which is the one
      // failure the whole driver exists to make impossible.
      const already = claimed.get(route);
      if (already) {
        throw new RegistryError(
          `two fixture roots both claim the route ${route}:\n` +
            `  ${already}\n  ${file}\n` +
            `One would shadow the other, and the specs driving that route would not say so. ` +
            `Rename the PSFlow-authored fixture — the vendored tree stays byte-identical.`
        );
      }
      claimed.set(route, file);
      fixtures.push({ route, file });
    }
  }

  // An empty registry would build a page that answers every route with a 404 —
  // a green build and a suite that fails everywhere, blaming the library.
  if (fixtures.length === 0) {
    throw new RegistryError(`found no fixtures under ${roots.map((r) => r.dir).join(", ")}`);
  }

  return fixtures;
};

// ── The second kind of route ────────────────────────────────────────────

/**
 * What a directly-mounted component *is*, and the corpus's question in one
 * field. An **example driver** declares its own flow inline, so it is its own
 * **fixture** and gets a mount-only baseline like every other fixture does. A
 * **contract** component renders a ps-flow-specific guard for one of the two
 * project suites and is a fixture of nothing, so it gets none — mounting it on
 * the upstream side would compare a page written against ps-flow's own contract
 * with upstream's reading of it, which is not a claim the net makes.
 */
export const COMPONENT_KINDS = ["example-driver", "contract"];

/**
 * The routes the page mounts a component on directly, rather than handing a
 * fixture to `Flow.tsx`.
 *
 * **Written down rather than globbed**, unlike the fixtures, and the count is
 * why: upstream ships 65 example directories and a glob would bundle all 65.
 * Here rather than in `build.mjs` for the same reason `fixtureRoots` is — the
 * corpus derives the example driver's baseline from this list, and a second
 * copy would drift into a route the page serves and the net never mounts.
 *
 * A route is the path the driver's hash carries, without the `#`, exactly as a
 * fixture's is once `routeOf` has flattened it. The page keys on the whole
 * hash, so whoever builds that registry puts the `#` back.
 *
 * `file` is repo-relative, and `name` is what a scenario cites when it needs a
 * route from here — the two together are what let the corpus name a component
 * without knowing where the repository is.
 */
export const DIRECT_COMPONENTS = [
  {
    name: "color-mode",
    route: "/examples/color-mode",
    kind: "example-driver",
    file: "xyflow/examples/react/src/examples/ColorMode/index.tsx",
    missing:
      `upstream's ColorMode example is not in the vendored tree. It is imported unmodified — it is ` +
      `its own fixture — so re-vendor \`xyflow/\`, or follow the example if a baseline bump moved it.`,
  },
  {
    name: "smoke",
    route: "/smoke",
    kind: "contract",
    file: "parity/driver/src/Smoke.tsx",
    missing: `ps-flow's smoke component is missing — it is this repo's own and committed. Restore it from git.`,
  },
  {
    name: "node-props",
    route: "/examples/node-props",
    kind: "contract",
    file: "parity/driver/src/NodePropsGuard.tsx",
    missing: `ps-flow's NodeProps guard is missing — it is this repo's own and committed. Restore it from git.`,
  },
];

/** The same list with `file` resolved against a checkout. */
export const directComponents = (repoRoot) =>
  DIRECT_COMPONENTS.map((component) => ({ ...component, file: resolve(repoRoot, component.file) }));

/**
 * One component's route, by name.
 *
 * A scenario that drives a directly-mounted component names it this way rather
 * than writing the hash path out, so that a baseline bump which moves or
 * renames the component fails here — naming the scenario's own citation —
 * instead of leaving the scenario pointed at a route the page answers with a
 * 404 and the driving log records as an unresolved mount.
 */
export const componentRoute = (name) => {
  const found = DIRECT_COMPONENTS.find((component) => component.name === name);
  if (!found) {
    throw new RegistryError(
      `no directly mounted component named ${JSON.stringify(name)} — there is ` +
        DIRECT_COMPONENTS.map((c) => c.name).join(", ")
    );
  }
  return found.route;
};

/**
 * Checks every component is on disk and returns `{ route, kind, file }`.
 *
 * The same treatment a missing fixture root gets, and for the same reason: a
 * page built around a route whose module is absent is a page that answers it
 * with a 404, and every spec driving that route then fails somewhere else.
 */
export const collectComponents = (components) => {
  const claimed = new Set();

  return components.map(({ route, kind, file, missing }) => {
    if (!COMPONENT_KINDS.includes(kind)) {
      throw new RegistryError(`${route}: kind ${JSON.stringify(kind)} is not one of ${COMPONENT_KINDS.join(", ")}`);
    }
    if (claimed.has(route)) throw new RegistryError(`two components both claim the route ${route}`);
    claimed.add(route);

    if (!statSync(file, { throwIfNoEntry: false })?.isFile()) {
      throw new RegistryError(missing ?? `no component at ${file} for route ${route}`);
    }
    return { route, kind, file };
  });
};

/**
 * Both registries at once — the whole of what the driver page can route to.
 *
 * Three callers need exactly this pair and no part of it alone: the build, which
 * turns them into the page's two module registries; the net's corpus, which
 * mounts a baseline per fixture; and the fork register, which hashes the
 * vendored half. Written once because three copies of `collectFixtures(...)`
 * beside `collectComponents(...)` is three places for one of them to be
 * forgotten.
 */
export const routeSpace = (repoRoot) => ({
  fixtures: collectFixtures(fixtureRoots(repoRoot)),
  components: collectComponents(directComponents(repoRoot)),
});
