// Surface parity — the two small behavioral observations that belong at the
// JS barrel rather than below it or in a browser.
//
// The fixtures below are shared literally: each side receives a structured
// clone of the same frozen arguments. That keeps a mutating implementation
// from changing the experiment the second implementation sees while avoiding
// two hand-maintained readings of an upstream signature.

import { isDeepStrictEqual } from "node:util";

export const ENUM_EXPORTS = Object.freeze([
  "BackgroundVariant",
  "ConnectionLineType",
  "ConnectionMode",
  "MarkerType",
  "PanOnScrollMode",
  "Position",
  "ResizeControlVariant",
  "SelectionMode",
]);

const fullNode = (id, x, y) => ({
  id,
  position: { x, y },
  data: { label: id },
  type: undefined,
  sourcePosition: undefined,
  targetPosition: undefined,
  hidden: false,
  selected: false,
  dragging: false,
  draggable: undefined,
  selectable: undefined,
  connectable: undefined,
  deletable: undefined,
  dragHandle: undefined,
  width: 40,
  height: 20,
  initialWidth: undefined,
  initialHeight: undefined,
  parentId: undefined,
  zIndex: undefined,
  extent: undefined,
  expandParent: false,
  ariaLabel: undefined,
  origin: undefined,
  handles: undefined,
  measured: { width: 40, height: 20 },
  className: undefined,
  style: undefined,
});

const fullEdge = (id, source, target) => ({
  id,
  type: undefined,
  source,
  target,
  sourceHandle: undefined,
  targetHandle: undefined,
  animated: false,
  hidden: false,
  deletable: undefined,
  selectable: undefined,
  data: undefined,
  selected: false,
  markerStart: undefined,
  markerEnd: undefined,
  zIndex: undefined,
  label: undefined,
  ariaLabel: undefined,
  interactionWidth: undefined,
  className: undefined,
  style: undefined,
});

const source = fullNode("source", 0, 20);
const focus = fullNode("focus", 100, 40);
const target = fullNode("target", 200, 100);
const incoming = fullEdge("source-focus", "source", "focus");
const outgoing = fullEdge("focus-target", "focus", "target");

const edgePoints = {
  sourceX: 0,
  sourceY: 20,
  targetX: 150,
  targetY: 100,
};

const calls = [
  {
    name: "getBezierEdgeCenter",
    args: [{ ...edgePoints, sourceControlX: 50, sourceControlY: 20, targetControlX: 100, targetControlY: 100 }],
  },
  {
    name: "getBezierPath",
    args: [{ ...edgePoints, sourcePosition: "right", targetPosition: "left", curvature: 0.25 }],
  },
  { name: "getConnectedEdges", args: [[focus], [incoming, outgoing]] },
  { name: "getEdgeCenter", args: [edgePoints] },
  { name: "getIncomers", args: [focus, [source, focus, target], [incoming, outgoing]] },
  { name: "getNodesBounds", args: [[source, focus, target]] },
  { name: "getOutgoers", args: [focus, [source, focus, target], [incoming, outgoing]] },
  { name: "getSimpleBezierPath", args: [edgePoints] },
  {
    name: "getSmoothStepPath",
    args: [{
      ...edgePoints,
      sourcePosition: "right",
      targetPosition: "left",
      borderRadius: 5,
      offset: 20,
      stepPosition: 0.5,
    }],
  },
  { name: "getStraightPath", args: [edgePoints] },
  { name: "getViewportForBounds", args: [{ x: 0, y: 0, width: 100, height: 50 }, 800, 600, 0.5, 2, 0.1] },
  { name: "addEdge", args: [fullEdge("new-edge", "source", "target"), []] },
  {
    name: "applyEdgeChanges",
    args: [[{ type: "select", id: outgoing.id, selected: true }], [outgoing]],
  },
  {
    name: "applyNodeChanges",
    args: [[{ type: "select", id: focus.id, selected: true }], [focus]],
  },
  { name: "isEdge", args: [outgoing] },
  { name: "isNode", args: [focus] },
  {
    name: "reconnectEdge",
    args: [outgoing, { source: "source", target: "target", sourceHandle: null, targetHandle: null }, [outgoing]],
  },
];

const deepFreeze = (value) => {
  if (value && typeof value === "object" && !Object.isFrozen(value)) {
    for (const child of Object.values(value)) deepFreeze(child);
    Object.freeze(value);
  }
  return value;
};

export const PURE_FUNCTION_CALLS = Object.freeze(
  calls.map(({ name, args }) => Object.freeze({ name, args: deepFreeze(args) }))
);

const returned = (value) => ({ kind: "return", value });
const threw = (error) => ({
  kind: "throw",
  error: `${error?.constructor?.name ?? "Error"}: ${error?.message ?? String(error)}`,
});

const observe = (fn, args) => {
  try {
    return returned(fn(...structuredClone(args)));
  } catch (error) {
    return threw(error);
  }
};

const difference = (name, differenceClass, upstream, psflow) => ({
  id: `${name}.${differenceClass}`,
  name,
  differenceClass,
  upstream,
  psflow,
});

/** Compare the eight enum values with a frozen snapshot of upstream's object. */
export const enumDifferences = (upstream, psflow) => {
  const differences = [];
  for (const name of ENUM_EXPORTS) {
    const expected = upstream[name];
    const actual = psflow[name];
    if (actual === null || typeof actual !== "object" || Array.isArray(actual)) {
      differences.push(difference(name, "enum-object", returned(expected), returned(actual)));
      continue;
    }
    if (!Object.isFrozen(actual)) {
      differences.push(difference(name, "enum-not-frozen", returned(expected), returned(actual)));
      continue;
    }
    const frozenExpected = Object.freeze({ ...expected });
    if (!isDeepStrictEqual(frozenExpected, actual)) {
      differences.push(difference(name, "enum-members", returned(frozenExpected), returned(actual)));
    }
  }
  return differences;
};

const returnDifferenceClass = (upstream, psflow) => {
  if (typeof upstream === "function" || typeof psflow === "function") return "call-convention";
  if (Array.isArray(upstream) !== Array.isArray(psflow)) return "positional-array-return";
  return "return-value";
};

/** Call all seventeen pure exports once through the two supplied barrels. */
export const pureFunctionDifferences = (upstream, psflow) => {
  const differences = [];
  for (const { name, args } of PURE_FUNCTION_CALLS) {
    const expected = observe(upstream[name], args);
    const actual = observe(psflow[name], args);
    if (expected.kind !== actual.kind) {
      differences.push(difference(name, "throw-vs-return", expected, actual));
    } else if (expected.kind === "throw") {
      if (expected.error !== actual.error) {
        differences.push(difference(name, "thrown-error", expected, actual));
      }
    } else if (!isDeepStrictEqual(expected.value, actual.value)) {
      differences.push(difference(name, returnDifferenceClass(expected.value, actual.value), expected, actual));
    }
  }
  return differences;
};

export const behaviorDifferences = (upstream, psflow) => ({
  enums: enumDifferences(upstream, psflow),
  functions: pureFunctionDifferences(upstream, psflow),
});

export const describeObservation = (observation) => {
  if (observation.kind === "throw") return `throws ${observation.error}`;
  if (typeof observation.value === "function") return `returns Function(arity=${observation.value.length})`;
  const json = JSON.stringify(observation.value, (_key, value) =>
    value === undefined ? "<undefined>" : value
  );
  return `returns ${json ?? String(observation.value)}`;
};
