"use strict";

// `divEl.closest('.react-flow')` — walks ancestors to find the root
// flow container the ZoomPane is parented into. Returns null when the
// host element isn't yet attached or has no `.react-flow` ancestor.
export const closestReactFlowRootImpl = (divEl) => () => {
  if (!divEl || typeof divEl.closest !== "function") return null;
  return divEl.closest(".react-flow");
};
