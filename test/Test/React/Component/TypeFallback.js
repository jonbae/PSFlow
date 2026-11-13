// The two type maps hold one component each, under `default`, drawing an
// element whose class says which component drew it.
import { createElement } from "react";

export const nodeTypesWithDefault = {
  default: () => createElement("div", { className: "custom-default" }),
};

export const edgeTypesWithDefault = {
  default: () => createElement("path", { className: "custom-default-edge" }),
};
