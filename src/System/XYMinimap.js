"use strict";

export const sourceTypeIs = (event) => (typeName) => () =>
  !!(event && event.type === typeName);

export const sourceClientXY = (event) => () => {
  if (!event) return { x: 0, y: 0 };
  if (typeof event.clientX === "number" && typeof event.clientY === "number") {
    return { x: event.clientX, y: event.clientY };
  }
  if (event.touches && event.touches[0]) {
    return { x: event.touches[0].clientX, y: event.touches[0].clientY };
  }
  return { x: 0, y: 0 };
};

export const sourceCtrlKey = (event) => () => !!(event && event.ctrlKey);
export const sourceDeltaY = (event) => () =>
  event && typeof event.deltaY === "number" ? event.deltaY : 0;
export const sourceDeltaMode = (event) => () =>
  event && typeof event.deltaMode === "number" ? event.deltaMode : 0;

export const logN = (n) => Math.log(n);
export const powN = (base) => (exp) => Math.pow(base, exp);
