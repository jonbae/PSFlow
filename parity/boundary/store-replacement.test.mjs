// `setState(next, true)`, entered from JavaScript, against upstream: what the
// state is after a replacement, which keys it has and in what order, what its
// properties are, and what the store goes on to read from it.
//
// zustand's replacement is `state = nextState`, and every later `set` is
// `Object.assign({}, state, partial)`. Upstream's internals read members with
// `get().member`, so they read whatever the state object answers, through its
// prototype included, at the moment they read it.
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

const both = (run) => {
  const [up, ps] = sides.map(([, library]) => run(library));
  return { up, ps };
};

// What `Object.getOwnPropertyDescriptor` says, without the values.
const describe = (object, key) => {
  const descriptor = Object.getOwnPropertyDescriptor(object, key);
  if (descriptor === undefined) return 'absent';
  const { enumerable, configurable } = descriptor;
  return 'value' in descriptor
    ? { kind: 'data', writable: descriptor.writable, enumerable, configurable }
    : { kind: 'accessor', enumerable, configurable };
};

const recorder = (calls) => ({
  update: () => {},
  destroy: () => {},
  getViewport: () => ({ x: 0, y: 0, zoom: 1 }),
  setViewport: () => Promise.resolve(undefined),
  setViewportConstrained: () => Promise.resolve(undefined),
  scaleTo: () => Promise.resolve(true),
  scaleBy: () => Promise.resolve(true),
  setScaleExtent: (extent) => calls.push(['setScaleExtent', ...extent]),
  setTranslateExtent: () => {},
  syncViewport: () => {},
  setClickDistance: () => {},
});

const errorName = (run) => {
  try {
    run();
    return 'none';
  } catch (error) {
    return error.constructor.name;
  }
};

// zustand's state is a plain object, so a key it gains comes after the keys
// it had, in the order the `set` named it, and `reset`'s merge moves none.
test('keys written after the store was made come in the order they were written', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const initial = Object.keys(api.getState()).length;
    api.setState({ myApplication: 1 });
    api.setState({ onConnect: () => {}, onNodeDragStart: () => {} });
    api.setState({ defaultEdgeOptions: {}, onMove: undefined, onNodesDelete: () => {} });
    const written = Object.keys(api.getState()).slice(initial);
    api.getState().reset();
    return { written, afterReset: Object.keys(api.getState()).slice(initial) };
  });
  assert.deepEqual(ps, up);
  assert.deepEqual(up.written, ['myApplication', 'onConnect', 'onNodeDragStart', 'defaultEdgeOptions', 'onMove', 'onNodesDelete']);
});

test('a replacement keeps its own property descriptors, and the store reads through them', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const calls = [];
    api.setState({ panZoom: recorder(calls) });
    const next = { ...api.getState(), minZoom: 0.75 };
    Object.defineProperty(next, 'maxZoom', { value: 3, writable: true, enumerable: false, configurable: true });
    Object.defineProperty(next, 'snapToGrid', { get: () => true, enumerable: true, configurable: true });
    api.setState(next, true);
    const state = api.getState();
    const keys = ['minZoom', 'maxZoom', 'snapToGrid', 'nodes', 'setMinZoom'];
    const replaced = Object.fromEntries(keys.map((key) => [key, describe(state, key)]));
    state.setMinZoom(0.25);
    const merged = api.getState();
    const after = Object.fromEntries(keys.map((key) => [key, describe(merged, key)]));
    merged.setMinZoom(0.3);
    return { identity: state === next, replaced, after, snapToGrid: merged.snapToGrid, calls };
  });
  assert.deepEqual(ps, up);
  assert.equal(up.identity, true);
});

test('a sealed replacement is the state itself, and a direct write into it is used', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const calls = [];
    api.setState({ panZoom: recorder(calls) });
    const sealed = Object.seal({ ...api.getState(), minZoom: 0.75 });
    api.setState(sealed, true);
    const identity = api.getState() === sealed;
    sealed.minZoom = 0.4;
    const added = errorName(() => {
      api.getState().custom = 1;
    });
    api.getState().setMaxZoom(5);
    const merged = api.getState();
    return {
      identity,
      added,
      descriptor: describe(sealed, 'minZoom'),
      calls,
      sealedAfter: [Object.isSealed(merged), merged === sealed, merged.minZoom, merged.maxZoom],
    };
  });
  assert.deepEqual(ps, up);
  assert.equal(up.identity, true);
});

