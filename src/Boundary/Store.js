// Interop for `Boundary.Store`: the JavaScript object a consumer reads through
// `useStore` and `useStoreApi`, and the zustand calling conventions around
// it. Every conversion is PureScript's; this file decides only *when* one
// runs and keeps the identities a JavaScript reader compares.
import React from "react";

const isReference = (value) =>
  (typeof value === "object" && value !== null) || typeof value === "function";

// A field converter answers this to say the key is not on upstream's state at
// all, which is how an optional callback upstream never set looks.
export const absent = Object.freeze({ "ps-flow": "absent" });

// Converted values, remembered both ways. Forward keeps an unchanged element
// the same object across reads; backward lets a value the store handed out be
// written back as the PureScript value it came from.
const producedFrom = new WeakMap();

export const reversibleImpl = (convert) => {
  const forward = new WeakMap();
  return (value) => {
    if (!isReference(value)) return convert(value);
    if (forward.has(value)) return forward.get(value);
    const converted = convert(value);
    forward.set(value, converted);
    if (isReference(converted)) producedFrom.set(converted, value);
    return converted;
  };
};

export const producedFromImpl = (value) => (isReference(value) ? producedFrom.get(value) : undefined);

// One `Symbol` per middleware key, as upstream registers each middleware
// under a `Symbol()` of its own.
const symbols = new Map();
export const middlewareSymbol = (key) => {
  if (!symbols.has(key)) symbols.set(key, Symbol());
  return symbols.get(key);
};

export const newMap = (entries) => new Map(entries);

export const mapEntriesImpl = (value) => (value instanceof Map ? [...value.entries()] : null);

export const refusingFunction = (message) => () => {
  throw new Error(message);
};

// `Object.assign`'s keys: own, enumerable, strings and symbols.
const assignedKeys = (object) =>
  Reflect.ownKeys(object).filter((key) => Object.prototype.propertyIsEnumerable.call(object, key));

const views = new WeakMap();

export const storeViewImpl = (store) => (makeSpec) => {
  if (views.has(store)) return views.get(store);
  const view = createView(makeSpec());
  views.set(store, view);
  return view;
};

function createView(spec) {
  const { fields, actions } = spec;
  const keys = spec.keys;
  const known = new Set(keys);
  const lastConverted = new Map();
  const handedOut = new Map(keys.map((key) => [key, new WeakMap()]));
  const viewOfState = new WeakMap();
  const extrasOfState = new WeakMap();
  let extras = {};

  const toJs = (key, state, value) => {
    const last = lastConverted.get(key);
    if (last !== undefined && Object.is(last.ps, value)) return last.js;
    const js = fields[key].toJs(state)(value);
    lastConverted.set(key, { ps: value, js });
    if (isReference(js)) handedOut.get(key).set(js, value);
    return js;
  };

  // A value the store handed out goes back as the PureScript value it came
  // from; anything else converts, and reads back as the consumer's own value.
  const toPs = (key, js) => {
    const out = handedOut.get(key);
    if (isReference(js) && out.has(js)) return out.get(js);
    const value = fields[key].fromJs(js);
    lastConverted.set(key, { ps: value, js });
    if (isReference(js)) out.set(js, value);
    return value;
  };

  // Upstream's state is a plain object, and a write into it is a write into
  // the live state that notifies nobody. `mutate` is that write when this is
  // the live state; an older state is written as itself, as upstream's is.
  const writeInPlace = (state, key, value) => {
    if (state === spec.getState()) spec.mutate(() => ({ [key]: value }))();
    else state[key] = value;
  };

  const defineField = (object, state, key, seen) => {
    Object.defineProperty(object, key, {
      enumerable: true,
      configurable: true,
      get() {
        const value = state[key];
        const cached = seen.get(key);
        if (cached !== undefined && Object.is(cached.ps, value)) return cached.js;
        const js = toJs(key, state, value);
        seen.set(key, { ps: value, js });
        return js;
      },
      set(js) {
        const value = toPs(key, js);
        seen.set(key, { ps: value, js });
        writeInPlace(state, key, value);
      },
    });
  };

  const viewOf = (state) => {
    if (viewOfState.has(state)) return viewOfState.get(state);
    const object = {};
    const seen = new Map();
    const optional = [];
    for (const key of keys) {
      if (fields[key].optional) optional.push(key);
      else defineField(object, state, key, seen);
    }
    for (const name of Object.keys(actions)) object[name] = actions[name];
    for (const key of optional) {
      if (toJs(key, state, state[key]) !== absent) defineField(object, state, key, seen);
    }
    const own = extrasOfState.get(state) ?? extras;
    for (const key of Reflect.ownKeys(own)) object[key] = own[key];
    viewOfState.set(state, object);
    return object;
  };

  const getState = () => viewOf(spec.getState());

  // zustand 4.5.7's `setState`, field for field: a function is called with the
  // state, an identical result changes nothing, and anything else is merged
  // over the state with `Object.assign` and notifies every listener.
  const setState = (partial, replace) => {
    const current = getState();
    const next = typeof partial === "function" ? partial(current) : partial;
    if (Object.is(next, current)) return;
    const replaces = replace != null ? replace : typeof next !== "object" || next === null;
    if (replaces) throw new Error(spec.replaceRefusal);
    const values = {};
    let nextExtras = null;
    if (typeof next === "object" && next !== null) {
      for (const key of assignedKeys(next)) {
        const js = next[key];
        if (typeof key === "string" && known.has(key)) {
          if (!Object.is(js, current[key])) values[key] = toPs(key, js);
        } else {
          nextExtras ??= { ...extras };
          nextExtras[key] = js;
        }
      }
    }
    if (nextExtras !== null) extras = nextExtras;
    spec.patch((state) => Object.assign({}, state, values))();
    extrasOfState.set(spec.getState(), extras);
  };

  const subscribe = (listener) => {
    const unsubscribe = spec.subscribeStates((state) => (previous) => () =>
      listener(viewOf(state), viewOf(previous))
    )();
    return () => {
      unsubscribe();
    };
  };

  const selectors = new WeakMap();
  const select = (selector) => {
    if (selector === undefined) return viewOf;
    if (!selectors.has(selector)) selectors.set(selector, (state) => selector(viewOf(state)));
    return selectors.get(selector);
  };

  return { getState, setState, subscribe, select };
}

const objectIs = (a) => (b) => Object.is(a, b);
const equalities = new WeakMap();

// The curried equality `React.Hook.Store`'s selection memo calls. Stable per
// consumer function, because the memo is rebuilt when its equality changes.
export const curriedEquality = (equalityFn) => {
  if (equalityFn === undefined) return objectIs;
  if (!equalities.has(equalityFn)) equalities.set(equalityFn, (a) => (b) => equalityFn(a, b));
  return equalities.get(equalityFn);
};

// `useMemo(() => ({ getState, setState, subscribe }), [store])`: a fresh
// object per component, holding the store's own three functions.
export const useApiObject = (view) =>
  React.useMemo(
    () => ({ getState: view.getState, setState: view.setState, subscribe: view.subscribe }),
    [view]
  );

export const selectThrough = (view) => (selector) => view.select(selector);
