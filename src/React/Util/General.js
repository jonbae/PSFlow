export const isNodeImpl = (e) =>
  e != null && typeof e === "object"
    && "id" in e && "position" in e
    && !("source" in e) && !("target" in e);

export const isEdgeImpl = (e) =>
  e != null && typeof e === "object"
    && "id" in e && "source" in e && "target" in e;
