import { test } from "node:test";
import assert from "node:assert/strict";

import { MARKER, SerializationError, serializeCall, serializeValue } from "./serialize.mjs";

// The two events the serializer exists to tell apart. Neither is constructed by
// a browser here: what distinguishes them is *where their properties live*, and
// that is reproducible in node.
//
//   * A React synthetic event carries its fields as enumerable own properties.
//   * A native event carries them on its prototype, as accessors.
//
// So the native one has no own enumerable properties at all, which is why its
// class has to be recorded for the difference to be visible.
class NativeMouseEvent {
  constructor(fields) {
    Object.defineProperties(
      this,
      Object.fromEntries(Object.entries(fields).map(([k, v]) => [k, { get: () => v, enumerable: false }]))
    );
  }
}
const syntheticEvent = (fields) => {
  class SyntheticBaseEvent {}
  return Object.assign(new SyntheticBaseEvent(), fields);
};

const domNode = (nodeName) => ({ nodeType: 1, nodeName, className: "react-flow__node" });

test("a change array — what onNodesChange is handed — serializes as itself", () => {
  const changes = [{ id: "1", type: "dimensions", dimensions: { width: 150, height: 36 }, resizing: false }];

  assert.deepEqual(serializeValue(changes), changes);
});

test("every enumerable own property is kept, including ones a whitelist would never have thought to ask for", () => {
  const event = syntheticEvent({ type: "pointerdown", button: 0, _reactName: "onPointerDown", bubbles: true });

  assert.deepEqual(serializeValue(event), {
    [MARKER.class]: "SyntheticBaseEvent",
    type: "pointerdown",
    button: 0,
    _reactName: "onPointerDown",
    bubbles: true,
  });
});

test("a native event where a synthetic one is expected is caught, and the other way round", () => {
  const fields = { type: "pointerdown", button: 0, bubbles: true };

  const synthetic = serializeValue(syntheticEvent(fields));
  const native = serializeValue(new NativeMouseEvent(fields));

  assert.notDeepEqual(synthetic, native);
  // And it says which, rather than only that fourteen fields went missing: the
  // class is the one thing a native event still has to say for itself.
  assert.equal(native[MARKER.class], "NativeMouseEvent");
  assert.equal(synthetic[MARKER.class], "SyntheticBaseEvent");
});

test("two native events of different kinds differ, though neither has an own property to differ in", () => {
  class PointerEvent {}
  class MouseEvent {}

  assert.notDeepEqual(serializeValue(new PointerEvent()), serializeValue(new MouseEvent()));
});

test("a plain object records no class, so the marker means something when it appears", () => {
  assert.deepEqual(serializeValue({ x: 1 }), { x: 1 });
  assert.deepEqual(serializeValue(Object.create(null)), {});
});

test("reference-typed values keep their kind and lose their identity", () => {
  const value = serializeValue({
    target: domNode("DIV"),
    handler: function onNodesChange() {},
    nested: { deeper: domNode("BUTTON") },
  });

  assert.deepEqual(value, {
    target: { [MARKER.ref]: "DIV" },
    // Deliberately not the function's name: upstream is vendored source and
    // PSFlow is compiled PureScript, so names differ for reasons that are not
    // behaviour.
    handler: { [MARKER.ref]: "function" },
    nested: { deeper: { [MARKER.ref]: "BUTTON" } },
  });
});

test("and only those — a data value is never mistaken for a reference", () => {
  const value = {
    id: "1",
    position: { x: 75, y: 25 },
    selected: false,
    data: { label: "Node 1", nested: [1, "two", { three: true }] },
  };

  assert.deepEqual(serializeValue(value), value);
});

test("a field that resolved to a reference is still a field, so a handler that stops passing one is a difference", () => {
  const withTarget = serializeValue({ target: domNode("DIV") });
  const withoutTarget = serializeValue({});

  assert.notDeepEqual(withTarget, withoutTarget);
});

test("the values JSON cannot carry are recorded rather than flattened onto null", () => {
  assert.deepEqual(serializeValue([undefined, null, NaN, Infinity, -0, 0]), [
    { [MARKER.undefined]: true },
    null,
    { [MARKER.number]: "NaN" },
    { [MARKER.number]: "Infinity" },
    { [MARKER.number]: "-0" },
    0,
  ]);
  assert.deepEqual(serializeValue(10n), { [MARKER.bigint]: "10" });
  assert.deepEqual(serializeValue(Symbol("react.element")), { [MARKER.symbol]: "Symbol(react.element)" });
});

test("a cycle records where it came back to, rather than recursing forever", () => {
  const event = { type: "pointerdown" };
  event.nativeEvent = { detail: 1, synthetic: event };

  assert.deepEqual(serializeValue(event, { path: ["args", 0] }), {
    type: "pointerdown",
    nativeEvent: { detail: 1, synthetic: { [MARKER.cycle]: "args/0" } },
  });
});

test("a graph deeper than the limit is marked, not truncated silently", () => {
  const deep = { a: { b: { c: { d: "bottom" } } } };

  assert.deepEqual(serializeValue(deep, { maxDepth: 2 }), { a: { b: { [MARKER.depth]: 2 } } });
});

test("a getter that throws costs its own field and not the capture", () => {
  const hostile = { get width() { throw new TypeError("detached"); }, height: 36 };

  assert.deepEqual(serializeValue(hostile), { width: { [MARKER.threw]: "TypeError" }, height: 36 });
});

test("an object owning a marker key is loud, because a quiet one would be indistinguishable from the marker", () => {
  assert.throws(() => serializeValue({ [MARKER.ref]: "not really" }), SerializationError);
});

test("a call is a name and its serialized arguments, which is the trace's shape for one", () => {
  assert.deepEqual(serializeCall("onNodeDrag", [syntheticEvent({ type: "pointermove" }), { id: "1" }, []]), {
    name: "onNodeDrag",
    args: [{ [MARKER.class]: "SyntheticBaseEvent", type: "pointermove" }, { id: "1" }, []],
  });
});

test("a call addresses its arguments by position, so a cycle inside one says which", () => {
  const first = { id: "1" };
  const second = { type: "position" };
  second.node = second;

  const call = serializeCall("onNodeDrag", [first, second]);

  assert.deepEqual(call.args[1], { type: "position", node: { [MARKER.cycle]: "args/1" } });
});

test("the markers are the reserved key set, so nothing can be reserved without being one", () => {
  assert.deepEqual([...new Set(Object.values(MARKER))].sort(), Object.values(MARKER).sort());
  assert.ok(Object.values(MARKER).every((key) => key.startsWith("@")));
});
