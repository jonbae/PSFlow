// The store's lifecycle, entered from JavaScript, against upstream: what
// `reset` keeps, which listeners a notification reaches while listeners come
// and go, and how a queued `fitView` settles when there is no pan-zoom
// instance to fit with.
//
// Each check runs the same consumer code over both libraries and compares the
// order of what it observed. A server render mounts each flow and hands the
// probe the store and the instance; `StoreUpdater`'s effects do not run in a
// server render, so on both sides the store holds what the props seed.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';
import { serializeValue } from '../system/harness/serialize.mjs';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

const sides = [
  ['upstream', upstream],
  ['psflow', psflow],
];

const graph = () => ({
  nodes: [
    { id: 'a', position: { x: 0, y: 0 }, data: { label: 'a' } },
    { id: 'b', position: { x: 100, y: 100 }, data: { label: 'b' } },
    { id: 'c', position: { x: 200, y: 0 }, data: { label: 'c' } },
  ],
  edges: [{ id: 'ab', source: 'a', target: 'b' }],
});

function mount(library) {
  const flow = {};
  function Probe() {
    flow.api = library.useStoreApi();
    flow.instance = library.useReactFlow();
    return null;
  }
  const { nodes, edges } = graph();
  renderToStaticMarkup(createElement(library.ReactFlow, { nodes, edges, children: createElement(Probe) }));
  return flow;
}

const bothAsync = async (run) => {
  const [up, ps] = await Promise.all(sides.map(([, library]) => run(library)));
  return { up, ps };
};

const both = (run) => {
  const [up, ps] = sides.map(([, library]) => run(library));
  return { up, ps };
};

// Settles after every promise job and timer the step queued has run.
const settle = () => new Promise((resolve) => setTimeout(resolve, 5));

// Whether `promise` has settled by the time queued work has run, and how.
const stateOf = async (promise) => {
  let outcome = ['pending'];
  promise.then(
    (value) => (outcome = ['resolved', value]),
    (reason) => (outcome = ['rejected', String(reason)])
  );
  await settle();
  return outcome;
};

// ── reset ────────────────────────────────────────────────────────────────

// Upstream's `reset` is `set({ ...getInitialState() })`, a merge: every member
// the initial state names goes back to its initial value, and everything
// else on the state stays as it was.
test('reset keeps the members the initial state does not name', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const written = {
      onNodesDelete: () => {},
      onEdgesDelete: () => {},
      onDelete: () => {},
      onBeforeDelete: async () => true,
      onConnect: () => {},
      onConnectStart: () => {},
      onConnectEnd: () => {},
      onClickConnectStart: () => {},
      onClickConnectEnd: () => {},
      onNodeDragStart: () => {},
      onNodeDrag: () => {},
      onNodeDragStop: () => {},
      onSelectionDragStart: () => {},
      onSelectionDrag: () => {},
      onSelectionDragStop: () => {},
      onMoveStart: () => {},
      onMove: () => {},
      onMoveEnd: () => {},
      onViewportChangeStart: () => {},
      onViewportChange: () => {},
      onViewportChangeEnd: () => {},
      defaultEdgeOptions: { animated: true },
      onNodesChange: () => {},
      onEdgesChange: () => {},
      isValidConnection: () => true,
      onError: () => {},
      myApplication: { flag: true },
    };
    api.setState(written);
    const before = api.getState();
    before.reset();
    const after = api.getState();
    // The order these keys come in is `store-replacement.test.mjs`'s.
    return {
      keys: Object.keys(after).sort(),
      kept: Object.fromEntries(Object.keys(written).map((key) => [key, after[key] === written[key]])),
      reinitialized: serializeValue({
        nodes: after.nodes,
        onNodesChange: after.onNodesChange,
        onEdgesChange: after.onEdgesChange,
        isValidConnection: after.isValidConnection,
        onError: typeof after.onError,
      }),
      changed: after !== before,
    };
  });
  assert.deepEqual(ps, up);
  assert.equal(up.kept.onConnect, true);
  assert.equal(up.kept.onNodesChange, false);
});

