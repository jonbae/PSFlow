// One system-parity run — four traces, and the order they are read in (#43).
//
// A run is one scenario, two sides, two captures each. The order below is the
// whole content of this module, and it is an interpretation order rather than a
// pipeline:
//
//   1. **Each side against itself.** A side disagreeing with itself is its own
//      failure class, and it comes first because it invalidates everything after
//      it: a cross-side difference between two sides that are not reproducible
//      cannot be attributed to either implementation.
//   2. **The driving log across the sides.** Same argument one level down —
//      inputs that differed make output differences uninterpretable.
//   3. **Everything else**, claimed by regions as usual.
//
// Nothing earlier suppresses anything later. Capture-everything is the rule the
// whole net is built on, and a run whose first two steps failed still reports
// its third in full: the real divergence may well be down there, and a report
// that stopped at the first bad news would hide it. What the earlier steps buy
// is *framing* — the report says which findings are readings and which are
// consequences of a run that was not one experiment.

import { SIDES } from "../../driver/sides.mjs";

import { compareTraces, comparisonScope, isDriving } from "./index.mjs";
import { checkSelfConsistency } from "./consistency.mjs";
import { OUTCOME, outcomesWith } from "./regions.mjs";

// Upstream reads left: it is the reference, and a difference is a thing PSFlow
// did to it. That is the opposite of `SIDES`' own order, where psflow comes
// first because it is the side the driver page serves by default.
export const COMPARISON_ORDER = ["upstream", "psflow"];

/** The failure classes a run can report, in the order it reports them. */
export const FAILURE = Object.freeze({
  selfInconsistent: "self-inconsistent",
  drivingDivergence: "driving-divergence",
  unclaimed: "unclaimed-difference",
  staleRegion: "stale-region",
  movedRegion: "region-needs-reaffirming",
  staleWeakening: "stale-weakening",
});

export class RunError extends Error {
  constructor(message) {
    super(message);
    this.name = "RunError";
  }
}

/**
 * Groups the traces by side, and insists on exactly the shape a run has: two
 * sides, two captures each. Everything about this check is about arriving at
 * the four traces without needing them in a fixed argument order — a run
 * assembled wrong would otherwise compare a side against the wrong thing and
 * report it as a finding.
 */
const bySide = (traces) => {
  if (!Array.isArray(traces)) throw new RunError("a run is an array of four traces");

  const captures = new Map(COMPARISON_ORDER.map((side) => [side, []]));
  for (const trace of traces) {
    if (!captures.has(trace?.side)) {
      throw new RunError(
        `${JSON.stringify(trace?.side)} is not a side — expected ${SIDES.join(" or ")}`
      );
    }
    captures.get(trace.side).push(trace);
  }

  for (const [side, traced] of captures) {
    if (traced.length !== 2) {
      throw new RunError(
        `a run is two captures of each side; got ${traced.length} of ${side}. ` +
          `Self-consistency is what makes a recorded trace baseline mean anything, and it needs the second capture.`
      );
    }
  }
  // Ascending capture, so `captures[0]` is the one the cross-side comparison
  // reads and the report can say which.
  return COMPARISON_ORDER.map((side) => captures.get(side).sort((a, b) => a.capture - b.capture));
};

const failuresOf = (consistency, comparison) => {
  const failures = [];

  for (const side of consistency) {
    if (!side.consistent) {
      failures.push({ class: FAILURE.selfInconsistent, side: side.side, differences: side.differences });
    }
  }

  const driving = comparison.unclaimed.filter(isDriving);
  const rest = comparison.unclaimed.filter((difference) => !isDriving(difference));
  if (driving.length) failures.push({ class: FAILURE.drivingDivergence, differences: driving });
  if (rest.length) failures.push({ class: FAILURE.unclaimed, differences: rest });

  const named = (status) => outcomesWith(comparison.outcomes, status).map((o) => o.region.id);
  const stale = named(OUTCOME.stale);
  const moved = named(OUTCOME.moved);
  if (stale.length) failures.push({ class: FAILURE.staleRegion, regions: stale });
  if (moved.length) failures.push({ class: FAILURE.movedRegion, regions: moved });

  // Its own class rather than a stale region: a weakening records no values, so
  // there is nothing to re-affirm and nothing `--record` could write. It either
  // still forgives something or it goes.
  const staleWeakenings = outcomesWith(comparison.weakenings, OUTCOME.stale);
  if (staleWeakenings.length) {
    failures.push({
      class: FAILURE.staleWeakening,
      weakenings: staleWeakenings.map((o) => `${o.weakening.callback} (${o.weakening.axis})`),
    });
  }

  return failures;
};

/**
 * Reads one run. `traces` is the four traces in any order; they are grouped by
 * the side each one records.
 *
 * Returns `{ scenario, consistency, comparison, failures, ok }`. The cross-side
 * comparison reads capture 1 of each side — which is only meaningful *because*
 * the self-consistency check read both.
 */
export const compareRun = (traces, { rules = [], regions = [], weakenings = [] } = {}) => {
  const [upstream, psflow] = bySide(traces);
  const scope = comparisonScope(upstream[0].scenario);

  // No weakenings on the way in: a side is held to reproducing its own call log
  // exactly, whatever the two sides are allowed to differ on between them.
  const consistency = [upstream, psflow].map(([first, second]) =>
    checkSelfConsistency(first, second, { rules, scope })
  );
  const comparison = compareTraces(upstream[0], psflow[0], { rules, regions, weakenings, scope });
  const failures = failuresOf(consistency, comparison);

  return {
    scenario: comparison.scenario,
    scope,
    consistency,
    comparison,
    failures,
    ok: failures.length === 0,
  };
};
