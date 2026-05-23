export const mergeStyleImpl = (a) => (b) => ({ ...a, ...b });

export const filterEmptyImpl = (xs) => xs.filter((s) => s.length > 0);

export const joinWithSpaceImpl = (xs) => xs.join(" ");
