import { test } from "node:test";
import assert from "node:assert/strict";

import { createDrivingLog } from "./driving.mjs";
import { createFakePort } from "./fake-port.mjs";
import { PRIMITIVES, createPrimitives } from "./actions.mjs";

// A 150×36 node whose top-left is (75, 25), so its centre is (150, 43) — the
// coordinates the trace format's own worked example carries.
const NODE = { x: 75, y: 25, width: 150, height: 36 };
const PANE = { x: 0, y: 0, width: 800, height: 600 };

// Not `harness()`: the **harness** is `parity/system/harness/`, the net's
// capture half, and a local factory of the same name would make the word mean
// two things in one directory.
const bench = (options = {}) => {
  const { port, sent } = createFakePort({ boxes: { ".node": NODE, ".pane": PANE }, ...options });
  const log = createDrivingLog();
  // `api.calls` is the trace section a mutator's return lands in. It is the
  // harness's, not the scenario's: handing a return value back to a scenario
  // is the one way left for it to learn which side it is running against.
  const apiCalls = [];
  return { actions: createPrimitives(port, log, apiCalls), log, sent, apiCalls };
};

test("the primitive tier is closed at the seven the spec names", () => {
  assert.deepEqual(PRIMITIVES, ["pointerDown", "pointerMove", "pointerUp", "key", "wheel", "touch", "call"]);

  const { actions } = bench();
  assert.deepEqual(Object.keys(actions).sort(), [...PRIMITIVES].sort());
});

test("a target resolves to its own box and the pointer lands in the centre", async () => {
  const { actions, log, sent } = bench();
  await actions.pointerDown(".node");

  assert.deepEqual(log.entries(), [
    {
      index: 0,
      action: "pointerDown",
      target: ".node",
      resolved: true,
      box: NODE,
      dispatched: { x: 150, y: 43, button: "left" },
    },
  ]);
  assert.deepEqual(sent, [{ kind: "mouse", type: "down", x: 150, y: 43, button: "left" }]);
});

test("an offset is from the centre by default and from the top-left on request", async () => {
  const { actions, log } = bench();
  await actions.pointerDown(".node", { dx: 10, dy: -5 });
  await actions.pointerDown(".node", { dx: 10, dy: -5, origin: "topLeft" });

  assert.deepEqual(
    log.entries().map((e) => e.dispatched),
    [
      { x: 160, y: 38, button: "left" },
      { x: 85, y: 20, button: "left" },
    ]
  );
});

test("an unknown origin fails at once rather than silently meaning centre", async () => {
  const { actions } = bench();
  await assert.rejects(() => actions.pointerDown(".node", { origin: "middle" }), /origin/);
});

test("a null target moves the pointer relative to where it already is", async () => {
  const { actions, log } = bench();
  await actions.pointerDown(".node");
  await actions.pointerMove(null, { dx: 20, dy: 30 });
  await actions.pointerMove(null, { dx: 20, dy: 30 });
  await actions.pointerUp(null);

  assert.deepEqual(
    log.entries().map((e) => [e.action, e.target, e.box, e.dispatched]),
    [
      ["pointerDown", ".node", NODE, { x: 150, y: 43, button: "left" }],
      ["pointerMove", null, null, { x: 170, y: 73 }],
      ["pointerMove", null, null, { x: 190, y: 103 }],
      ["pointerUp", null, null, { x: 190, y: 103, button: "left" }],
    ]
  );
});

// The rule the whole section exists for.
test("an unresolved target is recorded and skipped, never thrown", async () => {
  const { actions, log, sent } = bench();
  const entry = await actions.pointerDown(".missing");

  assert.equal(entry.resolved, false);
  assert.deepEqual(log.entries(), [
    { index: 0, action: "pointerDown", target: ".missing", resolved: false, box: null, dispatched: null },
  ]);
  assert.deepEqual(sent, [], "nothing may be dispatched for an action that did not resolve");
});

test("driving continues past an unresolved target, and the pointer has not moved", async () => {
  const { actions, log } = bench();
  await actions.pointerDown(".node");
  await actions.pointerMove(".missing");
  await actions.pointerMove(null, { dx: 5, dy: 5 });

  assert.deepEqual(
    log.entries().map((e) => [e.action, e.resolved, e.dispatched]),
    [
      ["pointerDown", true, { x: 150, y: 43, button: "left" }],
      ["pointerMove", false, null],
      ["pointerMove", true, { x: 155, y: 48 }],
    ]
  );
});

test("a key is pressed by default, and down and up are available for a held modifier", async () => {
  const { actions, log, sent } = bench();
  await actions.key("Shift", { action: "down" });
  await actions.key("ArrowRight");
  await actions.key("Shift", { action: "up" });

  assert.deepEqual(
    log.entries().map((e) => [e.target, e.dispatched]),
    [
      [null, { key: "Shift", action: "down" }],
      [null, { key: "ArrowRight", action: "press" }],
      [null, { key: "Shift", action: "up" }],
    ]
  );
  assert.deepEqual(sent.map((s) => [s.kind, s.action, s.key]), [
    ["keyboard", "down", "Shift"],
    ["keyboard", "press", "ArrowRight"],
    ["keyboard", "up", "Shift"],
  ]);
});

