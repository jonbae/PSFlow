// The comparison core — given two stored traces, what differs (#40).
//
// The pipeline, in order, and the order is the design:
//
//   1. **Validate the envelopes.** Two traces of different scenarios are not
//      two runs of one experiment, and comparing them is a mistake rather than
//      a finding.
//   2. **Normalize both sides** with one content-blind ruleset (`normalize.mjs`).
//   3. **Check nothing collapsed.** A value that differed before normalization
//      and agrees after it fails the run unless the two were reorderings.
//   4. **Diff section by section**, keyed rather than positional (`diff.mjs`).
//   5. **Claim what is left** with hand-written regions (`regions.mjs`).
//
// Capture and compare are separate steps by design (#18): a trace records
// everything observable and persists to disk, and *everything the noise policy
// forgives* lives here. That keeps a capture whitelist from smuggling
// hand-authored assertions into the recording, and it means revising the noise
// policy re-runs this step in seconds rather than re-running a browser.

import { DRIVING, validateTrace } from "../trace-format.mjs";
import { diffValues } from "./diff.mjs";
import { assertNoCollapse, normalize } from "./normalize.mjs";
import { claimDifferences, passes } from "./regions.mjs";

// The driving log is compared ahead of the other sections as its own class:
// if the inputs differed, the outputs differing tells you nothing new (#26).
export const REPORT_ORDER = [DRIVING, "dom", "callbacks", "hooks", "api", "props", "console"];

/** Is this difference in the receipt for the input side, rather than in a response? */
export const isDriving = (difference) => difference.path[0] === DRIVING;

// What the sections after `driving` are, once it has diverged. Not a filter:
// a run whose inputs differed reports every difference it found, and the
// consequences are exactly where a real divergence would be hiding (#43).
export const CONSEQUENCE = "consequence of the driving divergence";

export class ComparisonError extends Error {
  constructor(message) {
    super(message);
    this.name = "ComparisonError";
  }
}

const identity = (trace) => ({
  side: trace.side,
  capture: trace.capture,
  baseline: trace.baseline,
  scenario: trace.scenario,
});

/**
 * Compares two traces and returns everything the report needs.
 *
 * `rules` is the normalization ruleset, `regions` the register of hand-written
 * claims. Both default to empty, which is the strictest possible run: every
 * difference is unclaimed and the run fails.
 */
export const compareTraces = (leftTrace, rightTrace, { rules = [], regions = [] } = {}) => {
  validateTrace(leftTrace, `${leftTrace?.side ?? "left"} trace`);
  validateTrace(rightTrace, `${rightTrace?.side ?? "right"} trace`);

  if (leftTrace.scenario !== rightTrace.scenario) {
    throw new ComparisonError(
      `traces are of different scenarios (${leftTrace.scenario} against ${rightTrace.scenario}); ` +
        `two scenarios are not two runs of one experiment`
    );
  }

  const left = normalize(leftTrace.sections, rules);
  const right = normalize(rightTrace.sections, rules);
  assertNoCollapse(
    { left: leftTrace.sections, right: rightTrace.sections },
    { left: left.value, right: right.value },
    rules
  );

  const differences = REPORT_ORDER.flatMap((section) =>
    diffValues(left.value[section], right.value[section], [section])
  );

  const claimed = claimDifferences(differences, regions, { scenario: leftTrace.scenario });

  // Whether the two runs were the same experiment, which is a different question
  // from whether the run passes. A region can claim a driving difference — that
  // is someone's stated decision about pass and fail — and it still cannot make
  // the sections after it readable, so the framing turns on the difference
  // existing rather than on it going unclaimed.
  const drivingDifferences = differences.filter(isDriving);

  return {
    scenario: leftTrace.scenario,
    left: identity(leftTrace),
    right: identity(rightTrace),
    differences,
    ...claimed,
    driving: { diverged: drivingDifferences.length > 0, differences: drivingDifferences },
    deleted: { left: left.deleted, right: right.deleted },
    ok: passes(claimed),
  };
};
