"use strict";

export const classListContains = (element) => (cls) => () => {
  if (!element || !element.classList) return false;
  return element.classList.contains(cls);
};

export const getAttributeImpl = (element) => (name) => () => {
  if (!element) return null;
  const v = element.getAttribute(name);
  return v == null ? null : v;
};

export const isMultiTouchEvent = (eitherEvent) => () => {
  // PS `Either MouseEvent TouchEvent` is encoded as an object with a `value0`.
  // We don't depend on the exact shape — try the wrapped form first, then
  // treat the input as the raw event.
  if (!eitherEvent) return false;
  const ev = eitherEvent && "value0" in eitherEvent ? eitherEvent.value0 : eitherEvent;
  if (ev && ev.touches && typeof ev.touches.length === "number") {
    return ev.touches.length > 0;
  }
  return false;
};

export const querySelectorOnDocImpl = (host) => (selector) => () => {
  const root = host.value;
  if (!root || typeof root.querySelector !== "function") return null;
  return root.querySelector(selector);
};

export const elementFromPointOnDocImpl = (host) => (x) => (y) => () => {
  const root = host.value;
  if (!root || typeof root.elementFromPoint !== "function") return null;
  return root.elementFromPoint(x, y);
};

export const docCoerce = (doc) => doc;
export const shadowCoerce = (sr) => sr;

// Build a proper PS `Either` runtime value from a native event. `left`
// and `right` are the PS `Left` / `Right` data constructors threaded in
// from the call site — using them ensures the value is `instanceof Left`
// (or Right), which downstream pattern-matches require.
const wrapEither = (left, right, ev) => {
  if (ev && ev.touches) return right(ev);
  return left(ev);
};

const wireListener = (host, left, right, moveCb, upCb, op) => {
  const root = host.value;
  if (!root || typeof root[op] !== "function") return;
  if (op === "addEventListener") {
    if (!root.__xyflowListeners) root.__xyflowListeners = new Map();
    const moveAdapter = (ev) => moveCb(wrapEither(left, right, ev))();
    const upAdapter = (ev) => upCb(wrapEither(left, right, ev))();
    root.__xyflowListeners.set(moveCb, moveAdapter);
    root.__xyflowListeners.set(upCb, upAdapter);
    root.addEventListener("mousemove", moveAdapter);
    root.addEventListener("mouseup", upAdapter);
    root.addEventListener("touchmove", moveAdapter);
    root.addEventListener("touchend", upAdapter);
  } else {
    if (!root.__xyflowListeners) return;
    const moveAdp = root.__xyflowListeners.get(moveCb);
    const upAdp = root.__xyflowListeners.get(upCb);
    if (moveAdp) {
      root.removeEventListener("mousemove", moveAdp);
      root.removeEventListener("touchmove", moveAdp);
    }
    if (upAdp) {
      root.removeEventListener("mouseup", upAdp);
      root.removeEventListener("touchend", upAdp);
    }
    root.__xyflowListeners.delete(moveCb);
    root.__xyflowListeners.delete(upCb);
  }
};

export const addDocListenersImpl = (host) => (left) => (right) => (move) => (up) => () => {
  wireListener(host, left, right, move, up, "addEventListener");
};

// removeDocListenersImpl does not need the constructors — it only looks
// up previously-registered adapter refs in the WeakMap and unregisters
// them. Pass `null`s through to preserve the call signature.
export const removeDocListenersImpl = (host) => (move) => (up) => () => {
  wireListener(host, null, null, move, up, "removeEventListener");
};
