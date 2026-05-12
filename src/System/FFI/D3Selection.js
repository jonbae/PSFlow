import { select, pointer } from "d3-selection";

export const d3Select = (node) => () => select(node);

export const d3SelectionOnNull = (sel) => (typename) => () => {
  sel.on(typename, null);
};

export const d3Pointer = (event) => (container) => () => {
  const [x, y] = pointer(event, container);
  return { x, y };
};
