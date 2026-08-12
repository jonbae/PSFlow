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
import { join, posix, relative, sep } from "node:path";

export class RegistryError extends Error {
  constructor(message) {
    super(message);
    this.name = "RegistryError";
  }
}

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
