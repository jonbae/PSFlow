// The selector hooks and the two toolbars, entered from JavaScript, against
// upstream.
//
// Each of upstream's selector hooks is `useStore(selector, equality)`, and the
// equality decides two things a consumer can see: whether a store update
// renders the component, and whether the component reads back the object it
// read before. `useNodes`, `useEdges`, `useInternalNode`, `useViewport` and
// `useConnection` compare with zustand's `shallow`. `useNodesData` compares
// with `shallowNodeData`, which reads only `id`, `type` and `data`, and `data`
// by `Object.is`. `<NodeToolbar />` and `<EdgeToolbar />` compare what they
// draw from.
//
// Every check runs one script over both libraries. Each step drives the store
// and records how many times the probe rendered, whether the probe read back
// the object it read before the step, and the value it read. The two records
// must match, and upstream's render counts are written out as well, so a probe
// that never re-renders can't pass by matching itself.
//
// A server render never re-renders, so these mount with `react-dom/client`.
// The tree is a `ReactFlowProvider` whose children render nothing, so React
// touches no DOM beyond the root container. The stub that follows is that
// much of a DOM. The store is driven through its own `setNodes`, `setEdges`
// and `setState`, inside `act`, which is how a consumer's handler reaches it.
import assert from 'node:assert/strict';
import test from 'node:test';
import { act, createElement as h, Profiler, useState } from 'react';
import { createRoot } from 'react-dom/client';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';
import { serializeValue } from '../system/harness/serialize.mjs';

globalThis.IS_REACT_ACT_ENVIRONMENT = true;
const document = { activeElement: null, body: null, addEventListener() {}, removeEventListener() {} };
globalThis.document = document;
// React reads the focused element before and after each commit, and the
// event that is running, from `window`.
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
    { id: 'a', position: { x: 0, y: 0 }, data: { label: 'a' }, type: 'input' },
    { id: 'b', position: { x: 100, y: 0 }, data: { label: 'b' } },
  ],
  edges: [{ id: 'ab', source: 'a', target: 'b' }],
});

// Mount `read` as a hook, or `draw` inside a `<Profiler />` that counts the
// commits it takes part in. `force` renders the probe again without a store
// update.
function mount(library, { read, draw }) {
  const flow = { reads: [], commits: 0, ...graph() };
  function Probe() {
    const [, setCount] = useState(0);
    flow.force = () => act(() => setCount((n) => n + 1));
    flow.api = library.useStoreApi();
    if (read) flow.reads.push(read(library));
    if (!draw) return null;
    return h(Profiler, { id: 'probe', onRender: () => flow.commits++ }, draw(library));
  }
  const root = createRoot(container());
  act(() =>
    root.render(
      h(library.ReactFlowProvider, { initialNodes: flow.nodes, initialEdges: flow.edges }, h(Probe))
    )
  );
  flow.state = () => flow.api.getState();
  flow.setNodes = (update) => act(() => flow.state().setNodes(update(flow.state().nodes)));
  flow.setEdges = (update) => act(() => flow.state().setEdges(update(flow.state().edges)));
  flow.setState = (partial) => act(() => flow.api.setState(partial));
  flow.unmount = () => act(() => root.unmount());
  return flow;
}

// One record per step. `same` is whether the last read is the object read
// before the step, and it is only recorded when the step rendered.
function record(library, probe, steps, inspect = () => ({})) {
  const flow = mount(library, probe);
  const trace = [{ step: 'mount', value: serializeValue(flow.reads.at(-1)), ...inspect(flow) }];
  for (const [step, drive] of steps) {
    const reads = flow.reads.length;
    const commits = flow.commits;
    const before = flow.reads.at(-1);
    drive(flow);
    const entry = { step };
    if (probe.draw) entry.commits = flow.commits - commits;
    else {
      entry.renders = flow.reads.length - reads;
      if (entry.renders > 0) {
        entry.same = Object.is(flow.reads.at(-1), before);
        entry.value = serializeValue(flow.reads.at(-1));
      }
    }
    trace.push({ ...entry, ...inspect(flow) });
  }
  flow.unmount();
  return trace;
}

function compare(probe, steps, inspect) {
  const [up, ps] = sides.map(([, library]) => record(library, probe, steps, inspect));
  assert.deepEqual(ps, up);
  return up;
}

const counts = (trace, key) => trace.slice(1).map((entry) => entry[key]);

const at = (id, update) => (nodes) => nodes.map((n) => (n.id === id ? update(n) : n));
const move = (id) => at(id, (n) => ({ ...n, position: { x: n.position.x + 1, y: n.position.y } }));
const withData = (id, data) => at(id, (n) => ({ ...n, data }));
const without = (id) => (nodes) => nodes.filter((n) => n.id !== id);

