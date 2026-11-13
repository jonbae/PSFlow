// Which component draws a node or an edge whose type the consumer's
// `nodeTypes` or `edgeTypes` cannot resolve, rendered against upstream.
//
// Upstream's `<NodeWrapper />` reads `nodeTypes?.[type] ||
// builtinNodeTypes[type]`. When that finds nothing, it reports error 003 and
// falls back to `nodeTypes?.['default'] || builtinNodeTypes.default`, so a
// consumer's own `default` node type wins over the built-in one (upstream
// #5384). A node with no `type` is `'default'` from the start (#5735).
// `<EdgeWrapper />` does the same with `edgeTypes` and error 011. Every
// lookup uses `||`, so a key the consumer set to `undefined` resolves nothing.
//
// A server render draws each node and each edge through the component its type
// resolves to. The node and edge layers and the reported errors must agree with
// upstream's, and the upstream side of each case must reach the branch the case
// is named for.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

const CustomDefault = ({ id }) => createElement('div', { className: 'custom-default' }, `custom default ${id}`);
const Custom = ({ id }) => createElement('div', { className: 'custom' }, `custom ${id}`);
const CustomDefaultEdge = ({ id }) => createElement('path', { className: 'custom-default-edge', 'data-edge': id });
const CustomEdge = ({ id }) => createElement('path', { className: 'custom-edge', 'data-edge': id });

const handle = (type) => [
  { id: null, type, position: type === 'source' ? 'bottom' : 'top', x: 20, y: 0, width: 6, height: 6 },
];

const node = (id, y, handleType, extra = {}) => ({
  id,
  position: { x: 0, y },
  data: { label: `label ${id}` },
  width: 50,
  height: 20,
  handles: handle(handleType),
  ...extra,
});

const edge = (extra = {}) => ({ id: 'ab', source: 'a', target: 'b', ...extra });

const sortAttributes = (markup) =>
  markup.replace(/<([a-zA-Z]+)((?:\s+[\w:-]+="[^"]*")*)(\s*\/?)>/g, (_, tag, attrs, end) => {
    const sorted = (attrs.match(/[\w:-]+="[^"]*"/g) ?? []).sort().join(' ');
    return `<${tag}${sorted ? ' ' + sorted : ''}${end}>`;
  });

const between = (markup, from, to) => {
  const start = markup.indexOf(from);
  assert.notEqual(start, -1, `the render has ${from}`);
  return markup.slice(start, markup.indexOf(to, start));
};

const render = (library, { nodeType, nodeTypes, edgeType, edgeTypes }) => {
  const errors = [];
  const markup = renderToStaticMarkup(
    createElement(library.ReactFlow, {
      nodes: [node('a', 0, 'source', { type: nodeType }), node('b', 120, 'target')],
      edges: [edge({ type: edgeType })],
      nodeTypes,
      edgeTypes,
      onError: (code, message) => errors.push([code, message]),
    })
  );
  const edges = between(markup, '<div class="react-flow__edges">', '<div class="react-flow__edgelabel-renderer">');
  const nodes = between(markup, '<div class="react-flow__nodes"', '<div class="react-flow__viewport-portal"');
  return { layers: sortAttributes(`${edges}\n${nodes}`), errors };
};

const cases = [
  {
    name: "an unknown node type falls back to the consumer's default node type",
    flow: { nodeType: 'unknown', nodeTypes: { default: CustomDefault, custom: Custom } },
    upstreamReaches: 'custom default a',
  },
  {
    name: "a node with no type uses the consumer's default node type",
    flow: { nodeTypes: { default: CustomDefault } },
    upstreamReaches: 'custom default a',
  },
  {
    name: 'an unknown node type falls back to the built-in default without a consumer one',
    flow: { nodeType: 'unknown', nodeTypes: { custom: Custom } },
    upstreamReaches: 'label a',
  },
  {
    name: 'a node type the consumer set to undefined resolves nothing, and falls back',
    flow: { nodeType: 'custom', nodeTypes: { default: CustomDefault, custom: undefined } },
    upstreamReaches: 'custom default a',
  },
  {
    name: 'a resolvable node type still draws its own component',
    flow: { nodeType: 'custom', nodeTypes: { default: CustomDefault, custom: Custom } },
    upstreamReaches: 'custom a',
  },
  {
    name: "an unknown edge type falls back to the consumer's default edge type",
    flow: { edgeType: 'unknown', edgeTypes: { default: CustomDefaultEdge, custom: CustomEdge } },
    upstreamReaches: 'custom-default-edge',
  },
  {
    name: 'an unknown edge type falls back to the built-in default without a consumer one',
    flow: { edgeType: 'unknown', edgeTypes: { custom: CustomEdge } },
    upstreamReaches: 'react-flow__edge-path',
  },
  {
    name: 'an edge type the consumer set to undefined resolves nothing, and falls back',
    flow: { edgeType: 'custom', edgeTypes: { default: CustomDefaultEdge, custom: undefined } },
    upstreamReaches: 'custom-default-edge',
  },
  {
    name: 'a built-in type the consumer set to undefined falls through to the built-in one',
    flow: { nodeType: 'input', nodeTypes: { input: undefined }, edgeType: 'step', edgeTypes: { step: null } },
    upstreamReaches: 'react-flow__node-input',
  },
];

for (const { name, flow, upstreamReaches } of cases) {
  test(name, () => {
    const theirs = render(upstream, flow);
    assert.ok(theirs.layers.includes(upstreamReaches), `upstream's render reaches ${upstreamReaches}`);

    const ours = render(psflow, flow);
    assert.equal(ours.layers, theirs.layers);
    assert.deepEqual(ours.errors, theirs.errors);
  });
}
