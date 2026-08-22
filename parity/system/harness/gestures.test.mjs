import { test } from "node:test";
import assert from "node:assert/strict";

import { createDrivingLog } from "./driving.mjs";
import { createFakePort } from "./fake-port.mjs";
import { createPrimitives } from "./actions.mjs";
import { GESTURES, createGestures } from "./gestures.mjs";

const NODE = { x: 75, y: 25, width: 150, height: 36 }; // centre (150, 43)
const OTHER = { x: 275, y: 125, width: 100, height: 40 }; // centre (325, 145)
const PANE = { x: 0, y: 0, width: 800, height: 600 }; // centre (400, 300)

// Not `harness()`: the **harness** is `parity/system/harness/`, the net's
// capture half, and a local factory of the same name would make the word mean
// two things in one directory.
const bench = () => {
  const { port, sent } = createFakePort({
    boxes: {
      ".node": NODE,
      ".other": OTHER,
      ".react-flow__pane": PANE,
      ".source-handle": NODE,
      ".target-handle": OTHER,
    },
  });
  const log = createDrivingLog();
  const primitives = createPrimitives(port, log, []);
  return { actions: { ...primitives, ...createGestures(primitives) }, log, sent };
};

// What a gesture *is*: a named composition of primitives. The assertion that
// matters is therefore the decomposition, and the driving log is where it is
// legible — which is the same property coverage derivation depends on.
//
// Named for the glossary's **driven** rather than "steps": an entry in the
// driving log is an **action**, which the glossary tells us not to call a step,
// and a `steps` here would read as the gesture option of that name two lines
// below it.
const driven = (log) => log.entries().map((e) => [e.action, e.target, e.dispatched]);

test("the gesture tier is the six the spec names, and it is open by addition", () => {
  assert.deepEqual(GESTURES, ["click", "dragNode", "selectionBox", "connect", "pan", "pinch", "arrowKeyNudge"]);
});

// The gesture almost every lifted spec opens with. Playwright's own `click()`
// moves to the element, presses and releases without resolving it a second
// time, and so does this: an element that moved under the press is a finding,
// not something to chase.
test("click presses on its target and releases where the press landed", async () => {
  const { actions, log } = bench();
  await actions.click(".node");

  assert.deepEqual(driven(log), [
    ["pointerDown", ".node", { x: 150, y: 43, button: "left" }],
    ["pointerUp", null, { x: 150, y: 43, button: "left" }],
  ]);
});

// The offset form is what a lifted spec is usually written in — upstream aims
// at an edge's box centre plus a nudge to land inside its interaction width.
test("click takes a point, so a spec's own offset survives the lift", async () => {
  const { actions, log } = bench();
  await actions.click({ target: ".node", dx: 21 });

  assert.deepEqual(driven(log), [
    ["pointerDown", ".node", { x: 171, y: 43, button: "left" }],
    ["pointerUp", null, { x: 171, y: 43, button: "left" }],
  ]);
});

// Held across the press and released after it, the same shape `selectionBox`
// gives Shift. Upstream's multi-selection specs press `s` because the fixtures
// set `multiSelectionKeyCode: 's'` — Meta does not survive their runner.
test("click holds a modifier across the press and releases it after", async () => {
  const { actions, log } = bench();
  await actions.click(".other", { modifier: "s" });

  assert.deepEqual(driven(log), [
    ["key", null, { key: "s", action: "down" }],
    ["pointerDown", ".other", { x: 325, y: 145, button: "left" }],
    ["pointerUp", null, { x: 325, y: 145, button: "left" }],
    ["key", null, { key: "s", action: "up" }],
  ]);
});

test("click on a target that is not there records the skip and drives on", async () => {
  const { actions, log, sent } = bench();
  await actions.click(".missing");

  assert.deepEqual(
    log.entries().map((e) => [e.action, e.resolved]),
    [
      ["pointerDown", false],
      ["pointerUp", true],
    ]
  );
  assert.equal(sent.length, 1, "the press never happened; the release still did, from where the pointer was");
});

test("dragNode presses on the node, moves in even steps, and releases", async () => {
  const { actions, log } = bench();
  await actions.dragNode(".node", { dx: 100, dy: 40, steps: 4 });

  assert.deepEqual(driven(log), [
    ["pointerDown", ".node", { x: 150, y: 43, button: "left" }],
    ["pointerMove", null, { x: 175, y: 53 }],
    ["pointerMove", null, { x: 200, y: 63 }],
    ["pointerMove", null, { x: 225, y: 73 }],
    ["pointerMove", null, { x: 250, y: 83 }],
    ["pointerUp", null, { x: 250, y: 83, button: "left" }],
  ]);
});

// Mid-drag the node follows the pointer, so a target-relative move would chase
// what it is dragging. The moves are pointer-relative for that reason, and the
// per-step delta is computed from the cumulative offset so `steps` never
// changes where the gesture ends up.
test("a drag ends in the same place however many steps it takes", async () => {
  const end = async (n) => {
    const { actions, log } = bench();
    await actions.dragNode(".node", { dx: 100, dy: 40, steps: n });
    return log.entries().at(-1).dispatched;
  };

  assert.deepEqual(await end(3), { x: 250, y: 83, button: "left" });
  assert.deepEqual(await end(7), { x: 250, y: 83, button: "left" });
});

test("dragNode on a node that is not there records the skip and drives on", async () => {
  const { actions, log, sent } = bench();
  await actions.dragNode(".missing", { dx: 10, dy: 10, steps: 1 });

  assert.deepEqual(
    log.entries().map((e) => [e.action, e.resolved]),
    [
      ["pointerDown", false],
      ["pointerMove", true],
      ["pointerUp", true],
    ]
  );
  assert.equal(sent.length, 2, "the press never happened; the moves still did, from where the pointer was");
});

