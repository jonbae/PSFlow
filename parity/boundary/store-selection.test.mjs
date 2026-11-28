// `addSelectedNodes` and `addSelectedEdges`, entered from JavaScript, against
// upstream: the order of the changes each callback receives, the deselection
// of the other type outside multi-selection, and when the internal nodes an
// edge selection unselects change relative to `onEdgesChange`.
//
// Each check runs the same consumer code over both libraries and compares the
// order of what it observed. A server render mounts each flow and hands the
// probe the store; `StoreUpdater`'s effects do not run in a server render, so
// on both sides the store holds what the props seed, and an uncontrolled flow
// is seeded with `setDefaultNodesAndEdges`, as `StoreUpdater` seeds it on
// mount.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

const sides = [upstream, psflow];

// The ids are out of key order on purpose: upstream walks its lookups in the
// order they were filled, which is the order of `nodes` and `edges`.
const graph = ({ selectedNodes = [], selectedEdges = [] } = {}) => ({
  nodes: ['c', 'a', 'd', 'b'].map((id, i) => ({
    id,
    position: { x: i * 100, y: 0 },
    data: { label: id },
    measured: { width: 40, height: 20 },
    ...(selectedNodes.includes(id) ? { selected: true } : {}),
  })),
  edges: [
    ['cb', 'c', 'b'],
    ['ad', 'a', 'd'],
    ['ba', 'b', 'a'],
  ].map(([id, source, target]) => ({ id, source, target, ...(selectedEdges.includes(id) ? { selected: true } : {}) })),
});

function mount(library, { uncontrolled = false, ...selection } = {}) {
  const flow = {};
  function Probe() {
    flow.api = library.useStoreApi();
    return null;
  }
  const { nodes, edges } = graph(selection);
  const props = uncontrolled ? { defaultNodes: nodes, defaultEdges: edges } : { nodes, edges };
  renderToStaticMarkup(createElement(library.ReactFlow, { ...props, children: createElement(Probe) }));
  if (uncontrolled) flow.api.getState().setDefaultNodesAndEdges(nodes, edges);
  return flow;
}

const internalSelection = (state) =>
  [...state.nodeLookup.values()].filter((node) => node.selected).map((node) => node.id);

// Records each callback's changes, what each callback and listener reads of
// the internal node selection, and every notification, in order.
function observe(api) {
  const calls = [];
  const changes = (list) => list.map((change) => [change.type, change.id, change.selected]);
  api.setState({
    onNodesChange: (list) => calls.push(['onNodesChange', changes(list), internalSelection(api.getState())]),
    onEdgesChange: (list) => calls.push(['onEdgesChange', changes(list), internalSelection(api.getState())]),
  });
  api.subscribe((state) =>
    calls.push([
      'listener',
      internalSelection(state),
      state.edges.filter((edge) => edge.selected).map((edge) => edge.id),
    ])
  );
  return calls;
}

const both = (run) => {
  const [up, ps] = sides.map((library) => run(library));
  return { up, ps };
};

const modes = [
  ['controlled', false],
  ['uncontrolled', true],
];

for (const [mode, uncontrolled] of modes) {
  // Upstream's `getSelectionChanges` walks the lookup with `for…of`.
  test(`${mode}: selecting a node reports node and edge changes in lookup order`, () => {
    const { up, ps } = both((library) => {
      const { api } = mount(library, { uncontrolled, selectedNodes: ['d', 'c'], selectedEdges: ['ba', 'cb'] });
      const calls = observe(api);
      api.getState().addSelectedNodes(['b']);
      return calls;
    });
    assert.deepEqual(ps, up);
    assert.deepEqual(up.find(([name]) => name === 'onNodesChange')[1], [
      ['select', 'c', false],
      ['select', 'd', false],
      ['select', 'b', true],
    ]);
  });

  test(`${mode}: selecting an edge reports edge and node changes in lookup order`, () => {
    const { up, ps } = both((library) => {
      const { api } = mount(library, { uncontrolled, selectedNodes: ['d', 'c'], selectedEdges: ['ba', 'cb'] });
      const calls = observe(api);
      api.getState().addSelectedEdges(['ad']);
      return calls;
    });
    assert.deepEqual(ps, up);
    assert.deepEqual(up.find(([name]) => name === 'onEdgesChange')[1], [
      ['select', 'cb', false],
      ['select', 'ad', true],
      ['select', 'ba', false],
    ]);
  });

  // Outside multi-selection, upstream's second statement runs whatever the
  // list held: an empty node selection still unselects every edge, and an
  // empty edge selection every node.
  test(`${mode}: addSelectedNodes([]) unselects the selected edges`, () => {
    const { up, ps } = both((library) => {
      const { api } = mount(library, { uncontrolled, selectedNodes: ['a'], selectedEdges: ['ba', 'cb'] });
      const calls = observe(api);
      api.getState().addSelectedNodes([]);
      return calls;
    });
    assert.deepEqual(ps, up);
    assert.ok(up.some(([name]) => name === 'onEdgesChange'));
  });

  test(`${mode}: addSelectedEdges([]) unselects the selected nodes`, () => {
    const { up, ps } = both((library) => {
      const { api } = mount(library, { uncontrolled, selectedNodes: ['d', 'a'], selectedEdges: ['cb'] });
      const calls = observe(api);
      api.getState().addSelectedEdges([]);
      return calls;
    });
    assert.deepEqual(ps, up);
    assert.ok(up.some(([name]) => name === 'onNodesChange'));
  });

  // Upstream computes the node half of an edge selection after
  // `triggerEdgeChanges` returns, so `onEdgesChange` still reads the internal
  // nodes selected.
  test(`${mode}: onEdgesChange runs before an edge selection unselects the internal nodes`, () => {
    const { up, ps } = both((library) => {
      const { api } = mount(library, { uncontrolled, selectedNodes: ['a'] });
      const calls = observe(api);
      api.getState().addSelectedEdges(['ba']);
      return { calls, after: internalSelection(api.getState()) };
    });
    assert.deepEqual(ps, up);
    assert.deepEqual(up.calls.find(([name]) => name === 'onEdgesChange')[2], ['a']);
    assert.deepEqual(up.after, []);
  });

  // Upstream's node half selects the internal nodes before
  // `onNodesChange`, and its edge half runs after it.
  test(`${mode}: onNodesChange runs before a node selection unselects the edges`, () => {
    const { up, ps } = both((library) => {
      const { api } = mount(library, { uncontrolled, selectedEdges: ['ad'] });
      const calls = observe(api);
      api.getState().addSelectedNodes(['d']);
      return calls;
    });
    assert.deepEqual(ps, up);
  });

  // In multi-selection, each call selects what it is given and leaves the
  // other type alone.
  test(`${mode}: multi-selection keeps the given order and the other type`, () => {
    const { up, ps } = both((library) => {
      const { api } = mount(library, { uncontrolled, selectedNodes: ['a'], selectedEdges: ['cb'] });
      api.setState({ multiSelectionActive: true });
      const calls = observe(api);
      api.getState().addSelectedNodes(['d', 'b']);
      api.getState().addSelectedEdges(['ba', 'ad']);
      api.getState().addSelectedNodes([]);
      return calls;
    });
    assert.deepEqual(ps, up);
  });
}
