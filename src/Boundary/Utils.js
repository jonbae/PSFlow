// FFI for `Boundary.Utils.purs`: default parameters and platform operations.
// PureScript owns the selection, validation and arithmetic; JavaScript exposes
// property reads, parsing/coercion, presence tests, Map.get and the environment.
//
// Upstream's `addEdge` is declared `(edgeParams, edges, options = {})`, so its
// `length` is two and a consumer may call it with two arguments or three.
// PureScript has no default parameters — `Fn3` compiles to a function of three
// declared arguments, whose `length` is three — so expressing upstream's arity
// needs one line of JavaScript.
//
// `options = undefined` rather than `= {}`: the PureScript side reads the
// third argument as `Undefinable`, where absence *is* `undefined`, and an
// empty object would arrive as a supplied options bag with nothing in it.
// The two behave identically; this one says what it means.

export const withDefaultedOptions =
  (impl) =>
  (first, second, options = undefined) =>
    impl(first, second, options);

// `getViewportForBounds`' padding is an untagged JavaScript value that
// upstream reads with the platform's own operations, and each of these is one
// of them, so the behaviour that matters is the platform's rather than ours:
//
//   * `readProperty` — `padding.top`. On `null` it throws the `TypeError` the
//     engine writes, which is what upstream throws; a message composed in
//     PureScript would match one engine's wording at best.
//   * `parseFloat` — the global, which reads a numeric prefix and stops, and
//     returns `Infinity` for `"Infinity…"`.
//   * `interpolate` — the template-literal coercion upstream's error message
//     applies to the value it reports.
//
// Every decision about *which* of these to call, and in what order, is in
// `Boundary.Utils.purs`.

export const readProperty = (key, object) => object[key];

export const parseFloat = (string) => globalThis.parseFloat(string);

export const interpolate = (value) => `${value}`;

// The second parameter of getNodesBounds has a JS default. PureScript owns
// its value/default selection; this preserves the actual Function.length.
export const withBoundsOptions = (impl) => (nodes, params = undefined) => impl(nodes, params);

// Platform operations only. Node/lookup selection, geometry and warning
// decisions remain in PureScript, including the order in which these run.
export const boundsHasProperty = (key, object) => key in object;
export const boundsTruthy = (value) => Boolean(value);
export const boundsMapGet = (lookup, key) => lookup.get(key);
export const boundsDevelopment = () => process.env.NODE_ENV === "development";

export const withReconnectOptions = (impl) => (oldEdge, connection, edges, options = undefined) =>
  impl(oldEdge, connection, edges, options);

// Native object rest/spread preserves own enumerable string/symbol keys,
// invokes getters in platform order, and treats __proto__ as an own key.
export const copyEnumerable = (object) => ({ ...object });
export const splitEdgeIdentity = (object) => {
  // Keep the same static id/rest destructuring syntax as the source.
  const { id: value, ...rest } = object;
  return { value, rest };
};
export const mergeEnumerable = (base, update) => ({ ...base, ...update });
export const invokeBinary = (fn, receiver, first, second) => Reflect.apply(fn, receiver, [first, second]);

// Fresh collections and native mutation only; change grouping, precedence and
// selection stay in PureScript. splice preserves JS index coercion.
export const newChangeMap = () => new Map();
export const setChangeMap = (map, key, value) => { map.set(key, value); };
export const newConsumerArray = () => [];
export const pushConsumerImpl = (array, value) => { array.push(value); };
export const spliceConsumer = (array, index, value) => { array.splice(index, 0, value); };
export const writeProperty = (key, object, value) => { object[key] = value; };

export const deleteProperty = (key, object) => { delete object[key]; };
export const concatConsumer = (array, value) => array.concat(value);