test("dragNode returns the entries it drove", async () => {
  const { actions, log } = bench();
  const entries = await actions.dragNode(".node", { dx: 10, dy: 0, steps: 2 });

  assert.deepEqual(entries, log.entries());
});

test("selectionBox holds its modifier across the drag and releases it after", async () => {
  const { actions, log } = bench();
  await actions.selectionBox({ target: ".node", dx: -150, dy: -25, origin: "topLeft" }, { target: ".node", dx: 275, dy: 200, origin: "topLeft" });

  assert.deepEqual(driven(log), [
    ["key", null, { key: "Shift", action: "down" }],
    ["pointerDown", ".node", { x: -75, y: 0, button: "left" }],
    ["pointerMove", ".node", { x: 350, y: 225 }],
    ["pointerUp", null, { x: 350, y: 225, button: "left" }],
    ["key", null, { key: "Shift", action: "up" }],
  ]);
});

test("a selection box can be drawn with no modifier at all", async () => {
  const { actions, log } = bench();
  await actions.selectionBox({ target: ".react-flow__pane" }, { target: ".node" }, { modifier: null });

  assert.deepEqual(
    log.entries().map((e) => e.action),
    ["pointerDown", "pointerMove", "pointerUp"]
  );
});

test("connect presses the source handle, nudges, crosses, and releases on the target", async () => {
  const { actions, log } = bench();
  await actions.connect(".source-handle", ".target-handle");

  assert.deepEqual(driven(log), [
    ["pointerDown", ".source-handle", { x: 150, y: 43, button: "left" }],
    ["pointerMove", ".source-handle", { x: 155, y: 48 }],
    ["pointerMove", ".target-handle", { x: 325, y: 145 }],
    ["pointerUp", ".target-handle", { x: 325, y: 145, button: "left" }],
  ]);
});

// The nudge is target-relative rather than pointer-relative so that dropping it
// changes only whether the move happens, never where the gesture lands.
test("connect's nudge can be turned off without moving the endpoints", async () => {
  const { actions, log } = bench();
  await actions.connect(".source-handle", ".target-handle", { nudge: null });

  assert.deepEqual(driven(log), [
    ["pointerDown", ".source-handle", { x: 150, y: 43, button: "left" }],
    ["pointerMove", ".target-handle", { x: 325, y: 145 }],
    ["pointerUp", ".target-handle", { x: 325, y: 145, button: "left" }],
  ]);
});

// The nudge is a move *away from the press*, so it adds to the grab offset
// rather than replacing it. Overwriting would make the nudge shrink as the grab
// offset grew — a source grabbed at `{ dx: 3 }` under the default 5-pixel nudge
// would move the pointer 2 — which is a gesture quietly doing something other
// than what it says, on both sides, comparing clean.
test("connect's nudge is measured from the grab point, not from the target's centre", async () => {
  const { actions, log } = bench();
  await actions.connect({ target: ".source-handle", dx: 3, dy: -2 }, ".target-handle");

  assert.deepEqual(driven(log).slice(0, 2), [
    ["pointerDown", ".source-handle", { x: 153, y: 41, button: "left" }],
    ["pointerMove", ".source-handle", { x: 158, y: 46 }],
  ]);
});

test("pan drags the pane by default", async () => {
  const { actions, log } = bench();
  await actions.pan({ dx: -50, dy: 100, steps: 2 });

  assert.deepEqual(driven(log), [
    ["pointerDown", ".react-flow__pane", { x: 400, y: 300, button: "left" }],
    ["pointerMove", null, { x: 375, y: 350 }],
    ["pointerMove", null, { x: 350, y: 400 }],
    ["pointerUp", null, { x: 350, y: 400, button: "left" }],
  ]);
});

test("pinch spreads two touch points from the target's centre and ends the gesture", async () => {
  const { actions, log } = bench();
  await actions.pinch(".node", { spread: 20, scale: 2, steps: 2 });

  const entries = log.entries();
  assert.deepEqual(
    entries.map((e) => e.dispatched.type),
    ["touchStart", "touchMove", "touchMove", "touchEnd"]
  );
  assert.deepEqual(
    entries.map((e) => e.dispatched.points.map((p) => p.x)),
    [
      [130, 170], // ±20, the spread it starts at
      [120, 180], // ±30, halfway
      [110, 190], // ±40, spread × scale
      [],
    ]
  );
  assert.deepEqual(
    entries.map((e) => e.dispatched.points.map((p) => p.id)),
    [[1, 2], [1, 2], [1, 2], []]
  );
});

test("a pinch that closes is the same gesture with a scale below one", async () => {
  const { actions, log } = bench();
  await actions.pinch(".node", { spread: 40, scale: 0.5, steps: 1 });

  assert.deepEqual(
    log.entries().map((e) => e.dispatched.points.map((p) => p.x)),
    [
      [110, 190],
      [130, 170],
      [],
    ]
  );
});

test("arrowKeyNudge presses the named direction, focusing its target once", async () => {
  const { actions, log } = bench();
  await actions.arrowKeyNudge("right", { target: ".node", times: 3 });

  assert.deepEqual(driven(log), [
    ["key", ".node", { key: "ArrowRight", action: "press" }],
    ["key", null, { key: "ArrowRight", action: "press" }],
    ["key", null, { key: "ArrowRight", action: "press" }],
  ]);
});

test("a direction that is not one of the four fails rather than pressing a made-up key", async () => {
  const { actions } = bench();
  await assert.rejects(() => actions.arrowKeyNudge("northwest"), /northwest/);
});
