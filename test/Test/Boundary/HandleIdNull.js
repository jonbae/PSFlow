// `spago test` has no DOM, so the measured handles come from stand-ins. Each
// answers only what `getHandleBoundsImpl` asks of it.
const handleElement = (attributes) => ({
  getAttribute: (name) => (name in attributes ? attributes[name] : null),
  getBoundingClientRect: () => ({ left: 44, top: 10, width: 6, height: 6 }),
  offsetWidth: 6,
  offsetHeight: 6,
});

const nodeElementHolding = (handle) => ({
  querySelectorAll: (selector) => (selector === ".source" ? [handle] : []),
});

export const nodeElementWithoutHandleId = nodeElementHolding(handleElement({ "data-handlepos": "right" }));

export const nodeElementWithHandleId = nodeElementHolding(
  handleElement({ "data-handleid": "out", "data-handlepos": "right" }),
);

// One handle the consumer wrote without an `id`, one with `id: null`, and
// one with an id.
export const nodeWithHandles = {
  id: "a",
  position: { x: 0, y: 0 },
  data: {},
  handles: [
    { x: 50, y: 10, position: "right", type: "source" },
    { id: null, x: 0, y: 10, position: "left", type: "target" },
    { id: "in", x: 0, y: 20, position: "left", type: "target" },
  ],
};

// Each id as the consumer would see it. The values matter here, not whether
// the key exists, which `Boundary.Undefined.pruneUndefined` covers.
const idOf = (handle) =>
  handle.id === null ? "null" : handle.id === undefined ? "undefined" : `id ${handle.id}`;

export const handleIds = (handles) => handles.map(idOf);

export const nodeHandleIds = (node) => node.handles.map(idOf);

export const internalHandleIds = (internal) =>
  [...internal.internals.handleBounds.source, ...internal.internals.handleBounds.target].map(idOf);
