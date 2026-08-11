// FFI for `Boundary.Hooks`. One thing lives here: the tuple.
//
// `useNodesState` returns `[nodes, setNodes, onNodesChange]` — an array whose
// three slots have three different types, which PureScript's `Array` cannot
// say and its `Tuple` does not compile to. So the constructor is one line of
// JavaScript, and `JsTriple` is opaque on the PureScript side because the only
// thing ps-flow ever does with one is hand it to a consumer who destructures
// it.

export const mkTriple = (first, second, third) => [first, second, third];
