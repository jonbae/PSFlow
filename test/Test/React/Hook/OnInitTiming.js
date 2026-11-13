import assert from 'node:assert/strict';
import React from 'react';

export const initialNode = { id: 'init', position: { x: 0, y: 0 }, data: { marker: 'real store' } };

// A React dispatcher with real commit/cleanup phases and persistent hook
// slots. Store, selectors, useReactFlow and the hook under test are real.
export const newRenderer = context => () => {
  const slots = [];
  let index = 0;
  let pending = [];
  const slot = create => {
    const i = index++;
    if (i === slots.length) slots.push(create());
    return slots[i];
  };
  const changed = (previous, next) => previous === undefined || next === undefined ||
    previous.length !== next.length || previous.some((value, i) => !Object.is(value, next[i]));
  const memo = (create, deps) => {
    const state = slot(() => ({}));
    if (changed(state.deps, deps)) { state.value = create(); state.deps = deps; }
    return state.value;
  };
  const effect = (create, deps) => {
    const state = slot(() => ({}));
    if (changed(state.deps, deps)) {
      state.deps = deps;
      pending.push(() => {
        if (typeof state.cleanup === 'function') state.cleanup();
        state.cleanup = create();
      });
    }
  };
  const dispatcher = {
    useContext: () => context,
    useRef: value => slot(() => ({ current: value })),
    useMemo: memo,
    useCallback: (fn, deps) => memo(() => fn, deps),
    useEffect: effect,
    useLayoutEffect: effect,
    useInsertionEffect: effect,
    useSyncExternalStore: (_, snapshot) => { slot(() => ({})); return snapshot(); },
    useState: initial => [slot(() => ({ value: typeof initial === 'function' ? initial() : initial })).value, () => {}],
    useDebugValue() {},
  };
  return {
    render(render) {
      const cell = React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentDispatcher;
      const previous = cell.current;
      cell.current = dispatcher;
      index = 0;
      pending = [];
      try { render(); } finally { cell.current = previous; }
      for (const commit of pending) commit();
    },
    unmount() { for (const state of slots) if (typeof state.cleanup === 'function') state.cleanup(); },
  };
};

export const checkTiming = create => {
  const nativeSet = globalThis.setTimeout;
  const nativeClear = globalThis.clearTimeout;
  const timers = new Map();
  let id = 0;
  let now = 0;
  globalThis.setTimeout = (callback, delay) => { const key = ++id; timers.set(key, { callback, due: now + delay }); return key; };
  globalThis.clearTimeout = key => timers.delete(key);
  const tick = duration => {
    now += duration;
    for (const [key, timer] of timers) if (timer.due <= now) { timers.delete(key); timer.callback(); }
  };
  const validate = instance => {
    assert.equal(instance.viewportInitialized, true);
    assert.equal(instance.getNodes()[0].data.marker, 'real store');
  };
  try {
    const events = [];
    const session = create();
    const callback = instance => { validate(instance); events.push('first'); };
    session.render(callback);
    assert.deepEqual(events, [], 'not ready: no callback');
    assert.equal(timers.size, 0);
    session.ready(true);
    session.render(callback);
    assert.deepEqual(events, [], 'commit must schedule, not invoke onInit');
    assert.equal(timers.size, 1);
    tick(0);
    assert.deepEqual(events, [], 'not before 1ms');
    session.render(instance => { validate(instance); events.push('replacement'); });
    assert.equal(timers.size, 1, 'initialized flag is set at scheduling');
    tick(1);
    assert.deepEqual(events, ['first'], 'the scheduled closure retains its handler');
    session.render(callback);
    assert.equal(timers.size, 0, 'only once');

    const late = create();
    late.ready(true);
    late.render(undefined);
    assert.equal(timers.size, 0);
    late.render(instance => { validate(instance); events.push('late'); });
    assert.equal(timers.size, 1, 'a handler added after readiness must schedule');
    tick(1);
    assert.deepEqual(events, ['first', 'late']);

    const unmounted = create();
    unmounted.ready(true);
    unmounted.render(instance => { validate(instance); events.push('after unmount'); });
    unmounted.unmount();
    tick(1);
    assert.deepEqual(events, ['first', 'late', 'after unmount'], 'source does not cancel the timer at unmount');
  } finally {
    globalThis.setTimeout = nativeSet;
    globalThis.clearTimeout = nativeClear;
  }
};
