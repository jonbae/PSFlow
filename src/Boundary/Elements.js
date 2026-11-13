// Object spread for `Boundary.Elements`: `{ ...under, ...over }`, which
// copies symbol keys and keeps `under`'s key order where `over` does not
// override it, as upstream's object literals do.
export const spreadUnder = (under, over) => ({ ...under, ...over });
