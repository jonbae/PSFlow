// Reference mutation and the interop views that must retain that reference.
// Field selection and conversion are supplied by PureScript.
const mirrors = new WeakMap();

export const inPlace = (f) => (s) => {
  Object.assign(s, f(s));
  for (const refresh of mirrors.get(s) ?? []) refresh();
  return s;
};

export const inPlaceThenImpl = (f, s, result) => {
  inPlace(f)(s);
  return result;
};

export const mirrorInPlaceImpl = (refresh, source, view) => {
  const watchers = mirrors.get(source) ?? [];
  watchers.push(() => Object.assign(view, refresh(source)(view)));
  mirrors.set(source, watchers);
  return view;
};
