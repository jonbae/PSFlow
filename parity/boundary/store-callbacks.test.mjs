// Store callbacks that PureScript code installed, called from JavaScript.
//
// A JavaScript consumer's callback reads back from the store as itself. A
// callback that PureScript code installed has no JavaScript original, so the
// store hands out an adapter: a JavaScript function that converts upstream's
// arguments in, calls the PureScript function, and converts its answer out.
//
// Upstream has nothing to compare against here, because every upstream
// callback is a JavaScript function. What this file proves instead is that
// each adapter is the inverse of the converter that brings the same kind of
// callback in: a JavaScript recorder converted to PureScript and back hands
// the recorder what it was called with. `xIn` does not remember the
// recorder, so `xOut` cannot shortcut to it and has to build the adapter.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import * as psflow from '../../index.js';
import * as C from '../../output/Boundary.Callbacks/index.js';
import * as Store from '../../output/Boundary.Store/index.js';
import { createStore } from '../../output/React.Store.Shell/index.js';
import { defaultInitialStateOptions } from '../../output/React.Store.InitialState/index.js';
import { PatchState } from '../../output/React.Store.Action/index.js';
import { Just, Nothing } from '../../output/Data.Maybe/index.js';
import * as Middleware from '../../output/React.Store.Middleware/index.js';
import { serializeValue } from '../system/harness/serialize.mjs';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

// The arguments one call delivers, and what the adapter returned.
function roundTrip(name, args, answer) {
  const received = [];
  const recorder = (...callArgs) => (received.push(callArgs), answer);
  const adapter = C[`${name}Out`](C[`${name}In`](recorder));
  assert.equal(typeof adapter, 'function', `${name}Out returns a function`);
  assert.notEqual(adapter, recorder, `${name}: the adapter is not the recorder`);
  const returned = adapter(...args);
  return { received, returned };
}

const sameCall = (name, args, answer) => {
  const { received, returned } = roundTrip(name, args, answer);
  assert.deepEqual(serializeValue(received), serializeValue([args]), name);
  return returned;
};

// A node, an internal node and a handle as the store hands them out.
function storeElements() {
  const result = {};
  function Probe() {
    result.api = psflow.useStoreApi();
    return null;
  }
  const nodes = [
    { id: 'a', position: { x: 0, y: 0 }, data: { label: 'a' } },
    { id: 'b', position: { x: 100, y: 0 }, data: { label: 'b' } },
  ];
  const edges = [{ id: 'ab', source: 'a', target: 'b' }];
  renderToStaticMarkup(createElement(psflow.ReactFlow, { nodes, edges, children: createElement(Probe) }));
  const state = result.api.getState();
  return { nodes, edges, internal: state.nodeLookup.get('a') };
}

const mouse = { type: 'mousemove', clientX: 1, clientY: 2 };
const touch = { type: 'touchend', touches: [], changedTouches: [] };
const viewport = { x: 1, y: 2, zoom: 1.5 };

test('change, delete and selection callbacks hand JavaScript what they were called with', () => {
  const { nodes, edges } = storeElements();
  sameCall('onNodesChange', [[
    { id: 'a', type: 'position', position: { x: 1, y: 2 }, dragging: true },
    { id: 'b', type: 'select', selected: true },
    { id: 'a', type: 'remove' },
  ]]);
  sameCall('onEdgesChange', [[{ id: 'ab', type: 'select', selected: false }, { id: 'ab', type: 'remove' }]]);
  sameCall('onNodesDelete', [nodes]);
  sameCall('onEdgesDelete', [edges]);
  sameCall('onDelete', [{ nodes, edges }]);
  sameCall('onSelectionChange', [{ nodes: [nodes[0]], edges: [] }]);
  const { received } = roundTrip('onNodesDelete', [nodes]);
  assert.equal(received[0][0][0], nodes[0], 'a node keeps its identity across the round trip');
});

test('drag, move and viewport callbacks hand JavaScript what they were called with', () => {
  const { nodes } = storeElements();
  sameCall('onNodeDrag', [mouse, nodes[0], nodes]);
  sameCall('selectionDragHandler', [mouse, nodes]);
  sameCall('onMove', [mouse, viewport]);
  sameCall('onMove', [null, viewport]);
  sameCall('onViewportChange', [viewport]);
  sameCall('onError', ['002', 'a message']);
});

