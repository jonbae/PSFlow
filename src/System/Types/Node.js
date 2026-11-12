// Representation interop only: associate a decoded record with the original
// JS object without adding consumer-visible fields or caching decoded values.
const originals = new WeakMap();
export const rememberUserNode = (original, decoded) => {
  originals.set(decoded, original);
  return decoded;
};
export const originalUserNode = node => originals.get(node);
