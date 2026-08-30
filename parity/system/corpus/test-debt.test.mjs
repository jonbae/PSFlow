import { test } from "node:test";
import assert from "node:assert/strict";

import { AFTER_MOUNT } from "../../driver/controls.mjs";
import { createDrivingLog } from "../harness/driving.mjs";
import { createFakePort } from "../harness/fake-port.mjs";
import { VOCABULARY, createVocabulary } from "../harness/vocabulary.mjs";
import { RESERVED } from "./reserved.mjs";
import { ROUTE_PREFIX } from "./routes.mjs";
import { testDebtScenarios } from "./test-debt.mjs";

const byId = new Map(testDebtScenarios.map((scenario) => [scenario.id, scenario]));

// A page on which **everything resolves** and the imperative bridge is
// installed. `createFakePort` keys its boxes off exact selector strings, which
// would make this file a second copy of every selector in the corpus — and a
// copy that went stale would leave a scenario recording unresolved actions here
// and passing anyway. What is under test is the *shape* of the action sequence,
// so the two answers a scenario's shape depends on are given unconditionally.
const everythingResolves = () => {
  const { port } = createFakePort({ bridge: () => null });
  return { ...port, box: async () => ({ x: 100, y: 100, width: 40, height: 20 }) };
};

/**
 * Runs one scenario and returns the driving log it produced, plus the API calls
 * it made. That is the whole of what a scenario is: the actions it takes are
 * exactly the entries it records, which is what the two-tier vocabulary was
 * closed for.
 */
const drive = async (scenario) => {
  const log = createDrivingLog();
  const apiCalls = [];
  await scenario.run(createVocabulary(everythingResolves(), log, apiCalls));
  return { entries: log.entries(), apiCalls };
};

test("the thirty are exactly the thirty ids reserved for them", () => {
  assert.equal(testDebtScenarios.length, 30);
  assert.deepEqual(
    testDebtScenarios.map(({ id }) => id).sort(),
    Object.keys(RESERVED).sort()
  );
});

// The check that costs nothing and would be the expensive one to discover from
// a red run: a route the page does not serve answers 404, and the trace records
// it as a mount that never resolved followed by a scenario whose every action
// also failed to resolve — which reads as a total library divergence.
test("every scenario mounts a route in the driver's flat route space", () => {
  for (const { id, route } of testDebtScenarios) {
    assert.ok(route.startsWith("/"), `${id}: ${route}`);
    assert.ok(
      route.startsWith(`${ROUTE_PREFIX}/`) || route.startsWith("/examples/"),
      `${id} names ${route}, which is neither a fixture route nor a directly mounted component`
    );
  }
});

// A scenario is handed the vocabulary and nothing else, so this cannot fail by
// a scenario reaching past it — but it can fail by a scenario calling something
// that is not there at all, which throws at run time inside a browser session
// rather than here.
test("every action a scenario takes is in the named vocabulary", async () => {
  for (const scenario of testDebtScenarios) {
    const { entries } = await drive(scenario);
    assert.ok(entries.length > 0, `${scenario.id} drives nothing`);
    for (const entry of entries) {
      assert.ok(
        VOCABULARY.includes(entry.action),
        `${scenario.id} recorded ${entry.action}, which is not a primitive or a gesture`
      );
    }
  }
});

// The four that have to settle **mid-gesture**, because the state each one is
// about exists only while an input is held: a selection rectangle, an aborted
// drag still being held, a connection line. Named rather than derived — that a
// scenario ends this way is a decision about what it observes, and one that
// quietly stopped doing it would go on passing while measuring the aftermath.
//
// `drag-node-autopan` is deliberately not among them, though its behaviour is
// also live only while the pointer is down: autopan runs on a frame loop, so a
// page still holding it never settles and the run aborts instead of recording.
// It dwells and then releases; `test-debt.mjs` says why that costs nothing.
const MID_GESTURE = {
  "drag-node-escape-mid-gesture": "the drag state after an abort, still held",
  "selection-box-mid-gesture": "the selection rectangle exists only mid-drag",
  "connect-then-keyboard-move": "the connection line does not survive the release",
  "connect-second-touch-point": "a second finger during a connection still in progress",
};

const RELEASES = new Set(["pointerUp", "touch"]);

test("the mid-gesture scenarios end with the input still down", async () => {
  for (const [id, why] of Object.entries(MID_GESTURE)) {
    const scenario = byId.get(id);
    assert.ok(scenario, `${id} is not in the corpus`);

    const { entries } = await drive(scenario);
    const last = entries.at(-1);
    assert.ok(last, `${id} drives nothing`);
    assert.ok(
      !RELEASES.has(last.action) || last.dispatched?.type === "touchMove",
      `${id} ends on ${last.action}, releasing the input — ${why}`
    );
  }
});

