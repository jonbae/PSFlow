// Runtime shape guards for `NodeBase` and `EdgeBase`. Both functions are
// total — they accept any value and return a `Boolean`. They look at JS
// own-property names rather than at the PS type, so they are useful at
// API boundaries where the input is `Foreign` (e.g. JSON revival).

export const isNodeBaseImpl = (e) =>
  e != null && typeof e === "object"
    && "id" in e && "position" in e
    && !("source" in e) && !("target" in e);

export const isEdgeBaseImpl = (e) =>
  e != null && typeof e === "object"
    && "id" in e && "source" in e && "target" in e;
