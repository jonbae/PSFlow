// A d3 drag event as `startDrag` reads it: only its source event, a main-button
// mouse event at the origin.
export const dragEventAtOrigin = {
  sourceEvent: { type: "mousemove", clientX: 0, clientY: 0, button: 0 },
};

// The source event the drag handler keeps for `updateNodes`, which hands it
// to the callbacks without reading it.
export const sourceEvent = {};

// The node's `<div>` ref before React attaches it. `handleNodeClick` reads it
// only when it unselects a node.
export const emptyNodeRef = { current: null };

// `DragUpdateParams.domNode`: `startDrag` doesn't read it.
export const unusedElement = {};
