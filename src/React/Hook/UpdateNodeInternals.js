// Query the wrapper div's `.react-flow__node[data-id="<id>"]` child and
// return it as a `Maybe HTMLDivElement`. `Nothing` (encoded as `null`)
// when no element matches, which a PS-side `Maybe`-wrapping helper turns
// into a proper `Nothing`.
//
// We escape the id by replacing `"` with `\\"` so ids that themselves
// contain quotes don't break the selector.
export const querySelectorNodeImpl = (host) => (id) => () => {
  if (!host || typeof host.querySelector !== "function") {
    return null;
  }
  const safeId = String(id).replace(/"/g, '\\"');
  const el = host.querySelector(`.react-flow__node[data-id="${safeId}"]`);
  return el || null;
};
