// `debug: true`, entered from JavaScript, against upstream: the change logs
// `triggerNodeChanges`, `triggerEdgeChanges` and `updateNodeInternals` print,
// what they print, and where they fall among the store's notifications and
// change callbacks.
//
// Each check runs the same consumer code over both libraries and compares the
// order of what it observed, with each `console.log` call's arguments
// serialized. The measurements run in a browser, through
// `browser/harness.mjs`. Everything else runs in a server render, which
// mounts each flow and hands the probe the store;
// `StoreUpdater`'s effects do not run in a server render, so `debug` is
// written with `setState`, as the updater writes it, and an uncontrolled flow
// is seeded with `setDefaultNodesAndEdges`, as it seeds it on mount.
import assert from 'node:assert/strict';
import test, { after, before } from 'node:test';
import { fileURLToPath } from 'node:url';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';
import { serializeValue } from '../system/harness/serialize.mjs';
import { open } from './browser/harness.mjs';
import cases from './store-debug-log.cases.mjs';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

const sides = [upstream, psflow];

const graph = () => ({
  nodes: [
    { id: 'a', position: { x: 0, y: 0 }, data: { label: 'a' }, measured: { width: 40, height: 20 } },
    { id: 'b', position: { x: 100, y: 100 }, data: { label: 'b' }, measured: { width: 40, height: 20 }, selected: true },
  ],
  edges: [{ id: 'ab', source: 'a', target: 'b', selected: true }],
});

function mount(library, { uncontrolled = false, provider = false } = {}) {
  const flow = {};
  function Probe() {
    flow.api = library.useStoreApi();
    return null;
  }
  const { nodes, edges } = graph();
  const props = uncontrolled ? { defaultNodes: nodes, defaultEdges: edges } : { nodes, edges };
  const tree = createElement(library.ReactFlow, { ...props, children: createElement(Probe) });
  renderToStaticMarkup(provider ? createElement(library.ReactFlowProvider, null, tree) : tree);
  if (uncontrolled) flow.api.getState().setDefaultNodesAndEdges(nodes, edges);
  return flow;
}

// Runs `step` with `console.log` recorded alongside the callbacks and the
// listener, in the order they happen.
function observed(library, { debug = true, ...options }, step) {
  const { api } = mount(library, options);
  const calls = [];
  api.setState({
    debug,
    onNodesChange: (changes) => calls.push(['onNodesChange', changes]),
    onEdgesChange: (changes) => calls.push(['onEdgesChange', changes]),
  });
  api.subscribe(() => calls.push(['listener']));
  const log = console.log;
  console.log = (...args) => calls.push(['console.log', ...args]);
  try {
    step(api.getState());
  } finally {
    console.log = log;
  }
  return serializeValue(calls);
}

const both = (run) => {
  const [up, ps] = sides.map((library) => run(library));
  return { up, ps };
};

const moveA = [{ type: 'position', id: 'a', position: { x: 10, y: 10 } }];
const removeAb = [{ type: 'remove', id: 'ab' }];
const addC = [{ type: 'add', item: { id: 'c', position: { x: 5, y: 5 }, data: { label: 'c' } } }];

const steps = [
  ['triggerNodeChanges', (state) => state.triggerNodeChanges(moveA)],
  ['triggerNodeChanges with an add', (state) => state.triggerNodeChanges(addC)],
  ['triggerEdgeChanges', (state) => state.triggerEdgeChanges(removeAb)],
  ['addSelectedNodes', (state) => state.addSelectedNodes(['a'])],
  ['addSelectedEdges', (state) => state.addSelectedEdges([])],
  ['unselectNodesAndEdges', (state) => state.unselectNodesAndEdges()],
  ['an empty change list', (state) => state.triggerNodeChanges([])],
];

const mounts = [
  ['controlled', {}],
  ['uncontrolled', { uncontrolled: true }],
  ['inside ReactFlowProvider', { provider: true }],
];

// Upstream's uncontrolled `unselectNodesAndEdges` notifies once for its node
// changes and again for its edge changes, where ps-flow's notifies once for
// both. That difference is not the log's, so this case compares the logs and
// the callbacks without the listener.
const withoutListener = (calls) => calls.filter(([name]) => name !== 'listener');
const comparedAs = (mode, name) =>
  mode === 'uncontrolled' && name === 'unselectNodesAndEdges' ? withoutListener : (calls) => calls;

for (const [mode, options] of mounts) {
  for (const [name, step] of steps) {
    test(`${mode}: ${name} logs as upstream's does`, () => {
      const compared = comparedAs(mode, name);
      const { up, ps } = both((library) => compared(observed(library, options, step)));
      assert.deepEqual(ps, up);
    });
  }
}

test('upstream logs each non-empty change list once, before its callback', () => {
  const up = observed(upstream, {}, (state) => state.triggerNodeChanges(moveA));
  assert.deepEqual(up.map((call) => call[0]), ['console.log', 'onNodesChange']);
  assert.equal(up[0][1], 'React Flow: trigger node changes');
});

test('without debug, neither side logs', () => {
  const { up, ps } = both((library) =>
    observed(library, { debug: false }, (state) => {
      state.triggerNodeChanges(moveA);
      state.triggerEdgeChanges(removeAb);
    })
  );
  assert.deepEqual(ps, up);
  assert.ok(!up.some(([name]) => name === 'console.log'));
});

// ── After mount, in a browser ──────────────────────────────────────────

let harness;

before(async () => {
  harness = await open(fileURLToPath(new URL('./store-debug-log.cases.mjs', import.meta.url)));
});
after(() => harness?.close());

for (const { name } of cases) {
  test(name, async () => {
    const { upstream: up, psflow: ps } = await harness.run(name);
    assert.deepEqual(ps, up);
  });
}

test('upstream logs a measurement in updateNodeInternals and again in triggerNodeChanges', async () => {
  const { upstream: up } = await harness.run(cases[0].name);
  const order = up.calls.map((call) => (call.name === 'console.log' ? call.args[0] : call.name));
  assert.deepEqual(order.slice(0, 3), [
    'React Flow: trigger node changes',
    'React Flow: trigger node changes',
    'onNodesChange',
  ]);
});
