// The two JavaScript coercions upstream's minimap leans on when it sizes the
// svg from `style.width` and `style.height`.

// `value ?? fallback`: only `null` and `undefined` fall back.
export const nullishOr = (fallback) => (value) => (value === null || value === undefined ? fallback : value);

// What `/` and `*` make of the value: a number stays itself, and a string
// reads as `Number(string)`, so `'100'` is 100 and `'100px'` is `NaN`.
export const asArithmetic = (value) => +value;
