// FFI for `Boundary.Untagged` — the `typeof` / `Array.isArray` narrowing
// TypeScript does at the use site and erases.

export const asStringImpl = (nothing, just, x) => (typeof x === "string" ? just(x) : nothing);

export const asNumberImpl = (nothing, just, x) => (typeof x === "number" ? just(x) : nothing);

export const asBooleanImpl = (nothing, just, x) => (typeof x === "boolean" ? just(x) : nothing);

export const asArrayImpl = (nothing, just, x) => (Array.isArray(x) ? just(x) : nothing);

export const typeName = (x) => {
  if (x === null) return "null";
  if (Array.isArray(x)) return "array";
  return typeof x;
};
