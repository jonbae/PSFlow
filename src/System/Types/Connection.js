// Representation interop: a connection copy remembers the default edge
// options it was merged over, without a field either side can see.
const defaults = new WeakMap();

export const withEdgeDefaults = (options, connection) => {
  const copy = { ...connection };
  defaults.set(copy, options);
  return copy;
};

export const edgeDefaultsOf = (connection) => defaults.get(connection);
