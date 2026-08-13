// Self-consistency — the third of the noise policy's three mechanisms, and the
// one that runs first (#19 §8, #43).
//
// Each side is captured twice and compared **against itself** before any
// cross-side comparison runs. A side disagreeing with itself is its own named
// failure class, because a recorded trace baseline is meaningless if traces are not
// reproducible: a region affirmed against a value that only appears half the
// time claims noise, and the next run's "moved" verdict says nothing about
// upstream at all.
//
// It is the same machinery as the cross-side comparison — normalize, then diff —
// with two deliberate differences.
//
//   * **No regions, and no callback weakenings.** A region is a claim about the
//     two implementations disagreeing; there is no such thing as a claim that a
//     side disagrees with itself, and inventing one would turn the only check
//     that can see non-reproducibility into one more register of forgiven
//     differences. A weakening is the same claim about the same pair, one
//     section down: a side that fires a handler eleven times and then twelve is
//     not reproducible, whatever the two sides do about it between them.
//   * **The driving log carries no tolerance.** It is diffed straight off the
//     two traces and never handed to the normalizer at all, so no rule that
//     could be written — not one aimed at it, not a `**` one that reaches it by
//     accident — can forgive a difference there. A side whose resolved boxes
//     wobble between its own two captures fails against itself. That is the
//     measured-DOM-dimensions question — what remains of the spike's
//     *Measurement and rounding* — asked in the cheapest available form, of each
//     implementation separately rather than of the pair. It is also the only
//     place it *can* be asked without tolerance: across two sides a box
//     differing by 1e-5 is a finding somebody has to judge, and within one side
//     there is nothing to judge.
//
// Every other section normalizes exactly as it does across the sides. Class
// token order is as much noise within one side as between two, and a check that
// refused the whole ruleset would be red for reasons the noise policy has
// already settled.

import { CALLBACKS, DRIVING, validateTrace } from "../trace-format.mjs";
import { compareCallbacks } from "./callbacks.mjs";
import { diffValues } from "./diff.mjs";
import { REPORT_ORDER } from "./index.mjs";
import { assertNoCollapse, normalize } from "./normalize.mjs";

export class ConsistencyError extends Error {
  constructor(message) {
    super(message);
    this.name = "ConsistencyError";
  }
}

/** Everything a rule may touch here — which is everything but the receipt. */
const tolerated = ({ [DRIVING]: _receipt, ...sections }) => sections;

const sameRun = (first, second) => {
  for (const field of ["scenario", "side", "baseline"]) {
    if (first[field] !== second[field]) {
      throw new ConsistencyError(
        `self-consistency compares one side against itself, but these two traces differ in ${field} ` +
          `(${JSON.stringify(first[field])} against ${JSON.stringify(second[field])}); ` +
          `two runs of different things are not one thing captured twice`
      );
    }
  }
  if (first.capture === second.capture) {
    throw new ConsistencyError(
      `both traces are capture ${first.capture} of ${first.side} — a trace compared against itself is a ` +
        `check that cannot go red, which is the shape this check exists to rule out`
    );
  }
};

/**
 * Compares two captures of one side. `first` and `second` are validated traces
 * of the same scenario, side and baseline, and different captures.
 *
 * Returns `{ side, scenario, captures, differences, consistent }`. Nothing here
 * claims a difference: the side reproduced itself or it did not.
 */
export const checkSelfConsistency = (first, second, { rules = [] } = {}) => {
  validateTrace(first, `${first?.side ?? "a"} trace, capture ${first?.capture ?? "?"}`);
  validateTrace(second, `${second?.side ?? "a"} trace, capture ${second?.capture ?? "?"}`);
  sameRun(first, second);

  const left = normalize(tolerated(first.sections), rules);
  const right = normalize(tolerated(second.sections), rules);
  assertNoCollapse(
    { left: tolerated(first.sections), right: tolerated(second.sections) },
    { left: left.value, right: right.value },
    rules
  );

  // Section by section in report order, so the driving log leads here for the
  // same reason it leads there — off the raw traces, since it is the one
  // section the normalizer never saw. `callbacks` takes its own comparison with
  // an empty weakening set: a side has to reproduce its own call log exactly.
  const differences = REPORT_ORDER.flatMap((section) => {
    if (section === DRIVING) return diffValues(first.sections[DRIVING], second.sections[DRIVING], [DRIVING]);
    if (section === CALLBACKS) {
      return compareCallbacks(left.value[CALLBACKS], right.value[CALLBACKS], { path: [CALLBACKS] }).differences;
    }
    return diffValues(left.value[section], right.value[section], [section]);
  });

  return {
    side: first.side,
    scenario: first.scenario,
    captures: [first.capture, second.capture],
    differences,
    consistent: differences.length === 0,
  };
};
