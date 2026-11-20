// `useStore` and `useStoreApi`, entered from JavaScript, against upstream.
//
// Every check runs the same consumer code over both libraries and compares
// what it reads back. A server render mounts each flow and hands the probe the
// store; the checks then drive that store directly, which is how a consumer's
// event handler or effect reaches it. `StoreUpdater`'s effects do not run in
// a server render, so on both sides the state is the initial state the props
// seed.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';
import { serializeValue } from '../system/harness/serialize.mjs';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

const sides = [
  ['upstream', upstream],
  ['psflow', psflow],
];

const graph = () => {
  const nodes = [
    { id: 'a', position: { x: 0, y: 0 }, data: { label: 'a' }, type: 'input', custom: 1 },
    { id: 'b', position: { x: 100, y: 100 }, data: { label: 'b' }, parentId: 'a' },
    { id: 'c', position: { x: 200, y: 0 }, data: { label: 'c' } },
  ];
  const edges = [
    { id: 'ab', source: 'a', target: 'b', sourceHandle: 'h', custom: 2 },
    { id: 'bc', source: 'b', target: 'c' },
  ];
  return { nodes, edges };
};

function mount(library, props = {}, select = (s) => s.transform, equalityFn) {
  const result = {};
  function Probe() {
    result.api = library.useStoreApi();
    result.again = library.useStoreApi();
    result.selected = library.useStore(select, equalityFn);
    result.whole = library.useStore();
    return null;
  }
  const { nodes, edges } = graph();
  result.nodes = props.nodes ?? nodes;
  result.edges = props.edges ?? edges;
  renderToStaticMarkup(
    createElement(library.ReactFlow, { nodes: result.nodes, edges: result.edges, ...props, children: createElement(Probe) })
  );
  return result;
}

const entries = (map) =>
  [...map.entries()].map(([key, value]) => [
    key,
    value instanceof Map ? entries(value) : serializeValue(value),
  ]);

// The four lookups are `Map`s, which the serializer records as their class
// alone, so their entries are compared separately.
const snapshot = (state) => ({
  state: serializeValue(state),
  nodeLookup: entries(state.nodeLookup),
  parentLookup: entries(state.parentLookup),
  edgeLookup: entries(state.edgeLookup),
  connectionLookup: entries(state.connectionLookup),
});

const both = (run) => {
  const [up, ps] = sides.map(([, library]) => run(library));
  return { up, ps };
};

test('getState hands over upstream state, member for member and entry for entry', () => {
  const { up, ps } = both((library) => snapshot(mount(library).api.getState()));
  assert.deepEqual(Object.keys(ps.state), Object.keys(up.state));
  assert.deepEqual(ps, up);
});

test('useStore answers the selection, and the whole state with no selector', () => {
  const { up, ps } = both((library) => {
    const flow = mount(library, {}, (s) => ({ count: s.nodes.length, zoom: s.transform[2] }));
    return {
      selected: flow.selected,
      whole: flow.whole === flow.api.getState(),
    };
  });
  assert.deepEqual(ps, up);
  assert.equal(ps.whole, true);
});

test('reads hand back the consumer objects and keep their identity', () => {
  for (const [name, library] of sides) {
    const flow = mount(library);
    const state = flow.api.getState();
    assert.equal(flow.api.getState(), state, `${name}: getState is stable while nothing changes`);
    assert.equal(state.nodes, flow.nodes, `${name}: nodes is the consumer's array`);
    assert.equal(state.edges, flow.edges, `${name}: edges is the consumer's array`);
    assert.equal(state.nodeLookup.get('a').internals.userNode, flow.nodes[0], `${name}: userNode`);
    assert.equal(state.edgeLookup.get('ab'), flow.edges[0], `${name}: edgeLookup holds the consumer's edge`);
    assert.equal(state.nodes, state.nodes, `${name}: a member reads the same value twice`);
    assert.notEqual(flow.api, flow.again, `${name}: each useStoreApi call memoizes its own object`);
    assert.equal(flow.api.getState, flow.again.getState, `${name}: around the store's own getState`);
  }
});

test('setState merges like zustand and notifies with the state and the one before', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const calls = [];
    const before = api.getState();
    const unsubscribe = api.subscribe((state, previous) => {
      calls.push({
        previousIsBefore: previous === before,
        stateIsCurrent: state === api.getState(),
        nodesDraggable: state.nodesDraggable,
        extra: state.myApplication,
      });
    });
    api.setState({ nodesDraggable: false, myApplication: { flag: true } });
    const afterFirst = api.getState();
    api.setState((state) => ({ minZoom: state.minZoom / 2 }));
    api.setState(api.getState());
    unsubscribe();
    api.setState({ connectOnClick: false });
    const after = api.getState();
    return {
      calls,
      changed: afterFirst !== before,
      nodesShared: afterFirst.nodes === before.nodes,
      extraKept: after.myApplication === afterFirst.myApplication,
      values: [after.nodesDraggable, after.minZoom, after.connectOnClick],
    };
  });
  assert.deepEqual(ps, up);
  assert.equal(ps.calls.length, 2);
});

