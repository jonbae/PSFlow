// The corpus — every scenario the net drives, assembled from its sources.
//
// `tickets/081-interaction-corpus.md` names four sources. The first exists:
//
//   1. the **conformance seed** (`seed.mjs`), upstream's own suite transcribed
//      with the assertions dropped, gated against drift by `fork.mjs` — and
//      with it the **mount-only baselines** (`mount-baselines.mjs`), one per
//      fixture, *derived* from the driver's two registries rather than written
//      down, since one is the general rule the seed's transcription leans on
//   2. the **thirty test-debt scenarios** (`test-debt.mjs`), the forty-two
//      audit rows bound for the net collapsed onto thirty conditions, under the
//      ids `reserved.mjs` had been holding for them — the source that turns a
//      `gate-pending` row from *reserved* into driven
//   3. the **retirement debt** (`retirement-debt.mjs`), the hand-authored parity
//      assertions in the two ps-flow browser specs, whose retirement was made
//      conditional on the net covering them — and, beside the scenarios, the
//      per-test record of which one replaced which assertion (#61)
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
// One claim is deliberately *not* made here. `assertRetirementsResolve` — every
// scenario a **retirement** names is one the corpus holds — lives with the
// register in `retirement-debt.mjs` and is re-exported through this file, since
// it needs nothing from the assembly but a set of ids. `../net.mjs` hands it the
// assembled corpus rather than `buildCorpus` calling it, because it is a
// property of the corpus the *real* registry produces: a caller assembling a
// two-fixture corpus to test the assembly is making no claim about a
// retirement, and failing it there would say otherwise.
//
// `mountBaselines` guards the same hazard *within* the derived source, and the
// two are not one function because they can say different things. Two fixtures
// that flatten onto one id are told which two **paths** collided, and that the
// ps-flow-authored one is the one free to be renamed; up here there are only
// scenarios, so all that can be named is two routes. The specific message is
// worth more than the shared line, and it runs first.

import { CorpusError } from "./routes.mjs";
import { mountBaselines } from "./mount-baselines.mjs";
import { probeVariants, readProbePlan } from "./probes.mjs";
import { RESERVED } from "./reserved.mjs";
import { retirementDebtScenarios } from "./retirement-debt.mjs";
import { seedScenarios } from "./seed.mjs";
import { testDebtScenarios } from "./test-debt.mjs";

export { CorpusError, ROUTE_PREFIX, idOf, routeOf } from "./routes.mjs";
export { RESERVED } from "./reserved.mjs";
export { LIVENESS, RETIREMENTS, assertRetirementsResolve, retiredTestProblems } from "./retirement-debt.mjs";

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
export const buildCorpus = (fixtures, components = []) => {
  const plain = [
    ...mountBaselines(
      fixtures,
      components.filter(({ kind }) => kind === "example-driver")
    ),
    ...seedScenarios,
    ...testDebtScenarios,
    ...retirementDebtScenarios,
  ];
  return assertDistinctIds([...plain, ...probeVariants(plain, readProbePlan())]);
};

/**
 * Every id the corpus answers to, split by whether a scenario exists under it.
 *
 * The **name space**, and it is wider than the corpus on purpose. `written` are
 * the ids scenarios exist under today; `reserved` are the thirty
 * `reserved.mjs` holds for the test-debt scenarios, which no other source may
 * take. A `gate-pending` row in the changelog audit cites a scenario by name and
 * fails when the name resolves to neither — a typo and an invention look
 * identical in a JSON file, and this is the only thing that can tell either from
 * a plan.
 *
 * The two are returned apart rather than unioned because the difference is the
 * interesting half: a row against a `written` id is waiting on a run, and a row
 * against a `reserved` one is waiting on someone to write the scenario at all.
 * Collapsing them would make fifty rows read as though they were the same thing.
 *
 * Since #60 the thirty are written *as well as* reserved, so the second list no
 * longer holds anything the first does not. It stays because the register is
 * what a name is checked against: a scenario deleted from `test-debt.mjs`
 * without its rows being re-decided would otherwise stop being reserved at the
 * same moment it stopped being written, and fifty rows would go from resolving
 * to dangling in one commit with nothing having said so.
 */
export const scenarioNames = (fixtures, components = []) => ({
  written: buildCorpus(fixtures, components).map((scenario) => scenario.id),
  reserved: Object.keys(RESERVED),
});

/**
 * The check across sources, separately, because the sources it guards between
 * do not all exist yet.
 *
 * A derived baseline's id always leads with `mount-baseline--` and no
 * hand-written scenario's does, so the derived source cannot collide with any of
 * them. The three hand-named ones can collide with each other: the seed, the
 * test-debt scenarios (#60) and the retirement debt (#61) arrived at different
 * times, written by someone reading an upstream spec, a changelog row or a
 * retiring assertion rather than this file, and the hole-closing scenarios after
 * them will arrive the same way. That is precisely when a duplicate is easiest
 * to introduce and hardest to see.
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
