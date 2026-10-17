// Key presence is what the parity net compares, and PureScript records can't
// ask whether a key exists, so these build and read the JavaScript changes
// directly.

// A dimension change as `updateNodeInternals` and `handleExpandParent` build
// one, without `resizing`, and the two `NodeResizeControl` builds.
export const measureChange = { id: "a", type: "dimensions", dimensions: { width: 50, height: 25 } };

export const resizeStep = { id: "a", type: "dimensions", dimensions: { width: 50, height: 25 }, resizing: true };

export const resizeEnd = { id: "a", type: "dimensions", dimensions: { width: 50, height: 25 }, resizing: false };

export const hasOwnKey = (key) => (o) => Object.prototype.hasOwnProperty.call(o, key);

export const valueAt = (key) => (value) => (o) => o[key] === value;
