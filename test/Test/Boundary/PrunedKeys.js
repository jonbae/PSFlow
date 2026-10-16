// Key presence is what the parity net compares, and PureScript records can't
// ask whether a key exists, so these read the converted objects directly.
export const undefinedKeys = (o) => Object.keys(o).filter((key) => o[key] === undefined);

export const sortedKeys = (o) => Object.keys(o).sort();

export const hasOwnKey = (key) => (o) => Object.prototype.hasOwnProperty.call(o, key);

export const isNullAt = (key) => (o) => o[key] === null;

export const markerOf = (key) => (o) => o[key];
