// FFI for `Boundary.Utils.purs`. Two things live here: a default parameter,
// and the three platform operations `getViewportForBounds`' padding reads
// through.
//
// Upstream's `addEdge` is declared `(edgeParams, edges, options = {})`, so its
// `length` is two and a consumer may call it with two arguments or three.
// PureScript has no default parameters — `Fn3` compiles to a function of three
// declared arguments, whose `length` is three — so expressing upstream's arity
// needs one line of JavaScript.
//
// `options = undefined` rather than `= {}`: the PureScript side reads the
// third argument as `Undefinable`, where absence *is* `undefined`, and an
// empty object would arrive as a supplied options bag with nothing in it.
// The two behave identically; this one says what it means.

export const withDefaultedOptions =
  (impl) =>
  (first, second, options = undefined) =>
    impl(first, second, options);

// `getViewportForBounds`' padding is an untagged JavaScript value that
// upstream reads with the platform's own operations, and each of these is one
// of them, so the behaviour that matters is the platform's rather than ours:
//
//   * `readProperty` — `padding.top`. On `null` it throws the `TypeError` the
//     engine writes, which is what upstream throws; a message composed in
//     PureScript would match one engine's wording at best.
//   * `parseFloat` — the global, which reads a numeric prefix and stops, and
//     returns `Infinity` for `"Infinity…"`.
//   * `interpolate` — the template-literal coercion upstream's error message
//     applies to the value it reports.
//
// Every decision about *which* of these to call, and in what order, is in
// `Boundary.Utils.purs`.

export const readProperty = (key, object) => object[key];

export const parseFloat = (string) => globalThis.parseFloat(string);

export const interpolate = (value) => `${value}`;
