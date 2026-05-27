import { drag } from "d3-drag";

export const dragBehavior = () => drag();

export const setDragClickDistance = (n) => (behavior) => () => {
  behavior.clickDistance(n);
  return behavior;
};

export const setDragOn = (typename) => (handler) => (behavior) => () => {
  behavior.on(typename, (event) => handler(event)());
  return behavior;
};

// d3-drag's `.filter` is invoked with the raw native MouseEvent/TouchEvent,
// not a D3DragEvent wrapper. The PS-side `filterPredicate` expects a
// D3DragEvent and calls `dragSourceEvent` on it. Adapt by wrapping the
// raw event in a `{ sourceEvent }` shape so `dragSourceEvent` returns the
// native event and `mouseButtonIsZero` can read `.button` on it.
export const setDragFilter = (predicate) => (behavior) => () => {
  behavior.filter((event) => predicate({ sourceEvent: event })());
  return behavior;
};

export const applyDrag = (selection) => (behavior) => () => {
  selection.call(behavior);
};

export const dragSourceEvent = (event) => () => event.sourceEvent;