test('connection callbacks hand JavaScript what they were called with', () => {
  const { internal } = storeElements();
  sameCall('onConnect', [{ source: 'a', target: 'b', sourceHandle: null, targetHandle: 't' }]);
  sameCall('onConnect', [{ animated: true, type: 'step', source: 'a', target: 'b', sourceHandle: 's', targetHandle: null }]);
  sameCall('onConnectStart', [mouse, { nodeId: 'a', handleId: null, handleType: 'source' }]);
  sameCall('onConnectStart', [touch, { nodeId: null, handleId: null, handleType: null }]);
  const handle = { id: null, type: 'source', nodeId: 'a', position: 'right', x: 10, y: 5, width: 4, height: 4 };
  const ended = {
    isValid: true,
    from: { x: 1, y: 2 },
    fromHandle: handle,
    fromPosition: 'right',
    fromNode: internal,
    to: { x: 3, y: 4 },
    toHandle: null,
    toPosition: 'left',
    toNode: null,
    pointer: { x: 3, y: 4 },
  };
  sameCall('onConnectEnd', [mouse, ended]);
  sameCall('onConnectEnd', [touch, Object.fromEntries(Object.keys(ended).map((key) => [key, null]))]);
  // The internal nodes arrive equal, not identical: `connectionStateOut`
  // copies an internal node for every `onConnectEnd`, a consumer's own too.
});

test('the two callbacks that answer hand the answer back', async () => {
  const { nodes, edges } = storeElements();
  const connection = { source: 'a', target: 'b', sourceHandle: null, targetHandle: null };
  assert.equal(sameCall('isValidConnection', [connection], false), false);
  assert.equal(sameCall('isValidConnection', [connection], true), true);
  const { received } = roundTrip('isValidConnection', [edges[0]], true);
  assert.deepEqual(serializeValue(received[0][0]), serializeValue(edges[0]), 'an edge crosses as an edge');
  for (const answer of [true, false, { nodes: [nodes[0]], edges: [] }]) {
    const { received: calls, returned } = roundTrip('onBeforeDelete', [{ nodes, edges }], Promise.resolve(answer));
    assert.deepEqual(serializeValue(calls), serializeValue([[{ nodes, edges }]]));
    assert.equal(typeof returned?.then, 'function', 'onBeforeDelete answers with a promise');
    assert.deepEqual(serializeValue(await returned), serializeValue(answer));
  }
});

// A store that PureScript code filled, read through the JavaScript view.
test('a callback PureScript installed is callable through the store, and reads back as one function', () => {
  const store = createStore(defaultInitialStateOptions)();
  const received = [];
  const onConnect = (connection) => () => received.push(connection);
  const isValidConnection = (candidate) => candidate.edge instanceof Nothing && candidate.sourceHandle instanceof Just;
  const onError = (id) => (message) => () => received.push([id, message]);
  store.dispatch(
    PatchState.create((s) => ({
      ...s,
      onConnect: Just.create(onConnect),
      isValidConnection: Just.create(isValidConnection),
      onError: Just.create(onError),
    }))
  )();
  const view = Store.storeViewOf(store);
  const state = view.getState();
  assert.equal(typeof state.onConnect, 'function');
  state.onConnect({ source: 'a', target: 'b', sourceHandle: null, targetHandle: 'h' });
  assert.equal(received[0].source, 'a');
  assert.ok(received[0].sourceHandle instanceof Nothing);
  assert.equal(received[0].targetHandle.value0, 'h');
  assert.equal(state.isValidConnection({ source: 'a', target: 'b', sourceHandle: 's', targetHandle: null }), true);
  assert.equal(state.isValidConnection({ source: 'a', target: 'b', sourceHandle: null, targetHandle: null }), false);
  state.onError('008', 'message');
  assert.deepEqual(received[1], ['008', 'message']);

  view.setState({ minZoom: 0.1 });
  const next = view.getState();
  assert.notEqual(next, state);
  assert.equal(next.onConnect, state.onConnect, 'one PureScript function reads back as one JavaScript function');
  view.setState({ onConnect: next.onConnect });
  assert.equal(store.getState().onConnect.value0, onConnect, 'the adapter written back is the PureScript function');
});

// A middleware PureScript code registered sits in the live map as a
// JavaScript function, which converts upstream's changes in and out.
test('a middleware PureScript registered reads from the map as a function JavaScript can call', () => {
  const store = createStore(defaultInitialStateOptions)();
  const map = Store.storeViewOf(store).getState().onNodesChangeMiddlewareMap;
  const dropB = (changes) => changes.filter((change) => change.value0.id !== 'b');
  const key = Middleware.freshMiddlewareKey();
  Middleware.setNativeMiddleware('nodes')(key)(dropB)(map)();
  const adapter = map.get(key);
  assert.equal(typeof adapter, 'function');
  const changes = [
    { id: 'a', type: 'position', position: { x: 1, y: 2 }, dragging: true },
    { id: 'b', type: 'select', selected: true },
  ];
  assert.deepEqual(serializeValue(adapter(changes)), serializeValue([changes[0]]));
  Middleware.setNativeMiddleware('nodes')(key)(dropB)(map)();
  assert.equal(map.get(key), adapter, 'one PureScript function is one JavaScript function');
  assert.equal(map.size, 1);
});
