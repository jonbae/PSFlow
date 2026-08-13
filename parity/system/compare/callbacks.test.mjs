import { test } from "node:test";
import assert from "node:assert/strict";

import { compareCallbacks, validateWeakenings } from "./callbacks.mjs";
import { serializeCall } from "../harness/serialize.mjs";
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

test("two calls of the same name, reordered, is an order difference and not two argument ones", () => {
  const upstream = [call("onNodesChange", [{ id: "1" }]), call("onNodesChange", [{ id: "2" }])];
  const psflow = [call("onNodesChange", [{ id: "2" }]), call("onNodesChange", [{ id: "1" }])];

  const { differences } = compareCallbacks(upstream, psflow);

  // The common case, `onNodesChange` being the highest-volume callback in the
  // corpus — and the one where pairing by name alone invents differences in
  // *arguments*, which read as findings about what the two libraries pass.
  assert.deepEqual(paths(differences), ["order callbacks"]);
  assert.deepEqual(differences[0].left, ["onNodesChange#1", "onNodesChange#2"]);
  assert.deepEqual(differences[0].right, ["onNodesChange#2", "onNodesChange#1"]);
});

test("a call whose arguments changed still pairs, rather than reading as one missing and one extra", () => {
  const upstream = [call("onNodesChange", [{ id: "1", dragging: true }])];
  const psflow = [call("onNodesChange", [{ id: "1", dragging: false }])];

  const { differences } = compareCallbacks(upstream, psflow);

  assert.deepEqual(paths(differences), ["changed callbacks/0/args/0/0/dragging"]);
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

// ── The two halves, joined ─────────────────────────────────────────────────
// Everything above compares hand-written trace content, which is right: the
// subject under test is the comparison. But the claim the ticket actually makes
// is about the two halves *together* — a serializer that recorded a synthetic
// event where a native one belongs, and a comparison that goes red on it. Held
// apart, each half could be correct against data the other never produces.

test("the serializer's own output goes red through the comparison, native against synthetic", () => {
  // Node's `Event` is a real native one: its fields live on the prototype, so
  // it has no own enumerable properties. React's are own properties.
  class SyntheticBaseEvent {}
  const synthetic = Object.assign(new SyntheticBaseEvent(), { type: "click", button: 0, _reactName: "onClick" });

  const upstream = [serializeCall("onNodeClick", [new Event("click"), { id: "1" }])];
  const psflow = [serializeCall("onNodeClick", [synthetic, { id: "1" }])];

  const { differences } = compareCallbacks(upstream, psflow);

  assert.ok(differences.length > 0, "the substitution nothing else can see must fail here");
  assert.ok(
    differences.some((d) => formatPath(d.path) === "callbacks/0/args/0/@class"),
    "and it names the class rather than only listing fields that went missing"
  );
});

test("the same two halves agree when the argument really is the same", () => {
  const upstream = [serializeCall("onNodeClick", [new Event("click"), { id: "1" }])];
  const psflow = [serializeCall("onNodeClick", [new Event("click"), { id: "1" }])];

  // The green half of the falsification: a comparison that reported the pair
  // above would be worth nothing if it also reported this one.
  assert.deepEqual(compareCallbacks(upstream, psflow).differences, []);
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
  const weakenings = [weakening({ callback: "onNodeMouseMove", axis: "count" })];

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
    weakenings: [weakening({ callback: "onNodesChange", axis: "order" })],
  });
  assert.deepEqual(weakened.differences, []);
  assert.equal(weakened.outcomes[0].status, "rides-free");
});

test("a weakening that forgives nothing fails as stale, like every other register here", () => {
  const { outcomes } = compareCallbacks(DRAG, structuredClone(DRAG), {
    weakenings: [weakening({ callback: "onNodeDrag", axis: "count" })],
  });

  assert.equal(outcomes[0].status, "stale");
});

test("a weakening naming a callback nothing fired is stale rather than quietly harmless", () => {
  const { outcomes } = compareCallbacks(DRAG, structuredClone(DRAG), {
    weakenings: [weakening({ callback: "onSelectionEnd", axis: "count" })],
  });

  assert.equal(outcomes[0].status, "stale");
});

test("a weakening is judged on what it alone forgives, so one cannot ride on another's back", () => {
  const upstream = [call("onNodeMouseMove", { x: 10 }), call("onNodeMouseMove", { x: 20 })];
  const psflow = [call("onNodeMouseMove", { x: 10 })];

  const { outcomes } = compareCallbacks(upstream, psflow, {
    weakenings: [
      weakening({ callback: "onNodeMouseMove", axis: "count" }),
      weakening({ callback: "onNodeMouseMove", axis: "order" }),
    ],
  });

  assert.deepEqual(
    outcomes.map((o) => `${o.weakening.axis} ${o.status}`),
    ["count rides-free", "order stale"]
  );
});

test("a weakening needs a written reason", () => {
  assert.throws(() => validateWeakenings([{ callback: "onNodeDrag", axis: "count" }]), /reason/);
  assert.throws(() => validateWeakenings([{ callback: "onNodeDrag", axis: "count", reason: "" }]), /reason/);
});

test("the weakening axes are closed, and arguments is deliberately not one of them", () => {
  assert.throws(
    () => validateWeakenings([weakening({ callback: "onNodeDrag", axis: "arguments" })]),
    /count, order/
  );
  assert.throws(() => validateWeakenings([weakening({ axis: "count" })]), /callback/);
});

test("one callback cannot carry the same weakening twice, which would let one of them never go stale", () => {
  assert.throws(
    () =>
      validateWeakenings([
        weakening({ callback: "onNodeDrag", axis: "count" }),
        weakening({ callback: "onNodeDrag", axis: "count" }),
      ]),
    /already/
  );
});
