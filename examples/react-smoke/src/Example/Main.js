// Mount FFI for the smoke-test app. Uses `react-dom/client` (React 18+).
// `react` / `react-dom` are not installed in this repo by default — bundling
// and running the example is covered by ticket 053. The PS side type-checks
// regardless.

import { createRoot } from "react-dom/client";

export const mountAppImpl = (element) => (jsx) => () => {
  const root = createRoot(element);
  root.render(jsx);
};

// Current URL hash, e.g. "#/tests/generic/nodes/general" (or "" at the root).
export const getHashImpl = () => window.location.hash;

// Smoke-test observation hooks. PureScript ADTs (NodeChange, Connection)
// arrive here as JS class instances; the tests rely only on length /
// presence so the raw form is fine. Each call also bumps a counter so
// tests can wait for "something happened" without inspecting the array.
export const recordNodesChangeImpl = (changes) => () => {
  window.__lastNodeChanges = changes;
  window.__lastNodeChangesCount = (window.__lastNodeChangesCount || 0) + 1;
};

export const recordConnectImpl = (connection) => () => {
  window.__lastConnection = connection;
};