// The members `reset` keeps are the ones the store goes on calling.
test('after reset, the store calls the delete callbacks it kept, in upstream order', async () => {
  const { up, ps } = await bothAsync(async (library) => {
    const { api, instance } = mount(library);
    const calls = [];
    api.setState({
      onBeforeDelete: async ({ nodes, edges }) => (calls.push(['onBeforeDelete', nodes.map((n) => n.id), edges.map((e) => e.id)]), true),
      onNodesDelete: (nodes) => calls.push(['onNodesDelete', nodes.map((n) => n.id)]),
      onEdgesDelete: (edges) => calls.push(['onEdgesDelete', edges.map((e) => e.id)]),
      onDelete: ({ nodes, edges }) => calls.push(['onDelete', nodes.map((n) => n.id), edges.map((e) => e.id)]),
    });
    api.getState().reset();
    const { nodes, edges } = graph();
    api.getState().setNodes(nodes);
    api.getState().setEdges(edges);
    api.setState({ onNodesChange: (changes) => calls.push(['onNodesChange', changes.map((c) => [c.type, c.id])]) });
    api.setState({ onEdgesChange: (changes) => calls.push(['onEdgesChange', changes.map((c) => [c.type, c.id])]) });
    const result = await instance.deleteElements({ nodes: [{ id: 'a' }] });
    return { calls, deleted: serializeValue(result) };
  });
  assert.deepEqual(ps, up);
  assert.ok(up.calls.length >= 4);
});

// ── listeners ────────────────────────────────────────────────────────────

// zustand keeps its listeners in a `Set` and notifies with `forEach`, which
// visits the entries present when it reaches them: one removed before its
// turn is skipped, one added during the pass is reached in it.
test('a listener removed during a notification is not notified in that pass', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const log = [];
    const unsubscribe = {};
    unsubscribe.a = api.subscribe((state) => {
      log.push(['a', state.minZoom]);
      unsubscribe.b();
    });
    unsubscribe.b = api.subscribe((state) => log.push(['b', state.minZoom]));
    unsubscribe.c = api.subscribe((state) => {
      log.push(['c', state.minZoom]);
      unsubscribe.c();
    });
    unsubscribe.d = api.subscribe((state) => log.push(['d', state.minZoom]));
    api.setState({ minZoom: 0.3 });
    api.setState({ minZoom: 0.4 });
    unsubscribe.a();
    unsubscribe.d();
    api.setState({ minZoom: 0.6 });
    return log;
  });
  assert.deepEqual(ps, up);
  assert.deepEqual(up, [['a', 0.3], ['c', 0.3], ['d', 0.3], ['a', 0.4], ['d', 0.4]]);
});

test('a listener that removes one already notified leaves the rest of the pass alone', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const log = [];
    const unsubscribe = {};
    unsubscribe.a = api.subscribe(() => log.push('a'));
    unsubscribe.b = api.subscribe(() => (log.push('b'), unsubscribe.a()));
    unsubscribe.c = api.subscribe(() => log.push('c'));
    api.setState({ minZoom: 0.3 });
    api.setState({ minZoom: 0.4 });
    return log;
  });
  assert.deepEqual(ps, up);
  assert.deepEqual(up, ['a', 'b', 'c', 'b', 'c']);
});

test('a listener added during a notification is notified in that pass', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const log = [];
    let added = false;
    api.subscribe((state) => {
      log.push(['outer', state.minZoom]);
      if (!added) {
        added = true;
        api.subscribe((inner) => log.push(['inner', inner.minZoom]));
      }
    });
    api.subscribe((state) => log.push(['after', state.minZoom]));
    api.setState({ minZoom: 0.3 });
    api.setState({ minZoom: 0.4 });
    return log;
  });
  assert.deepEqual(ps, up);
});

// A `Set` holds a function once, so subscribing it again adds nothing, and
// either unsubscribe removes it.
test('one function subscribed twice is notified once, and one unsubscribe removes it', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const log = [];
    const listener = (state) => log.push(['twice', state.minZoom]);
    const first = api.subscribe(listener);
    api.subscribe((state) => log.push(['other', state.minZoom]));
    api.subscribe(listener);
    api.setState({ minZoom: 0.3 });
    first();
    api.setState({ minZoom: 0.4 });
    api.subscribe(listener);
    api.setState({ minZoom: 0.6 });
    return log;
  });
  assert.deepEqual(ps, up);
});

