"use strict";

// A stand-in for the browser's frame clock, installed as `globalThis.window`
// for the length of one test. `System.FFI.AnimationFrame` reaches for
// `window.requestAnimationFrame`, which Node does not have. Requests are
// counted and never run, so a test sees exactly one auto-pan frame at a time;
// handles are the request count, so the first frame asked for is 1.
export const installFrameClock = () => {
  const previous = Object.getOwnPropertyDescriptor(globalThis, "window");
  let requests = 0;
  const cancelled = [];
  globalThis.window = {
    requestAnimationFrame: () => ++requests,
    cancelAnimationFrame: (handle) => {
      cancelled.push(handle);
    },
  };
  return {
    requests: () => requests,
    cancelled: () => cancelled.slice(),
    restore: () => {
      if (previous) Object.defineProperty(globalThis, "window", previous);
      else delete globalThis.window;
    },
  };
};

// A stand-in for the `MouseEvent` the drag handler stores on the state. The
// callbacks under test pass it straight through to the consumer, so nothing
// reads it; `DragState.dragEvent` only has to be a `Just` for them to fire.
export const stubMouseEvent = {};