test("a targeted key focuses first, and records the box it focused", async () => {
  const { actions, log, sent } = bench();
  await actions.key("ArrowRight", { target: ".node" });

  assert.deepEqual(log.entries()[0], {
    index: 0,
    action: "key",
    target: ".node",
    resolved: true,
    box: NODE,
    dispatched: { key: "ArrowRight", action: "press" },
  });
  assert.deepEqual(sent, [
    { kind: "focus", selector: ".node" },
    { kind: "keyboard", action: "press", key: "ArrowRight" },
  ]);
});

test("an unknown key action fails rather than being dispatched as a name", async () => {
  const { actions } = bench();
  await assert.rejects(() => actions.key("Shift", { action: "hold" }), /hold/);
});

test("a wheel is dispatched over its target and records both the point and the deltas", async () => {
  const { actions, log, sent } = bench();
  await actions.wheel(".node", { deltaY: -120 });

  assert.deepEqual(log.entries()[0].dispatched, { x: 150, y: 43, deltaX: 0, deltaY: -120 });
  assert.deepEqual(sent, [{ kind: "wheel", x: 150, y: 43, deltaX: 0, deltaY: -120 }]);
});

test("touch points resolve individually and the entry names the selector list", async () => {
  const { actions, log, sent } = bench();
  await actions.touch("start", [
    { target: ".node", dx: -20, id: 1 },
    { target: ".node", dx: 20, id: 2 },
  ]);

  const [entry] = log.entries();
  assert.equal(entry.target, ".node, .node");
  assert.equal(entry.resolved, true);
  assert.equal(entry.box, null, "a multi-point action has no single box; the points carry theirs");
  assert.deepEqual(entry.dispatched, {
    type: "touchStart",
    points: [
      { target: ".node", box: NODE, x: 130, y: 43, id: 1 },
      { target: ".node", box: NODE, x: 170, y: 43, id: 2 },
    ],
  });
  assert.deepEqual(sent, [
    {
      kind: "touch",
      type: "touchStart",
      points: [
        { x: 130, y: 43, id: 1 },
        { x: 170, y: 43, id: 2 },
      ],
    },
  ]);
});

test("one unresolved touch point skips the whole action", async () => {
  const { actions, log, sent } = bench();
  await actions.touch("move", [{ target: ".node", id: 1 }, { target: ".missing", id: 2 }]);

  assert.deepEqual(log.entries(), [
    { index: 0, action: "touch", target: ".node, .missing", resolved: false, box: null, dispatched: null },
  ]);
  assert.deepEqual(sent, []);
});

test("a touch end carries no points and still records what was dispatched", async () => {
  const { actions, log } = bench();
  await actions.touch("end", []);

  assert.deepEqual(log.entries()[0], {
    index: 0,
    action: "touch",
    target: null,
    resolved: true,
    box: null,
    dispatched: { type: "touchEnd", points: [] },
  });
});

test("a touch phase that is not one of the four fails", async () => {
  const { actions } = bench();
  await assert.rejects(() => actions.touch("tap", [{ target: ".node" }]), /tap/);
});

test("a touch point without a target fails — there is no base to offset from", async () => {
  const { actions } = bench();
  await assert.rejects(() => actions.touch("start", [{ dx: 10 }]), /target/);
});

// `call` is in the fixed primitive tier, but the imperative instance does not
// cross until boundary stage 3 (#56). An absent bridge is a page that cannot
// answer, which is the same thing as a target that did not resolve.
test("call records unresolved while the imperative bridge is not installed", async () => {
  const { actions, log, sent, apiCalls } = bench();
  await actions.call("zoomIn");

  assert.deepEqual(log.entries(), [
    { index: 0, action: "call", target: null, resolved: false, box: null, dispatched: null },
  ]);
  assert.deepEqual(apiCalls, [], "a call that never happened is not an api observation");
  assert.deepEqual(sent, []);
});

test("call dispatches through the bridge when the page has one, and the return lands in api", async () => {
  const { actions, log, sent, apiCalls } = bench({ bridge: (method, args) => ({ method, args }) });
  await actions.call("setViewport", [{ x: 1, y: 2, zoom: 3 }]);

  assert.deepEqual(log.entries()[0], {
    index: 0,
    action: "call",
    target: null,
    resolved: true,
    box: null,
    dispatched: { method: "setViewport", args: [{ x: 1, y: 2, zoom: 3 }] },
  });
  assert.deepEqual(apiCalls, [
    { method: "setViewport", args: [{ x: 1, y: 2, zoom: 3 }], result: { method: "setViewport", args: [{ x: 1, y: 2, zoom: 3 }] } },
  ]);
  assert.deepEqual(sent, [{ kind: "call", method: "setViewport", args: [{ x: 1, y: 2, zoom: 3 }] }]);
});

// The scenario is handed the vocabulary and nothing else. A `call` that
// returned its result would be an aperture onto the running library — the one
// remaining way a scenario could branch on which side it is driving.
test("call hands the scenario the driving entry, never the library's answer", async () => {
  const { actions } = bench({ bridge: () => ({ nodes: [], edges: [] }) });
  const entry = await actions.call("toObject");

  assert.deepEqual(Object.keys(entry), ["index", "action", "target", "resolved", "box", "dispatched"]);
});

test("every primitive returns the entry it recorded", async () => {
  const { actions, log } = bench();
  const entries = [
    await actions.pointerDown(".node"),
    await actions.pointerMove(null, { dx: 1 }),
    await actions.pointerUp(null),
    await actions.key("a"),
    await actions.wheel(".node", { deltaY: 1 }),
    await actions.touch("end", []),
    await actions.call("zoomIn"),
  ];

  assert.deepEqual(entries, log.entries());
});