test('a value written with setState reads back as the consumer wrote it', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const onNodesChange = () => {};
    const nodes = [{ id: 'z', position: { x: 1, y: 2 }, data: {} }];
    const options = { animated: true, type: 'step' };
    api.setState({ onNodesChange, nodes, defaultEdgeOptions: options });
    const state = api.getState();
    return [state.onNodesChange === onNodesChange, state.nodes === nodes, state.defaultEdgeOptions === options];
  });
  assert.deepEqual(ps, up);
  assert.deepEqual(ps, [true, true, true]);
});

test('a direct write into the state changes it without notifying anyone', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    let notified = 0;
    api.subscribe(() => notified++);
    const state = api.getState();
    state.elementsSelectable = false;
    return { notified, sameState: api.getState() === state, value: api.getState().elementsSelectable };
  });
  assert.deepEqual(ps, up);
});

test('the twenty actions are on the state and reach the store', async () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const changes = [];
    api.setState({ onNodesChange: (c) => changes.push(...c), onEdgesChange: (c) => changes.push(...c) });
    const state = api.getState();
    const names = Object.keys(state).filter((key) => typeof state[key] === 'function' && !key.startsWith('on') && key !== 'isValidConnection');
    state.addSelectedNodes(['b']);
    state.addSelectedEdges(['bc']);
    state.setMinZoom(0.3);
    state.setMaxZoom(3);
    state.setNodeExtent([[-10, -10], [10, 10]]);
    state.triggerNodeChanges([{ type: 'select', id: 'c', selected: true }]);
    state.cancelConnection();
    const after = api.getState();
    return {
      names,
      changes: serializeValue(changes),
      zoom: [after.minZoom, after.maxZoom],
      nodeExtent: after.nodeExtent,
      connection: serializeValue(after.connection),
      panBy: after.panBy({ x: 1, y: 1 }),
      setCenter: after.setCenter(0, 0),
    };
  });
  assert.equal(await ps.panBy, await up.panBy);
  assert.equal(await ps.setCenter, await up.setCenter);
  delete up.panBy, delete ps.panBy, delete up.setCenter, delete ps.setCenter;
  assert.deepEqual(ps, up);
  assert.equal(ps.names.length, 20);
});

test('an equalityFn is called with the previous and next selection', () => {
  const { up, ps } = both((library) => {
    const seen = [];
    mount(library, {}, (s) => s.nodes.length, (a, b) => (seen.push([a, b]), a === b));
    return seen.length;
  });
  assert.equal(ps, up);
});

// `setState(next, true)` makes `next` the state itself, as zustand's does, and
// an action afterwards merges over it.
test('a whole-state replacement is the consumer object, and an action merges over it', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const before = api.getState();
    const calls = [];
    api.subscribe((state, previous) => calls.push([state, previous]));
    const next = { ...before, minZoom: 0.75, myApplication: 1 };
    api.setState(next, true);
    const replaced = api.getState();
    replaced.setMinZoom(0.25);
    const merged = api.getState();
    return {
      identity: replaced === next,
      listener: calls.map(([state, previous]) => [
        state === next ? 'next' : state === merged ? 'merged' : 'other',
        previous === before ? 'before' : previous === next ? 'next' : 'other',
      ]),
      keys: Object.keys(replaced).join() === Object.keys(next).join(),
      mergedKeys: Object.keys(merged),
      minZoom: [replaced.minZoom, merged.minZoom],
      extra: merged.myApplication,
      nodes: merged.nodes === before.nodes,
    };
  });
  assert.deepEqual(ps, up);
  assert.equal(up.identity, true);
});

test('a partial replacement leaves only its own keys, with no actions', () => {
  const { up, ps } = both((library) => {
    const flow = mount(library);
    const nodes = flow.nodes.slice(0, 1);
    flow.api.setState({ nodes, custom: 1 }, true);
    const state = flow.api.getState();
    return {
      keys: Object.keys(state),
      nodes: state.nodes === nodes,
      actions: typeof state.setNodes,
      minZoom: 'minZoom' in state,
    };
  });
  assert.deepEqual(ps, up);
  assert.deepEqual(up.keys, ['nodes', 'custom']);
});

