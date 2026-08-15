// Mount-only baselines — one per fixture, and the whole corpus for now (#51).
//
// The cheapest scenario there is: navigate to a fixture's route, let the page
// settle, capture. No action vocabulary at all. It is also the one the dual-run
// spike ran, and it found an entirely unlisted missing export — a mounted flow
// is a very large observation, and 64 of the trace's 156 exports land in `dom`
// where a mount alone puts them.
//
// **Mount-only is a general rule for every fixture in the corpus**, PSFlow's own
// included (#55), which is why these are *derived* from the fixture registry
// rather than written down. A hand-listed corpus and a globbed registry drift
// into a fixture the driver page serves and the net never mounts — a hole
// nothing reports, because neither list knows the other exists. Adding a fixture
// adds its baseline; there is no second edit to forget.
//
// What is deliberately *not* here is upstream's **example driver**
// (`#/examples/color-mode`) and the two PSFlow contract components the page also
// serves. They are routes, not fixtures: the page mounts them directly rather
// than handing them to `Flow.tsx`, they are written down in `build.mjs` as a
// decision about the crossing set, and the example driver's baseline belongs
// with the corpus proper (#55) alongside the interaction it exists for.

import { defineScenario } from "../harness/scenario.mjs";

/** Upstream's own route for the generic fixtures, kept so a lifted spec changes only its origin. */
export const ROUTE_PREFIX = "/tests/generic";

export class CorpusError extends Error {
  constructor(message) {
    super(message);
    this.name = "CorpusError";
  }
}

/** `./nodes/general.ts` — the registry's key — is `/tests/generic/nodes/general` to the page. */
export const routeOf = (fixture) => `${ROUTE_PREFIX}${fixture.replace(/^\./, "").replace(/\.ts$/, "")}`;

/**
 * `./pane/non-defaults.ts` becomes `mount-baseline--pane-non-defaults`.
 *
 * `--` separates the kind of scenario from the fixture it runs against, and the
 * fixture's own path separators flatten to `-`. Semantic throughout: a gate
 * cites scenarios by name, and a number would move the moment the corpus is
 * trimmed.
 */
export const idOf = (fixture) =>
  `mount-baseline--${fixture
    .replace(/^\.\//, "")
    .replace(/\.ts$/, "")
    .split("/")
    .join("-")}`;

/**
 * One mount-only scenario per fixture, in registry order.
 *
 * `fixtures` is `collectFixtures`' output — `{ route, file }`, where `route` is
 * the registry key rather than the page's hash path.
 */
export const mountBaselines = (fixtures) => {
  const scenarios = fixtures.map(({ route }) =>
    defineScenario({ id: idOf(route), route: routeOf(route), run: async () => {} })
  );

  // Two fixture paths can flatten onto one id — `a/b-c.ts` and `a-b/c.ts` both
  // give `a-b-c` — and the registry cannot see it, since it guards *routes*.
  // Left alone, the second scenario's four traces would land on the first's file
  // names and the run would compare one fixture against another while reporting
  // the difference as a library divergence.
  const seen = new Map();
  for (const [i, scenario] of scenarios.entries()) {
    const already = seen.get(scenario.id);
    if (already !== undefined) {
      throw new CorpusError(
        `two fixtures both name the scenario ${scenario.id}:\n` +
          `  ${fixtures[already].route}\n  ${fixtures[i].route}\n` +
          `Their traces would share file names and the run would compare one fixture against the other. ` +
          `Rename the ps-flow-authored fixture — the vendored tree stays byte-identical.`
      );
    }
    seen.set(scenario.id, i);
  }

  return scenarios;
};
