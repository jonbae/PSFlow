import { test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { SECTIONS, readTrace } from "../trace-format.mjs";
import { validateWeakenings } from "./callbacks.mjs";
import { REPORT_ORDER, compareTraces } from "./index.mjs";
import { validateRules } from "./normalize.mjs";
import { formatPath } from "./paths.mjs";
import { validateRegions } from "./regions.mjs";
import { renderReport } from "./report.mjs";
import { compareRun } from "./run.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const fixturePath = (name) => join(here, "fixtures", name);
const fixture = (name) => readTrace(fixturePath(name));

const CLI = join(here, "..", "compare.mjs");
const committed = (name) => JSON.parse(readFileSync(join(here, "..", name), "utf8"));
const SORT_RULES = committed("normalization.json").rules;

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

test("a driving divergence is reported first and frames the rest as consequences, suppressing none of them", () => {
  const result = compareTraces(fixture("baseline.upstream.json"), fixture("missed-target.psflow.json"), {
    rules: SORT_RULES,
  });
  const report = renderReport(result);

  assert.equal(result.driving.diverged, true);
  assert.ok(report.indexOf("### driving") < report.indexOf("### dom"), "the receipt for the input side leads");
  assert.match(report, /The inputs differed/);
  assert.match(report, /### dom \(1\) — consequence of the driving divergence/);
  // Framing is not filtering: the layout difference underneath is still here,
  // and is exactly where a real divergence would be hiding.
  assert.ok(result.unclaimed.some((d) => d.path[0] === "dom"));
  assert.match(report, /75\.00017302302994px/);
});

test("a driving log that agrees frames nothing", () => {
  const report = renderReport(compareTraces(fixture("baseline.upstream.json"), fixture("precise-coordinate.psflow.json"), {}));

  assert.doesNotMatch(report, /consequence/);
});

test("a region can claim a driving difference; it cannot make the sections after it readable", () => {
  const regions = [
    {
      id: "psflow-misses-the-node",
      kind: "known-divergence",
      reason: "the node PSFlow rendered is not where the selector looked",
      ticket: "https://github.com/jonbae/PSFlow/issues/22",
      affirmedAgainst: "12.11.0",
      path: "driving/**",
      recorded: [],
    },
  ];
  const result = compareTraces(fixture("baseline.upstream.json"), fixture("missed-target.psflow.json"), { regions });

  assert.equal(result.unclaimed.every((d) => d.path[0] !== "driving"), true, "the region claimed them");
  assert.equal(result.driving.diverged, true, "and the two runs are still not one experiment");

  const report = renderReport(result);
  assert.match(report, /consequence of the driving divergence/);
  assert.match(report, /does not fail on it.*decision about pass and fail/s);
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

test("the CLI reads four traces as one run and passes when both sides reproduced", () => {
  const out = join(mkdtempSync(join(tmpdir(), "psflow-compare-")), "report.md");
  execFileSync(process.execPath, [
    CLI,
    fixturePath("baseline.upstream.json"),
    fixturePath("baseline.upstream.capture2.json"),
    fixturePath("baseline.psflow.json"),
    fixturePath("baseline.psflow.capture2.json"),
    "--out",
    out,
  ]);

  const report = readFileSync(out, "utf8");
  assert.match(report, /## Self-consistency/);
  assert.match(report, /No unclaimed differences/);
});

test("the CLI fails a run whose sides agree with each other but not with themselves", () => {
  assert.throws(
    () =>
      execFileSync(
        process.execPath,
        [
          CLI,
          fixturePath("baseline.upstream.json"),
          fixturePath("baseline.upstream.capture2.json"),
          fixturePath("baseline.psflow.json"),
          fixturePath("wobbling-box.psflow.capture2.json"),
        ],
        { stdio: "pipe" }
      ),
    (e) => e.status === 1 && /psflow disagrees with itself/.test(String(e.stdout))
  );
});

test("the two-trace form says that self-consistency went unchecked", () => {
  const out = join(mkdtempSync(join(tmpdir(), "psflow-compare-")), "report.md");
  execFileSync(process.execPath, [CLI, fixturePath("baseline.upstream.json"), fixturePath("baseline.psflow.json"), "--out", out]);

  assert.match(readFileSync(out, "utf8"), /Not checked/);
});

test("the CLI exits 2 on traces that are not two captures of each of two sides", () => {
  assert.throws(
    () =>
      execFileSync(
        process.execPath,
        [
          CLI,
          fixturePath("baseline.upstream.json"),
          fixturePath("baseline.psflow.json"),
          fixturePath("baseline.psflow.capture2.json"),
          fixturePath("precise-coordinate.psflow.json"),
        ],
        { stdio: "pipe" }
      ),
    (e) => e.status === 2 && /two captures of each side/.test(String(e.stderr))
  );
});

test("the CLI exits 2 on a trace it cannot interpret, rather than comparing what is left", () => {
  const broken = join(mkdtempSync(join(tmpdir(), "psflow-compare-")), "broken.json");
  const trace = fixture("baseline.psflow.json");
  delete trace.sections.console;
  writeFileSync(broken, JSON.stringify(trace));

  assert.throws(
    () => execFileSync(process.execPath, [CLI, fixturePath("baseline.upstream.json"), broken], { stdio: "pipe" }),
    (e) => e.status === 2 && /sections\/console is missing/.test(String(e.stderr))
  );
});

test("the committed ruleset and both registers are themselves legal", () => {
  assert.doesNotThrow(() => validateRules(committed("normalization.json").rules));
  assert.doesNotThrow(() => validateRegions(committed("regions.json").regions));
  assert.doesNotThrow(() => validateWeakenings(committed("weakenings.json").weakenings));
});

// ── Callbacks ──────────────────────────────────────────────────────────────
// The section nothing else can stand in for: a handler that never fired leaves
// the DOM identical, so every other section of these two traces agrees.

test("a handler that fired on one side and not the other fails, though nothing else differs", () => {
  const result = compareTraces(fixture("baseline.upstream.json"), fixture("silent-handler.psflow.json"), {
    rules: SORT_RULES,
  });

  assert.equal(result.ok, false);
  assert.deepEqual(
    result.unclaimed.map((d) => `${d.kind} ${formatPath(d.path)}`),
    ["left-only callbacks/1"]
  );
  assert.match(renderReport(result), /### callbacks \(1\)/);
});

test("a weakening is read from the register and forgives the count it names", () => {
  const weakenings = [
    {
      callback: "onNodesChange",
      kind: "count",
      reason: "the second node's measurement lands in one batch upstream and two here",
      ticket: "https://github.com/jonbae/PSFlow/issues/22",
    },
  ];

  const result = compareTraces(fixture("baseline.upstream.json"), fixture("silent-handler.psflow.json"), {
    rules: SORT_RULES,
    weakenings,
  });

  assert.equal(result.ok, true);
  assert.deepEqual(result.unclaimed, []);
  assert.match(renderReport(result), /## Callback weakenings/);
});

test("a weakening that forgives nothing fails the run, with nothing for --record to write back", () => {
  const weakenings = [{ callback: "onNodesChange", kind: "order", reason: "a reason that has outlived its cause" }];

  const result = compareTraces(fixture("baseline.upstream.json"), fixture("baseline.psflow.json"), { weakenings });

  assert.equal(result.ok, false);
  assert.deepEqual(result.unclaimed, [], "nothing differed — the failure is the entry itself");
  assert.equal(result.weakenings[0].status, "stale");
  assert.match(renderReport(result), /stale callback weakening/);
});

test("self-consistency compares the call log too, and no weakening reaches it", () => {
  const weakenings = [{ callback: "onNodesChange", kind: "count", reason: "irrelevant here, and that is the point" }];
  const run = compareRun(
    [
      fixture("baseline.upstream.json"),
      fixture("baseline.upstream.capture2.json"),
      fixture("baseline.psflow.json"),
      fixture("restless-handler.psflow.capture2.json"),
    ],
    { rules: SORT_RULES, weakenings }
  );

  assert.equal(run.ok, false);
  const [psflow] = run.consistency.filter((side) => side.side === "psflow");
  assert.equal(psflow.consistent, false);
  assert.deepEqual(
    psflow.differences.map((d) => `${d.kind} ${formatPath(d.path)}`),
    ["right-only callbacks/2"]
  );
});
