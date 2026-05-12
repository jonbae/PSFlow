"use strict";

export const sourceEventInternal = (event) => () =>
  !!(event && event.internal);
export const sourceEventSync = (event) => () => !!(event && event.sync);
export const sourceEventButton = (event) => () =>
  event && typeof event.button === "number" ? event.button : 0;

export const sourceEventTypeIs = (event) => (typeName) => () =>
  !!(event && event.type === typeName);

export const sourceEventStopImmediate = (event) => () => {
  if (event && typeof event.stopImmediatePropagation === "function") {
    event.stopImmediatePropagation();
  }
};

export const sourceEventPreventDefault = (event) => () => {
  if (event && typeof event.preventDefault === "function") {
    event.preventDefault();
  }
};

export const sourceEventDeltaXY = (event) => () => ({
  x: (event && typeof event.deltaX === "number" && event.deltaX) || 0,
  y: (event && typeof event.deltaY === "number" && event.deltaY) || 0,
  mode: (event && typeof event.deltaMode === "number" && event.deltaMode) || 0,
  shiftKey: !!(event && event.shiftKey),
});

export const asMouseOrTouch = (event) => event;

export const foreignCtrlKey = (event) => () => !!(event && event.ctrlKey);
export const powN = (base) => (exp) => Math.pow(base, exp);

// d3 ZoomTransform accessors, polymorphic over input.
export const zoomTransformK_ = (t) => (t && typeof t.k === "number" ? t.k : 1);
export const transformX_ = (t) => (t && typeof t.x === "number" ? t.x : 0);
export const transformY_ = (t) => (t && typeof t.y === "number" ? t.y : 0);
