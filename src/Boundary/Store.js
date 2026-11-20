// Interop for `Boundary.Store`: the JavaScript object a consumer reads through
// `useStore` and `useStoreApi`, and the zustand calling conventions around
// it. Every conversion is PureScript's; this file decides only *when* one
// runs, keeps the identities a JavaScript reader compares, and keeps the
// shape upstream's plain state object would have.
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

export const newMap = (entries) => new Map(entries);

export const mapEntriesImpl = (value) => (value instanceof Map ? [...value.entries()] : null);

export const isMap = (value) => value instanceof Map;

// `Object.assign`'s keys: own, enumerable, strings and symbols.
const assignedKeys = (object) =>
  Reflect.ownKeys(object).filter((key) => Object.prototype.propertyIsEnumerable.call(object, key));

// A new reference holding the same thing. A write whose value ps-flow could
// not hold exactly gets one, so the written value reads back from this state
// and from no other state that happens to share what it decoded to.
const freshCopy = (value) => {
  if (Array.isArray(value)) return value.slice();
  if (value !== null && typeof value === "object") {
    return Object.assign(Object.create(Object.getPrototypeOf(value)), value);
  }
  return value;
};

const views = new WeakMap();

export const storeViewImpl = (store) => (makeSpec) => {
  if (views.has(store)) return views.get(store);
  const view = createView(makeSpec());
  views.set(store, view);
  return view;
};

