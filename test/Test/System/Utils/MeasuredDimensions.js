// `spago test` has no DOM, so `updateNodeInternals` measures stand-ins. Each
// element answers only what `System.Utils.Dom` asks of it: a size, a bounding
// rect, and no handles.
export const fakeNodeElement = (width) => (height) => ({
  offsetWidth: width,
  offsetHeight: height,
  getBoundingClientRect: () => ({ left: 0, top: 0, width, height }),
  querySelectorAll: () => [],
});

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
