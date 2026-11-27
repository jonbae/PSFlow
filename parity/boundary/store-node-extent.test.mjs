// `setNodeExtent`, entered from JavaScript, against upstream: whether an
// unchanged extent notifies, and where a node lands when the extent tightens
// around it.
//
// Each check runs the same consumer code over both libraries and compares
// what it observed. A server render mounts each flow and hands the probe the
// store; `StoreUpdater`'s effects do not run in a server render, so on both
// sides the store holds what the props seed.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

const sides = [upstream, psflow];

const graph = () => ({
  nodes: [
    { id: 'a', position: { x: 0, y: 0 }, data: { label: 'a' } },
    { id: 'b', position: { x: 100, y: 100 }, data: { label: 'b' } },
    { id: 'c', position: { x: 200, y: -40 }, data: { label: 'c' } },
    { id: 'd', position: { x: 300, y: 300 }, data: { label: 'd' }, extent: [[0, 0], [400, 400]] },
  ],
  edges: [{ id: 'ab', source: 'a', target: 'b' }],
});

function mount(library, props = {}) {
  const flow = {};
  function Probe() {
    flow.api = library.useStoreApi();
    return null;
  }
  const { nodes, edges } = graph();
  renderToStaticMarkup(createElement(library.ReactFlow, { nodes, edges, ...props, children: createElement(Probe) }));
  return flow;
}

const both = (run) => {
  const [up, ps] = sides.map((library) => run(library));
  return { up, ps };
};

const positions = (state) =>
  Object.fromEntries([...state.nodeLookup.values()].map((node) => [node.id, node.internals.positionAbsolute]));

// Upstream's `setNodeExtent` compares the four numbers with `===` and returns
// before its `set` when they all match, so no listener hears of it.
test('an unchanged extent notifies nobody and keeps the state', () => {
  const extents = {
    infinite: [[-Infinity, -Infinity], [Infinity, Infinity]],
    finite: [[-10, -10], [500, 500]],
  };
  const { up, ps } = both((library) =>
    Object.fromEntries(
      Object.entries(extents).map(([name, extent]) => {
        const { api } = mount(library, name === 'infinite' ? {} : { nodeExtent: extent });
        let notified = 0;
        const unsubscribe = api.subscribe(() => notified++);
        const before = api.getState();
        // A copy, so the check is of the numbers and not of the reference.
        before.setNodeExtent(extent.map((point) => [...point]));
        unsubscribe();
        return [name, { notified, sameState: api.getState() === before, extent: api.getState().nodeExtent }];
      })
    )
  );
  assert.deepEqual(ps, up);
  assert.equal(up.infinite.notified, 0);
  assert.equal(up.finite.notified, 0);
});

// Any one number differing is a change: upstream re-adopts and sets.
test('an extent differing in one number notifies once', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library, { nodeExtent: [[-10, -10], [500, 500]] });
    let notified = 0;
    const unsubscribe = api.subscribe(() => notified++);
    api.getState().setNodeExtent([[-10, -10], [500, 501]]);
    unsubscribe();
    return { notified, extent: api.getState().nodeExtent };
  });
  assert.deepEqual(ps, up);
  assert.equal(up.notified, 1);
});

// Upstream re-adopts with `checkEquality: false`, so every node is rebuilt and
// clamped to the new extent, including a node whose user object is unchanged.
// A node with its own extent keeps clamping to that one.
test('a tighter extent clamps every node already in the store', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    const before = positions(api.getState());
    const internalsBefore = new Map(api.getState().nodeLookup);
    api.getState().setNodeExtent([[0, 0], [150, 150]]);
    const state = api.getState();
    return {
      before,
      after: positions(state),
      rebuilt: Object.fromEntries([...state.nodeLookup.keys()].map((id) => [id, state.nodeLookup.get(id) !== internalsBefore.get(id)])),
      extent: state.nodeExtent,
    };
  });
  assert.deepEqual(ps, up);
  assert.deepEqual(up.after.c, { x: 150, y: 0 });
  assert.deepEqual(up.after.d, { x: 300, y: 300 });
});

// Loosening the extent again releases nothing: the user node still holds its
// own position, so the rebuild puts it back where the user put it.
test('loosening the extent after tightening it restores the user positions', () => {
  const { up, ps } = both((library) => {
    const { api } = mount(library);
    api.getState().setNodeExtent([[0, 0], [150, 150]]);
    const tightened = positions(api.getState());
    api.getState().setNodeExtent([[-Infinity, -Infinity], [Infinity, Infinity]]);
    return { tightened, loosened: positions(api.getState()) };
  });
  assert.deepEqual(ps, up);
  assert.deepEqual(up.loosened.c, { x: 200, y: -40 });
});