test('replacing with an earlier state makes that object the state again', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const earlier = api.getState();
    api.setState({ minZoom: 0.3, elementsSelectable: false });
    api.setState(earlier, true);
    const state = api.getState();
    state.elementsSelectable = 'direct';
    return {
      identity: state === earlier,
      values: [state.minZoom, state.elementsSelectable, api.getState().elementsSelectable],
    };
  });
  assert.deepEqual(ps, up);
  assert.equal(up.identity, true);
});

test('a partial that is not an object replaces the state, and a later write merges into it', () => {
  for (const [label, write] of [
    ['null', (api) => api.setState(null)],
    ['number', (api) => api.setState(5)],
    ['string', (api) => api.setState('ab')],
    ['nothing', (api) => api.setState()],
    ['function result', (api) => api.setState(() => 7)],
  ]) {
    const { up, ps } = both((library) => {
      const { api } = mount(library);
      const calls = [];
      api.subscribe((state, previous) => calls.push([typeof state, typeof previous]));
      write(api);
      const replaced = api.getState();
      api.setState({ minZoom: 2 });
      const merged = api.getState();
      return { replaced: serializeValue(replaced), merged: serializeValue(merged), calls };
    });
    assert.deepEqual(ps, up, label);
  }
});

// Upstream's store is a plain object: a value outside a member's type is
// stored, and every reader sees it.
test('a value outside a member type reads back as written', () => {
  const warnings = [];
  const warn = console.warn;
  console.warn = (...args) => warnings.push(args.join(' '));
  try {
    const { up, ps } = both((library) => {
      const { api } = mount(library);
      const written = {
        minZoom: '2',
        nodesDraggable: 0,
        rfId: 7,
        nodes: 'x',
        transform: 'not a transform',
        connectionMode: 'foo',
        onConnect: 5,
      };
      api.setState(written);
      const state = api.getState();
      return Object.fromEntries(Object.keys(written).map((key) => [key, state[key] === written[key]]));
    });
    assert.deepEqual(ps, up);
    assert.ok(Object.values(up).every(Boolean));
  } finally {
    console.warn = warn;
  }
  assert.deepEqual(warnings, [], 'outside development, neither side warns');
});

// ps-flow reads `NODE_ENV` once, when it loads, so a development build is a
// process of its own.
test('in development, ps-flow says which members its internals keep', () => {
  const script = `
    import { createElement } from 'react';
    import { renderToStaticMarkup } from 'react-dom/server';
    globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };
    const psflow = await import('./index.js');
    const flow = {};
    const Probe = () => ((flow.api = psflow.useStoreApi()), null);
    renderToStaticMarkup(createElement(psflow.ReactFlow, { nodes: [], edges: [], children: createElement(Probe) }));
    const warnings = [];
    console.warn = (...args) => warnings.push(args.join(' '));
    flow.api.setState({ nodes: 'x', minZoom: '2' });
    const written = warnings.length;
    flow.api.setState({ custom: 1 }, true);
    console.log(JSON.stringify({ written: warnings.slice(0, written), replaced: warnings.slice(written) }));
  `;
  const run = spawnSync(process.execPath, ['--input-type=module', '-e', script], {
    cwd: fileURLToPath(new URL('../../', import.meta.url)),
    env: { ...process.env, NODE_ENV: 'development' },
    encoding: 'utf8',
  });
  assert.equal(run.status, 0, run.stderr);
  const { written, replaced } = JSON.parse(run.stdout.trim().split('\n').at(-1));
  assert.equal(written.length, 1, 'one member could not be read');
  assert.match(written[0], /`nodes`/);
  assert.doesNotMatch(written[0], /`minZoom`/, 'a primitive member holds what was written');
  assert.equal(replaced.length, 1, 'a replacement says once which members it left out');
  for (const key of ['nodes', 'nodeLookup', 'transform']) assert.match(replaced[0], new RegExp(`\`${key}\``));
  assert.doesNotMatch(replaced[0], /`minZoom`/);
});

test('a value written outside its type does not leak into other states', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    api.setState({ connectionMode: 'loose' });
    const seen = [];
    api.subscribe((state, previous) =>
      seen.push([state.connectionMode, previous.connectionMode, state.nodeOrigin, previous.nodeOrigin])
    );
    api.setState({ connectionMode: 'foo', nodeOrigin: 'bad' });
    api.setState({ connectionMode: 'loose' });
    return seen;
  });
  assert.deepEqual(ps, up);
});

