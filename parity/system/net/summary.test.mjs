import { test } from "node:test";
import assert from "node:assert/strict";

import { difference } from "../compare/diff.mjs";
import { FAILURE } from "../compare/run.mjs";
import { netOk, renderNetReport } from "./summary.mjs";

const side = (name, capture) => ({ side: name, capture, baseline: "12.11.0", scenario: "s" });

const run = (scenario, { failures = [], unclaimed = [], inconsistent = [] } = {}) => ({
  scenario,
  ok: failures.length === 0,
  failures,
  consistency: [
    { side: "upstream", captures: [1, 2], differences: [], consistent: true },
    { side: "psflow", captures: [1, 2], differences: inconsistent, consistent: inconsistent.length === 0 },
  ],
  comparison: {
    scenario,
    left: side("upstream", 1),
    right: side("psflow", 1),
    differences: unclaimed,
    unclaimed,
    outcomes: [],
    weakenings: [],
    deleted: { left: [], right: [] },
    driving: { diverged: false, differences: [] },
    ok: unclaimed.length === 0,
  },
});

const failing = (scenario) => {
  const unclaimed = [difference("changed", ["dom", "root", "attrs", "class"], "a", "b")];
  return run(scenario, { failures: [{ class: FAILURE.unclaimed, differences: unclaimed }], unclaimed });
};

test("a net run passes only when every scenario's run does", () => {
  assert.equal(netOk([run("a"), run("b")]), true);
  assert.equal(netOk([run("a"), failing("b")]), false);
});

test("the summary leads with the verdict and names which scenarios failed", () => {
  const report = renderNetReport([run("mount-baseline--pane-general"), failing("mount-baseline--nodes-general")], {
    baseline: "12.11.0",
  });

  assert.match(report, /\*\*1 of 2 scenario\(s\) failed\.\*\*/);
  assert.match(report, /\| `mount-baseline--nodes-general` \| \*\*failed\*\* \| unclaimed-difference \| 1 \|/);
  assert.match(report, /\| `mount-baseline--pane-general` \| passed \| — \| 0 \|/);
});

test("a clean corpus says so, and still names the baseline it was measured against", () => {
  const report = renderNetReport([run("a")], { baseline: "12.11.0" });

  assert.match(report, /\*\*Passed\.\*\*/);
  assert.match(report, /vendored `@xyflow\/react` 12\.11\.0/);
});

// Nothing is suppressed: capture-everything applies to a failed run as much as
// to a passing one, and a real divergence is exactly what would be hiding under
// a scenario the summary chose not to print.
test("every scenario's own report follows the table, failed or not", () => {
  const report = renderNetReport([run("mount-baseline--pane-general"), failing("mount-baseline--nodes-general")], {
    baseline: "12.11.0",
  });

  assert.match(report, /# System parity run — mount-baseline--pane-general/);
  assert.match(report, /# System parity run — mount-baseline--nodes-general/);
});

// A stored-trace comparison read as a fresh measurement is a report claiming
// something about code it never ran.
test("a re-diff of stored traces says so rather than reading as a measurement", () => {
  const rediffed = renderNetReport([run("a")], { baseline: "12.11.0", captured: false });
  const captured = renderNetReport([run("a")], { baseline: "12.11.0", captured: true });

  assert.match(rediffed, /Re-diffed from stored traces.*No browser ran/s);
  assert.doesNotMatch(captured, /No browser ran/);
});

// A side that did not reproduce itself is a failure of its own class, and the
// summary has to count it — a scenario whose only differences are a side against
// itself would otherwise read as zero.
test("differences a side found against itself are counted too", () => {
  const wobble = [difference("changed", ["driving", 0, "box", "x"], 75, 75.0001)];
  const report = renderNetReport(
    [run("a", { failures: [{ class: FAILURE.selfInconsistent, side: "psflow" }], inconsistent: wobble })],
    { baseline: "12.11.0" }
  );

  assert.match(report, /\| `a` \| \*\*failed\*\* \| self-inconsistent \| 1 \|/);
});
