import * as React from "react";

const mk = (tag) => (props) => (children) =>
  React.createElement(tag, props, ...children);

export const div_ = mk("div");
export const span_ = mk("span");
export const button_ = mk("button");
export const g_ = mk("g");
export const path_ = mk("path");
export const text_ = mk("text");
export const rect_ = mk("rect");
export const circle_ = mk("circle");
export const foreignObject_ = mk("foreignObject");
export const svg_ = mk("svg");
export const defs_ = mk("defs");
export const marker_ = mk("marker");
export const pattern_ = mk("pattern");
export const polyline_ = mk("polyline");
export const symbol_ = mk("symbol");
export const title_ = mk("title");

export const scrollResetHandlerImpl = (cb) => (event) => {
  if (event && event.currentTarget && event.currentTarget.scrollTo) {
    event.currentTarget.scrollTo({ top: 0, left: 0, behavior: "instant" });
  }
  cb();
};

// Guarded, because `blur` is `HTMLOrSVGElement`'s and not every element has
// one: an SVG element in a browser old enough to predate that interface has
// the ref but not the method, and the edge would throw on Escape rather than
// merely keep its focus ring.
export const blurSvgElement = (element) => () => {
  if (element && typeof element.blur === "function") {
    element.blur();
  }
};
