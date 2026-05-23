// Mount FFI for the smoke-test app. Uses `react-dom/client` (React 18+).
// `react` / `react-dom` are not installed in this repo by default — bundling
// and running the example is covered by ticket 053. The PS side type-checks
// regardless.

import { createRoot } from "react-dom/client";

export const mountAppImpl = (element) => (jsx) => () => {
  const root = createRoot(element);
  root.render(jsx);
};
