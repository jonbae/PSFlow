import { test } from "node:test";
import assert from "node:assert/strict";

import { compareCallbacks, validateWeakenings } from "./callbacks.mjs";
import { formatPath } from "./paths.mjs";

const call = (name, ...args) => ({ name, args });

// The sequence a drag produces: the change callbacks interleave with the drag
// lifecycle, and the interleaving is the part nothing else can observe.
const DRAG = [
  call("onNodeDragStart", { id: "1" }),
  call("onNodesChange", [{ id: "1", type: "position", dragging: true }]),
  call("onNodeDrag", { id: "1" }),
  call("onNodesChange", [{ id: "1", type: "position", dragging: false }]),
  call("onNodeDragStop", { id: "1" }),
];

const weakening = (fields) => ({ reason: "measured, not assumed", ...fields });
const paths = (differences) => differences.map((d) => `${d.kind} ${formatPath(d.path)}`);

test("two identical sequences agree", () => {
  const { differences, outcomes } = compareCallbacks(DRAG, structuredClone(DRAG));

  assert.deepEqual(differences, []);
  assert.deepEqual(outcomes, []);
});

test("a missing call fails, and only the call that went missing is reported", () => {
  const psflow = DRAG.filter((c) => c.name !== "onNodeDrag");

  const { differences } = compareCallbacks(DRAG, psflow);

  // The two calls after the gap are the same calls, not four more findings:
  // a positional diff would report every one of them as changed, and the real
  // finding would be the last line of a table nobody reads to the end.
  assert.deepEqual(paths(differences), ["left-only callbacks/2"]);
  assert.equal(differences[0].left.name, "onNodeDrag");
});

test("a duplicated call fails", () => {
  const psflow = [...DRAG.slice(0, 3), DRAG[2], ...DRAG.slice(3)];

  const { differences } = compareCallbacks(DRAG, psflow);

  assert.deepEqual(paths(differences), ["right-only callbacks/3"]);
});

test("a reordered pair fails, as one difference carrying both sequences", () => {
  const psflow = structuredClone(DRAG);
  [psflow[1], psflow[2]] = [psflow[2], psflow[1]];

  const { differences } = compareCallbacks(DRAG, psflow);

  assert.deepEqual(paths(differences), ["order callbacks"]);
  assert.deepEqual(differences[0].left, [
    "onNodeDragStart#1",
    "onNodesChange#1",
    "onNodeDrag#1",
    "onNodesChange#2",
    "onNodeDragStop#1",
  ]);
  assert.equal(differences[0].right[1], "onNodeDrag#1");
});

test("a handler that fired on neither side is not a difference, and one that fired on one side is", () => {
  assert.deepEqual(compareCallbacks([], []).differences, []);
  assert.deepEqual(paths(compareCallbacks([], [call("onError", "008")]).differences), ["right-only callbacks/0"]);
});

test("arguments compare under the call they were passed to", () => {
  const psflow = structuredClone(DRAG);
  psflow[1].args[0][0].dragging = false;

  const { differences } = compareCallbacks(DRAG, psflow);

  assert.deepEqual(paths(differences), ["changed callbacks/1/args/0/0/dragging"]);
  assert.equal(differences[0].left, true);
});

test("an argument that is a synthetic event where a native one belongs differs field by field", () => {
  const upstream = [call("onNodeClick", { "@class": "MouseEvent" }, { id: "1" })];
  const psflow = [call("onNodeClick", { "@class": "SyntheticBaseEvent", type: "click", _reactName: "onClick" }, { id: "1" })];

  const { differences } = compareCallbacks(upstream, psflow);

  assert.deepEqual(paths(differences), [
    "changed callbacks/0/args/0/@class",
    "right-only callbacks/0/args/0/type",
    "right-only callbacks/0/args/0/_reactName",
  ]);
});

test("the calls a weakened count does not cover still compare exactly", () => {
  const upstream = [call("onNodeMouseMove", { x: 10 }), call("onNodeMouseMove", { x: 20 }), call("onNodeMouseMove", { x: 30 })];
  const psflow = [call("onNodeMouseMove", { x: 10 }), call("onNodeMouseMove", { x: 99 })];
  const weakenings = [weakening({ callback: "onNodeMouseMove", kind: "count" })];

  const { differences, outcomes } = compareCallbacks(upstream, psflow, { weakenings });

  assert.deepEqual(paths(differences), ["changed callbacks/1/args/0/x"]);
  assert.equal(outcomes[0].status, "rides-free");
});

test("a weakened order lets one callback float without letting the others", () => {
  const upstream = [call("onNodesChange", []), call("onNodeDragStart", { id: "1" }), call("onNodeDrag", { id: "1" })];
  const psflow = [call("onNodeDragStart", { id: "1" }), call("onNodesChange", []), call("onNodeDrag", { id: "1" })];

  const strict = compareCallbacks(upstream, psflow);
  assert.deepEqual(paths(strict.differences), ["order callbacks"]);

  const weakened = compareCallbacks(upstream, psflow, {
    weakenings: [weakening({ callback: "onNodesChange", kind: "order" })],
  });
  assert.deepEqual(weakened.differences, []);
  assert.equal(weakened.outcomes[0].status, "rides-free");
});

test("a weakening that forgives nothing fails as stale, like every other register here", () => {
  const { outcomes } = compareCallbacks(DRAG, structuredClone(DRAG), {
    weakenings: [weakening({ callback: "onNodeDrag", kind: "count" })],
  });

  assert.equal(outcomes[0].status, "stale");
});

test("a weakening naming a callback nothing fired is stale rather than quietly harmless", () => {
  const { outcomes } = compareCallbacks(DRAG, structuredClone(DRAG), {
    weakenings: [weakening({ callback: "onSelectionEnd", kind: "count" })],
  });

  assert.equal(outcomes[0].status, "stale");
});

test("a weakening is judged on what it alone forgives, so one cannot ride on another's back", () => {
  const upstream = [call("onNodeMouseMove", { x: 10 }), call("onNodeMouseMove", { x: 20 })];
  const psflow = [call("onNodeMouseMove", { x: 10 })];

  const { outcomes } = compareCallbacks(upstream, psflow, {
    weakenings: [
      weakening({ callback: "onNodeMouseMove", kind: "count" }),
      weakening({ callback: "onNodeMouseMove", kind: "order" }),
    ],
  });

  assert.deepEqual(
    outcomes.map((o) => `${o.weakening.kind} ${o.status}`),
    ["count rides-free", "order stale"]
  );
});

test("a weakening needs a written reason", () => {
  assert.throws(() => validateWeakenings([{ callback: "onNodeDrag", kind: "count" }]), /reason/);
  assert.throws(() => validateWeakenings([{ callback: "onNodeDrag", kind: "count", reason: "" }]), /reason/);
});

test("the weakening kinds are closed, and arguments is deliberately not one of them", () => {
  assert.throws(
    () => validateWeakenings([weakening({ callback: "onNodeDrag", kind: "arguments" })]),
    /count, order/
  );
  assert.throws(() => validateWeakenings([weakening({ kind: "count" })]), /callback/);
});

test("one callback cannot carry the same weakening twice, which would let one of them never go stale", () => {
  assert.throws(
    () =>
      validateWeakenings([
        weakening({ callback: "onNodeDrag", kind: "count" }),
        weakening({ callback: "onNodeDrag", kind: "count" }),
      ]),
    /already/
  );
});
