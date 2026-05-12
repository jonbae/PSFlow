"use strict";

export const setTimeoutImpl = (action) => (ms) => () =>
  setTimeout(() => action(), ms);

export const clearTimeoutImpl = (id) => () => {
  clearTimeout(id);
};
