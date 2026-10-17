// Key presence is what the parity net compares, and PureScript records can't
// ask whether a key exists, so these build and read the JavaScript nodes
// directly. Each node is measured, so `getNodesInside` can place it.
const node = (id, extra) => ({ id, position: { x: 0, y: 0 }, data: {}, measured: { width: 10, height: 10 }, ...extra });

export const plainNode = node("a", {});

export const nodeShown = node("b", { hidden: false });

export const nodeHidden = node("c", { hidden: true });

export const hasOwnKey = (key) => (o) => Object.prototype.hasOwnProperty.call(o, key);

export const isFalseAt = (key) => (o) => o[key] === false;
