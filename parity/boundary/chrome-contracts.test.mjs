// The chrome components' props and `<Handle />`'s, field by field, against
// upstream.
//
// Step 4 order 10 audits each E02 type's fields at their readers
// (`AAMF_TYPE_CONTRACT_REVIEW.md`). For a component that renders on a server,
// each guard, default and absence branch of a field shows in the markup: a
// default decides an attribute, a falsy guard picks a fallback, and a union
// member picks a branch. Every case below renders one value of one field on
// both sides, inside the same flow, and the component's markup must agree.
// A case that names no value renders the field absent; a case that names
// `undefined` renders the key present and holding it.
//
// Markup is compared as the net's DOM section compares it: attributes as a
// set, class tokens and style declarations sorted.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createElement as h } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

const sides = [
  ['upstream', upstream],
  ['psflow', psflow],
];

const handles = [
  { id: null, type: 'source', position: 'bottom', x: 20, y: 20, width: 6, height: 6 },
  { id: null, type: 'target', position: 'top', x: 20, y: 0, width: 6, height: 6 },
];

// Three sized nodes: one plain, one selected with a background, one hidden,
// and one with no size, which a minimap leaves out.
const nodes = () => [
  { id: 'a', position: { x: 0, y: 0 }, data: { label: 'a' }, width: 50, height: 20, handles },
  {
    id: 'b',
    position: { x: 120, y: 80 },
    data: { label: 'b' },
    width: 40,
    height: 30,
    selected: true,
    style: { background: 'rgb(1, 2, 3)' },
    handles,
  },
  { id: 'c', position: { x: 300, y: 0 }, data: { label: 'c' }, width: 10, height: 10, hidden: true },
  { id: 'd', position: { x: 0, y: 300 }, data: { label: 'd' } },
];

// ── Normalized markup ───────────────────────────────────────────────────

const attribute = /([\w:-]+)="([^"]*)"/g;

const normalizeAttributes = (attrs) =>
  [...attrs.matchAll(attribute)]
    .map(([, name, value]) => {
      if (name === 'class') value = value.split(/\s+/).filter(Boolean).sort().join(' ');
      if (name === 'style') value = value.split(';').filter(Boolean).sort().join(';');
      return `${name}="${value}"`;
    })
    .sort()
    .join(' ');

const normalize = (markup) =>
  markup.replace(/<([a-zA-Z]+)((?:\s+[\w:-]+="[^"]*")*)(\s*\/?)>/g, (_, tag, attrs, end) => {
    const sorted = normalizeAttributes(attrs);
    return `<${tag}${sorted ? ' ' + sorted : ''}${end}>`;
  });

// The element whose opening tag carries `marker`, with everything inside it.
function subtree(markup, marker) {
  const at = markup.indexOf(marker);
  if (at === -1) return null;
  const start = markup.lastIndexOf('<', at);
  const tag = markup.slice(start + 1).match(/^[a-zA-Z]+/)[0];
  const open = new RegExp(`<${tag}[\\s>/]`, 'g');
  const close = `</${tag}>`;
  let depth = 0;
  let i = start;
  for (;;) {
    open.lastIndex = i;
    const nextOpen = open.exec(markup);
    const nextClose = markup.indexOf(close, i);
    if (nextOpen && nextOpen.index < nextClose) {
      const selfClosing = markup.slice(nextOpen.index, markup.indexOf('>', nextOpen.index) + 1).endsWith('/>');
      if (!selfClosing) depth++;
      i = nextOpen.index + 1;
    } else {
      depth--;
      i = nextClose + close.length;
      if (depth === 0) return markup.slice(start, i);
    }
  }
}

// Renders the flow on one side with `chrome` inside it, and returns the
// subtree `marker` names, normalized. A throw is a result too, so a side that
// refuses a value compares as the message it refused it with.
function render(library, chrome, marker, flowProps = {}) {
  try {
    const markup = renderToStaticMarkup(
      h(library.ReactFlow, { nodes: nodes(), edges: [], ...flowProps }, chrome(library))
    );
    return normalize(subtree(markup, marker) ?? '(absent)');
  } catch (error) {
    return `(threw) ${error.message}`;
  }
}

