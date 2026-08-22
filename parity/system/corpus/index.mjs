// The corpus — every scenario the net drives, assembled from its sources.
//
// `tickets/081-interaction-corpus.md` names four, and two of them exist:
//
//   1. **mount-only baselines**, one per fixture, *derived* from the driver's
//      two registries rather than written down (`mount-baselines.mjs`)
//   2. the **conformance seed**, upstream's own suite transcribed with the
//      assertions dropped (`seed.mjs`), gated against drift by `fork.mjs`
//   3. the test-debt scenarios (#59), whose thirty ids `reserved.mjs` holds
//   4. hole-closing scenarios, until the corpus's termination condition
//
// Assembling them is one line and one check. The check is the reason this file
// exists: the sources are written by different people at different times and
// neither can see the other's ids, so an id two of them both claim would put
// two scenarios' traces on one set of file names — and the run would compare
// one experiment against another while reporting the difference as a library
// divergence. Exactly the hazard `mountBaselines` already guards *within* the
// derived source, one level out.

import { CorpusError } from "./routes.mjs";
import { mountBaselines } from "./mount-baselines.mjs";
import { seedScenarios } from "./seed.mjs";

export { CorpusError, ROUTE_PREFIX, idOf, routeOf } from "./routes.mjs";

/**
 * Every scenario, baselines first.
 *
 * `fixtures` is `collectFixtures`' output and `components` is
 * `collectComponents`', both from `parity/driver/registry.mjs` — the same two
 * registries the driver page is built from, so a route the page serves and a
 * route the net drives cannot drift apart.
 *
 * Baselines lead because they are the cheapest thing that can fail: a fixture
 * whose mount already diverges tells you why every scenario driving it did too,
 * and reading that first is the same ordering the report gives the driving log.
 */
export const buildCorpus = (fixtures, components = []) =>
  assertDistinctIds([
    ...mountBaselines(
      fixtures,
      components.filter(({ kind }) => kind === "example-driver")
    ),
    ...seedScenarios,
  ]);

/**
 * The check, separately, because the sources it guards between do not all
 * exist yet.
 *
 * Today a derived baseline's id always leads with `mount-baseline--` and no
 * hand-written scenario's does, so the two sources in the corpus cannot in fact
 * collide. The next two can: the test-debt scenarios (#59) and the hole-closing
 * scenarios after them are hand-named, arrive later, and are written by someone
 * reading a changelog row rather than this file. That is precisely when a
 * duplicate is easiest to introduce and hardest to see, so the check ships with
 * the assembly rather than with the source that will need it.
 */
export const assertDistinctIds = (scenarios) => {
  const seen = new Map();

  for (const scenario of scenarios) {
    const already = seen.get(scenario.id);
    if (already !== undefined) {
      throw new CorpusError(
        `two sources of the corpus both name the scenario ${scenario.id}, on routes ` +
          `${already} and ${scenario.route}. Their traces would share file names and the run would ` +
          `compare one scenario against the other. Rename the hand-written one — a derived baseline's ` +
          `id follows its fixture's path and is not free to move.`
      );
    }
    seen.set(scenario.id, scenario.route);
  }

  return scenarios;
};
