// Diagnostic observer of platform timeout scheduling; no library state reads.
export const installTimerObserver = () => {
  const key = '__psflowPlatformTimers';
  if (globalThis[key]) return;
  const timers = new Map();
  const schedule = globalThis.setTimeout;
  const cancel = globalThis.clearTimeout;
  globalThis.setTimeout = function (callback, delay, ...args) {
    const due = performance.now() + Math.max(0, Number(delay) || 0);
    const id = schedule(function (...values) {
      timers.delete(id);
      if (typeof callback === 'function') return Reflect.apply(callback, this, values);
      return (0, eval)(String(callback));
    }, delay, ...args);
    timers.set(id, due);
    return id;
  };
  globalThis.clearTimeout = function (id) { timers.delete(id); return cancel(id); };
  globalThis[key] = () => ({ now: performance.now(), due: [...timers.values()] });
};
