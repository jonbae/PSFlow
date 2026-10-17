// Key presence is what the parity net compares, and PureScript records can't
// ask whether a key exists, so these build and read the JavaScript nodes
// directly.
export const plainNode = { id: "a", position: { x: 0, y: 0 }, data: {} };

export const nodeNotExpanding = { id: "a", position: { x: 0, y: 0 }, data: {}, expandParent: false };

export const hasOwnKey = (key) => (o) => Object.prototype.hasOwnProperty.call(o, key);

export const isFalseAt = (key) => (o) => o[key] === false;
