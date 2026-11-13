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

test('replacing the whole state is refused with a message, not half-applied', () => {
  const { api } = mount(psflow);
  const before = api.getState();
  assert.throws(() => api.setState({ nodes: [] }, true), /cannot replace the whole state/);
  assert.throws(() => api.setState(null), /cannot replace the whole state/);
  assert.equal(api.getState(), before);
});

test('a member of the wrong type is refused with the member named', () => {
  const { api } = mount(psflow);
  assert.throws(() => api.setState({ minZoom: '2' }), /`minZoom` takes a number, got string/);
  assert.throws(() => api.setState({ panZoom: {} }), /`panZoom` accepts `null` or a value read from this store/);
  const { panZoom } = api.getState();
  api.setState({ panZoom });
  assert.equal(api.getState().panZoom, panZoom);
});

test('outside a flow both hooks throw upstream error001', () => {
  for (const [name, library] of sides) {
    for (const hook of ['useStore', 'useStoreApi']) {
      const Probe = () => (library[hook]((s) => s), null);
      assert.throws(() => renderToStaticMarkup(createElement(Probe)), /zustand provider as an ancestor/, `${name}.${hook}`);
    }
  }
});
