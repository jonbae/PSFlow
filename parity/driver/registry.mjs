// The fixture registry — which files the driver page can route to.
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
// the collision that creates is worth a test.

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