// One field, one value: a `test` per case, so each branch passes or fails by
// its own name.
function cases(component, marker, table, { wrap = (library, element) => element, flowProps } = {}) {
  for (const [field, values] of Object.entries(table)) {
    for (const value of values) {
      const absent = value === ABSENT;
      const label = absent ? 'absent' : describe(value);
      test(`${component}.${field}: ${label}`, () => {
        const props = absent ? {} : { [field]: value };
        const [up, ps] = sides.map(([, library]) =>
          render(
            library,
            (lib) => wrap(lib, h(lib[component], resolve(props, lib))),
            marker,
            flowProps
          )
        );
        assert.ok(!up.startsWith('(threw)') && up !== '(absent)', `upstream did not render: ${up}`);
        assert.equal(ps, up);
      });
    }
  }
}

const ABSENT = Symbol('absent');

// A value that has to be built per side — a component that renders the
// side's own `MiniMapNode` — is a function marked `perSide`.
const perSide = (build) => Object.assign(build, { perSide: true });
const resolve = (props, library) =>
  Object.fromEntries(
    Object.entries(props).map(([key, value]) => [key, value?.perSide ? value(library) : value])
  );

// A label that keeps what `JSON.stringify` loses: `NaN`, the infinities and
// `-0` would otherwise print as `null` and `0`.
const describe = (value) => {
  if (value === undefined) return 'undefined';
  if (typeof value === 'function') return value.label ?? 'a function';
  if (typeof value === 'symbol') return value.toString();
  if (typeof value === 'number') return Object.is(value, -0) ? '-0' : String(value);
  if (Array.isArray(value)) return `[${value.map(describe).join(',')}]`;
  return JSON.stringify(value);
};
const labelled = (label, fn) => Object.assign(fn, { label });

const positions = [
  'top-left',
  'top-center',
  'top-right',
  'bottom-left',
  'bottom-center',
  'bottom-right',
  'center-left',
  'center-right',
];

// ── Background ──────────────────────────────────────────────────────────

cases('Background', 'data-testid="rf__background"', {
  id: [ABSENT, undefined, '', 'second'],
  color: [ABSENT, undefined, '#123456', ''],
  bgColor: [ABSENT, undefined, '#654321', ''],
  className: [ABSENT, undefined, 'mine', ''],
  patternClassName: [ABSENT, undefined, 'dots'],
  gap: [ABSENT, undefined, 0, 15, 12.5, -10, [10, 30], [0, 5], [7.5, 0]],
  size: [ABSENT, undefined, 0, 3, 2.5],
  offset: [ABSENT, undefined, 0, 4, 1.5, -3, [2, 6], [0, 0]],
  lineWidth: [ABSENT, undefined, 0, 2.5],
  variant: [ABSENT, undefined, 'dots', 'lines', 'cross'],
  style: [ABSENT, undefined, { opacity: 0.5, width: 10, color: 'red' }],
});

// The variant decides which default `size` applies and which pattern draws,
// so `size` and `lineWidth` are read once more under each variant.
for (const variant of ['lines', 'cross']) {
  cases(
    'Background',
    'data-testid="rf__background"',
    { size: [ABSENT, 0, 4], lineWidth: [ABSENT, 3], gap: [[8, 16]], offset: [[3, 0]] },
    { wrap: (library, element) => h(library.Background, { ...element.props, variant }) }
  );
}

// ── Controls ────────────────────────────────────────────────────────────

cases('Controls', 'data-testid="rf__controls"', {
  showZoom: [ABSENT, undefined, true, false],
  showFitView: [ABSENT, undefined, true, false],
  showInteractive: [ABSENT, undefined, true, false],
  fitViewOptions: [ABSENT, undefined, { padding: 0.5, duration: 100 }],
  onZoomIn: [ABSENT, undefined, () => {}],
  onZoomOut: [ABSENT, undefined, () => {}],
  onFitView: [ABSENT, undefined, () => {}],
  onInteractiveChange: [ABSENT, undefined, () => {}],
  position: [ABSENT, undefined, ...positions],
  children: [ABSENT, undefined, 'text', perSide((library) => h(library.ControlButton, { title: 'extra' }, 'x'))],
  style: [ABSENT, undefined, { opacity: 0.5 }],
  className: [ABSENT, undefined, 'mine', ''],
  'aria-label': [ABSENT, undefined, 'Zoom things', ''],
  orientation: [ABSENT, undefined, 'horizontal', 'vertical'],
});