// Each PureScript state has one JavaScript view. Until a consumer replaces
// the whole state, a view is built the way upstream's `createStore` lays its
// state out: the members, the actions, the optional callbacks that are set,
// and the keys a consumer wrote beside them. After a replacement, upstream's
// state is whatever the consumer handed over, and each later state is
// `Object.assign({}, state, partial)` over it; a *layout* records those keys
// in order, for the replaced state and every state after it.
function createView(spec) {
  const { fields, actions } = spec;
  const keys = spec.keys;
  const known = new Set(keys);
  const isMember = (key) => typeof key === "string" && known.has(key);
  const lastConverted = new Map();
  const handedOut = new Map(keys.map((key) => [key, new WeakMap()]));
  const viewOfState = new WeakMap();
  const extrasOfState = new WeakMap();
  let extras = {};
  const layouts = new WeakMap();

  const warn = (message) => {
    if (spec.isDevelopment) console.warn(message);
  };

  const toJs = (key, state, value) => {
    const last = lastConverted.get(key);
    if (last !== undefined && Object.is(last.ps, value)) return last.js;
    const js = fields[key].toJs(state)(value);
    lastConverted.set(key, { ps: value, js });
    if (isReference(js)) handedOut.get(key).set(js, value);
    return js;
  };

  // A value the store handed out goes back as the PureScript value it came
  // from. Anything else converts, and reads back as the consumer's own value:
  // a conversion that would read back differently gets a fresh reference, and
  // a value the member's converter cannot read leaves `state`'s value in
  // place, under a fresh reference, for the internals. `kept` hears of that.
  const toPs = (key, js, state, kept) => {
    const out = handedOut.get(key);
    if (isReference(js) && out.has(js)) {
      const value = out.get(js);
      lastConverted.set(key, { ps: value, js });
      return value;
    }
    let value;
    try {
      value = fields[key].fromJs(js);
    } catch (error) {
      kept(key, error);
      value = freshCopy(state[key]);
      lastConverted.set(key, { ps: value, js });
      return value;
    }
    if (!Object.is(fields[key].toJs(state)(value), js)) value = freshCopy(value);
    lastConverted.set(key, { ps: value, js });
    if (isReference(js)) out.set(js, value);
    return value;
  };

  const keptOne = (key, error) =>
    warn(
      `ps-flow: the store member \`${key}\` holds a value ps-flow's internals cannot read ` +
        `(${error && error.message ? error.message : String(error)}). They keep its previous ` +
        "value; getState() reads back the value written."
    );

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
        let js = toJs(key, state, value);
        if (js === absent) js = undefined;
        seen.set(key, { ps: value, js });
        return js;
      },
      set(js) {
        const value = toPs(key, js, state, keptOne);
        seen.set(key, { ps: value, js });
        writeInPlace(state, key, value);
      },
    });
  };

  const defaultView = (state) => {
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
    return object;
  };

  const layoutView = (state, layout) => {
    if (layout.primitive) return layout.base;
    const object = {};
    const seen = new Map();
    for (const key of layout.keys) {
      if (isMember(key)) defineField(object, state, key, seen);
      else object[key] = layout.raw.get(key);
    }
    return object;
  };

  const viewOf = (state) => {
    if (viewOfState.has(state)) return viewOfState.get(state);
    const layout = layouts.get(state);
    const view = layout === undefined ? defaultView(state) : layoutView(state, layout);
    viewOfState.set(state, view);
    return view;
  };

  // A state the internals moved to, after a replacement: the keys carry
  // over, and a member the replacement left out comes back once the
  // internals change it, as an upstream `set` adds it back. `reset` sets
  // every key of `getInitialState`, which leaves out the optional members.
  spec.observeTransitions((previous) => (next) => (wasReset) => () => {
    if (layouts.has(next)) return;
    const layout = layouts.get(previous);
    if (layout === undefined) return;
    const present = new Set(layout.keys);
    const nextKeys = [...layout.keys];
    for (const key of keys) {
      if (present.has(key)) continue;
      if ((wasReset && !fields[key].optional) || !Object.is(previous[key], next[key])) {
        nextKeys.push(key);
        present.add(key);
      }
    }
    layouts.set(next, { primitive: false, keys: nextKeys, raw: layout.raw });
  })();

  const getState = () => viewOf(spec.getState());

  const isPresent = (view, key) =>
    view !== null && view !== undefined && Object.prototype.hasOwnProperty.call(Object(view), key);

  // `Object.assign({}, state, partial)`. A member's value converts; any other
  // key is kept beside the state as written.
  const mergeIn = (partial) => {
    const state = spec.getState();
    const current = viewOf(state);
    const source = partial === null || partial === undefined ? {} : Object(partial);
    const layout = layouts.get(state);
    const nextLayout =
      layout === undefined ? null : { primitive: false, keys: [...layout.keys], raw: new Map(layout.raw) };
    const present = nextLayout === null ? null : new Set(nextLayout.keys);
    const values = {};
    let nextExtras = null;
    for (const key of assignedKeys(source)) {
      const js = source[key];
      if (isMember(key)) {
        if (!(isPresent(current, key) && Object.is(js, current[key]))) {
          values[key] = toPs(key, js, state, keptOne);
        }
      } else if (nextLayout !== null) nextLayout.raw.set(key, js);
      else {
        nextExtras ??= { ...extras };
        nextExtras[key] = js;
      }
      if (nextLayout !== null && !present.has(key)) {
        nextLayout.keys.push(key);
        present.add(key);
      }
    }
    if (nextExtras !== null) extras = nextExtras;
    spec.patch((s) => {
      const patched = Object.assign({}, s, values);
      if (nextLayout !== null) layouts.set(patched, nextLayout);
      else extrasOfState.set(patched, extras);
      return patched;
    })();
  };

  // `next` becomes the view of `state` itself: its own members turn into
  // accessors over `state`, keeping their values, order and enumerability.
  // A frozen object cannot be written into upstream either, so it is the
  // view as it is. One whose members cannot be redefined is not adopted.
  const adopt = (next, state) => {
    if (Object.isFrozen(next)) return next;
    const members = assignedKeys(next).filter(isMember);
    if (members.some((key) => !Object.getOwnPropertyDescriptor(next, key).configurable)) return null;
    const seen = new Map();
    for (const key of members) defineField(next, state, key, seen);
    return next;
  };

  // zustand's `state = nextState`. Every member converts from `next`, the
  // ones `next` leaves out from `undefined`, as upstream's internals would
  // read them. A member whose value ps-flow's internals cannot hold keeps
  // its previous value for them, and the left-out ones say so together.
  const replaceWith = (next) => {
    const state = spec.getState();
    const reference = isReference(next);
    const source = next === null || next === undefined ? {} : Object(next);
    const own = assignedKeys(source);
    const ownSet = new Set(own);
    const values = {};
    const leftOut = [];
    for (const key of keys) {
      const js = next === null || next === undefined ? undefined : source[key];
      if (ownSet.has(key)) values[key] = toPs(key, js, state, keptOne);
      else {
        try {
          values[key] = fields[key].fromJs(js);
        } catch {
          leftOut.push(key);
        }
      }
    }
    const raw = new Map(own.filter((key) => !isMember(key)).map((key) => [key, source[key]]));
    const layout = reference
      ? { primitive: false, keys: own, raw }
      : { primitive: true, base: next, keys: own, raw };
    spec.patch((s) => {
      const replaced = Object.assign({}, s, values);
      layouts.set(replaced, layout);
      if (!reference) viewOfState.set(replaced, next);
      else {
        const adopted = adopt(next, replaced);
        if (adopted !== null) viewOfState.set(replaced, adopted);
      }
      return replaced;
    })();
    if (leftOut.length > 0) {
      warn(
        `ps-flow: \`setState\` replaced the state without ${leftOut.map((key) => `\`${key}\``).join(", ")}. ` +
          "ps-flow's internals keep their previous values; getState() leaves them out, as upstream's does."
      );
    }
  };

  // zustand 4.5.7's `setState`, field for field: a function is called with
  // the state, an identical result changes nothing, and anything else
  // replaces the state when `replace` says so, or when it is not an object,
  // and is otherwise merged over it. Every listener is notified.
  const setState = (partial, replace) => {
    const current = getState();
    const next = typeof partial === "function" ? partial(current) : partial;
    if (Object.is(next, current)) return;
    const replaces = replace != null ? replace : typeof next !== "object" || next === null;
    if (replaces) replaceWith(next);
    else mergeIn(next);
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

// A method call on an object the store was handed, made when the store
// calls it, as upstream's `panZoom.setViewport(…)` is.
export const callMethod = (object) => (name) => (args) => () => object[name](...args);

// The same call, awaited: upstream `await`s these, so a value that is not a
// promise settles as itself.
export const awaitMethodImpl = (object) => (name) => (args) => (onError, onSuccess) => {
  let result;
  try {
    result = object[name](...args);
  } catch (error) {
    onError(error);
    return (_cancelError, _onCancelerError, onCancelerSuccess) => onCancelerSuccess();
  }
  Promise.resolve(result).then(onSuccess, (reason) =>
    onError(reason instanceof Error ? reason : new Error(String(reason)))
  );
  return (_cancelError, _onCancelerError, onCancelerSuccess) => onCancelerSuccess();
};
