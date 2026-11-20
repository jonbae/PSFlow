// Object spread for `Boundary.Elements`: `{ ...under, ...over }`, which
// copies symbol keys and keeps `under`'s key order where `over` does not
// override it, as upstream's object literals do.
export const spreadUnder = (under, over) => ({ ...under, ...over });

// Native key presence and rest copying, retaining symbols and undefined.
export const hasProperty = (key, object) => key in object;
export const omitKey = (key, object) => {
  const { [key]: omitted, ...rest } = object;
  return rest;
};