// A pan-zoom instance written from JavaScript is the one the store calls.
const panZoomStub = (calls) => ({
  update: (...args) => calls.push(['update', ...args]),
  destroy: () => calls.push(['destroy']),
  getViewport: () => ({ x: 0, y: 0, zoom: 1 }),
  setViewport: (viewport, options) => {
    calls.push(['setViewport', viewport, options]);
    return Promise.resolve({ x: viewport.x, y: viewport.y, k: viewport.zoom });
  },
  setViewportConstrained: (viewport, extent, translateExtent) => {
    calls.push(['setViewportConstrained', viewport, extent, translateExtent]);
    return Promise.resolve({ x: viewport.x, y: viewport.y, k: viewport.zoom });
  },
  scaleTo: (...args) => (calls.push(['scaleTo', ...args]), Promise.resolve(true)),
  scaleBy: (...args) => (calls.push(['scaleBy', ...args]), Promise.resolve(true)),
  setScaleExtent: (...args) => calls.push(['setScaleExtent', ...args]),
  setTranslateExtent: (...args) => calls.push(['setTranslateExtent', ...args]),
  syncViewport: (...args) => calls.push(['syncViewport', ...args]),
  setClickDistance: (...args) => calls.push(['setClickDistance', ...args]),
});

test('a pan-zoom instance the store did not hand out is the one it calls', async () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const calls = [];
    const panZoom = panZoomStub(calls);
    api.setState({ panZoom, maxZoom: '2', width: 100, height: 50 });
    const state = api.getState();
    return {
      identity: state.panZoom === panZoom,
      calls,
      results: [state.setCenter(10, 20), state.panBy({ x: 5, y: 5 }), state.setMinZoom(0.5)],
    };
  });
  for (const side of [up, ps]) side.results = await Promise.all(side.results);
  assert.deepEqual(serializeValue(ps), serializeValue(up));
  assert.equal(up.identity, true);
});

test('a fit-view resolver the store did not hand out is the one it resolves', async () => {
  const sized = (nodes) => nodes.map((node) => ({ ...node, measured: { width: 40, height: 20 } }));
  const { up, ps } = both((library) => {
    const flow = mount(library);
    const calls = [];
    const resolved = [];
    let settle;
    const fitViewResolver = {
      promise: new Promise((resolve) => (settle = resolve)),
      resolve: (value) => (resolved.push(value), settle(value)),
    };
    flow.api.setState({ panZoom: panZoomStub(calls), width: 400, height: 200, fitViewQueued: true, fitViewResolver });
    const identity = flow.api.getState().fitViewResolver === fitViewResolver;
    flow.api.getState().setNodes(sized(flow.nodes));
    return { identity, calls, resolved, promise: fitViewResolver.promise, api: flow.api };
  });
  for (const side of [up, ps]) {
    side.value = await side.promise;
    await new Promise((resolve) => setTimeout(resolve, 0));
    side.cleared = side.api.getState().fitViewResolver;
    side.queued = side.api.getState().fitViewQueued;
    delete side.promise, delete side.api;
  }
  assert.deepEqual(serializeValue(ps), serializeValue(up));
  assert.deepEqual(up.resolved, [true]);
});

// Upstream keeps one live `Map` of middleware per store. A map written with
// `setState`, and an entry set into the map read from the store, both run.
test('node-change middleware the store did not hand out runs as upstream runs it', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const changes = [];
    api.setState({ onNodesChange: (batch) => changes.push(batch) });
    const dropB = (batch) => batch.filter((change) => change.id !== 'b');
    const written = new Map([[Symbol('dropB'), dropB]]);
    api.setState({ onNodesChangeMiddlewareMap: written });
    const map = api.getState().onNodesChangeMiddlewareMap;
    const drag = () =>
      new Map(['a', 'b'].map((id, i) => [id, { id, position: { x: i, y: i }, internals: { positionAbsolute: { x: i, y: i } }, measured: {} }]));
    api.getState().updateNodePositions(drag(), true);
    const tag = Symbol('tag');
    const tagged = (batch) => batch.map((change) => ({ ...change, tagged: true }));
    map.set(tag, tagged);
    api.getState().updateNodePositions(drag(), false);
    return {
      identity: map === written,
      reads: [map.get(tag) === tagged, [...map.values()].length],
      changes: serializeValue(changes),
    };
  });
  assert.deepEqual(ps, up);
  assert.equal(up.identity, true);
});

test('outside a flow both hooks throw upstream error001', () => {
  for (const [name, library] of sides) {
    for (const hook of ['useStore', 'useStoreApi']) {
      const Probe = () => (library[hook]((s) => s), null);
      assert.throws(() => renderToStaticMarkup(createElement(Probe)), /zustand provider as an ancestor/, `${name}.${hook}`);
    }
  }
});
