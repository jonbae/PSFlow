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

export const setDragFilter = (predicate) => (behavior) => () => {
  behavior.filter((event) => predicate(event)());
  return behavior;
};

export const applyDrag = (selection) => (behavior) => () => {
  selection.call(behavior);
};

export const dragSourceEvent = (event) => () => event.sourceEvent;
