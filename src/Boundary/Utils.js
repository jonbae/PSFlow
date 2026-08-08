// FFI for `Boundary.Utils.purs`. One thing lives here: a default parameter.
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
