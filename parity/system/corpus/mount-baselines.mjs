// Mount-only baselines — one per fixture, derived (#51, #55).
//
// The cheapest scenario there is: navigate to a fixture's route, let the page
// settle, capture. No action vocabulary at all. It is also the one the dual-run
// spike ran, and it found an entirely unlisted missing export — a mounted flow
// is a very large observation, and 64 of the trace's 156 exports land in `dom`
// where a mount alone puts them.
//
// **Mount-only is a general rule for every fixture in the corpus**, ps-flow's
// own included, which is why these are *derived* from the fixture registry
// rather than written down. A hand-listed corpus and a globbed registry drift
// into a fixture the driver page serves and the net never mounts — a hole
// nothing reports, because neither list knows the other exists. Adding a
// fixture adds its baseline; there is no second edit to forget.
//
// The **example driver** is a fixture too — it declares its own flow inline
// rather than being handed one — so it gets a baseline on the same rule, from
// the same registry (`parity/driver/registry.mjs`, which marks which directly
// mounted components are example drivers). A ps-flow **contract** component is
// not: it renders a ps-flow-specific guard for one of the project suites and is
// a fixture of nothing. The page served two until #61 retired the assertions
// they carried; the filter stays, because it is the distinction and not the
// count that decides.

import { defineScenario } from "../harness/scenario.mjs";
import { CorpusError, idOf, routeOf } from "./routes.mjs";

/**
 * One mount-only scenario per fixture, fixtures first and in registry order.
 *
 * `fixtures` is `collectFixtures`' output — `{ route, file }`, where `route` is
 * the registry key rather than the page's hash path. `exampleDrivers` is the
 * `example-driver` half of `collectComponents`' output, whose `route` is
 * already a hash path.
 */
export const mountBaselines = (fixtures, exampleDrivers = []) => {
  const mounted = [
    ...fixtures.map(({ route }) => ({ from: route, id: idOf(route), route: routeOf(route) })),
    ...exampleDrivers.map(({ route }) => ({ from: route, id: idOf(route), route })),
  ];
  const scenarios = mounted.map(({ id, route }) => defineScenario({ id, route, run: async () => {} }));

  // Two paths can flatten onto one id — `a/b-c.ts` and `a-b/c.ts` both give
  // `a-b-c` — and neither registry can see it, since they guard *routes*. Left
  // alone, the second scenario's four traces would land on the first's file
  // names and the run would compare one fixture against another while reporting
  // the difference as a library divergence.
  const seen = new Map();
  for (const [i, scenario] of scenarios.entries()) {
    const already = seen.get(scenario.id);
    if (already !== undefined) {
      throw new CorpusError(
        `two fixtures both name the scenario ${scenario.id}:\n` +
          `  ${mounted[already].from}\n  ${mounted[i].from}\n` +
          `Their traces would share file names and the run would compare one fixture against the other. ` +
          `Rename the ps-flow-authored fixture — the vendored tree stays byte-identical.`
      );
    }
    seen.set(scenario.id, i);
  }

  return scenarios;
};
