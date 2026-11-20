// `experimental_useOnNodesChangeMiddleware`, entered from JavaScript, against
// upstream.
//
// Upstream's hook keeps one `Symbol` per component and writes into the
// store's live middleware map in place: `map.set(symbol, fn)` whenever `fn`
// changes, and `map.delete(symbol)` on unmount, from the map it found at
// mount. Neither is a store update, so no subscriber hears of it, and a
// middleware that changes keeps its place in the map. A consumer reads that
// same map from `getState()`, and the store runs its values in order.
//
// The hooks only run their effects in a client render, so these mount with
// `react-dom/client` under a `ReactFlowProvider`, against the same stub DOM
// `selector-equality.test.mjs` uses.
import assert from 'node:assert/strict';
import test from 'node:test';
import { act, createElement as h } from 'react';
import { createRoot } from 'react-dom/client';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';
import { serializeValue } from '../system/harness/serialize.mjs';

globalThis.IS_REACT_ACT_ENVIRONMENT = true;
const document = { activeElement: null, body: null, addEventListener() {}, removeEventListener() {} };
globalThis.document = document;
globalThis.window = { document, event: undefined, HTMLIFrameElement: class {} };

const container = () => ({
  nodeType: 1,
  tagName: 'DIV',
  namespaceURI: null,
  ownerDocument: document,
  textContent: '',
  addEventListener() {},
  removeEventListener() {},
});

const sides = [
  ['upstream', upstream],
  ['psflow', psflow],
];

const graph = () => ({
  nodes: [
    { id: 'a', position: { x: 0, y: 0 }, data: {} },
    { id: 'b', position: { x: 100, y: 0 }, data: {} },
  ],
  edges: [],
});

const drag = () =>
  new Map(
    ['a', 'b'].map((id, i) => [
      id,
      { id, position: { x: i, y: i }, internals: { positionAbsolute: { x: i, y: i } }, measured: {} },
    ])
  );

function run(library) {
  const flow = {};
  function Store() {
    flow.api = library.useStoreApi();
    return null;
  }
  function Middleware({ fn }) {
    library.experimental_useOnNodesChangeMiddleware(fn);
    return null;
  }
  const root = createRoot(container());
  const { nodes, edges } = graph();
  const render = (first, second) =>
    act(() =>
      root.render(
        h(
          library.ReactFlowProvider,
          { initialNodes: nodes, initialEdges: edges },
          h(Store),
          first ? h(Middleware, { key: 'first', fn: first }) : null,
          second ? h(Middleware, { key: 'second', fn: second }) : null
        )
      )
    );

  const dropB = (changes) => changes.filter((change) => change.id !== 'b');
  const tag = (label) => (changes) => changes.map((change) => ({ ...change, [label]: true }));
  const first = tag('first');
  const replaced = tag('replaced');
  const trace = [];
  const look = (step) => {
    const map = flow.api.getState().onNodesChangeMiddlewareMap;
    const values = [...map.values()];
    trace.push({
      step,
      size: map.size,
      order: values.map((fn) => (fn === first ? 'first' : fn === replaced ? 'replaced' : fn === dropB ? 'dropB' : 'other')),
    });
  };

  render(first, dropB);
  const changes = [];
  let notified = 0;
  flow.api.subscribe(() => notified++);
  flow.api.setState({ onNodesChange: (batch) => changes.push(batch) });
  notified = 0;
  look('mount');
  act(() => flow.api.getState().updateNodePositions(drag(), true));
  render(replaced, dropB);
  look('first middleware replaced');
  act(() => flow.api.getState().updateNodePositions(drag(), false));
  render(null, dropB);
  look('first unmounted');
  act(() => flow.api.getState().updateNodePositions(drag(), false));
  const registrationNotified = notified;
  act(() => root.unmount());
  return { trace, changes: serializeValue(changes), registrationNotified };
}

test('the middleware hook writes into the live map as upstream does, and the store runs it in order', () => {
  const [up, ps] = sides.map(([, library]) => run(library));
  assert.deepEqual(ps, up);
  assert.deepEqual(
    up.trace.map(({ order }) => order),
    [['first', 'dropB'], ['replaced', 'dropB'], ['dropB']],
    'a replaced middleware keeps its place, and an unmounted one leaves'
  );
});
