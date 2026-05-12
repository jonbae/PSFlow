"use strict";

// Element / HTMLDivElement dimension reads ----------------------------------

export const offsetWidth = (node) => () => node.offsetWidth;
export const offsetHeight = (node) => () => node.offsetHeight;

// DOMRect extraction --------------------------------------------------------

export const elementBoundingRectImpl = (node) => () => {
  const r = node.getBoundingClientRect();
  return { left: r.left, top: r.top, width: r.width, height: r.height };
};

// Event positional reads ----------------------------------------------------

export const mouseClientX = (e) => () => e.clientX;
export const mouseClientY = (e) => () => e.clientY;

export const touchClientX = (e) => () => {
  const t = e.touches && e.touches[0];
  return t ? t.clientX : 0;
};
export const touchClientY = (e) => () => {
  const t = e.touches && e.touches[0];
  return t ? t.clientY : 0;
};

// Keyboard / input detection ------------------------------------------------

const inputTags = ["INPUT", "SELECT", "TEXTAREA"];

export const isInputDOMNodeImpl = (event) => () => {
  const path = typeof event.composedPath === "function" ? event.composedPath() : null;
  const target = (path && path[0]) || event.target;
  if (!target || target.nodeType !== 1) return false;
  const isInput =
    inputTags.indexOf(target.nodeName) >= 0 ||
    (typeof target.hasAttribute === "function" && target.hasAttribute("contenteditable"));
  if (isInput) return true;
  return typeof target.closest === "function" && target.closest(".nokey") !== null;
};

// Host-element resolution ---------------------------------------------------

// Returns { tag: "doc" | "shadow", value: <node> }. The PureScript wrapper
// packs this into Either Document ShadowRoot.
const tagRoot = (root) => {
  const isShadow = root && typeof root.host !== "undefined";
  return { tag: isShadow ? "shadow" : "doc", value: root };
};

export const getRootNodeImpl = (element) => () => {
  let root = null;
  if (element && typeof element.getRootNode === "function") {
    root = element.getRootNode();
  }
  if (!root && typeof window !== "undefined") {
    root = window.document;
  }
  return tagRoot(root);
};

export const windowDocumentRoot = () => {
  const root = typeof window !== "undefined" ? window.document : null;
  return tagRoot(root);
};

// Viewport zoom extraction --------------------------------------------------

// Reads the `.xyflow__viewport` child of `host` and returns its current zoom
// (the m22 component of its CSS transform matrix). Returns null if the
// viewport child is missing or `getComputedStyle` is unavailable.
export const findViewportZoomImpl = (host) => () => {
  if (!host || typeof host.querySelector !== "function") return null;
  const viewport = host.querySelector(".xyflow__viewport");
  if (!viewport || typeof window === "undefined") return null;
  if (typeof window.getComputedStyle !== "function") return null;
  const style = window.getComputedStyle(viewport);
  if (!style || typeof window.DOMMatrixReadOnly !== "function") return null;
  try {
    const matrix = new window.DOMMatrixReadOnly(style.transform);
    return matrix.m22;
  } catch (_e) {
    return null;
  }
};

// Handle bounds extraction --------------------------------------------------

// Reads `nodeElement.querySelectorAll('.<type>')` and synthesises a Handle
// record for each match. Returns null if the selector matches nothing.
export const getHandleBoundsImpl = (typeStr, nodeElement, nodeBounds, zoom, nodeId) => () => {
  const handles = nodeElement.querySelectorAll("." + typeStr);
  if (!handles || handles.length === 0) return null;

  const result = new Array(handles.length);
  for (let i = 0; i < handles.length; i++) {
    const h = handles[i];
    const r = h.getBoundingClientRect();
    result[i] = {
      id: h.getAttribute("data-handleid"),
      handlePos: h.getAttribute("data-handlepos"),
      x: (r.left - nodeBounds.left) / zoom,
      y: (r.top - nodeBounds.top) / zoom,
      width: h.offsetWidth,
      height: h.offsetHeight,
    };
  }
  return result;
};
