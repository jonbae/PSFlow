// Step 3 H: what a JavaScript consumer reads back, against upstream.
//
// Upstream hands a consumer either the objects it gave or shallow copies of
// them, and which one depends on the read: `getNode` and `getEdge` return the
// object itself, `getNodes`, `getEdges` and `toObject` copy each one. Either
// way every key the consumer wrote survives, including keys no type declares.
// A server render mounts each flow; effects do not run there, so the store
// holds the state the props seed on both sides.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

const sides = [
  ['upstream', upstream],
  ['psflow', psflow],
];

const graph = () => ({
  nodes: [
    { id: 'a', position: { x: 0, y: 0 }, data: { label: 'a' }, type: 'input', custom: 'node' },
    { id: 'b', position: { x: 100, y: 100 }, data: { label: 'b' } },
  ],
  edges: [{ id: 'ab', source: 'a', target: 'b', custom: 'edge' }],
});

function mount(library, props = {}, read = () => {}) {
  const result = graph();
  function Probe() {
    result.read = read(library.useReactFlow());
    return null;
  }
  result.markup = renderToStaticMarkup(
    createElement(library.ReactFlow, {
      nodes: result.nodes,
      edges: result.edges,
      ...props,
      children: createElement(Probe),
    })
  );
  return result;
}

for (const [side, library] of sides) {
  test(`${side}: getNode and getEdge return the consumer's own objects`, () => {
    const { nodes, edges, read } = mount(library, {}, (flow) => ({
      node: flow.getNode('a'),
      edge: flow.getEdge('ab'),
    }));
    assert.equal(read.node, nodes[0]);
    assert.equal(read.edge, edges[0]);
  });

  test(`${side}: getNodes, getEdges and toObject copy each object with every key`, () => {
    const { nodes, edges, read } = mount(library, {}, (flow) => ({
      nodes: flow.getNodes(),
      edges: flow.getEdges(),
      object: flow.toObject(),
    }));
    for (const copies of [read.nodes, read.object.nodes]) {
      assert.notEqual(copies[0], nodes[0]);
      assert.deepEqual(copies, nodes);
    }
    for (const copies of [read.edges, read.object.edges]) {
      assert.notEqual(copies[0], edges[0]);
      assert.deepEqual(copies, edges);
    }
  });

  test(`${side}: a node component reads 0 for the size of a node with none`, () => {
    let received;
    const Recorder = (props) => {
      received = { width: props.width, height: props.height };
      return null;
    };
    mount(library, {
      nodes: [{ id: 'a', position: { x: 0, y: 0 }, data: {}, type: 'recorder' }],
      edges: [],
      nodeTypes: { recorder: Recorder },
    });
    assert.deepEqual(received, { width: 0, height: 0 });
  });

  test(`${side}: useHandleConnections warns on every call`, () => {
    const warnings = [];
    const warn = console.warn;
    console.warn = (...args) => warnings.push(String(args[0]));
    try {
      const Calls = () => {
        library.useHandleConnections({ type: 'source', nodeId: 'a' });
        library.useHandleConnections({ type: 'target', nodeId: 'a' });
        return null;
      };
      renderToStaticMarkup(
        createElement(library.ReactFlow, { nodes: graph().nodes, edges: [], children: createElement(Calls) })
      );
    } finally {
      console.warn = warn;
    }
    assert.deepEqual(
      warnings.filter((text) => text.includes('useHandleConnections')),
      Array(2).fill(
        '[DEPRECATED] `useHandleConnections` is deprecated. Instead use `useNodeConnections` https://reactflow.dev/api-reference/hooks/useNodeConnections'
      )
    );
  });

  test(`${side}: a flow with no colorMode renders light`, () => {
    const { markup } = mount(library);
    const wrapper = markup.match(/class="([^"]*react-flow[^"]*)"/)[1].split(' ');
    assert.ok(wrapper.includes('light'), wrapper.join(' '));
    assert.ok(!wrapper.includes('dark'), wrapper.join(' '));
  });
}

// zustand's `useStore` hands React `getInitialState` as the server snapshot, so
// a server render reads the state the store began with even after a write.
for (const [side, library] of sides) {
  test(`${side}: a server render reads the store's initial state`, () => {
    let read;
    const Writer = () => {
      library.useStoreApi().setState({ minZoom: 0.25 });
      return null;
    };
    const Reader = () => {
      read = library.useStore((state) => state.minZoom);
      return null;
    };
    renderToStaticMarkup(
      createElement(library.ReactFlow, {
        nodes: [],
        edges: [],
        children: [createElement(Writer, { key: 'w' }), createElement(Reader, { key: 'r' })],
      })
    );
    assert.equal(read, 0.5);
  });
}
