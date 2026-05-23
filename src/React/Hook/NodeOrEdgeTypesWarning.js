export const objectKeysUnion = (a) => (b) => {
  const set = new Set();
  for (const k of Object.keys(a)) set.add(k);
  for (const k of Object.keys(b)) set.add(k);
  return Array.from(set);
};

export const lookupKey = (obj) => (key) => obj[key];

export const referenceEqual = (a) => (b) => a === b;

export const emptyTypes = {};
