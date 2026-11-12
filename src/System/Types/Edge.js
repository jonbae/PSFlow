// Representation interop only: associate a decoded edge with the consumer's
// original JS object, as `System.Types.Node` does for nodes.
const originals = new WeakMap();
export const rememberUserEdge = (original, decoded) => {
  originals.set(decoded, original);
  return decoded;
};
export const originalUserEdge = (edge) => originals.get(edge);
export const edgeOwnsKey = (key) => (edge) => {
  const original = originals.get(edge);
  return original !== undefined && Object.prototype.hasOwnProperty.call(original, key);
};
