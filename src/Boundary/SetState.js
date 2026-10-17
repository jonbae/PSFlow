// Each returned element that is one of the objects the updater was handed
// maps back to the record it was made from, so it stays the same object.
// Anything else goes in through `inward`.
export const keepIdentityImpl = (previous, handed, returned, inward) => {
  const origin = new Map();
  for (let i = 0; i < handed.length; i++) origin.set(handed[i], previous[i]);
  return returned.map((element) => (origin.has(element) ? origin.get(element) : inward(element)));
};
