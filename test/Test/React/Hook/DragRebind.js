import React from "react";

// A stand-in for React's hook dispatcher that also commits, as
// `Test.React.Hook.NodeObserver`'s does, with the `useState` that `useDrag`
// calls as well. `render` runs a hook as one render, `commit` runs the
// effects whose dependencies changed, cleaning up each one's previous run
// first, and `unmount` runs every cleanup.
export const newCommittingRenderer = () => {
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
    useRef: (init) => slot(() => ({ current: init })),
    useState: (init) => {
      const s = slot(() => ({ value: typeof init === "function" ? init() : init }));
      return [s.value, (u) => (s.value = typeof u === "function" ? u(s.value) : u)];
    },
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

// A node's `<div>` as d3-drag binds it. It takes touches (`ontouchstart`),
// so d3-drag adds its touch listeners, and it takes the style d3-drag
// writes. It counts the `touchmove` listeners it holds and how many were
// ever removed.
export const newDragTarget = () => {
  let held = 0;
  let removed = 0;
  return {
    ref: {
      current: {
        ontouchstart: null,
        style: { setProperty: () => {} },
        addEventListener: (type) => {
          if (type === "touchmove") held += 1;
        },
        removeEventListener: (type) => {
          if (type === "touchmove") {
            held -= 1;
            removed += 1;
          }
        },
      },
    },
    touchMoveListeners: () => held,
    touchMoveRemovals: () => removed,
  };
};
