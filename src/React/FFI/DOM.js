import * as React from "react";

const mk = (tag) => (props) => (children) =>
  React.createElement(tag, props, ...children);

export const div_ = mk("div");
export const span_ = mk("span");
export const g_ = mk("g");
export const path_ = mk("path");
export const text_ = mk("text");
export const rect_ = mk("rect");
export const circle_ = mk("circle");
export const foreignObject_ = mk("foreignObject");
