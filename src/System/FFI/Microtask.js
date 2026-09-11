"use strict";

export const queueMicrotaskImpl = (action) => () => {
  globalThis.queueMicrotask(() => action());
};
