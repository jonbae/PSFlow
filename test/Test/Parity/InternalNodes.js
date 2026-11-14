// Each number as `Object.is` tells it apart: `-0` apart from `0`, and `NaN` as
// itself.
export const exactNumber = (n) => (Object.is(n, -0) ? "-0" : String(n));

// `JSON.stringify`, with each number JSON can't hold written as `exactNumber`
// writes it.
export const exactJson = (value) =>
  JSON.stringify(value, (_key, v) =>
    typeof v === "number" && (!Number.isFinite(v) || Object.is(v, -0)) ? exactNumber(v) : v
  );
