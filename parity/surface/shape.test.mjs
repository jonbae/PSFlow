import { test } from "node:test";
import assert from "node:assert/strict";

import { ABSENT, formatShape, sameShape, shapeOf, shapeDifferences } from "./shape.mjs";

const memo = (inner) => ({ $$typeof: Symbol.for("react.memo"), type: inner, compare: null });
const forwardRef = (render) => ({ $$typeof: Symbol.for("react.forward_ref"), render });

test("a plain function carries its arity", () => {
  assert.deepEqual(shapeOf((a, b) => a + b), { kind: "function", wrappers: [], arity: 2 });
  assert.equal(formatShape(shapeOf((a, b) => a + b)), "fn/2");
});

test("a curried function reads as arity 1 — the divergence this gate exists to see", () => {
  const curried = (a) => (b) => (c) => a + b + c;
  assert.equal(formatShape(shapeOf(curried)), "fn/1");
  assert.equal(sameShape(shapeOf(curried), shapeOf((a, b, c) => a + b + c)), false);
});

test("plain data reads as its typeof, with no arity", () => {
  assert.deepEqual(shapeOf({ Left: "left" }), { kind: "object", wrappers: [], arity: null });
  assert.equal(formatShape(shapeOf("left")), "string");
  assert.equal(formatShape(shapeOf(null)), "null");
});

test("a name the module does not export is absent, and absent is not undefined", () => {
  assert.equal(formatShape(ABSENT), "absent");
  assert.equal(sameShape(ABSENT, shapeOf(undefined)), false);
  assert.equal(formatShape(shapeOf(undefined)), "undefined");
});

test("React wrappers are unwrapped to the function they carry", () => {
  assert.deepEqual(shapeOf(memo((props) => props)), {
    kind: "function",
    wrappers: ["memo"],
    arity: 1,
  });
  assert.equal(formatShape(shapeOf(memo(forwardRef((props, ref) => ref)))), "memo(forwardRef(fn/2))");
});

test("wrapper kind is compared in both directions", () => {
  const plain = (props) => props;
  // upstream memoizes and PSFlow does not …
  assert.equal(sameShape(shapeOf(memo(plain)), shapeOf(plain)), false);
  // … and PSFlow memoizes where upstream does not.
  assert.equal(sameShape(shapeOf(plain), shapeOf(memo(plain))), false);
  // A component that loses upstream's forwardRef keeps the same core arity, so
  // only the wrapper chain can tell the two apart.
  assert.equal(sameShape(shapeOf(forwardRef(plain)), shapeOf(plain)), false);
});

test("an unrecognised React tag is named rather than flattened into a plain object", () => {
  const lazy = { $$typeof: Symbol.for("react.lazy"), _payload: null };
  assert.deepEqual(shapeOf(lazy), { kind: "object", wrappers: ["react.lazy"], arity: null });
  assert.equal(sameShape(shapeOf(lazy), shapeOf({})), false);
});

test("shapeDifferences reports one row per disagreeing name and nothing for agreement", () => {
  const upstream = { agree: { kind: "function", wrappers: [], arity: 1 }, curried: { kind: "function", wrappers: [], arity: 3 } };
  const psflow = { agree: { kind: "function", wrappers: [], arity: 1 }, curried: { kind: "function", wrappers: [], arity: 1 }, own: { kind: "object", wrappers: [], arity: null } };

  const differences = shapeDifferences(upstream, psflow, ["agree", "curried", "own"]);

  assert.deepEqual(
    differences.map((d) => [d.name, d.upstream, d.psflow]),
    [
      ["curried", "fn/3", "fn/1"],
      ["own", "absent", "object"],
    ]
  );
});

test("shapeDifferences compares the names it is given, in the order it is given them", () => {
  const shape = { kind: "function", wrappers: [], arity: 0 };
  assert.deepEqual(shapeDifferences({}, { b: shape, a: shape }, ["b", "a"]).map((d) => d.name), ["b", "a"]);
  assert.deepEqual(shapeDifferences({}, { b: shape }, []), []);
});
