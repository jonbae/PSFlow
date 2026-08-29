import { test } from "node:test";
import assert from "node:assert/strict";

import { validateTrace } from "../trace-format.mjs";
import { DrivingLogError, createDrivingLog } from "./driving.mjs";

const box = { x: 75, y: 25, width: 150, height: 36 };

test("actions are indexed in the order they were driven, from zero", () => {
  const log = createDrivingLog();
  log.record({ action: "pointerDown", target: ".a", resolved: true, box, dispatched: { x: 1, y: 2 } });
  log.record({ action: "pointerUp", target: null, resolved: true, box: null, dispatched: { x: 1, y: 2 } });

  assert.deepEqual(
    log.entries().map((e) => [e.index, e.action]),
    [
      [0, "pointerDown"],
      [1, "pointerUp"],
    ]
  );
});

test("every entry carries all five fields, nulls included", () => {
  const log = createDrivingLog();
  log.record({ action: "call", resolved: true, dispatched: { method: "zoomIn", args: [] } });

  assert.deepEqual(log.entries()[0], {
    index: 0,
    action: "call",
    target: null,
    resolved: true,
    box: null,
    dispatched: { method: "zoomIn", args: [] },
  });
});

test("an unresolved target is recorded with no box and nothing dispatched", () => {
  const log = createDrivingLog();
  log.record({ action: "pointerDown", target: ".gone", resolved: false });

  assert.deepEqual(log.entries()[0], {
    index: 0,
    action: "pointerDown",
    target: ".gone",
    resolved: false,
    box: null,
    dispatched: null,
  });
});

// The receipt has to be a receipt. An entry claiming nothing resolved while
// carrying the box it resolved to is not a recording of anything that happened.
test("an unresolved entry carrying a box or a dispatch is a bug, not a record", () => {
  const log = createDrivingLog();

  assert.throws(() => log.record({ action: "pointerDown", target: ".gone", resolved: false, box }), DrivingLogError);
  assert.throws(
    () => log.record({ action: "pointerDown", target: ".gone", resolved: false, dispatched: { x: 1, y: 2 } }),
    DrivingLogError
  );
});

test("a resolved action must say what it dispatched", () => {
  const log = createDrivingLog();

  assert.throws(() => log.record({ action: "pointerDown", target: ".a", resolved: true, box }), DrivingLogError);
});

test("an action needs a name and a verdict", () => {
  const log = createDrivingLog();

  assert.throws(() => log.record({ resolved: true, dispatched: {} }), DrivingLogError);
  assert.throws(() => log.record({ action: "", resolved: true, dispatched: {} }), DrivingLogError);
  assert.throws(() => log.record({ action: "pointerDown", dispatched: {} }), DrivingLogError);
});

test("a recorded entry cannot be edited afterwards", () => {
  const log = createDrivingLog();
  log.record({ action: "pointerDown", target: ".a", resolved: true, box, dispatched: { x: 1, y: 2 } });

  const [entry] = log.entries();
  assert.throws(() => {
    entry.resolved = false;
  }, TypeError);
  assert.equal(log.entries()[0].resolved, true);
});

test("entries() hands out a copy, so a caller cannot lengthen the log", () => {
  const log = createDrivingLog();
  log.record({ action: "call", resolved: true, dispatched: { method: "zoomIn", args: [] } });

  log.entries().push({ index: 99 });
  assert.equal(log.entries().length, 1);
});

// The section is written straight into a trace, so what the format accepts is
// the only definition of well-formed that matters.
test("what the log produces is what the trace format accepts", () => {
  const log = createDrivingLog();
  log.record({ action: "pointerDown", target: ".a", resolved: true, box, dispatched: { x: 150, y: 43 } });
  log.record({ action: "pointerMove", target: null, resolved: true, box: null, dispatched: { x: 160, y: 53 } });
  log.record({ action: "wheel", target: ".gone", resolved: false });
  log.record({ action: "call", resolved: true, dispatched: { method: "zoomIn", args: [] } });

  const trace = {
    traceFormat: 2,
    scenario: "driving-log-shape",
    side: "psflow",
    capture: 1,
    baseline: "12.11.0",
    sections: {
      dom: { page: { scrollX: 0, scrollY: 0, visualViewportScale: 1 }, root: null },
      callbacks: [],
      hooks: {},
      api: { queries: {}, calls: [] },
      props: {},
      console: [],
      driving: log.entries(),
    },
  };

  assert.equal(validateTrace(trace, "in-memory"), trace);
});
