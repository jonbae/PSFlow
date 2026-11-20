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
import { useStoreApi as usePureScriptStoreApi } from '../../output/React.Hook.Store/index.js';

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

const render = (library, props) => {
  const flowProps = {
    nodes: [node('a', 0, 'source'), node('b', 120, 'target')],
    edges: [],
    ...props,
  };
  const flow = createElement(library.ReactFlow, flowProps);
  if (!props.defaultEdgeOptions) return renderToStaticMarkup(flow);
  // StoreUpdater's effects do not run on the server. Seed the provider's
  // initial snapshot in place before rendering the flow on either side.
  function SeedDefaults() {
    library.useStoreApi().getState().defaultEdgeOptions = props.defaultEdgeOptions;
    return flow;
  }
  function SeedPsflowDefaults() {
    const store = usePureScriptStoreApi();
    psflow.useStoreApi().setState({ defaultEdgeOptions: props.defaultEdgeOptions });
    // The JS store view has no setter for an initially absent optional key.
    // Render the seeded snapshot, as the native EdgeWrapper proxy tests do.
    store.getInitialState = store.getState;
    return flow;
  }
  return renderToStaticMarkup(createElement(library.ReactFlowProvider, {
    initialNodes: flowProps.nodes,
    initialEdges: flowProps.edges,
    children: createElement(library === psflow ? SeedPsflowDefaults : SeedDefaults),
  }));
};

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

test('defaultEdgeOptions pathOptions and selected render beyond the modeled options', () => {
  const nodes = [node('a', 0, 'source'), node('b', 120, 'target', { position: { x: 150, y: 120 } })];
  for (const type of ['default', 'smoothstep', 'step']) {
    const defaultEdgeOptions = { pathOptions: { curvature: 0.9, borderRadius: 0, offset: 40 }, selected: true, zIndex: 4 };
    const markup = same({ nodes, edges: [edge({ type })], defaultEdgeOptions });
    assert.match(markup, /selected/);
    assert.match(markup, /z-index:1004/);
    same({ nodes, edges: [edge({ type, selected: false, pathOptions: { curvature: 0.2, offset: 5 } })], defaultEdgeOptions });
    same({ nodes, edges: [edge({ type, selected: undefined, pathOptions: undefined })], defaultEdgeOptions });
  }
});

test('defaultEdgeOptions handle ids reach position lookup and custom edge props', () => {
  const recording = (library) => {
    const received = [];
    const edgeTypes = { recording: (props) => { received.push(props); return null; } };
    const pathOptions = { offset: 40, custom: { retained: true } };
    const nodes = [
      node('a', 0, 'source', { handles: [
        { ...handle('source')[0], id: 'first', x: 5 },
        { ...handle('source')[0], id: 'second', x: 35 },
      ] }),
      node('b', 120, 'target', { handles: [
        { ...handle('target')[0], id: 'first', x: 5 },
        { ...handle('target')[0], id: 'second', x: 35 },
      ] }),
    ];
    render(library, { nodes, edges: [edge({ type: 'recording' })], edgeTypes,
      defaultEdgeOptions: { sourceHandle: 'second', targetHandle: 'second', pathOptions, selected: true } });
    assert.equal(received.length, 1);
    assert.equal(received[0].sourceHandleId, 'second');
    assert.equal(received[0].sourceX, 38);
    assert.equal(received[0].pathOptions, pathOptions);
    return received[0];
  };
  assert.deepEqual(recording(psflow), recording(upstream));
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
