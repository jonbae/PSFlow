// Key presence is what the parity net compares, and PureScript records can't
// ask whether a key exists, so these build and read the JavaScript nodes and
// changes directly.
export const plainNode = { id: "a", position: { x: 0, y: 0 }, data: {} };

export const nodeAtRest = { id: "a", position: { x: 0, y: 0 }, data: {}, dragging: false };

// A position change as `NodeResizeControl` and `handleExpandParent` build
// one, without `dragging`, and one as the store's drag builds it.
export const moveWithoutDragging = { id: "a", type: "position", position: { x: 5, y: 5 } };

export const moveWhileDragging = { id: "a", type: "position", position: { x: 5, y: 5 }, dragging: true };

export const hasOwnKey = (key) => (o) => Object.prototype.hasOwnProperty.call(o, key);

export const valueAt = (key) => (value) => (o) => o[key] === value;