// The zoom buttons disable at the zoom limits, which the flow's props set.
cases(
  'Controls',
  'data-testid="rf__controls"',
  { showZoom: [ABSENT] },
  { flowProps: { minZoom: 1, maxZoom: 1 } }
);

// ── ControlButton ───────────────────────────────────────────────────────
//
// Upstream's `ControlButtonProps` is `ButtonHTMLAttributes<HTMLButtonElement>`,
// and the component spreads every attribute it does not destructure onto the
// `<button>` after its own `type`.

cases(
  'ControlButton',
  'react-flow__controls-button',
  {
    children: [ABSENT, 'label'],
    className: [ABSENT, undefined, 'mine'],
    onClick: [ABSENT, () => {}],
    disabled: [ABSENT, true, false],
    title: [ABSENT, 'Title'],
    'aria-label': [ABSENT, 'Label'],
    style: [ABSENT, { color: 'red' }],
    type: ['submit', 'reset'],
    id: ['button-id'],
    name: ['button-name'],
    value: ['v'],
    tabIndex: [-1, 3],
    'data-testid': ['custom'],
    'aria-pressed': [true],
    role: ['switch'],
    hidden: [true],
    onMouseEnter: [() => {}],
  },
  { wrap: (library, element) => h(library.Controls, { showZoom: false, showFitView: false, showInteractive: false }, element) }
);

// ── MiniMap ─────────────────────────────────────────────────────────────

const nodeFunction = (label, fn) => labelled(label, fn);

cases('MiniMap', 'data-testid="rf__minimap"', {
  nodeColor: [
    ABSENT,
    undefined,
    'red',
    '',
    nodeFunction('(node) => color by id', (node) => (node.id === 'a' ? 'green' : 'purple')),
    nodeFunction('() => undefined', () => undefined),
  ],
  nodeStrokeColor: [
    ABSENT,
    undefined,
    'blue',
    nodeFunction('(node) => stroke by selected', (node) => (node.selected ? 'black' : 'white')),
  ],
  nodeClassName: [
    ABSENT,
    undefined,
    'mm',
    '',
    nodeFunction('(node) => class by id', (node) => `mm-${node.id}`),
  ],
  nodeBorderRadius: [ABSENT, undefined, 0, 3, 2.5],
  nodeStrokeWidth: [ABSENT, undefined, 0, 2, 1.5],
  nodeComponent: [
    ABSENT,
    undefined,
    labelled('a component of its own', ({ id, x, y, width, height, color, selected }) =>
      h('circle', { 'data-id': id, cx: x, cy: y, r: width + height, fill: color, className: selected ? 's' : 'u' })
    ),
  ],
  bgColor: [ABSENT, undefined, '#eee', ''],
  maskColor: [ABSENT, undefined, 'rgba(0,0,0,0.5)', ''],
  maskStrokeColor: [ABSENT, undefined, 'red', ''],
  maskStrokeWidth: [ABSENT, undefined, 0, 2, 1.5],
  position: [ABSENT, undefined, ...positions],
  onClick: [ABSENT, undefined, () => {}],
  onNodeClick: [ABSENT, undefined, () => {}],
  pannable: [ABSENT, undefined, true, false],
  zoomable: [ABSENT, undefined, true, false],
  ariaLabel: [ABSENT, undefined, null, 'Overview', ''],
  'aria-label': [ABSENT, 'Overview'],
  inversePan: [ABSENT, undefined, true, false],
  zoomStep: [ABSENT, undefined, 2, 0.5],
  offsetScale: [ABSENT, undefined, 0, 10, 2.5],
  style: [ABSENT, undefined, { width: 100, height: 80 }, { background: 'pink', opacity: 0.5 }],
  className: [ABSENT, undefined, 'mine', ''],
  children: [ABSENT, 'text'],
  id: ['minimap-id'],
  'data-testid': ['custom'],
});

