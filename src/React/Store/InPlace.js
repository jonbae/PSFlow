export const inPlace = (f) => (s) => Object.assign(s, f(s));
