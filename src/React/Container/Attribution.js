import { createElement } from "react";

export const a_ = (props) => (children) =>
  createElement("a", props, ...children);
