import { createElement } from "react";

export const svg_ = (props) => (children) =>
  createElement("svg", props, ...children);
