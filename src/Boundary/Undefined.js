// FFI for `Boundary.Undefined`.
//
// `undefined` is a value PureScript has no literal for, so the three
// primitives that produce, wrap and case on it live here.

export const undefined = void 0;

export const defined = (a) => a;

// `== null` rather than `=== undefined`: a JavaScript caller following
// upstream's own types can legitimately pass `null` (e.g. `sourceHandle?:
// string | null`), and both mean "not set" to a PureScript `Maybe`.
export const undefinableImpl = (nothing, just, u) => (u == null ? nothing : just(u));

export const isNull = (u) => u === null;
