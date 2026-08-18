// FFI for `Boundary.Callbacks`. Two things, both about a value the consumer
// handed *back* — which is what makes them different from every other crossing
// in this directory, where ps-flow is the one producing the value.
//
//   * `awaitPromise` — `onBeforeDelete` answers with
//     `Promise<boolean | { nodes, edges }>`, and ps-flow's own type is an
//     `Aff`. `Effect.Aff.Compat` bridges the two given a function of
//     `(onError, onSuccess)`, which is what this returns.
//
//   * `isArrayOf` — the object form of that answer has to be checked before it
//     is iterated, and `Array.isArray` is not expressible in PureScript.

export const isArrayOf = (value) => Array.isArray(value);

// `Promise.resolve` rather than `value.then`: upstream `await`s the result, so
// a consumer returning the value itself instead of a promise is following
// upstream's own contract and must not be punished for it.
//
// The rejection is wrapped when it is not already an `Error`. `Aff`'s error
// channel is typed `Error` and a rejected `throw "nope"` would otherwise
// arrive as a string that every `Effect.Exception` accessor reads as
// `undefined`, hiding what the consumer actually threw.
export const awaitPromise = (value) => (onError, onSuccess) => {
  Promise.resolve(value).then(onSuccess, (reason) =>
    onError(reason instanceof Error ? reason : new Error(String(reason)))
  );
  return (_cancelError, _onCancelerError, onCancelerSuccess) => onCancelerSuccess();
};
