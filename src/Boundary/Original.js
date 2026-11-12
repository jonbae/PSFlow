// Representation interop: a converted PureScript value keeps a link to the
// consumer's own JavaScript value it was converted from, without adding a
// visible field to either. The conversions stay in PureScript.
const originals = new WeakMap();

export const rememberOriginal = (original, converted) => {
  if ((typeof converted === "object" && converted !== null) || typeof converted === "function") {
    originals.set(converted, original);
  }
  return converted;
};

export const originalOf_ = (converted) =>
  (typeof converted === "object" && converted !== null) || typeof converted === "function"
    ? originals.get(converted)
    : undefined;
