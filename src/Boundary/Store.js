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

const hasOwn = (object, key) => Object.prototype.hasOwnProperty.call(object, key);

// What `object[key]` answers, through the prototype and any getter, as
// upstream's `get().member` reads it. A primitive state has no members.
const memberOf = (object, key) => (object === null || object === undefined ? undefined : Object(object)[key]);

// Each PureScript state has one JavaScript view.
//
// Until a consumer replaces the whole state, a view is built from the state's
// *layout*: the keys upstream's state object would have, in its order, and
// the values of the keys that are not members. The first layout is
// `createStore`'s: the initial state's members, the actions, and the optional
// callbacks that are set. Each later state's layout adds the keys its update
// wrote that the layout lacked, as `Object.assign` adds them. A member reads
// through an accessor, converted on its first read.
//
// After `setState(next, true)`, upstream's state is `next` itself, and each
// later state is `Object.assign({}, state, partial)`. Here too, the view of a
// replaced state is `next`, untouched, and each later view is that merge, a
// plain object. Its members are the values upstream's state would hold, and
// the internals are brought up to date with it before they read: upstream's
// read `get().member`, which answers whatever the object then holds.
function createView(spec) {
  const { fields, actions } = spec;
  const keys = spec.keys;
  const known = new Set(keys);
  const isMember = (key) => typeof key === "string" && known.has(key);
  const actionNames = Object.keys(actions);
  const lastConverted = new Map();
  const handedOut = new Map(keys.map((key) => [key, new WeakMap()]));
  const viewOfState = new WeakMap();
  const layouts = new WeakMap();
  // A replaced state's plain object, and for each member the JavaScript value
  // and the PureScript value the internals last agreed on with it.
  const plain = new WeakMap();
  const held = new WeakMap();

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

  const jsOf = (key, state) => {
    const js = toJs(key, state, state[key]);
    return js === absent ? undefined : js;
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

  // ── Before a replacement ──────────────────────────────────────────────

  const makeLayout = (order, raw) => ({ keys: order, present: new Set(order), raw });

  const firstLayout = (state) => {
    const order = keys.filter((key) => !fields[key].optional);
    order.push(...actionNames);
    for (const key of keys) {
      if (fields[key].optional && toJs(key, state, state[key]) !== absent) order.push(key);
    }
    return makeLayout(order, new Map(actionNames.map((name) => [name, actions[name]])));
  };

  const layoutOf = (state) => {
    if (!layouts.has(state)) layouts.set(state, firstLayout(state));
    return layouts.get(state);
  };

  const withKeys = (layout, written, raw = layout.raw) => {
    const added = written.filter((key) => !layout.present.has(key));
    return added.length === 0 && raw === layout.raw ? layout : makeLayout([...layout.keys, ...added], raw);
  };

  const defaultView = (state) => {
    const layout = layoutOf(state);
    const object = {};
    const seen = new Map();
    for (const key of layout.keys) {
      if (isMember(key)) defineField(object, state, key, seen);
      else object[key] = layout.raw.get(key);
    }
    return object;
  };

  // ── After a replacement ───────────────────────────────────────────────

  // Brings `state` up to date with its plain object: each member whose value
  // the object answers differently from the one the internals hold converts
  // in place, as upstream's internals would read it next.
  const syncFrom = (state, kept) => {
    const object = plain.get(state);
    const agreed = held.get(state);
    for (const key of keys) {
      const js = memberOf(object, key);
      const entry = agreed.get(key);
      if (entry !== undefined && Object.is(js, entry.js)) continue;
      const value = toPs(key, js, state, kept);
      agreed.set(key, { js, ps: value });
      state[key] = value;
    }
  };

  // Upstream's internals change some members inside the objects they hold,
  // such as a node selected in `nodeLookup`, without a `set`. A member the
  // plain object holds as a writable value shows the internals' new value;
  // any other stays as the object answers it.
  const refreshFrom = (state) => {
    const object = plain.get(state);
    const agreed = held.get(state);
    for (const key of keys) {
      const entry = agreed.get(key);
      if (entry !== undefined && Object.is(entry.ps, state[key])) continue;
      const descriptor = Object.getOwnPropertyDescriptor(object, key);
      let js = memberOf(object, key);
      if (descriptor !== undefined && "value" in descriptor && descriptor.writable) {
        js = jsOf(key, state);
        object[key] = js;
      }
      agreed.set(key, { js, ps: state[key] });
    }
  };

  const adoptPlain = (state, object, agreed, kept) => {
    plain.set(state, object);
    held.set(state, agreed);
    syncFrom(state, kept);
    if (isReference(object)) {
      spec.mirror((source) => () => (refreshFrom(source), {}))(state)(object);
    }
  };

  // A state the internals moved to: an update after a replacement merges the
  // members its `set` names over the plain object, and one before it adds
  // them to the layout. A member the internals changed without naming it
  // shows its new value where the object holds it.
  spec.observeTransitions((previous) => (next) => (written) => () => {
    if (plain.has(next) || layouts.has(next)) return;
    if (!plain.has(previous)) {
      layouts.set(next, withKeys(layoutOf(previous), written));
      return;
    }
    const before = plain.get(previous);
    const partial = {};
    for (const key of written) partial[key] = jsOf(key, next);
    for (const key of keys) {
      if (hasOwn(partial, key) || Object.is(previous[key], next[key])) continue;
      if (isReference(before) && Object.prototype.propertyIsEnumerable.call(before, key)) partial[key] = jsOf(key, next);
    }
    const agreed = new Map(held.get(previous));
    for (const key of Object.keys(partial)) agreed.set(key, { js: partial[key], ps: next[key] });
    adoptPlain(next, Object.assign({}, before, partial), agreed, keptOne);
  })();

  spec.beforeRead((state) => () => {
    if (plain.has(state)) syncFrom(state, keptOne);
  })();

  const viewOf = (state) => {
    if (plain.has(state)) return plain.get(state);
    if (viewOfState.has(state)) return viewOfState.get(state);
    const view = defaultView(state);
    viewOfState.set(state, view);
    return view;
  };

  const getState = () => viewOf(spec.getState());

  const isPresent = (view, key) =>
    view !== null && view !== undefined && Object.prototype.hasOwnProperty.call(Object(view), key);

  // `Object.assign({}, state, partial)`. A member's value converts; any other
  // key is kept beside the state as written.
  const mergeIn = (partial) => {
    const state = spec.getState();
    if (plain.has(state)) {
      const object = Object.assign({}, plain.get(state), partial);
      spec.patch((s) => {
        const merged = Object.assign({}, s);
        adoptPlain(merged, object, new Map(held.get(s)), keptOne);
        return merged;
      })();
      return;
    }
    const current = viewOf(state);
    const source = partial === null || partial === undefined ? {} : Object(partial);
    const layout = layoutOf(state);
    const raw = new Map(layout.raw);
    const written = assignedKeys(source);
    const values = {};
    for (const key of written) {
      const js = source[key];
      if (!isMember(key)) raw.set(key, js);
      else if (!(isPresent(current, key) && Object.is(js, current[key]))) {
        values[key] = toPs(key, js, state, keptOne);
      }
    }
    const nextLayout = withKeys(layout, written, raw);
    spec.patch((s) => {
      const patched = Object.assign({}, s, values);
      layouts.set(patched, nextLayout);
      return patched;
    })();
  };

  // zustand's `state = nextState`. Every member converts from what `next`
  // answers for it, through its prototype, as upstream's internals would read
  // it. A member whose value ps-flow's internals cannot hold keeps its
  // previous value for them, and the ones `next` leaves out say so together.
  const replaceWith = (next) => {
    const leftOut = [];
    const kept = (key, error) => {
      if (isReference(next) ? key in next : false) keptOne(key, error);
      else leftOut.push(key);
    };
    spec.patch((s) => {
      const replaced = Object.assign({}, s);
      adoptPlain(replaced, next, new Map(), kept);
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

  // One PureScript listener per JavaScript one, so the store's `Set` sees
  // the same listener each time it is subscribed. zustand takes any value,
  // and calls it when it notifies.
  const listeners = new WeakMap();
  const primitiveListeners = new Map();
  const listenerFor = (listener) => {
    const table = isReference(listener) ? listeners : primitiveListeners;
    if (!table.has(listener)) {
      table.set(listener, (state) => (previous) => () => listener(viewOf(state), viewOf(previous)));
    }
    return table.get(listener);
  };
  const subscribe = (listener) => {
    const unsubscribe = spec.subscribeStates(listenerFor(listener))();
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
