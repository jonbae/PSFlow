const falsy = new WeakSet();

const isReference = (value) => (typeof value === "object" && value !== null) || typeof value === "function";

export const markFalsy = (value) => {
  if (isReference(value)) falsy.add(value);
  return value;
};

export const isTruthy = (value) => (isReference(value) ? !falsy.has(value) : !!value);
