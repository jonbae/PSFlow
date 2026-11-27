export const min = (a) => (b) => Math.min(a, b);

export const max = (a) => (b) => Math.max(a, b);

export const orDefault = (fallback) => (value) => (value === undefined ? fallback : value);

export const toString = (n) => `${n}`;
