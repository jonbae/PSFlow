// `spago test` has no DOM, so `updateNodeInternals` measures stand-ins. Each
// element answers only what `System.Utils.Dom` asks of it: a size, a bounding
// rect, and the handles of each side.
const handleElement = (position, left) => ({
  getAttribute: (name) => (name === "data-handlepos" ? position : null),
  getBoundingClientRect: () => ({ left, top: 10, width: 6, height: 6 }),
  offsetWidth: 6,
  offsetHeight: 6,
});

const nodeElementHolding = (sources, targets) => ({
  offsetWidth: 50,
  offsetHeight: 25,
  getBoundingClientRect: () => ({ left: 0, top: 0, width: 50, height: 25 }),
  querySelectorAll: (selector) =>
    selector === ".source" ? sources : selector === ".target" ? targets : [],
});

// A node with one source handle on its right and no target handle, as an
// `input` node renders.
export const sourceOnlyElement = nodeElementHolding([handleElement("right", 44)], []);

// A node with one target handle on its left and no source handle, as an
// `output` node renders.
export const targetOnlyElement = nodeElementHolding([], [handleElement("left", 0)]);

// A node with no handles at all.
export const handlelessElement = nodeElementHolding([], []);

// The flow's root, holding a viewport at zoom 1.
export const fakeFlowRoot = {
  querySelector: (selector) => (selector === ".xyflow__viewport" ? {} : null),
};

// `findViewportZoom` reads the viewport's transform through `window`, which
// node lacks. The stand-in is installed and removed around one synchronous
// call, so no other suite can observe it.
export const withFakeWindowImpl = (run) => () => {
  const had = Object.prototype.hasOwnProperty.call(globalThis, "window");
  const previous = globalThis.window;
  globalThis.window = {
    getComputedStyle: () => ({ transform: "none" }),
    DOMMatrixReadOnly: class {
      constructor() {
        this.m22 = 1;
      }
    },
  };
  try {
    return run();
  } finally {
    if (had) globalThis.window = previous;
    else delete globalThis.window;
  }
};

// One side of `internals.handleBounds` as a consumer reads it: `null`, or
// the number of handles in the array.
const sideOf = (side) => (side === null ? "null" : Array.isArray(side) ? `${side.length}` : typeof side);

export const handleBoundsSides = (internal) => {
  const bounds = internal.internals.handleBounds;
  if (bounds === undefined) return "undefined";
  return `source ${sideOf(bounds.source)}, target ${sideOf(bounds.target)}`;
};