// `same` is upstream's `shallowNodeData`: a new data object with the same
// contents renders, and so does a different number. `NaN` is itself and the
// two zeros differ, because `data` compares by `Object.is`.
const pairOfNumbers = [1, 2];
const dataSteps = [
  ['render again', (f) => f.force()],
  ['move the other node', (f) => f.setNodes(move('b'))],
  ['move the node', (f) => f.setNodes(move('a'))],
  ['select the node', (f) => f.setNodes(at('a', (n) => ({ ...n, selected: true })))],
  ['copy the node, keeping its data', (f) => f.setNodes(at('a', (n) => ({ ...n })))],
  ['copy its data', (f) => f.setNodes(at('a', (n) => ({ ...n, data: { ...n.data } })))],
  ['change its data', (f) => f.setNodes(withData('a', { label: 'z' }))],
  ['set data to 5', (f) => f.setNodes(withData('a', 5))],
  ['set data to 5 again', (f) => f.setNodes(withData('a', 5))],
  ['set data to NaN', (f) => f.setNodes(withData('a', NaN))],
  ['set data to NaN again', (f) => f.setNodes(withData('a', NaN))],
  ['set data to 0', (f) => f.setNodes(withData('a', 0))],
  ['set data to -0', (f) => f.setNodes(withData('a', -0))],
  ['set data to null', (f) => f.setNodes(withData('a', null))],
  ['set data to null again', (f) => f.setNodes(withData('a', null))],
  ['set data to an array', (f) => f.setNodes(withData('a', pairOfNumbers))],
  ['set data to the same array', (f) => f.setNodes(withData('a', pairOfNumbers))],
  ['set data to an equal array', (f) => f.setNodes(withData('a', [1, 2]))],
  ['change its type', (f) => f.setNodes(at('a', (n) => ({ ...n, type: 'output' })))],
  ['render again', (f) => f.force()],
  ['remove the node', (f) => f.setNodes(without('a'))],
  ['move the other node', (f) => f.setNodes(move('b'))],
];

test("useNodesData('a') renders when the node's id, type or data changes, as upstream's does", () => {
  const up = compare({ read: (l) => l.useNodesData('a') }, dataSteps);
  assert.deepEqual(counts(up, 'renders'), [1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0]);
  assert.equal(up[1].same, true, 'a render with nothing changed reads the same object back');
});

test('useNodesData([...]) answers every id asked for, repeats included, as upstream does', () => {
  const up = compare({ read: (l) => l.useNodesData(['a', 'b', 'a', 'missing']) }, dataSteps);
  assert.equal(up[0].value.length, 3, 'two picks for a, one for b, none for the missing id');
  assert.deepEqual(counts(up, 'renders'), [1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0]);
});

test("useNodesData answers null for a missing id and [] for no ids, as upstream's does", () => {
  const steps = [
    ['render again', (f) => f.force()],
    ['move a node', (f) => f.setNodes(move('a'))],
  ];
  for (const ids of ['missing', []]) {
    const up = compare({ read: (l) => l.useNodesData(ids) }, steps);
    assert.deepEqual(counts(up, 'renders'), [1, 0]);
    assert.equal(up[1].same, true);
  }
});

const listSteps = (set) => [
  ['render again', (f) => f.force()],
  ['set the same array', (f) => f[set]((items) => items)],
  ['set a new array of the same objects', (f) => f[set]((items) => [...items])],
  ['copy the first object', (f) => f[set]((items) => items.map((item, i) => (i === 0 ? { ...item } : item)))],
  ['render again', (f) => f.force()],
];

test("useNodes hands back the store's nodes array and renders when an element changes, as upstream's does", () => {
  const inspect = (f) => ({ isStoreArray: f.reads.at(-1) === f.state().nodes });
  const up = compare({ read: (l) => l.useNodes() }, [...listSteps('setNodes'), ['move a node', (f) => f.setNodes(move('a'))]], inspect);
  assert.deepEqual(counts(up, 'renders'), [1, 0, 0, 1, 1, 1]);
  assert.equal(up[0].isStoreArray, true);
});

test("useNodes reads the consumer's own array", () => {
  for (const [side, library] of sides) {
    const flow = mount(library, { read: (l) => l.useNodes() });
    assert.equal(flow.reads[0], flow.nodes, `${side}: the array passed as initialNodes`);
    flow.unmount();
  }
});

test("useEdges hands back the store's edges array and renders when an element changes, as upstream's does", () => {
  const inspect = (f) => ({ isStoreArray: f.reads.at(-1) === f.state().edges });
  const steps = [
    ...listSteps('setEdges'),
    ['move a node', (f) => f.setNodes(move('a'))],
    ['select the edge', (f) => f.setEdges((edges) => edges.map((e) => ({ ...e, selected: true })))],
  ];
  const up = compare({ read: (l) => l.useEdges() }, steps, inspect);
  assert.deepEqual(counts(up, 'renders'), [1, 0, 0, 1, 1, 0, 1]);
  assert.equal(up[0].isStoreArray, true);
});

