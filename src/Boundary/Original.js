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

// One conversion per consumer value and prop. Upstream's `<StoreUpdater />`
// and `memo` boundaries compare a prop with `!==`, so a consumer who passes
// the same callback, array or object again changes nothing. A conversion made
// afresh on each render is a new value every time; this hands back the one
// made the first time. Primitives are converted every time, as they compare
// by value anyway.
const stableCaches = new Map();

export const stablyImpl = (key, convert, value) => {
  if (!((typeof value === "object" && value !== null) || typeof value === "function")) {
    return convert(value);
  }
  let cache = stableCaches.get(key);
  if (cache === undefined) {
    cache = new WeakMap();
    stableCaches.set(key, cache);
  }
  if (!cache.has(value)) cache.set(value, convert(value));
  return cache.get(value);
};
