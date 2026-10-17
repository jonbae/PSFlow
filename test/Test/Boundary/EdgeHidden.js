// Key presence is what the parity net compares, and PureScript records can't
// ask whether a key exists, so these build and read the JavaScript edges
// directly.
export const plainEdge = { id: "ab", source: "a", target: "b" };

export const edgeShown = { id: "ab", source: "a", target: "b", hidden: false };

export const connection = { source: "a", target: "b", sourceHandle: null, targetHandle: null };

export const hasOwnKey = (key) => (o) => Object.prototype.hasOwnProperty.call(o, key);

export const isFalseAt = (key) => (o) => o[key] === false;
