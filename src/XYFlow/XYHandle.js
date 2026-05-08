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

const wrapEither = (ev) => {
  // The PS `Either MouseEvent TouchEvent` runtime constructors are
  // `Data_Either.Left.create` / `Data_Either.Right.create`. We adapt by
  // checking for the touches property — touch events go to Right.
  if (ev && ev.touches) {
    return { type: "Right", value0: ev };
  }
  return { type: "Left", value0: ev };
};

const wireListener = (host, moveCb, upCb, op) => {
  const root = host.value;
  if (!root || typeof root[op] !== "function") return;
  if (op === "addEventListener") {
    if (!root.__xyflowListeners) root.__xyflowListeners = new Map();
    const moveAdapter = (ev) => moveCb(wrapEither(ev))();
    const upAdapter = (ev) => upCb(wrapEither(ev))();
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

export const addDocListenersImpl = (host) => (move) => (up) => () => {
  wireListener(host, move, up, "addEventListener");
};

export const removeDocListenersImpl = (host) => (move) => (up) => () => {
  wireListener(host, move, up, "removeEventListener");
};
