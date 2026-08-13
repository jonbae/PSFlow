import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { SIDES } from "../../driver/sides.mjs";
import { readTrace } from "../trace-format.mjs";
import { COMPARISON_ORDER, FAILURE, compareRun, RunError } from "./run.mjs";
import { renderRunReport } from "./report.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const fixture = (name) => readTrace(join(here, "fixtures", name));
const SORT_RULES = JSON.parse(readFileSync(join(here, "..", "normalization.json"), "utf8")).rules;

const CLEAN = [
  "baseline.upstream.json",
  "baseline.upstream.capture2.json",
  "baseline.psflow.json",
  "baseline.psflow.capture2.json",
];

// One side that does not reproduce itself: psflow's second capture resolved the
// node's box a hundred-thousandth of a pixel wider.
const WOBBLING = [
  "baseline.upstream.json",
  "baseline.upstream.capture2.json",
  "baseline.psflow.json",
  "wobbling-box.psflow.capture2.json",
];

const run = (names, options = {}) => compareRun(names.map(fixture), { rules: SORT_RULES, ...options });

test("the run reads exactly the sides the driver serves, reordered rather than renamed", () => {
  // A side added to the driver and not here would be a side no run could group,
  // and one renamed here would silently stop matching any trace at all.
  assert.deepEqual([...COMPARISON_ORDER].sort(), [...SIDES].sort());
});

test("four agreeing captures pass, and the report says both sides agreed with themselves first", () => {
  const result = run(CLEAN);

  assert.equal(result.ok, true);
  assert.deepEqual(result.failures, []);
  assert.deepEqual(
    result.consistency.map((c) => [c.side, c.consistent]),
    [
      ["upstream", true],
      ["psflow", true],
    ]
  );

  const report = renderRunReport(result);
  assert.ok(report.indexOf("Self-consistency") < report.indexOf("Comparison report"), "self-consistency is reported first");
});

test("a side that disagrees with itself is its own failure class", () => {
  const result = run(WOBBLING);

  assert.equal(result.ok, false);
  assert.deepEqual(
    result.failures.map((f) => f.class),
    [FAILURE.selfInconsistent]
  );
  assert.equal(result.failures[0].side, "psflow");

  const report = renderRunReport(result);
  assert.match(report, /psflow disagrees with itself/);
  assert.match(report, /driving\/1\/box\/width/);
});

test("the cross-side comparison still runs and is still reported when a side is not reproducible", () => {
  const result = run(WOBBLING);

  // Capture-everything applies here too: an unreproducible side does not stop
  // the comparison, it frames it.
  assert.equal(result.comparison.scenario, "mount-baseline--nodes-general");
  assert.match(renderRunReport(result), /Comparison report/);
});

test("self-consistency is checked against both captures, not against the one that goes on to compare", () => {
  const result = run(WOBBLING);

  // The cross-side pair is capture 1 of each side, so the wobble lives only in
  // a trace the comparison never reads — and is still a failure.
  assert.equal(result.comparison.left.capture, 1);
  assert.equal(result.comparison.right.capture, 1);
  assert.equal(result.comparison.ok, true);
  assert.equal(result.ok, false);
});

test("a driving divergence between the sides is named apart from the differences it explains", () => {
  const result = run([
    "baseline.upstream.json",
    "baseline.upstream.capture2.json",
    "missed-target.psflow.json",
    "baseline.psflow.capture2.json",
  ]);

  assert.equal(result.ok, false);
  assert.deepEqual(
    result.failures.map((f) => f.class),
    [FAILURE.selfInconsistent, FAILURE.drivingDivergence, FAILURE.unclaimed]
  );
  // The psflow captures differ from each other too — one missed the node and
  // the other did not — and that is reported before the cross-side reading.
  assert.equal(result.failures[0].side, "psflow");
});

test("the run refuses traces that are not two captures of each of two sides", () => {
  assert.throws(
    () => run(["baseline.upstream.json", "baseline.psflow.json"]),
    (e) => e instanceof RunError && /two captures/.test(e.message)
  );
  assert.throws(
    () => run(["baseline.psflow.json", "baseline.psflow.capture2.json", "baseline.psflow.json", "baseline.psflow.capture2.json"]),
    (e) => e instanceof RunError
  );
});

test("upstream reads left, whichever order the traces arrived in", () => {
  const forwards = run(CLEAN);
  const backwards = run([...CLEAN].reverse());

  assert.equal(forwards.comparison.left.side, "upstream");
  assert.equal(backwards.comparison.left.side, "upstream");
  assert.deepEqual(backwards.consistency.map((c) => c.side), ["upstream", "psflow"]);
});

test("a stale region fails the run under its own name", () => {
  const regions = [
    {
      id: "nothing-here",
      kind: "intentional",
      reason: "claims a difference these traces do not have",
      affirmedAgainst: "12.11.0",
      path: "console/**",
      recorded: [],
    },
  ];

  const result = run(CLEAN, { regions });

  assert.equal(result.ok, false);
  assert.deepEqual(
    result.failures.map((f) => f.class),
    [FAILURE.staleRegion]
  );
  assert.deepEqual(result.failures[0].regions, ["nothing-here"]);
});
