const CALLBACK_HOOKS = new Set(["useOnSelectionChange", "useOnViewportChange"]);

/** Keep ordinary observations together, but run callback subscriptions one experiment at a time. */
export const selectProbeHooks = (names, probeCallback) =>
  names.filter((name) => !CALLBACK_HOOKS.has(name) || name === probeCallback);
