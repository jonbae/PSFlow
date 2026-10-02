// A consumer's component, as a fresh function each call so two calls are two
// distinct components. It renders nothing; only its identity is under test.
export const newUserComponent = (name) => () => {
  const C = () => null;
  Object.defineProperty(C, "name", { value: name });
  return C;
};

export const componentAt = (key) => (map) => map[key];

export const displayNameOf = (component) => component.displayName;
