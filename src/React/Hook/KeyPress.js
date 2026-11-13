// Whether a key event's target, or the first entry of its `composedPath()`,
// is a `<button>` or an `<a>`: upstream's `isInteractiveElement`, which keeps
// the press of a key such as Enter or Space for the element that has focus.
export const isInteractiveTarget = (event) => () => {
  const target = event.composedPath?.()?.[0] || event.target;
  return target?.nodeName === "BUTTON" || target?.nodeName === "A";
};
