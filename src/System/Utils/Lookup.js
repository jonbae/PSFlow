// Interop for `System.Utils.Lookup`: upstream's `Map` methods, called on a
// lookup a consumer wrote with something other than a `Map`.

export const getImpl = (key, lookup) => {
  const value = lookup.get(key);
  return value === undefined ? null : value;
};

export const hasImpl = (key, lookup) => lookup.has(key);

export const sizeAboveZero = (lookup) => lookup.size > 0;

export const sizeIsZeroImpl = (lookup) => lookup.size === 0;

export const valuesImpl = (lookup) => [...lookup.values()];

export const entryValuesImpl = (lookup) => [...lookup].map(([, value]) => value);

export const entryKeysImpl = (lookup) => [...lookup].map(([key]) => key);

export const forEachValuesImpl = (lookup) => {
  const values = [];
  lookup.forEach((value) => values.push(value));
  return values;
};

export const copiedImpl = (lookup) => new Map(lookup);

export const clearImpl = (lookup) => {
  lookup.clear();
  return lookup;
};

export const setImpl = (key, value, lookup) => {
  lookup.set(key, value);
  return lookup;
};

export const afterImpl = (_first, second) => second;

export const onThrowImpl = (handle, run) => {
  try {
    return run();
  } catch (error) {
    handle();
    throw error;
  }
};

export const foldlKeepingProgressImpl = (keep, step, initial, items) => {
  let result = initial;
  try {
    for (const item of items) result = step(result)(item);
  } catch (error) {
    keep(result);
    throw error;
  }
  return result;
};
