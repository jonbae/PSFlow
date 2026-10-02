import React from "react";

// A stand-in for React's hook dispatcher, so a hook can run outside a
// component. React routes every hook call through
// `ReactCurrentDispatcher.current`; installing this one for the length of a
// render records which hooks ran and keeps their state between renders, by
// call position, the way a fiber does. `spago test` has no DOM, so this is
// how a test sees what `useStore` asks React for.
//
// Only what `useStore` can reach is implemented. An effect is recorded and
// not run, as no commit happens; `useSyncExternalStore` keeps the
// `subscribe` and `getSnapshot` it was handed for the test to call.
export const newFakeRenderer = (contextValue) => () => {
  const internals = React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED;
  const slots = [];
  const calls = [];
  let external = null;
  let index = 0;

  const slot = (init) => {
    const i = index++;
    if (slots.length <= i) slots.push(init());
    return slots[i];
  };
  const depsChanged = (prev, next) =>
    prev === undefined || next === undefined || prev.length !== next.length || prev.some((d, i) => !Object.is(d, next[i]));

  const dispatcher = {
    readContext: () => contextValue,
    useContext: () => {
      calls.push("useContext");
      return contextValue;
    },
    useState: (init) => {
      calls.push("useState");
      const s = slot(() => ({ value: typeof init === "function" ? init() : init }));
      return [s.value, () => {}];
    },
    useReducer: (_, init) => {
      calls.push("useReducer");
      const s = slot(() => ({ value: init }));
      return [s.value, () => {}];
    },
    useRef: (init) => {
      calls.push("useRef");
      return slot(() => ({ current: init }));
    },
    useMemo: (create, deps) => {
      calls.push("useMemo");
      const s = slot(() => ({ deps: undefined, value: undefined }));
      if (depsChanged(s.deps, deps)) {
        s.value = create();
        s.deps = deps;
      }
      return s.value;
    },
    useCallback: (fn, deps) => {
      calls.push("useCallback");
      const s = slot(() => ({ deps: undefined, value: undefined }));
      if (depsChanged(s.deps, deps)) {
        s.value = fn;
        s.deps = deps;
      }
      return s.value;
    },
    useEffect: () => {
      calls.push("useEffect");
      slot(() => ({}));
    },
    useLayoutEffect: () => {
      calls.push("useLayoutEffect");
      slot(() => ({}));
    },
    useInsertionEffect: () => {
      calls.push("useInsertionEffect");
      slot(() => ({}));
    },
    useSyncExternalStore: (subscribe, getSnapshot, getServerSnapshot) => {
      calls.push("useSyncExternalStore");
      slot(() => ({}));
      external = { subscribe, getSnapshot, getServerSnapshot };
      return getSnapshot();
    },
    useDebugValue: () => {},
  };

  // One render of `hook`, a PureScript `Effect`. Returns its result.
  const render = (hook) => () => {
    const previous = internals.ReactCurrentDispatcher.current;
    internals.ReactCurrentDispatcher.current = dispatcher;
    index = 0;
    calls.length = 0;
    try {
      return hook();
    } finally {
      internals.ReactCurrentDispatcher.current = previous;
    }
  };

  return {
    render,
    calls: () => calls.slice(),
    hasExternalStore: () => external !== null,
    // The `subscribe` React was handed, as an identity a test can compare.
    subscribeIdentity: () => external.subscribe,
    // What React's `getSnapshot` returns now: a new object means a re-render.
    snapshot: () => external.getSnapshot(),
    // What a server render would read, or `null` when React was handed none,
    // in which case `react-dom/server` refuses to render at all.
    serverSnapshotOrNull: () =>
      typeof external.getServerSnapshot === "function" ? external.getServerSnapshot() : null,
    // Subscribe a listener as React would; returns the unsubscribe.
    subscribe: (listener) => () => {
      const unsubscribe = external.subscribe(() => listener());
      return () => unsubscribe();
    },
  };
};

export const sameReference = (a) => (b) => Object.is(a, b);
