// A d3 drag event as `startDrag` reads it: only its source event, a main-button
// mouse event at the origin.
export const dragEventAtOrigin = {
  sourceEvent: { type: "mousemove", clientX: 0, clientY: 0, button: 0 },
};

// `DragUpdateParams.domNode`: `startDrag` doesn't read it.
export const unusedElement = {};
