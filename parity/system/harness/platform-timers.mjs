// Platform timeout bookkeeping for wheel completion under the held clock.
// Observes scheduling only; no library state, callbacks or DOM are inspected.
export const installTimerObserver = () => {
  const key = '__psflowPlatformTimers';
  if (globalThis[key]) return;
  const timers = new Map();
  const schedule = globalThis.setTimeout;
  const cancel = globalThis.clearTimeout;
  const cancelInterval = globalThis.clearInterval;
  globalThis.setTimeout = function (callback, delay, ...args) {
    const milliseconds = Math.max(0, delay >> 0);
    const due = performance.now() + milliseconds;
    const id = schedule(function (...values) {
      timers.delete(id);
      if (typeof callback === 'function') return Reflect.apply(callback, this, values);
      return (0, eval)(String(callback));
    }, milliseconds, ...args);
    timers.set(id, due);
    return id;
  };
  globalThis.clearTimeout = function (id) { timers.delete(id); return cancel(id); };
  // HTML timers share an id pool: either clearing API can cancel a timeout.
  globalThis.clearInterval = function (id) { timers.delete(id); return cancelInterval(id); };
  globalThis[key] = () => ({ now: performance.now(), due: [...timers.values()] });
};
