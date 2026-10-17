import React from "react";

// A stand-in for React's hook dispatcher that also commits: `render` runs a
// hook as one render, `commit` runs the effects whose dependencies changed,
// cleaning up each one's previous run first, and `unmount` runs every
// cleanup. Hook state is kept by call position, the way a fiber keeps it.
// `Test.React.Hook.Store`'s renderer records effects without running them;
// this one runs them, because what `useNodeObserver` does is in its effects.
export const newCommittingRenderer = (contextValue) => () => {
  const internals = React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED;
  const slots = [];
  let pending = [];
  let index = 0;

  const slot = (init) => {
    const i = index++;
    if (slots.length <= i) slots.push(init());
    return slots[i];
  };
  const depsChanged = (prev, next) =>
    prev === undefined || next === undefined || prev.length !== next.length || prev.some((d, i) => !Object.is(d, next[i]));
  const effect = (create, deps) => {
    const s = slot(() => ({ deps: undefined, cleanup: undefined, isEffect: true }));
    if (depsChanged(s.deps, deps)) {
      s.deps = deps;
      pending.push(() => {
        if (s.cleanup) s.cleanup();
        const cleanup = create();
        s.cleanup = typeof cleanup === "function" ? cleanup : undefined;
      });
    }
  };

  const dispatcher = {
    readContext: () => contextValue,
    useContext: () => contextValue,
    useRef: (init) => slot(() => ({ current: init })),
    useEffect: effect,
    useLayoutEffect: effect,
    useDebugValue: () => {},
  };

  return {
    render: (hook) => () => {
      const previous = internals.ReactCurrentDispatcher.current;
      internals.ReactCurrentDispatcher.current = dispatcher;
      index = 0;
      try {
        return hook();
      } finally {
        internals.ReactCurrentDispatcher.current = previous;
      }
    },
    commit: () => {
      const run = pending;
      pending = [];
      run.forEach((f) => f());
    },
    unmount: () => {
      slots.forEach((s) => {
        if (s.isEffect && s.cleanup) s.cleanup();
      });
    },
  };
};

// A `ResizeObserver` that writes down what it was asked to do.
export const newRecordingObserver = () => {
  const log = [];
  return {
    observer: {
      observe: (el) => log.push("observe " + el.id),
      unobserve: (el) => log.push("unobserve " + el.id),
      disconnect: () => log.push("disconnect"),
    },
    log: () => log.slice(),
  };
};

// A stand-in for a node's `<div>`; only its identity and its name matter.
export const element = (id) => ({ id });

export const attach = (ref) => (el) => () => {
  ref.current = el;
};
