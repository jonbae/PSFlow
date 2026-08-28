// The corpus — every scenario the net drives, assembled from its sources.
//
// `tickets/081-interaction-corpus.md` names four sources. The first exists:
//
//   1. the **conformance seed** (`seed.mjs`), upstream's own suite transcribed
//      with the assertions dropped, gated against drift by `fork.mjs` — and
//      with it the **mount-only baselines** (`mount-baselines.mjs`), one per
//      fixture, *derived* from the driver's two registries rather than written
//      down, since one is the general rule the seed's transcription leans on
//   2. the thirty test-debt scenarios (#60), whose ids `reserved.mjs` holds
//   3. the retirement debt (#61), the hand-authored parity assertions whose
//      retirement was made conditional on the net covering them
//   4. hole-closing scenarios, until the corpus's termination condition — which
//      `../coverage/` now evaluates on every run, so what is left to close is
//      read off `../coverage.md` rather than guessed at (#57)
//
// Assembling them is one line and one check. The check is the reason this file
// exists: the sources are written by different people at different times and
// neither can see the other's ids, so an id two of them both claim would put
// two scenarios' traces on one set of file names — and the run would compare
// one experiment against another while reporting the difference as a library
// divergence.
//
// `mountBaselines` guards the same hazard *within* the derived source, and the
// two are not one function because they can say different things. Two fixtures
// that flatten onto one id are told which two **paths** collided, and that the
// ps-flow-authored one is the one free to be renamed; up here there are only
// scenarios, so all that can be named is two routes. The specific message is
// worth more than the shared line, and it runs first.

import { CorpusError } from "./routes.mjs";
import { mountBaselines } from "./mount-baselines.mjs";
import { RESERVED } from "./reserved.mjs";
import { seedScenarios } from "./seed.mjs";

export { CorpusError, ROUTE_PREFIX, idOf, routeOf } from "./routes.mjs";
export { RESERVED } from "./reserved.mjs";

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
 * Every id the corpus answers to, split by whether a scenario exists under it.
 *
 * The **name space**, and it is wider than the corpus on purpose. `written` are
 * the ids scenarios exist under today; `reserved` are the thirty
 * `reserved.mjs` holds for the test-debt scenarios (#60), which no source may
 * take in the meantime. A `gate-pending` row in the changelog audit cites a
 * scenario by name and fails when the name resolves to neither — a typo and an
 * invention look identical in a JSON file, and this is the only thing that can
 * tell either from a plan.
 *
 * The two are returned apart rather than unioned because the difference is the
 * interesting half: a row against a `written` id is waiting on a run, and a row
 * against a `reserved` one is waiting on someone to write the scenario at all.
 * Collapsing them would make fifty rows read as though they were the same thing.
 */
export const scenarioNames = (fixtures, components = []) => ({
  written: buildCorpus(fixtures, components).map((scenario) => scenario.id),
  reserved: Object.keys(RESERVED),
});

/**
 * The check across sources, separately, because the sources it guards between
 * do not all exist yet.
 *
 * Today a derived baseline's id always leads with `mount-baseline--` and no
 * hand-written scenario's does, so the two sources in the corpus cannot in fact
 * collide. The next two can: the test-debt scenarios (#60) and the hole-closing
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
