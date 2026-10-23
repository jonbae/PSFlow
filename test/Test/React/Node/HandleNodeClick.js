// The node's `<div>` ref before React attaches it.
export const emptyNodeRef = { current: null };

// `spago test` has no `window`, so a click that unselects schedules its blur
// on a stand-in that never runs it, installed for the length of the click
// only. It replaces whatever `window` is there rather than reusing it: the
// XYDrag tests run asynchronously, and their frame clock, which counts
// requests, can still be installed when a click runs.
export const withFrames = (action) => () => {
  const previous = Object.getOwnPropertyDescriptor(globalThis, "window");
  globalThis.window = { requestAnimationFrame: () => 0 };
  try {
    return action();
  } finally {
    if (previous) Object.defineProperty(globalThis, "window", previous);
    else delete globalThis.window;
  }
};