test('a frozen replacement is the state itself, and refuses a direct write', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const frozen = Object.freeze({ ...api.getState(), minZoom: 0.75 });
    api.setState(frozen, true);
    const identity = api.getState() === frozen;
    const written = errorName(() => {
      api.getState().minZoom = 0.4;
    });
    api.getState().setMinZoom(0.2);
    const merged = api.getState();
    return { identity, written, descriptor: describe(frozen, 'minZoom'), merged: [Object.isFrozen(merged), merged.minZoom] };
  });
  assert.deepEqual(ps, up);
  assert.equal(up.identity, true);
});

// A replacement's members are plain properties: writing one, or deleting it,
// changes what the store reads next, and notifies nobody.
test('a direct write into a replacement is what the store goes on to read', () => {
  const { up, ps } = both((library) => {
    const { api, instance } = mount(library);
    const next = { ...api.getState() };
    api.setState(next, true);
    let notified = 0;
    api.subscribe(() => notified++);
    const calls = [];
    next.nodes = [{ id: 'z', position: { x: 5, y: 5 }, data: {} }];
    next.onNodesChange = (changes) => calls.push(changes.map((change) => [change.type, change.id]));
    const nodes = instance.getNodes().map((node) => node.id);
    next.triggerNodeChanges([{ type: 'select', id: 'z', selected: true }]);
    delete next.onNodesChange;
    next.triggerNodeChanges([{ type: 'select', id: 'z', selected: false }]);
    return { nodes, calls, notified, descriptor: describe(next, 'nodes') };
  });
  assert.deepEqual(ps, up);
  assert.deepEqual(up.calls, [[['select', 'z']]]);
});

// Upstream's actions `set` named members whether or not their value
// changes, so a member a replacement left out comes back at the first `set`
// that names it, in the order that `set` names it.
test('a member a replacement left out comes back when an action writes it, unchanged values included', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const before = api.getState();
    const { nodesSelectionActive, nodesInitialized, connection, fitViewOptions, minZoom, ...rest } = before;
    api.setState(rest, true);
    const added = (from) => Object.keys(api.getState()).slice(from);
    const base = Object.keys(rest).length;
    api.setState({ fitViewQueued: true });
    rest.setNodes(graph().nodes.map((node) => ({ ...node, measured: { width: 40, height: 20 } })));
    const afterSetNodes = added(base);
    api.getState().cancelConnection();
    const afterCancel = added(base);
    api.getState().setMinZoom(0.5);
    const afterMinZoom = added(base);
    const state = api.getState();
    return {
      afterSetNodes,
      afterCancel,
      afterMinZoom,
      values: serializeValue({
        nodesSelectionActive: state.nodesSelectionActive,
        fitViewOptions: state.fitViewOptions,
        fitViewQueued: state.fitViewQueued,
        connection: state.connection,
        minZoom: state.minZoom,
      }),
    };
  });
  assert.deepEqual(ps, up);
  assert.deepEqual(up.afterSetNodes, ['nodesInitialized', 'fitViewOptions', 'nodesSelectionActive']);
});

test('reset brings back the members a replacement left out, in the initial state order', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const { minZoom, connection, rfId, ...rest } = api.getState();
    api.setState(rest, true);
    rest.reset();
    const state = api.getState();
    return { keys: Object.keys(state), values: [state.minZoom, state.rfId, serializeValue(state.connection)] };
  });
  assert.deepEqual(ps, up);
});

// `get().member` reads through the prototype, and `Object.assign` copies only
// own enumerable keys, so what the prototype held is gone after one `set`.
test('a replacement whose members are inherited is read through its prototype until a write', () => {
  const { up, ps } = both((library) => {
    const { api, instance } = mount(library);
    const calls = [];
    api.setState({ panZoom: recorder(calls), maxZoom: 2 });
    const replaced = Object.create(api.getState());
    api.setState(replaced, true);
    const keys = Object.keys(api.getState());
    const nodes = instance.getNodes().map((node) => node.id);
    replaced.setMinZoom(0.3);
    const merged = api.getState();
    return { keys, nodes, calls, mergedKeys: Object.keys(merged), setMaxZoom: typeof merged.setMaxZoom };
  });
  assert.deepEqual(ps, up);
  assert.deepEqual(up.calls, [['setScaleExtent', 0.3, 2]]);
});
