import { test } from "node:test";
import assert from "node:assert/strict";

import { createDrivingLog } from "../harness/driving.mjs";
import { createFakePort } from "../harness/fake-port.mjs";
import { createVocabulary } from "../harness/vocabulary.mjs";
import { RESERVED } from "./reserved.mjs";
import { seedScenarios } from "./seed.mjs";

const byId = (id) => {
  const found = seedScenarios.find((s) => s.id === id);
  assert.ok(found, `no seed scenario ${id}`);
  return found;
};

// Boxes for everything the seed aims at, so a scenario can be driven with no
// browser and the driving log read back. Sizes are arbitrary; what the
// assertions are about is which target each action named and where in the box
// it landed, which is exactly what the log records.
const BOXES = {
  ".react-flow__pane": { x: 0, y: 0, width: 1280, height: 720 },
  ".react-flow__node": { x: 100, y: 100, width: 150, height: 36 },
  '.react-flow__node[data-id="drag-handle"]': { x: 400, y: 100, width: 150, height: 36 },
  ".custom-drag-handle": { x: 410, y: 106, width: 20, height: 20 },
  '[data-id="interaction-width"]': { x: 200, y: 300, width: 100, height: 60 },
  '.react-flow__handle[data-nodeid="Node-1"]': { x: 170, y: 132, width: 6, height: 6 },
  '.react-flow__handle[data-nodeid="Node-4"]': { x: 170, y: 500, width: 6, height: 6 },
  '[data-testid="colormode-select"]': { x: 1100, y: 20, width: 80, height: 24 },
};

const drive = async (scenario) => {
  const { port } = createFakePort({ boxes: BOXES });
  const log = createDrivingLog();
  await scenario.run(createVocabulary(port, log, []));
  return log.entries();
};

const driven = (entries) => entries.map((e) => [e.action, e.target, e.dispatched]);

test("the seed lifts one scenario per distinct interaction sequence, not one per test", () => {
  // Upstream's five spec files hold 43 tests. Most of the static ones collapse
  // into their fixture's mount-only baseline, and two are deliberately not
  // lifted at all — `fork.json` is where each of those decisions is written
  // down and gated. What is left is this, and the number is a consequence
  // rather than a target.
  assert.equal(seedScenarios.length, 25);
});

test("every seed scenario has a semantic id and a route", () => {
  for (const { id, route } of seedScenarios) {
    assert.doesNotMatch(id, /^s?\d+$/i, id);
    assert.ok(route.startsWith("/"), `${id}: ${route}`);
  }
});

test("no two seed scenarios share an id", () => {
  const ids = seedScenarios.map((s) => s.id);
  assert.deepEqual([...new Set(ids)], ids);
});

// The collision that would be invisible afterwards: `gate-pending` only asks
// whether the name is in the corpus, so a seed scenario holding a reserved name
// would report a row as driven that nothing drove.
test("the seed claims no id reserved for the test-debt scenarios", () => {
  for (const { id } of seedScenarios) assert.ok(!(id in RESERVED), `${id} is reserved (was ${RESERVED[id]})`);
});

// The seed drives the four vendored fixtures and the example driver, and
// nothing else. A route that is not one of those is a scenario mounting a page
// nobody registered, which would read as an unresolved mount rather than as the
// typo it is.
test("the seed drives only routes the driver page serves", () => {
  const known = new Set([
    "/tests/generic/edges/general",
    "/tests/generic/nodes/general",
    "/tests/generic/node-toolbar/general",
    "/tests/generic/pane/general",
    "/tests/generic/pane/non-defaults",
    "/examples/color-mode",
  ]);

  for (const { id, route } of seedScenarios) assert.ok(known.has(route), `${id} mounts ${route}`);
});

// Touch is a declared page-level capability, and declaring it everywhere would
// narrow the whole net to a touch-capable browser. Nothing upstream's suite
// does needs one.
test("no seed scenario declares touch", () => {
  for (const { id, touch } of seedScenarios) assert.equal(touch, false, id);
});

// A scenario is handed the vocabulary and nothing else. This is the seed's own
// half of that claim: every one of them runs to completion against a port that
// answers with canned boxes, so none of them reached for a page, a side or a
// return value that a fake could not supply.
test("every seed scenario drives to completion against a fake port", async () => {
  for (const scenario of seedScenarios) {
    const entries = await drive(scenario);
    assert.ok(entries.length > 0, `${scenario.id} drove nothing`);
  }
});

