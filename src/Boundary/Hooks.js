// FFI for `Boundary.Hooks`: native tuples and callback identity association.
//
// `useNodesState` returns `[nodes, setNodes, onNodesChange]` — an array whose
// three slots have three different types, which PureScript's `Array` cannot
// say and its `Tuple` does not compile to. So the constructor is one line of
// JavaScript, and `JsTriple` is opaque on the PureScript side because the only
// thing ps-flow ever does with one is hand it to a consumer who destructures
// it.

export const mkTriple = (first, second, third) => [first, second, third];

// Generic representation interop. PureScript still owns the conversion;
// native weak keys keep a consumer callback's adapter reference stable.
export const cacheCallback = convert => {
  const callbacks = new WeakMap();
  return callback => {
    if (!callbacks.has(callback)) callbacks.set(callback, convert(callback));
    return callbacks.get(callback);
  };
};
