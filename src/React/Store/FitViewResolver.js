// Upstream's `withResolvers` polyfill, member for member.
export const newFitViewResolver = () => {
  let resolve;
  let reject;
  const promise = new Promise((res, rej) => {
    resolve = res;
    reject = rej;
  });
  return { promise, resolve, reject };
};

// A method call on whatever the store holds, so a consumer's own resolver is
// called as upstream calls it, and a value without `resolve` throws as
// upstream's `fitViewResolver?.resolve(true)` does.
export const resolveFitView = (resolver) => (value) => () => {
  resolver.resolve(value);
};

// `Promise.resolve`, so a resolver whose `promise` is not a thenable settles
// with that value, as `return fitViewResolver.promise` from an `async`
// function does.
export const awaitFitViewImpl = (resolver) => (onError, onSuccess) => {
  Promise.resolve(resolver.promise).then(onSuccess, (reason) =>
    onError(reason instanceof Error ? reason : new Error(String(reason)))
  );
  return (_cancelError, _onCancelerError, onCancelerSuccess) => onCancelerSuccess();
};
