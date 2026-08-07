import { test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { SECTIONS, readTrace } from "../trace-format.mjs";
import { REPORT_ORDER, compareTraces } from "./index.mjs";
import { renderReport } from "./report.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const fixturePath = (name) => join(here, "fixtures", name);
const fixture = (name) => readTrace(fixturePath(name));

const CLI = join(here, "..", "compare.mjs");

const SORT_RULES = [
  { kind: "sort", at: "dom/**/attrs/class", as: "tokens", reason: "class token order is not semantic" },
  { kind: "sort", at: "dom/**/attrs/style", as: "declarations", reason: "declaration order is not semantic" },
];

test("the report leads with the driving log, because inputs that differed frame everything after", () => {
  assert.equal(REPORT_ORDER[0], "driving");
  // A section added to the format and not to the report order would be captured
  // and never compared, which is the silent-pass shape this repo keeps paying for.
  assert.deepEqual([...REPORT_ORDER].sort(), [...SECTIONS].sort());
});

test("two traces that agree compare clean", () => {
  const result = compareTraces(fixture("baseline.upstream.json"), fixture("baseline.psflow.json"), {});

  assert.equal(result.ok, true);
  assert.deepEqual(result.differences, []);
  assert.match(renderReport(result), /No unclaimed differences/);
});

test("comparing two different scenarios is a mistake, not a difference", () => {
  const other = fixture("baseline.psflow.json");
  other.scenario = "drag-node-release";

  assert.throws(() => compareTraces(fixture("baseline.upstream.json"), other, {}), /scenario/);
});

test("normalization runs before comparison, so reordering never reaches the report", () => {
  const result = compareTraces(fixture("baseline.upstream.json"), fixture("precise-coordinate.psflow.json"), {
    rules: SORT_RULES,
  });

  assert.equal(result.ok, false);
  assert.equal(result.differences.length, 1);
  assert.equal(result.unclaimed.length, 1);
  assert.match(renderReport(result), /75\.00017302302994px/);
});

test("an unclaimed difference fails the run and is reported under its section", () => {
  const result = compareTraces(fixture("baseline.upstream.json"), fixture("precise-coordinate.psflow.json"), {});
  const report = renderReport(result);

  assert.equal(result.ok, false);
  assert.equal(result.unclaimed.length, 2);
  assert.match(report, /## Unclaimed differences/);
  assert.match(report, /### dom \(2\)/);
});

test("a difference claimed by a region does not fail the run", () => {
  const regions = [
    {
      id: "layout-float-drift",
      kind: "known-divergence",
      reason: "PSFlow's layout math accumulates 1.7e-4 where upstream lands on whole pixels",
      ticket: "https://github.com/jonbae/PSFlow/issues/22",
      affirmedAgainst: "12.11.0",
      path: "dom/**/attrs/style",
      recorded: [
        {
          path: "dom/root/children/div[0]/children/1/attrs/style",
          kind: "changed",
          left: "z-index: 0; transform: translate(75px, 25px); pointer-events: all; visibility: visible;",
          right:
            "pointer-events: all; transform: translate(75.00017302302994px, 25.000038167661856px); visibility: visible; z-index: 0;",
        },
      ],
    },
  ];

  const result = compareTraces(fixture("baseline.upstream.json"), fixture("precise-coordinate.psflow.json"), {
    regions,
  });

  assert.equal(result.unclaimed.length, 1, "the class reorder is still unclaimed");
  assert.equal(result.outcomes[0].status, "rides-free");
  assert.match(renderReport(result), /layout-float-drift/);
});

test("the report names both sides by the identity their traces carry", () => {
  const report = renderReport(compareTraces(fixture("baseline.upstream.json"), fixture("baseline.psflow.json"), {}));

  assert.match(report, /mount-baseline--nodes-general/);
  assert.match(report, /upstream/);
  assert.match(report, /psflow/);
  assert.match(report, /12\.11\.0/);
});

test("the deleted fields are reported as unobserved rather than as agreement", () => {
  const result = compareTraces(fixture("baseline.upstream.json"), fixture("baseline.psflow.json"), {
    rules: [{ kind: "delete", at: "dom/**/attrs/data-testid", reason: "harness-injected" }],
  });

  assert.equal(result.ok, true);
  assert.match(renderReport(result), /unobserved/i);
});

test("the CLI produces a report and passes on an agreeing pair", () => {
  const out = join(mkdtempSync(join(tmpdir(), "psflow-compare-")), "report.md");
  execFileSync(process.execPath, [CLI, fixturePath("baseline.upstream.json"), fixturePath("baseline.psflow.json"), "--out", out]);

  assert.match(readFileSync(out, "utf8"), /No unclaimed differences/);
});

test("the CLI exits non-zero on an unclaimed difference", () => {
  assert.throws(
    () =>
      execFileSync(process.execPath, [CLI, fixturePath("baseline.upstream.json"), fixturePath("precise-coordinate.psflow.json")], {
        stdio: "pipe",
      }),
    (e) => e.status === 1
  );
});