test("useInternalNode hands back the store's internal node and renders when it is replaced, as upstream's does", () => {
  const inspect = (f) => ({ isStoreNode: f.reads.at(-1) === f.state().nodeLookup.get('a') });
  const steps = [
    ['render again', (f) => f.force()],
    ['move the other node', (f) => f.setNodes(move('b'))],
    ['copy the node', (f) => f.setNodes(at('a', (n) => ({ ...n })))],
    ['move the node', (f) => f.setNodes(move('a'))],
    ['copy its data', (f) => f.setNodes(at('a', (n) => ({ ...n, data: { ...n.data } })))],
    ['render again', (f) => f.force()],
    ['remove the node', (f) => f.setNodes(without('a'))],
    ['move the other node', (f) => f.setNodes(move('b'))],
  ];
  const up = compare({ read: (l) => l.useInternalNode('a') }, steps, inspect);
  assert.deepEqual(counts(up, 'renders'), [1, 0, 1, 1, 1, 1, 1, 0]);
  assert.equal(up[0].isStoreNode, true);
});

test("useViewport renders when x, y or zoom changes by Object.is, as upstream's does", () => {
  const steps = [
    ['render again', (f) => f.force()],
    ['move a node', (f) => f.setNodes(move('a'))],
    ['pan', (f) => f.setState({ transform: [10, 0, 1] })],
    ['set the same numbers', (f) => f.setState({ transform: [10, 0, 1] })],
    ['pan to -0', (f) => f.setState({ transform: [-0, 0, 1] })],
    ['pan to 0', (f) => f.setState({ transform: [0, 0, 1] })],
    ['render again', (f) => f.force()],
  ];
  const up = compare({ read: (l) => l.useViewport() }, steps);
  assert.deepEqual(counts(up, 'renders'), [1, 0, 1, 0, 1, 1, 1]);
  assert.equal(up[1].same, true);
});

test("useConnection renders when the connection changes by shallow, as upstream's does", () => {
  const steps = [
    ['render again', (f) => f.force()],
    ['move a node', (f) => f.setNodes(move('a'))],
    ['pan', (f) => f.setState({ transform: [10, 0, 1] })],
  ];
  for (const read of [(l) => l.useConnection(), (l) => l.useConnection((c) => ({ inProgress: c.inProgress }))]) {
    const up = compare({ read }, steps);
    assert.deepEqual(counts(up, 'renders'), [1, 0, 0]);
    assert.equal(up[1].same, true);
  }
});

// Upstream's `<NodeToolbar />` renders again when one of its nodes moves,
// resizes, is selected or changes `internals.z`, and when the viewport or the
// number of selected nodes changes. Nothing else about the store does.
const nodeToolbarSteps = [
  ['render the parent', (f) => f.force()],
  ['move the other node', (f) => f.setNodes(move('b'))],
  ["change the node's data", (f) => f.setNodes(withData('a', { label: 'q' }))],
  ['copy the node', (f) => f.setNodes(at('a', (n) => ({ ...n })))],
  ['move the node', (f) => f.setNodes(move('a'))],
  ['select the other node', (f) => f.setNodes(at('b', (n) => ({ ...n, selected: true })))],
  ['pan to -0', (f) => f.setState({ transform: [-0, 0, 1] })],
  ['pan', (f) => f.setState({ transform: [10, 0, 1] })],
  ['change an edge', (f) => f.setEdges((edges) => edges.map((e) => ({ ...e, animated: true })))],
];

test('NodeToolbar renders when its nodes or the viewport change, as upstream does', () => {
  const cases = [
    [{ nodeId: 'a', isVisible: true }, [1, 0, 0, 0, 1, 1, 1, 1, 0]],
    [{ nodeId: 'a' }, [1, 0, 0, 0, 1, 1, 1, 1, 0]],
    [{ nodeId: ['a', 'b'], isVisible: true }, [1, 1, 0, 0, 1, 1, 1, 1, 0]],
  ];
  for (const [props, expected] of cases) {
    const up = compare({ draw: (l) => h(l.NodeToolbar, props, 'toolbar') }, nodeToolbarSteps);
    assert.deepEqual(counts(up, 'commits'), expected, JSON.stringify(props));
  }
});

// Upstream's `<EdgeToolbar />` compares its edge with `shallow` and the zoom
// by `Object.is`, so a copy of the edge with the same keys, or a pan, doesn't
// render it again.
test('EdgeToolbar renders when its edge or the zoom changes, as upstream does', () => {
  const steps = [
    ['render the parent', (f) => f.force()],
    ['move a node', (f) => f.setNodes(move('a'))],
    ['set the same edges', (f) => f.setEdges((edges) => edges)],
    ['copy the edge', (f) => f.setEdges((edges) => edges.map((e) => ({ ...e })))],
    ['select the edge', (f) => f.setEdges((edges) => edges.map((e) => ({ ...e, selected: true })))],
    ['pan', (f) => f.setState({ transform: [10, 0, 1] })],
    ['zoom', (f) => f.setState({ transform: [10, 0, 2] })],
  ];
  const up = compare({ draw: (l) => h(l.EdgeToolbar, { edgeId: 'ab', x: 0, y: 0, isVisible: false }, 'toolbar') }, steps);
  assert.deepEqual(counts(up, 'commits'), [1, 0, 0, 0, 1, 0, 1]);
});
