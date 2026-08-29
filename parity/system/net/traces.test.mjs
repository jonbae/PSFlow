import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { TraceFormatError } from "../trace-format.mjs";
import { TraceStoreError, orphanedTraces, readRun, runNames, storedScenarios, traceName, writeTrace } from "./traces.mjs";

const trace = (side, capture, scenario = "mount-baseline--nodes-general") => ({
  traceFormat: 2,
  scenario,
  side,
  capture,
  baseline: "12.11.0",
  sections: {
    dom: { page: { scrollX: 0, scrollY: 0, visualViewportScale: 1 }, root: null },
    callbacks: [],
    hooks: {},
    api: { queries: {}, calls: [] },
    props: {},
    console: [],
    driving: [],
  },
});

const store = () => mkdtempSync(join(tmpdir(), "psflow-traces-"));

const full = (dir, scenario = "mount-baseline--nodes-general") => {
  for (const side of ["psflow", "upstream"]) for (const capture of [1, 2]) writeTrace(dir, trace(side, capture, scenario));
  return dir;
};

test("a trace file is named after the envelope it carries, so a run's four sort together", () => {
  assert.equal(traceName("mount-baseline--nodes-general", "psflow", 2), "mount-baseline--nodes-general.psflow.capture2.json");
  assert.deepEqual(runNames("mount-baseline--pane-general"), [
    "mount-baseline--pane-general.psflow.capture1.json",
    "mount-baseline--pane-general.psflow.capture2.json",
    "mount-baseline--pane-general.upstream.capture1.json",
    "mount-baseline--pane-general.upstream.capture2.json",
  ]);
});

// The disk is the seam the whole comparison half is built around — a revised
// noise policy re-diffs every trace ever captured without a browser — so what
// comes back has to be what went out.
test("a trace written out reads back identical, and validated on the way in", () => {
  const dir = full(store());
  const run = readRun(dir, "mount-baseline--nodes-general");

  assert.deepEqual(run.map((t) => [t.side, t.capture]).sort(), [
    ["psflow", 1],
    ["psflow", 2],
    ["upstream", 1],
    ["upstream", 2],
  ]);
  assert.deepEqual(run[0], trace("psflow", 1));
});

// Three traces compare as "self-consistency went unchecked on one side", which
// is a gate proving less than its name while still reporting.
test("a run missing one of its four traces is an error, not a run of three", () => {
  const dir = store();
  writeTrace(dir, trace("psflow", 1));
  writeTrace(dir, trace("psflow", 2));
  writeTrace(dir, trace("upstream", 1));

  assert.throws(() => readRun(dir, "mount-baseline--nodes-general"), (e) => {
    assert.ok(e instanceof TraceStoreError);
    assert.match(e.message, /upstream\.capture2/);
    return true;
  });
});

test("a stored trace that is not a valid trace fails as one, on the way in", () => {
  const dir = full(store());
  writeFileSync(join(dir, "mount-baseline--nodes-general.psflow.capture1.json"), '{"traceFormat":1}\n');

  assert.throws(() => readRun(dir, "mount-baseline--nodes-general"), TraceFormatError);
});

// Re-diffing must not need the vendored checkout: without this the traces being
// committed would buy nothing on a clean clone, and a bumped baseline could not
// re-diff the previous one's stored traces — which is why they are in the repo.
test("the scenarios on disk are readable from the file names alone, with no corpus", () => {
  const dir = full(store());
  full(dir, "mount-baseline--pane-general");

  assert.deepEqual(storedScenarios(dir), ["mount-baseline--nodes-general", "mount-baseline--pane-general"]);
});

// A trace left behind by a renamed scenario is stale in exactly the sense every
// register here uses: it stops corresponding to anything real, and it sits in
// the repo being read as a recorded divergence.
test("traces no scenario in the corpus claims are reported as orphans", () => {
  const dir = full(store());
  full(dir, "mount-baseline--gone-away");

  assert.deepEqual(orphanedTraces(dir, [{ id: "mount-baseline--nodes-general" }]), [
    "mount-baseline--gone-away.psflow.capture1.json",
    "mount-baseline--gone-away.psflow.capture2.json",
    "mount-baseline--gone-away.upstream.capture1.json",
    "mount-baseline--gone-away.upstream.capture2.json",
  ]);
  assert.deepEqual(
    orphanedTraces(dir, [{ id: "mount-baseline--nodes-general" }, { id: "mount-baseline--gone-away" }]),
    []
  );
});