test("no other scenario is left mid-gesture by accident", async () => {
  for (const scenario of testDebtScenarios) {
    if (scenario.id in MID_GESTURE) continue;

    const { entries } = await drive(scenario);
    const held = entries.filter((e) => e.action === "pointerDown").length - entries.filter((e) => e.action === "pointerUp").length;
    assert.equal(held, 0, `${scenario.id} leaves the pointer down but is not declared mid-gesture`);
  }
});

// Emulation has to be enabled before the document loads, so it is a declared
// capability rather than something the `touch` primitive turns on for itself.
// A scenario that dispatched touch without declaring it would have its events
// accepted and ignored — silently, on both sides, comparing clean.
test("every scenario that touches declares it, and no other does", async () => {
  for (const scenario of testDebtScenarios) {
    const { entries } = await drive(scenario);
    const touches = entries.some((entry) => entry.action === "touch");
    assert.equal(
      touches,
      scenario.touch,
      scenario.touch
        ? `${scenario.id} declares touch and never dispatches one`
        : `${scenario.id} dispatches touch without declaring it`
    );
  }
});

test("the three touch scenarios are the ones the dispositions named", () => {
  assert.deepEqual(
    testDebtScenarios.filter(({ touch }) => touch).map(({ id }) => id).sort(),
    ["connect-second-touch-point", "pinch-over-nowheel-node", "selection-box-touch"]
  );
});

// The four the dispositions flagged, and the reason the warning is carried in
// code as well as in prose: a scenario carrying four rows is four rows lost if
// it is ever trimmed, and the count is not visible from the scenario itself.
test("the four concentration-risk scenarios are all in the corpus", () => {
  for (const id of [
    "connect-handle-to-handle",
    "flow-props-change-after-mount",
    "viewport-helpers-with-options",
    "fitview-onnodeschange-variants",
  ]) {
    assert.ok(byId.has(id), `${id} carries three or four audit rows and is not in the corpus`);
  }
});

// The ten API exports held as a hole under this issue are reached by exactly one
// scenario, so what it calls is worth pinning: an option dropped from one of
// these calls is an export that goes back to being undriven, and the coverage
// artifact would report it as residue rather than as a scenario that changed.
test("the imperative scenario calls every helper with options", async () => {
  const { apiCalls } = await drive(byId.get("viewport-helpers-with-options"));
  const called = apiCalls.map(({ method }) => method);

  for (const method of [
    "setViewport",
    "zoomTo",
    "zoomIn",
    "zoomOut",
    "fitView",
    "setCenter",
    "fitBounds",
    "deleteElements",
  ]) {
    assert.ok(called.includes(method), `viewport-helpers-with-options no longer calls ${method}`);
  }

  // The row is that the helpers pass their options on, so every call has to
  // carry some — and non-default ones, since a helper that ignored its options
  // entirely would answer a default one identically. Each of these takes its
  // options record last, `deleteElements` included, whose sole argument is the
  // `DeleteElementsOptions` the hole named.
  for (const { method, args } of apiCalls) {
    const last = args.at(-1);
    assert.ok(
      last !== null && typeof last === "object" && !Array.isArray(last) && Object.keys(last).length > 0,
      `${method} is called without an options record, so its options export goes undriven`
    );
  }
});

// `updateNode` and the four mutators beside it are the corpus's only source of
// add and replace changes; every other scenario produces dimensions, position,
// select and remove.
test("the uncontrolled scenario drives the mutators that raise add and replace changes", async () => {
  const { apiCalls } = await drive(byId.get("uncontrolled-update-node"));

  assert.deepEqual(
    apiCalls.map(({ method }) => method),
    ["updateNode", "updateNodeData", "addNodes", "addEdges", "updateEdge"]
  );
});

// The driver renders this control only for a fixture declaring `afterMount`,
// and it is the only way a scenario can change a flow prop at all. Its id is
// shared through `driver/controls.mjs` precisely so a rename cannot leave a
// scenario aiming at a button that is no longer called that.
test("the two scenarios that change props after mount aim at the shared control id", async () => {
  for (const id of ["flow-props-change-after-mount", "mount-in-display-none"]) {
    const { entries } = await drive(byId.get(id));
    assert.ok(
      entries.some((entry) => String(entry.target).includes(AFTER_MOUNT)),
      `${id} never presses the after-mount control, so nothing about the flow changes`
    );
  }
});
