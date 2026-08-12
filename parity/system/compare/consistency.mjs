// Self-consistency — the third of the noise policy's three mechanisms, and the
// one that runs first (#19 §8, #43).
//
// Each side is captured twice and compared **against itself** before any
// cross-side comparison runs. A side disagreeing with itself is its own named
// failure class, because a recorded baseline is meaningless if traces are not
// reproducible: a region affirmed against a value that only appears half the
// time claims noise, and the next run's "moved" verdict says nothing about
// upstream at all.
//
// It is the same machinery as the cross-side comparison — normalize, then diff —
// with two deliberate differences.
//
//   * **No regions.** A region is a claim about the two implementations
//     disagreeing; there is no such thing as a claim that a side disagrees with
//     itself, and inventing one would turn the only check that can see
//     non-reproducibility into an allowlist.
//   * **The driving log carries no tolerance.** Rules that could reach the
//     driving section are *withheld* here rather than trusted not to be written,
//     so a side whose resolved boxes wobble between its own two captures fails
//     against itself. That is the measured-DOM-dimensions question — what
//     remains of the spike's *Measurement and rounding* — asked in the cheapest
//     available form, of each implementation separately rather than of the pair.
//     It is also the only place it *can* be asked without tolerance: across two
//     sides, a box differing by 1e-5 is a finding somebody has to judge, and
//     within one side it is never anything but noise.

import { validateTrace } from "../trace-format.mjs";
import { diffValues } from "./diff.mjs";
import { REPORT_ORDER } from "./index.mjs";
import { assertNoCollapse, normalize } from "./normalize.mjs";

/** The section the check refuses to normalize. */
export const UNTOLERATED = "driving";

export class ConsistencyError extends Error {
  constructor(message) {
    super(message);
    this.name = "ConsistencyError";
  }
}

// A rule reaches the driving log if its first segment names it, or is a
// wildcard that could stand for it. Judged on the pattern rather than on what
// it happens to match today: `**/width` claims nothing about `driving` and
// would silently start forgiving box widths the moment one appeared.
const reachesDriving = (rule) => {
  const first = rule.at.split("/")[0];
  return first === UNTOLERATED || first === "*" || first === "**";
};

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
 * Returns `{ side, scenario, captures, differences, driving, withheld,
 * consistent }`. Nothing here claims a difference: the run is consistent or it
 * is not.
 */
export const checkSelfConsistency = (first, second, { rules = [] } = {}) => {
  validateTrace(first, `${first?.side ?? "a"} trace, capture ${first?.capture ?? "?"}`);
  validateTrace(second, `${second?.side ?? "a"} trace, capture ${second?.capture ?? "?"}`);
  sameRun(first, second);

  const withheld = rules.filter(reachesDriving);
  const applied = rules.filter((rule) => !reachesDriving(rule));

  const left = normalize(first.sections, applied);
  const right = normalize(second.sections, applied);
  assertNoCollapse({ left: first.sections, right: second.sections }, { left: left.value, right: right.value }, applied);

  // Section by section in report order, so the driving log leads here for the
  // same reason it leads there.
  const differences = REPORT_ORDER.flatMap((section) =>
    diffValues(left.value[section], right.value[section], [section])
  );
  const driving = differences.filter((d) => d.path[0] === UNTOLERATED);

  return {
    side: first.side,
    scenario: first.scenario,
    captures: [first.capture, second.capture],
    differences,
    driving: { diverged: driving.length > 0, differences: driving },
    withheld,
    consistent: differences.length === 0,
  };
};
