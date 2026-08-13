import { test } from "node:test";
import assert from "node:assert/strict";

import {
  ENUM_EXPORTS,
  PURE_FUNCTION_CALLS,
  enumDifferences,
  pureFunctionDifferences,
} from "./behavior.mjs";
import { claim } from "./allowlist.mjs";

test("the behavioral surface is exactly the eight enum objects and seventeen pure functions", () => {
  assert.equal(ENUM_EXPORTS.length, 8);
  assert.equal(PURE_FUNCTION_CALLS.length, 17);
  assert.deepEqual(ENUM_EXPORTS, [...ENUM_EXPORTS].sort());
  assert.deepEqual(
    PURE_FUNCTION_CALLS.map(({ name }) => name),
    [
      "getBezierEdgeCenter", "getBezierPath", "getConnectedEdges", "getEdgeCenter",
      "getIncomers", "getNodesBounds", "getOutgoers", "getSimpleBezierPath",
      "getSmoothStepPath", "getStraightPath", "getViewportForBounds", "addEdge",
      "applyEdgeChanges", "applyNodeChanges", "isEdge", "isNode", "reconnectEdge",
    ]
  );
});

test("enum comparison requires a frozen object with upstream's exact members", () => {
  const upstream = Object.fromEntries(ENUM_EXPORTS.map((name) => [name, { Member: name }]));
  const matching = Object.fromEntries(
    ENUM_EXPORTS.map((name) => [name, Object.freeze({ Member: name })])
  );
  assert.deepEqual(enumDifferences(upstream, matching), []);

  const mutable = { ...matching, Position: { Member: "Position" } };
  assert.equal(enumDifferences(upstream, mutable).find((d) => d.name === "Position").differenceClass, "enum-not-frozen");

  const wrong = { ...matching, Position: Object.freeze({ Member: "wrong" }) };
  assert.equal(enumDifferences(upstream, wrong).find((d) => d.name === "Position").differenceClass, "enum-members");
});

test("all seventeen functions are called with independent clones of the same shared inputs", () => {
  const upstreamSeen = new Map();
  const psflowSeen = new Map();
  const upstream = {};
  const psflow = {};
  for (const { name } of PURE_FUNCTION_CALLS) {
    upstream[name] = (...args) => (upstreamSeen.set(name, args), name);
    psflow[name] = (...args) => (psflowSeen.set(name, args), name);
  }

  assert.deepEqual(pureFunctionDifferences(upstream, psflow), []);
  assert.equal(upstreamSeen.size, 17);
  assert.equal(psflowSeen.size, 17);
  for (const { name } of PURE_FUNCTION_CALLS) {
    assert.deepEqual(upstreamSeen.get(name), psflowSeen.get(name));
    assert.notEqual(upstreamSeen.get(name), psflowSeen.get(name));
  }
});

test("a labelled record where upstream returns a positional array is its own failure class", () => {
  const upstream = {};
  const psflow = {};
  for (const { name } of PURE_FUNCTION_CALLS) {
    upstream[name] = () => name;
    psflow[name] = () => name;
  }
  upstream.getStraightPath = () => ["path", 1, 2, 3, 4];
  psflow.getStraightPath = () => ({ path: "path", labelX: 1, labelY: 2, offsetX: 3, offsetY: 4 });

  const [failure] = pureFunctionDifferences(upstream, psflow);
  assert.equal(failure.id, "getStraightPath.positional-array-return");
  assert.equal(failure.name, "getStraightPath");
  assert.equal(failure.differenceClass, "positional-array-return");
});

test("call convention and throw/return failures name both export and class", () => {
  const upstream = {};
  const psflow = {};
  for (const { name } of PURE_FUNCTION_CALLS) {
    upstream[name] = () => name;
    psflow[name] = () => name;
  }
  psflow.getConnectedEdges = () => () => [];
  psflow.getBezierPath = () => { throw new TypeError("raw enum"); };

  const failures = pureFunctionDifferences(upstream, psflow);
  assert.deepEqual(
    failures.map(({ id }) => id),
    ["getBezierPath.throw-vs-return", "getConnectedEdges.call-convention"]
  );
});

test("an allowlisted behavior that changes class is both new and stale", () => {
  const result = claim(
    ["getStraightPath.return-value"],
    { "getStraightPath.positional-array-return": "retires in boundary stage 5" }
  );
  assert.deepEqual(result.unclaimed, ["getStraightPath.return-value"]);
  assert.deepEqual(result.stale, ["getStraightPath.positional-array-return"]);
});
