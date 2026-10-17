// `null` and `undefined` are both absent to PureScript, so these read the
// converted connection directly.
export const isNullAt = (key) => (o) => o[key] === null;

export const keysOf = (o) => Object.keys(o);

export const valueIs = (key) => (value) => (o) => o[key] === value;
