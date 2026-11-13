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

// Upstream's `{ ...defaultEdgeOptions, ...edge }` is an object built from the
// consumer's two objects, so an edge handler handed the merged edge reads
// every key the consumer gave either. ps-flow merges the decoded records; this
// keeps the merge of the consumer's objects beside the merged record.
const defaultOptionsOriginals = new WeakMap();
export const rememberDefaultEdgeOptions = (original, decoded) => {
  if (typeof original === "object" && original !== null) defaultOptionsOriginals.set(decoded, original);
  return decoded;
};
export const rememberMergedEdge = (defaults, edge, merged) => {
  const shared = defaultOptionsOriginals.get(defaults);
  const own = originals.get(edge);
  if (shared !== undefined && own !== undefined) originals.set(merged, { ...shared, ...own });
  return merged;
};
