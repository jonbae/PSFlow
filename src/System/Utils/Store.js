// Upstream's `updateAbsolutePositions` writes a root node's position into the
// internal node it already holds: `node.internals.positionAbsolute = …`. The
// node and its `internals` keep their identity, so a `<NodeWrapper />` whose
// shallow slice holds them does not re-render.
export const writePositionAbsolute = (position) => (node) => {
  node.internals.positionAbsolute = position;
  return node;
};
