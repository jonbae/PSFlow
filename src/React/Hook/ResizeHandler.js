// Last-element pick. Inlined here to avoid pulling Data.Array into the
// hook for one function.
export const lastEntryImpl = (arr) => arr[arr.length - 1];
