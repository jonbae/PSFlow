// Upstream's middleware maps: a plain `Map<symbol, fn>` per store.
//
// Every value is a JavaScript function taking and returning upstream's change
// objects, as in upstream's map. A PureScript function goes in as an adapter,
// and `native` remembers which PureScript function each adapter wraps, so
// running the map calls that function directly on PureScript changes.

const native = new WeakMap();
const adapters = { nodes: new WeakMap(), edges: new WeakMap() };
const converters = { nodes: null, edges: null };

const convertersFor = (kind) => {
  const found = converters[kind];
  if (found === null) {
    throw new Error(
      `ps-flow: a ${kind} change middleware was called from JavaScript before ` +
        'any JavaScript reached the store, which should not be possible.'
    );
  }
  return found;
};

export const freshMiddlewareMap = () => new Map();

export const freshMiddlewareKey = () => Symbol();

export const setMiddlewareImpl = (key, fn, map) => {
  map.set(key, fn);
};

const adapterFor = (kind, fn) => {
  const cache = adapters[kind];
  if (!cache.has(fn)) {
    const adapter = (changes) => {
      const { toJs, fromJs } = convertersFor(kind);
      return toJs(fn(fromJs(changes)));
    };
    native.set(adapter, fn);
    cache.set(fn, adapter);
  }
  return cache.get(fn);
};

export const setNativeMiddlewareImpl = (kind, key, fn, map) => {
  map.set(key, adapterFor(kind, fn));
};

export const deleteMiddlewareImpl = (key, map) => {
  map.delete(key);
};

export const hasMiddleware = (map) => map.size > 0;

export const runNodesChangeMiddlewareImpl = (map, changes) => {
  let current = changes;
  for (const middleware of map.values()) {
    const fn = native.get(middleware);
    if (fn !== undefined) current = fn(current);
    else {
      const { toJs, fromJs } = convertersFor('nodes');
      current = fromJs(middleware(toJs(current)));
    }
  }
  return current;
};

export const nodesChangeMiddlewareFrom = (fns) =>
  new Map(fns.map((fn) => [Symbol(), adapterFor('nodes', fn)]));

export const registerChangeConvertersImpl = (nodes, edges) => {
  converters.nodes = nodes;
  converters.edges = edges;
};
