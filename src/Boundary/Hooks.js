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

// zustand 4.5.7's `shallow`, which upstream's `useConnection` hands `useStore`
// as its equality: `Object.is`, then one level of keys (or Map/Set entries).
export const shallowEqual = (objA, objB) => {
  if (Object.is(objA, objB)) return true;
  if (typeof objA !== "object" || objA === null || typeof objB !== "object" || objB === null) {
    return false;
  }
  if (objA instanceof Map && objB instanceof Map) {
    if (objA.size !== objB.size) return false;
    for (const [key, value] of objA) {
      if (!Object.is(value, objB.get(key))) return false;
    }
    return true;
  }
  if (objA instanceof Set && objB instanceof Set) {
    if (objA.size !== objB.size) return false;
    for (const value of objA) {
      if (!objB.has(value)) return false;
    }
    return true;
  }
  const keysA = Object.keys(objA);
  if (keysA.length !== Object.keys(objB).length) return false;
  for (const keyA of keysA) {
    if (!Object.prototype.hasOwnProperty.call(objB, keyA) || !Object.is(objA[keyA], objB[keyA])) {
      return false;
    }
  }
  return true;
};
