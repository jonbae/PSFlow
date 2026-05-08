"use strict";

import { zoom, zoomTransform, zoomIdentity as _zoomIdentity } from "d3-zoom";
import { interpolate as _interpolate, interpolateZoom } from "d3-interpolate";

// ZoomTransform accessors — the value is the d3 ZoomTransform itself.
export const zoomTransformX = (t) => t.x;
export const zoomTransformY = (t) => t.y;
export const zoomTransformK = (t) => t.k;

export const zoomIdentity = _zoomIdentity;

export const zoomTranslate = (t) => (x) => (y) => t.translate(x, y);
export const zoomScale = (t) => (k) => t.scale(k);

export const zoomCreate = () => zoom();

export const setScaleExtent = (mn) => (mx) => (b) => () => {
  b.scaleExtent([mn, mx]);
  return b;
};

export const setTranslateExtent =
  (x1) => (y1) => (x2) => (y2) => (b) => () => {
    b.translateExtent([[x1, y1], [x2, y2]]);
    return b;
  };

export const setWheelDelta = (fn) => (b) => () => {
  b.wheelDelta((event) => fn(event)());
  return b;
};

export const setClickDistance = (n) => (b) => () => {
  b.clickDistance(n);
  return b;
};

export const setZoomOn = (typename) => (handler) => (b) => () => {
  b.on(typename, (event) => handler(event)());
  return b;
};

export const setZoomFilter = (predicate) => (b) => () => {
  b.filter((event) => predicate(event)());
  return b;
};

export const setInterpolate = (interp) => (b) => () => {
  b.interpolate(interp);
  return b;
};

export const zoomBehaviorTransform = (b) => (sel) => (t) => () => {
  b.transform(sel, t);
};

export const zoomBehaviorScaleTo = (b) => (sel) => (k) => () => {
  b.scaleTo(sel, k);
};

export const zoomBehaviorScaleBy = (b) => (sel) => (factor) => () => {
  b.scaleBy(sel, factor);
};

export const zoomBehaviorTranslateBy = (b) => (sel) => (dx) => (dy) => () => {
  b.translateBy(sel, dx, dy);
};

export const zoomBehaviorConstrain =
  (b) => (t) => (x1) => (y1) => (x2) => (y2) => (mx1) => (my1) => (mx2) => (my2) => {
    const constrainFn = b.constrain();
    return constrainFn(t, [[x1, y1], [x2, y2]], [[mx1, my1], [mx2, my2]]);
  };

export const currentZoomTransform = (node) => () => zoomTransform(node);

export const selectionGetZoomProperty = (sel) => () => sel.property("__zoom");

export const selectionSetWheelHandler = (sel) => (handler) => () => {
  sel.on("wheel.zoom", (event) => handler(event)(), { passive: false });
};

export const selectionGetZoomHandler = (sel) => (typename) => () => {
  const fn = sel.on(typename);
  // Wrap as a thunk that PS can store as a Foreign-typed callback.
  return (event) => () => {
    if (typeof fn === "function") fn.call(sel.node(), event);
  };
};

export const selectionCallZoom = (sel) => (b) => () => {
  sel.call(b);
};

export const selectionSetDblClickHandler = (sel) => (handler) => () => {
  sel.on("dblclick.zoom", (event) => handler(event)());
};

export const selectionSetDblClickNull = (sel) => () => {
  sel.on("dblclick.zoom", null);
};

export const linearInterpolate = _interpolate;
export const smoothZoomInterpolate = interpolateZoom;

export const zoomEventTransform = (event) => event.transform;
export const zoomEventSourceEvent = (event) =>
  event.sourceEvent === undefined ? null : event.sourceEvent;
