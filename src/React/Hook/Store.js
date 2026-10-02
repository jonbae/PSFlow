import React from "react";

// Upstream's `useStore` is zustand's `useStoreWithEqualityFn`, which is
// `useSyncExternalStoreWithSelector` from `use-sync-external-store`. This is
// that hook, ported from `use-sync-external-store/with-selector` 1.6.0
// (`cjs/use-sync-external-store-with-selector.development.js`).
//
// The server snapshot is zustand's `getServerState || getInitialState`, and
// here it is `getState`: on a server nothing has dispatched, so the two are
// the same state. Without one, React refuses a server render outright
// ("Missing getServerSnapshot"), which is how `parity:boundary`'s mount check
// renders the converted props.
//
// What it buys over a `useState` fed by a subscription is React's own
// `useSyncExternalStore`. A slice that moved between the render and the
// subscription, or that moves later, re-renders on the synchronous lane,
// which React flushes at the end of the effect pass that noticed it, and a
// render that reads a store already ahead of it is caught before it commits.
//
// `memoizedSelector` is what keeps an unchanged slice from re-rendering. React
// compares snapshots with `Object.is`, so the slice handed back has to be the
// same object whenever the selector's `Eq` says nothing changed.
const selectionMemo = (selector) => (isEqual) => (inst) => {
  let hasMemo = false;
  let memoizedSnapshot;
  let memoizedSelection;
  return (nextSnapshot) => {
    if (!hasMemo) {
      hasMemo = true;
      memoizedSnapshot = nextSnapshot;
      const nextSelection = selector(nextSnapshot);
      if (inst.hasValue && isEqual(inst.value)(nextSelection)) {
        memoizedSelection = inst.value;
        return memoizedSelection;
      }
      memoizedSelection = nextSelection;
      return nextSelection;
    }
    const currentSelection = memoizedSelection;
    if (Object.is(memoizedSnapshot, nextSnapshot)) return currentSelection;
    const nextSelection = selector(nextSnapshot);
    if (isEqual(currentSelection)(nextSelection)) {
      memoizedSnapshot = nextSnapshot;
      return currentSelection;
    }
    memoizedSnapshot = nextSnapshot;
    memoizedSelection = nextSelection;
    return nextSelection;
  };
};

// A fresh memo's instance, before any render has committed a value.
const newSelectionInstance = () => ({ hasValue: false, value: null });

export const useStoreImpl = (store, selector, isEqual) => {
  // React resubscribes whenever `subscribe` changes, so it is fixed per store.
  const subscribe = React.useCallback(
    (onStoreChange) => store.subscribeAll(onStoreChange)(),
    [store]
  );
  const getSnapshot = store.getState;

  const instRef = React.useRef(null);
  if (instRef.current === null) instRef.current = newSelectionInstance();
  const inst = instRef.current;

  const getServerSnapshot = store.getState;

  const [getSelection, getServerSelection] = React.useMemo(() => {
    const memoizedSelector = selectionMemo(selector)(isEqual)(inst);
    return [() => memoizedSelector(getSnapshot()), () => memoizedSelector(getServerSnapshot())];
  }, [getSnapshot, getServerSnapshot, selector, isEqual]);

  const value = React.useSyncExternalStore(subscribe, getSelection, getServerSelection);
  React.useEffect(() => {
    inst.hasValue = true;
    inst.value = value;
  }, [value]);
  React.useDebugValue(value);
  return value;
};
