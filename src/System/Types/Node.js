// Representation interop only: associate a decoded record with the original
// JS object without adding consumer-visible fields or caching decoded values.
const originals = new WeakMap();
export const rememberUserNode = (original, decoded) => {
  originals.set(decoded, original);
  return decoded;
};
export const originalUserNode = node => originals.get(node);

// Upstream hands the drag handlers `{ ...userNode, position, dragging }`, a copy
// of the consumer's own node with two keys replaced. ps-flow updates the
// decoded record; this keeps the same copy of the consumer's object beside the
// updated record, so the node crosses back with every key the consumer gave.
export const rememberDraggedNode = (source, updated) => {
  const original = originals.get(source);
  if (original !== undefined) {
    originals.set(updated, { ...original, position: updated.position, dragging: updated.dragging.value0 });
  }
  return updated;
};