// ── MiniMapNode, rendered by a consumer ─────────────────────────────────
//
// A consumer's `nodeComponent` can render the library's own `MiniMapNode`.
// Its fill is `color`, else `style.background`, else
// `style.backgroundColor`.

const required = { id: 'n', x: 1, y: 2, width: 30, height: 20, borderRadius: 4, className: '', shapeRendering: 'crispEdges', selected: false };

const viaMiniMapNode = (extra) =>
  perSide((library) => (props) => h(library.MiniMapNode, { ...required, ...extra(props) }));

cases('MiniMap', 'data-testid="rf__minimap"', {
  nodeComponent: [
    labelled('MiniMapNode with only its required props', viaMiniMapNode(() => ({}))),
    labelled('MiniMapNode with color', viaMiniMapNode(() => ({ color: 'red' }))),
    labelled('MiniMapNode with style.background', viaMiniMapNode(() => ({ style: { background: 'blue' } }))),
    labelled('MiniMapNode with style.backgroundColor', viaMiniMapNode(() => ({ style: { backgroundColor: 'green' } }))),
    labelled('MiniMapNode with an empty color', viaMiniMapNode(() => ({ color: '', style: { background: 'blue' } }))),
    labelled('MiniMapNode with strokeColor and strokeWidth', viaMiniMapNode(() => ({ strokeColor: 'black', strokeWidth: 0 }))),
    labelled('MiniMapNode selected, with a class', viaMiniMapNode(() => ({ selected: true, className: 'x y' }))),
    labelled('MiniMapNode with an onClick', viaMiniMapNode(() => ({ onClick: () => {} }))),
    labelled('MiniMapNode handed every prop', viaMiniMapNode((props) => props)),
  ],
});

// ── Handle, inside a custom node ────────────────────────────────────────

function handleCases(table) {
  for (const [field, values] of Object.entries(table)) {
    for (const value of values) {
      const absent = value === ABSENT;
      test(`Handle.${field}: ${absent ? 'absent' : describe(value)}`, () => {
        const props = absent ? {} : { [field]: value };
        const [up, ps] = sides.map(([, library]) => {
          const custom = () => h('div', { className: 'custom' }, h(library.Handle, props));
          return render(library, () => null, 'class="custom"', {
            nodes: [{ id: 'a', type: 'custom', position: { x: 0, y: 0 }, data: {}, width: 50, height: 20 }],
            nodeTypes: { custom },
          });
        });
        assert.ok(!up.startsWith('(threw)') && up !== '(absent)', `upstream did not render: ${up}`);
        assert.equal(ps, up);
      });
    }
  }
}

handleCases({
  type: [ABSENT, undefined, 'source', 'target'],
  position: [ABSENT, undefined, 'top', 'right', 'bottom', 'left'],
  id: [ABSENT, undefined, null, '', 'h1'],
  isConnectable: [ABSENT, undefined, true, false],
  isConnectableStart: [ABSENT, undefined, true, false],
  isConnectableEnd: [ABSENT, undefined, true, false],
  isValidConnection: [ABSENT, undefined, () => true],
  onConnect: [ABSENT, undefined, () => {}],
  className: [ABSENT, undefined, 'mine'],
  style: [ABSENT, { background: 'red' }],
  children: [ABSENT, 'inside'],
  title: ['A handle'],
  'data-testid': ['custom'],
  'aria-label': ['label'],
  tabIndex: [0],
  onMouseEnter: [() => {}],
});

// `size || defaultSize[variant]`, `gap * zoom || 1` and `offset * zoom || …`
// fall back on any falsy number, `NaN` included.
cases('Background', 'data-testid="rf__background"', {
  size: [NaN, -0],
  gap: [NaN, [NaN, 4]],
  offset: [NaN, [5, NaN]],
});
