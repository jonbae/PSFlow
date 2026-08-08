// The driver's page — a twin of upstream's `generic-tests/index.tsx`, which
// picks a fixture out of a glob by the current route and hands it to `Flow`.
//
// Two differences from upstream's, both forced and both named in the corpus
// ticket. Upstream is vite plus `react-router`'s `useLocation`, so its route is
// a **path**; ps-flow is a static server, so the route is the **hash** and one
// `index.html` serves every fixture. And upstream's glob (`import.meta.glob`)
// is a vite feature that only ever sees files beneath the vendored tree; here
// the same registry is built by `../build.mjs` and injected as
// `psflow:fixtures`, so it can span more than one fixture root.
//
// Neither difference is cosmetic — the container's box feeds `fitView`, which
// feeds the viewport transform, which feeds everything — which is exactly why
// *both* of the net's runs use this page rather than one of them using
// upstream's app.
import { createRoot, type Root } from 'react-dom/client';

import Flow, { type FlowConfig } from './Flow';
import fixtures from 'psflow:fixtures';

// `#/tests/generic/nodes/general` names `./nodes/general.ts`, the same key
// upstream's path router derives. The prefix is upstream's route, kept so that
// a spec lifted from upstream's suite changes only its origin.
const ROUTE_PREFIX = '#/tests/generic';

function routeKey(): string {
  return `.${window.location.hash.replace(ROUTE_PREFIX, '')}.ts`;
}

const container = document.getElementById('app');
if (!container) {
  throw new Error('ps-flow driver: no #app element to mount into.');
}
const root: Root = createRoot(container);

function render() {
  const key = routeKey();
  const flowConfig: FlowConfig | undefined = fixtures[key];

  if (!flowConfig) {
    root.render(`404: This route doesn't exists.`);
    return;
  }

  // Keyed by route so that changing the hash remounts rather than handing the
  // running `Flow` a second fixture — its `useState` seeds from the first one
  // it sees, and a stale seed would look like a library that ignored the props.
  root.render(<Flow key={key} flowConfig={flowConfig} />);
}

window.addEventListener('hashchange', render);
render();
