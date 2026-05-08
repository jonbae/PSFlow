"use strict";

// Convert a NonEmptyArray Int to a JS Array<number>. The PS NonEmptyArray
// runtime representation is just a JS array, so we read it as-is.
export const foreignToArray = (xs) => {
  if (Array.isArray(xs)) return xs;
  // NonEmptyArray's underlying value is at .value0 in some compiler outputs.
  if (xs && Array.isArray(xs.value0)) return xs.value0;
  return [];
};

export const isWrappedWithClassImpl = (event) => (className) => () => {
  if (!event || !event.target) return false;
  const target = event.target;
  if (typeof target.closest !== "function") return false;
  return target.closest("." + className) != null;
};

export const foreignCtrlKey = (event) => () => !!(event && event.ctrlKey);
export const foreignDeltaY = (event) => () => {
  if (!event || typeof event.deltaY !== "number") return 0;
  return event.deltaY;
};
export const foreignDeltaMode = (event) => () => {
  if (!event || typeof event.deltaMode !== "number") return 0;
  return event.deltaMode;
};
