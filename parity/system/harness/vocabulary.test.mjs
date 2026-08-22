import { test } from "node:test";
import assert from "node:assert/strict";

import { createDrivingLog } from "./driving.mjs";
import { createFakePort } from "./fake-port.mjs";
import { PRIMITIVES } from "./actions.mjs";
import { GESTURES } from "./gestures.mjs";
import { VOCABULARY, createVocabulary } from "./vocabulary.mjs";

const build = () => createVocabulary(createFakePort().port, createDrivingLog(), []);

test("the vocabulary is the two tiers and nothing else", () => {
  assert.deepEqual(VOCABULARY, [...PRIMITIVES, ...GESTURES]);
  assert.deepEqual(Object.keys(build()).sort(), [...VOCABULARY].sort());
});

test("no gesture is named after a primitive", () => {
  assert.deepEqual(
    GESTURES.filter((g) => PRIMITIVES.includes(g)),
    []
  );
});

// The property the whole design turns on. A scenario that could branch on which
// implementation it is driving would silently invalidate every comparison the
// net ever makes, so the aperture is closed rather than discouraged.
test("nothing on the vocabulary names or exposes the side", () => {
  const actions = build();

  for (const [name, value] of Object.entries(actions)) {
    assert.equal(typeof value, "function", `${name} is not a function`);
  }
  assert.deepEqual(Object.getOwnPropertyNames(actions).sort(), [...VOCABULARY].sort());
  assert.equal(Object.getPrototypeOf(actions), Object.prototype);
});

// A driving entry carries the box *that side* resolved, and geometry is exactly
// what differs between the two — the spike's whole finding was a zoom gap. An
// action that handed one back would let a scenario branch on the side as surely
// as being told its name, so the tiers beneath may return entries and the
// vocabulary may not.
test("no action hands anything back to the scenario", async () => {
  const port = createFakePort({ boxes: { ".node": { x: 0, y: 0, width: 10, height: 10 } } }).port;
  const actions = createVocabulary(port, createDrivingLog(), []);

  const returned = [
    await actions.pointerDown(".node"),
    await actions.pointerMove(null, { dx: 1 }),
    await actions.pointerUp(null),
    await actions.key("a"),
    await actions.wheel(".node", { deltaY: 1 }),
    await actions.touch("end", []),
    await actions.call("zoomIn"),
    await actions.click(".node"),
    await actions.dragNode(".node", { dx: 1, dy: 1, steps: 1 }),
    await actions.selectionBox({ target: ".node" }, { target: ".node" }),
    await actions.connect(".node", ".node"),
    await actions.pan({ target: ".node", dx: 1, steps: 1 }),
    await actions.pinch(".node", { steps: 1 }),
    await actions.arrowKeyNudge("right"),
  ];

  assert.equal(returned.length, VOCABULARY.length, "every action in the vocabulary is covered");
  assert.deepEqual(new Set(returned), new Set([undefined]));
});

test("the vocabulary is frozen, so nothing can be attached to it later", () => {
  const actions = build();

  assert.ok(Object.isFrozen(actions));
  assert.throws(() => {
    actions.page = "leaked";
  }, TypeError);
  assert.throws(() => {
    actions.pointerDown = () => {};
  }, TypeError);
});

test("the two tiers share one driving log, in one sequence", async () => {
  const log = createDrivingLog();
  const actions = createVocabulary(createFakePort({ boxes: { ".node": { x: 0, y: 0, width: 10, height: 10 } } }).port, log, []);

  await actions.pointerDown(".node");
  await actions.dragNode(".node", { dx: 10, dy: 0, steps: 1 });

  assert.deepEqual(
    log.entries().map((e) => e.index),
    [0, 1, 2, 3]
  );
});
