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

// Keep boundary conversions beside decoded options without adding visible
// fields or a dependency from the core back to the boundary.
const defaultOptionsConversions = new WeakMap();
export const rememberDefaultEdgeOptions = (decoded, conversions) => {
  defaultOptionsConversions.set(decoded, conversions);
  return decoded;
};
export const rememberMergedEdge = (defaults, edge, merged) => {
  const conversions = defaultOptionsConversions.get(defaults);
  return conversions === undefined ? merged : conversions.merge(edge);
};
export const rememberConnectedEdge = (defaults, connection, edge) => {
  const conversions = defaultOptionsConversions.get(defaults);
  return conversions === undefined ? edge : conversions.connect(connection)(edge);
};
