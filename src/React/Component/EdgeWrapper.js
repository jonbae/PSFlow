import { createElement } from "react";

export const svg_ = (props) => (children) =>
  createElement("svg", props, ...children);

export const joinSpace = (xs) => xs.filter((s) => s !== "").join(" ");
