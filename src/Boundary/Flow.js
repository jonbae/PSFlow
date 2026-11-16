import { useEffect, useRef } from "react";

// Upstream's `<StoreUpdater />` writes each prop it tracks into the store
// with `setState({ [field]: value })` when the value changed and is defined.
// `defaultNodes` and `defaultEdges` are two of them, and neither is a member
// of `ReactFlowState`, so they arrive as keys outside the declared state.
// ps-flow's own store has no slot for either; this writes them through the
// store's JavaScript view, which keeps a key that is not a state member as
// zustand's state does.
export function storeDefaultsWriter({ view, defaultNodes, defaultEdges }) {
  const previous = useRef({});
  useEffect(() => {
    for (const [key, value] of [
      ["defaultNodes", defaultNodes],
      ["defaultEdges", defaultEdges],
    ]) {
      if (value === previous.current[key]) continue;
      if (typeof value === "undefined") continue;
      view.setState({ [key]: value });
    }
    previous.current = { defaultNodes, defaultEdges };
  }, [defaultNodes, defaultEdges]);
  return null;
}
