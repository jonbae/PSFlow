// Interop for `System.Utils.AsWritten`: store members a consumer wrote with a
// value ps-flow's converter cannot read, held as that value.

const isReference = (value) =>
  (typeof value === "object" && value !== null) || typeof value === "function";

const held = new WeakSet();

// An array's items are held with it: ps-flow's code reads them as upstream's
// does, as the values written.
export const hold = (value) => {
  if (isReference(value)) held.add(value);
  if (Array.isArray(value)) for (const item of value) if (isReference(item)) held.add(item);
  return value;
};

// A member's converted value is always a reference, so a primitive one is a
// value held as written.
export const isHeld = (value) => !isReference(value) || held.has(value);

export const orHeld = (convert) => (value) => {
  try {
    return convert(value);
  } catch {
    return hold(value);
  }
};

// A record whose fields read `written` by index each time they are read, as
// upstream reads `transform[2]` or `extent[1][0]`.
const indexedFrom = new WeakMap();

export const indexedImpl = (paths) => (written) => {
  const view = {};
  for (const [name, path] of paths) {
    Object.defineProperty(view, name, {
      enumerable: true,
      get: () => path.reduce((value, index) => value[index], written),
    });
  }
  indexedFrom.set(view, written);
  return view;
};

export const writtenOfImpl = (record) => (indexedFrom.has(record) ? { value: indexedFrom.get(record) } : null);

export const orElseImpl = (first, second, value) => {
  try {
    return first(value);
  } catch {
    return second(value);
  }
};

// `const [a, b, c] = written` for a record `indexed` built, and `null` for
// any other.
export const destructuredImpl = (record) => {
  if (!indexedFrom.has(record)) return null;
  const [a, b, c] = indexedFrom.get(record);
  return [a, b, c];
};

export const iterated = (value) => (Array.isArray(value) ? value : [...value]);

export const forEachItems = (value) => {
  if (Array.isArray(value)) return value;
  const items = [];
  value.forEach((item) => items.push(item));
  return items;
};

export const mapped = (f) => (value) => value.map((item) => f(item));

export const some = (f) => (value) => value.some((item) => f(item));

export const reducedImpl = (step, initial, value) => value.reduce((result, item) => step(result)(item), initial);

export const nullish = (value) => {
  const written = indexedFrom.has(value) ? indexedFrom.get(value) : value;
  return written === null || written === undefined;
};

export const truthy = (value) => (indexedFrom.has(value) ? !!indexedFrom.get(value) : !!value);

export const member = (name) => (value) => value[name];

export const optionalMember = (name) => (value) => value?.[name];

export const spreadWith = (name) => (value) => (object) => ({ ...object, [name]: value });

export const spread = (object) => ({ ...object });

export const absent = undefined;

export const orIfUndefined = (fallback) => (value) =>
  value === undefined || (indexedFrom.has(value) && indexedFrom.get(value) === undefined) ? fallback : value;

export const copies = (value) => value.map((item) => ({ ...item }));
