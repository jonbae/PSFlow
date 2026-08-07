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

import { SECTIONS, validateTrace } from "../trace-format.mjs";
import { diffValues } from "./diff.mjs";
import { assertNoCollapse, normalize } from "./normalize.mjs";
import { claimDifferences, passes } from "./regions.mjs";

// The driving log is compared ahead of the other sections as its own class:
// if the inputs differed, the outputs differing tells you nothing new (#26).
// Framing the rest as consequences of a driving divergence is issue #43's; this
// is the ordering it lands on.
export const REPORT_ORDER = ["driving", "dom", "callbacks", "hooks", "api", "props", "console"];

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

  return {
    scenario: leftTrace.scenario,
    left: identity(leftTrace),
    right: identity(rightTrace),
    differences,
    ...claimed,
    deleted: { left: left.deleted, right: right.deleted },
    ok: passes(claimed),
  };
};
