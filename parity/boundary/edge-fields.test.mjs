// The edge and node members ps-flow dropped until Step 3 G, rendered against
// upstream.
//
// A server render draws edges between nodes whose `width`, `height` and
// `handles` are given, so each member's effect on the edge `<g>`, its path,
// its label, its reconnect anchors and the node `<div>` is visible in the
// markup. Both libraries render the same props, and the edge layer and the
// node wrappers' opening tags must agree. The rest of the page is left out:
// the server-rendered color-mode class and handle attribute order differ for
// reasons of their own, and neither depends on these members. Attributes are
// compared as a set per element, as the net's DOM section compares them: the
// built-in label and path write theirs in a different order from upstream's.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

const handle = (type) => [
  { id: null, type, position: type === 'source' ? 'bottom' : 'top', x: 20, y: 0, width: 6, height: 6 },
];

const node = (id, y, type, extra = {}) => ({
  id,
  position: { x: 0, y },
  data: {},
  width: 50,
  height: 20,
  handles: handle(type),
  ...extra,
});

const render = (library, props) =>
  renderToStaticMarkup(
    createElement(library.ReactFlow, {
      nodes: [node('a', 0, 'source'), node('b', 120, 'target')],
      edges: [],
      ...props,
    })
  );

const sortAttributes = (markup) =>
  markup.replace(/<([a-zA-Z]+)((?:\s+[\w:-]+="[^"]*")*)(\s*\/?)>/g, (_, tag, attrs, end) => {
    const sorted = (attrs.match(/[\w:-]+="[^"]*"/g) ?? []).sort().join(' ');
    return `<${tag}${sorted ? ' ' + sorted : ''}${end}>`;
  });

const subject = (markup) => {
  const edges = markup.slice(
    markup.indexOf('<div class="react-flow__edges">'),
    markup.indexOf('<div class="react-flow__edgelabel-renderer">')
  );
  const markers = markup.match(/<svg class="react-flow__marker"[\s\S]*?<\/svg>/)?.[0] ?? '';
  const nodes = markup.match(/<div class="react-flow__node [^>]*>/g) ?? [];
  return sortAttributes([markers, edges, ...nodes].join('\n'));
};

const same = (props) => {
  const [up, ps] = [upstream, psflow].map((library) => subject(render(library, props)));
  assert.ok(up.includes('react-flow__edge') || !props.edges?.length, 'upstream drew no edge');
  assert.equal(ps, up);
  return up;
};

const edge = (extra) => ({ id: 'e', source: 'a', target: 'b', ...extra });

test('edge focusable overrides edgesFocusable either way', () => {
  same({ edges: [edge({ focusable: false })] });
  const markup = same({ edges: [edge({ focusable: true })], edgesFocusable: false });
  assert.match(markup, /tabindex="0"/);
});

test('edge ariaRole replaces the role and domAttributes spread last onto <g>', () => {
  const markup = same({
    edges: [edge({ ariaRole: 'button', domAttributes: { 'data-kind': 'x', title: 'edge', 'aria-roledescription': 'link' } })],
  });
  assert.match(markup, /role="button"/);
  assert.match(markup, /aria-roledescription="link"/);
});

test('edge label options reach the label and its background', () => {
  const markup = same({
    edges: [
      edge({
        label: 'L',
        labelStyle: { fill: 'red' },
        labelShowBg: true,
        labelBgStyle: { fill: 'blue' },
        labelBgPadding: [7, 9],
        labelBgBorderRadius: 4,
      }),
    ],
  });
  assert.match(markup, /style="fill:red"/);
  same({ edges: [edge({ label: 'L', labelShowBg: false })] });
});

test('a falsy label draws nothing, and a React element label draws itself', () => {
  for (const label of ['', 0]) {
    const markup = same({ edges: [edge({ label })] });
    assert.doesNotMatch(markup, /react-flow__edge-text/);
  }
  const markup = same({ edges: [edge({ label: createElement('tspan', { className: 'rich' }, 'R') })] });
  assert.match(markup, /class="rich"/);
});

test('edge pathOptions reach the built-in path they belong to', () => {
  same({ edges: [edge({ type: 'smoothstep', pathOptions: { borderRadius: 0, offset: 40 } })] });
  same({ edges: [edge({ type: 'step', pathOptions: { offset: 5 } })] });
  same({ edges: [edge({ type: 'default', pathOptions: { curvature: 0.9 } })] });
});

test('edge reconnectable decides which reconnect anchors render', () => {
  for (const reconnectable of [undefined, true, false, 'source', 'target']) {
    same({ edges: [edge({ reconnectable })], onReconnect: () => {} });
    same({ edges: [edge({ reconnectable })], onReconnect: () => {}, edgesReconnectable: false });
  }
});

test('edge markers render from the edge', () => {
  same({ edges: [edge({ markerEnd: 'arrowclosed', markerStart: { type: 'arrow', color: 'red' } })] });
});

test('node focusable, ariaRole and domAttributes render as upstream renders them', () => {
  for (const extra of [
    { focusable: false },
    { focusable: true },
    { ariaRole: 'listitem' },
    { focusable: false, ariaRole: 'img' },
    { domAttributes: { 'data-kind': 'n', title: 'node', role: 'note' } },
  ]) {
    same({ nodes: [node('a', 0, 'source', extra), node('b', 120, 'target')], nodesFocusable: !extra.focusable });
  }
});