// A listener that writes to the store starts a pass of its own, which every
// listener present then hears before the outer pass goes on.
test('a write during a notification notifies the listeners left in the outer pass after its own', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const log = [];
    const unsubscribe = {};
    unsubscribe.a = api.subscribe((state, previous) => {
      log.push(['a', state.minZoom, previous.minZoom]);
      if (state.minZoom === 0.3) {
        unsubscribe.c();
        api.setState({ minZoom: 0.35 });
      }
    });
    unsubscribe.b = api.subscribe((state, previous) => log.push(['b', state.minZoom, previous.minZoom]));
    unsubscribe.c = api.subscribe((state, previous) => log.push(['c', state.minZoom, previous.minZoom]));
    api.setState({ minZoom: 0.3 });
    return log;
  });
  assert.deepEqual(ps, up);
});

// ── a queued fitView ─────────────────────────────────────────────────────

const sized = (nodes) => nodes.map((node) => ({ ...node, measured: { width: 40, height: 20 } }));

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

// Upstream's `resolveFitView` returns at once without a pan-zoom instance, so
// the resolver is neither resolved nor cleared. The fit is no longer queued.
test('without a pan-zoom instance, a queued fitView stays pending and keeps its resolver', async () => {
  const { up, ps } = await bothAsync(async (library) => {
    const { api } = mount(library);
    const calls = [];
    const fitViewResolver = {
      promise: new Promise(() => {}),
      resolve: (value) => calls.push(['resolve', value]),
    };
    api.subscribe((state) => calls.push(['listener', state.fitViewQueued, state.fitViewResolver === fitViewResolver]));
    api.setState({ width: 400, height: 200, fitViewQueued: true, fitViewResolver });
    api.getState().setNodes(sized(graph().nodes));
    await settle();
    const state = api.getState();
    return {
      calls,
      queued: state.fitViewQueued,
      kept: state.fitViewResolver === fitViewResolver,
      options: state.fitViewOptions,
    };
  });
  assert.deepEqual(ps, up);
  assert.equal(up.kept, true);
});

// The instance's `fitView` reuses the store's resolver, so a fit that could
// not run leaves its promise for the next fit to settle.
test('a fitView that could not run is settled by the next one, with the same promise', async () => {
  const { up, ps } = await bothAsync(async (library) => {
    const { api, instance } = mount(library);
    const calls = [];
    api.setState({ width: 400, height: 200 });
    const first = instance.fitView();
    api.getState().setNodes(sized(graph().nodes));
    const afterFirst = await stateOf(first);
    const resolver = api.getState().fitViewResolver;
    api.setState({ panZoom: panZoomStub(calls) });
    const second = instance.fitView({ padding: 0.2 });
    const reused = api.getState().fitViewResolver === resolver;
    api.getState().setNodes(sized(graph().nodes));
    const [firstAfter, secondAfter] = [await stateOf(first), await stateOf(second)];
    return {
      afterFirst,
      reused,
      firstAfter,
      secondAfter,
      calls: serializeValue(calls),
      cleared: api.getState().fitViewResolver,
    };
  });
  assert.deepEqual(ps, up);
  assert.deepEqual(up.afterFirst, ['pending']);
  assert.deepEqual(up.firstAfter, ['resolved', true]);
});

// With a pan-zoom instance, upstream fits before the `set` that clears the
// queue: the viewport is set before any listener hears of the new nodes, and
// the resolver resolves once the viewport promise has settled, before the
// `set` that clears it.
test('a queued fitView sets the viewport, notifies, resolves and clears in upstream order', async () => {
  const { up, ps } = await bothAsync(async (library) => {
    const { api } = mount(library);
    const calls = [];
    let settled;
    const fitViewResolver = {
      promise: new Promise((resolve) => (settled = resolve)),
      resolve: (value) => (calls.push(['resolve', value]), settled(value)),
    };
    api.setState({ panZoom: panZoomStub(calls), width: 400, height: 200, fitViewQueued: true, fitViewResolver });
    api.subscribe((state) =>
      calls.push(['listener', state.fitViewQueued, state.fitViewResolver === fitViewResolver ? 'resolver' : state.fitViewResolver])
    );
    api.getState().setNodes(sized(graph().nodes));
    calls.push(['setNodes returned']);
    const value = await fitViewResolver.promise;
    await settle();
    return { calls: serializeValue(calls), value };
  });
  assert.deepEqual(ps, up);
});