test("clicking an edge presses on it and releases where the press landed", async () => {
  assert.deepEqual(driven(await drive(byId("click-inside-interaction-width"))), [
    ["pointerDown", '[data-id="interaction-width"]', { x: 271, y: 330, button: "left" }],
    ["pointerUp", null, { x: 271, y: 330, button: "left" }],
  ]);
});

// Upstream's own comment is the reason: Meta does not survive their runner, and
// the fixtures set `multiSelectionKeyCode: 's'`, so the lift presses what the
// fixture actually listens for.
test("the multi-selection modifier is the key the fixture listens for", async () => {
  const keys = (await drive(byId("multi-select-edges-with-modifier")))
    .filter((e) => e.action === "key")
    .map((e) => [e.dispatched.key, e.dispatched.action]);

  assert.deepEqual(keys, [
    ["s", "down"],
    ["s", "up"],
  ]);
});

// The pane pan is the one lift that drops to primitives, and this is why:
// upstream never releases, so the scenario settles **mid-gesture**. A `pan()`
// would have released and quietly changed what is observed.
test("panning the pane leaves the pointer down, as upstream's own spec does", async () => {
  assert.deepEqual(driven(await drive(byId("drag-pans-the-pane"))), [
    ["pointerDown", ".react-flow__pane", { x: 640, y: 360, button: "left" }],
    ["pointerMove", null, { x: 740, y: 460 }],
  ]);
});

// Both corners are measured from the node's top left, which is the form
// upstream wrote it in — the vocabulary carries a second origin for exactly
// this, and a centre-relative lift would silently draw a different box.
test("the shift-drag selection box keeps upstream's top-left offsets", async () => {
  assert.deepEqual(driven(await drive(byId("shift-drag-selects-nodes"))), [
    ["key", null, { key: "Shift", action: "down" }],
    ["pointerDown", ".react-flow__node", { x: -50, y: 75, button: "left" }],
    ["pointerMove", ".react-flow__node", { x: 375, y: 300 }],
    ["pointerUp", null, { x: 375, y: 300, button: "left" }],
    ["key", null, { key: "Shift", action: "up" }],
  ]);
});

// Two drags, and the first one is the assertion upstream cared about: grabbing
// the node's body must not move it. Lifting only the second would have dropped
// half the scenario while still looking like a drag-handle test.
test("the drag-handle lift grabs the body first and the handle second", async () => {
  const presses = (await drive(byId("drag-by-custom-drag-handle")))
    .filter((e) => e.action === "pointerDown")
    .map((e) => [e.target, e.dispatched]);

  assert.deepEqual(presses, [
    ['.react-flow__node[data-id="drag-handle"]', { x: 410, y: 110, button: "left" }],
    [".custom-drag-handle", { x: 420, y: 116, button: "left" }],
  ]);
});

// The connect gesture resolves its target again at release time, so a handle
// that moved under the connection line is a finding rather than something the
// release follows.
test("connecting releases on the target handle, not where the last move landed", async () => {
  assert.deepEqual(driven(await drive(byId("connect-source-handle-to-target-handle"))), [
    ["pointerDown", '.react-flow__handle[data-nodeid="Node-1"]', { x: 173, y: 135, button: "left" }],
    ["pointerMove", '.react-flow__handle[data-nodeid="Node-1"]', { x: 178, y: 140 }],
    ["pointerMove", '.react-flow__handle[data-nodeid="Node-4"]', { x: 173, y: 503 }],
    ["pointerUp", '.react-flow__handle[data-nodeid="Node-4"]', { x: 173, y: 503, button: "left" }],
  ]);
});

// Upstream reaches for Playwright's `selectOption`, which is not an input event
// and has no place in the closed primitive tier. A focused `<select>` moves to
// its next option on ArrowDown and fires `change` the same way, and `light` is
// the option before `dark`.
test("the colour mode is chosen with a key, inside the closed primitive tier", async () => {
  assert.deepEqual(driven(await drive(byId("select-dark-color-mode"))), [
    ["key", '[data-testid="colormode-select"]', { key: "ArrowDown", action: "press" }],
  ]);
});

// A target that does not resolve is recorded and driven past, never thrown —
// which is what makes a missing element a finding rather than a flake. The seed
// has to survive that, because a fixture that mounted nothing on one side would
// otherwise take the run down with it.
test("a scenario whose targets all miss still drives to the end", async () => {
  const { port } = createFakePort({ boxes: {} });
  const log = createDrivingLog();

  await byId("delete-key-removes-node-and-edges").run(createVocabulary(port, log, []));

  assert.deepEqual(
    log.entries().map((e) => [e.action, e.resolved]),
    [
      ["pointerDown", false],
      ["pointerUp", true],
      ["key", true],
    ]
  );
});
