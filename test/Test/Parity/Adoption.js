// `JSON.stringify` with every object's keys sorted, so two results compare as
// strings whichever order their members were written in.
const sortKeys = (value) => {
  if (Array.isArray(value)) return value.map(sortKeys);
  if (value === null || typeof value !== "object") return value;
  return Object.fromEntries(
    Object.keys(value)
      .sort()
      .map((key) => [key, sortKeys(value[key])])
  );
};

export const canonicalJson = (value) => JSON.stringify(sortKeys(value));
