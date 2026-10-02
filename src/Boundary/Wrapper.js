// FFI for `Boundary.Wrapper`. One function, shared by the three props whose
// values are components the consumer wrote.
//
// The wrapper carries the wrapped component's own name. React devtools, error
// boundaries and every stack trace read `displayName` off the outermost
// function, so a fixed name here would rename every custom node type, every
// custom edge type and the minimap's node component to the same thing.
//
// The fallback is generic for the same reason the type is: this function
// cannot tell which of the three props it is serving, and inventing a name
// that says would mean three copies of it.
//
// One wrapper per consumer component per prop, made once and then handed
// back. The props are converted on every render, and React reconciles by the
// component it is handed: a fresh wrapper each time is a different component
// type each time, so React unmounted every custom node and edge and mounted a
// new one on every render of the flow. Upstream hands React the consumer's own
// component, whose identity is the consumer's to keep, and the cache gives the
// wrapper that identity. Keyed by `prop` as well, because the render function
// converts props for one prop only, and a component a consumer registered as
// both a node type and an edge type needs both wrappers.
const caches = new Map();

export const mkComponentWrapper = (prop) => (wrapped) => (render) => {
  let cache = caches.get(prop);
  if (cache === undefined) {
    cache = new WeakMap();
    caches.set(prop, cache);
  }
  const cached = cache.get(wrapped);
  if (cached !== undefined) return cached;
  const Wrapper = (props) => render(props);
  Wrapper.displayName = wrapped.displayName || wrapped.name || "PSFlowUserComponent";
  cache.set(wrapped, Wrapper);
  return Wrapper;
};
