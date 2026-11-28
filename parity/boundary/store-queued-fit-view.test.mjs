// A queued `fitView` that a node change settles, entered from JavaScript,
// against upstream. Upstream's uncontrolled `triggerNodeChanges` applies the
// changes and calls `setNodes`, and `setNodes` fits a queued view once the
// nodes are initialized. A controlled flow's changes go to `onNodesChange`
// only, so its fit waits for the next `setNodes`.
//
// Each check runs the same consumer code over both libraries and compares the
// order of what it observed. A server render mounts each flow and hands the
// probe the store; `StoreUpdater`'s effects do not run in a server render, so
// on both sides the store holds what the props seed.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';
import { serializeValue } from '../system/harness/serialize.mjs';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

const sides = [upstream, psflow];

const sized = (nodes) => nodes.map((node) => ({ ...node, measured: { width: 40, height: 20 } }));

const graph = () => ({
  nodes: [
    { id: 'a', position: { x: 0, y: 0 }, data: { label: 'a' } },
    { id: 'b', position: { x: 100, y: 100 }, data: { label: 'b' } },
    { id: 'c', position: { x: 200, y: 0 }, data: { label: 'c' } },
  ],
  edges: [{ id: 'ab', source: 'a', target: 'b' }],
});

// An uncontrolled flow is seeded as upstream's `StoreUpdater` seeds it on
// mount, with `setDefaultNodesAndEdges`, which sets `hasDefaultNodes`.
// `ReactFlow` hands `defaultNodes` to nothing else, and the server render
// runs no effects.
function mount(library, { uncontrolled = true, measured = true } = {}) {
  const flow = {};
  function Probe() {
    flow.api = library.useStoreApi();
    return null;
  }
  const { nodes, edges } = graph();
  const seeded = measured ? sized(nodes) : nodes;
  const props = uncontrolled ? { defaultNodes: seeded, defaultEdges: edges } : { nodes: seeded, edges };
  renderToStaticMarkup(createElement(library.ReactFlow, { ...props, children: createElement(Probe) }));
  if (uncontrolled) flow.api.getState().setDefaultNodesAndEdges(seeded, edges);
  return flow;
}

const bothAsync = async (run) => {
  const [up, ps] = await Promise.all(sides.map((library) => run(library)));
  return { up, ps };
};

// Settles after every promise job and timer the step queued has run.
const settle = () => new Promise((resolve) => setTimeout(resolve, 5));

const panZoomStub = (calls) => ({
  update: () => {},
  destroy: () => {},
  getViewport: () => ({ x: 0, y: 0, zoom: 1 }),
  setViewport: (viewport) => {
    calls.push(['setViewport', viewport]);
    return Promise.resolve({ x: viewport.x, y: viewport.y, k: viewport.zoom });
  },
  setViewportConstrained: (viewport) => Promise.resolve({ x: viewport.x, y: viewport.y, k: viewport.zoom }),
  scaleTo: () => Promise.resolve(true),
  scaleBy: () => Promise.resolve(true),
  setScaleExtent: () => {},
  setTranslateExtent: () => {},
  syncViewport: () => {},
  setClickDistance: () => {},
});

const moveA = [{ type: 'position', id: 'a', position: { x: 10, y: 10 } }];

// Queues a fit with a resolver the step can watch, records what each listener
// and `onNodesChange` call sees, runs `step`, and lets every queued job settle.
async function queuedFit(library, { mountWith, panZoom, step }) {
  const { api } = mount(library, mountWith);
  const calls = [];
  const fitViewResolver = {
    promise: new Promise(() => {}),
    resolve: (value) => calls.push(['resolve', value]),
  };
  api.setState({
    ...(panZoom ? { panZoom: panZoomStub(calls) } : {}),
    width: 400,
    height: 200,
    fitViewQueued: true,
    fitViewOptions: { padding: 0.3 },
    fitViewResolver,
    onNodesChange: (changes) => calls.push(['onNodesChange', changes.map((change) => [change.type, change.id])]),
  });
  api.subscribe((state) =>
    calls.push([
      'listener',
      state.fitViewQueued,
      state.fitViewOptions,
      state.fitViewResolver === fitViewResolver ? 'resolver' : state.fitViewResolver,
    ])
  );
  step(api.getState());
  calls.push(['step returned']);
  await settle();
  const state = api.getState();
  return {
    calls: serializeValue(calls),
    queued: state.fitViewQueued,
    options: serializeValue(state.fitViewOptions),
    resolver: state.fitViewResolver === fitViewResolver ? 'resolver' : state.fitViewResolver,
    positionA: state.nodeLookup.get('a').internals.positionAbsolute,
  };
}

test('an uncontrolled node change fits a queued view with the pan-zoom instance', async () => {
  const { up, ps } = await bothAsync((library) =>
    queuedFit(library, { panZoom: true, step: (state) => state.triggerNodeChanges(moveA) })
  );
  assert.deepEqual(ps, up);
  assert.equal(up.queued, false);
  assert.equal(up.resolver, null);
});

// Without an instance, upstream's `resolveFitView` returns at once: the fit is
// no longer queued, and the resolver stays for the next fit.
test('an uncontrolled node change dequeues the fit without a pan-zoom instance', async () => {
  const { up, ps } = await bothAsync((library) =>
    queuedFit(library, { panZoom: false, step: (state) => state.triggerNodeChanges(moveA) })
  );
  assert.deepEqual(ps, up);
  assert.equal(up.queued, false);
  assert.equal(up.resolver, 'resolver');
});

// Every action that reaches `triggerNodeChanges` fits the same way.
test('an uncontrolled selection fits a queued view', async () => {
  const { up, ps } = await bothAsync((library) =>
    queuedFit(library, { panZoom: true, step: (state) => state.addSelectedNodes(['b']) })
  );
  assert.deepEqual(ps, up);
  assert.equal(up.queued, false);
});

// `setNodes` fits only once every visible node is measured.
test('an uncontrolled change to unmeasured nodes keeps the fit queued', async () => {
  const { up, ps } = await bothAsync((library) =>
    queuedFit(library, { mountWith: { measured: false }, panZoom: true, step: (state) => state.triggerNodeChanges(moveA) })
  );
  assert.deepEqual(ps, up);
  assert.equal(up.queued, true);
});

// A controlled flow's change goes to `onNodesChange` alone.
test('a controlled node change keeps the fit queued', async () => {
  const { up, ps } = await bothAsync((library) =>
    queuedFit(library, { mountWith: { uncontrolled: false }, panZoom: true, step: (state) => state.triggerNodeChanges(moveA) })
  );
  assert.deepEqual(ps, up);
  assert.equal(up.queued, true);
});
