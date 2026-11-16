// `ReactFlowProps`, field by field: the cases `flow-contracts.test.mjs` runs
// on both sides through `browser/harness.mjs`.
//
// Each case mounts the default three-node flow with one field set, lets it
// settle, and reads back what a consumer can: the store, the DOM, the
// callbacks it fired and what it printed. A case that drives the flow does so
// in the page, with the DOM events a browser would dispatch, and the result is
// read after it settles again. The test compares the two sides' results whole.
//
// `undefined` is a value of its own here: the key is present and holds it,
// which upstream's destructuring defaults treat as absent. The `defaults` case
// is absence.

import { useEffect } from 'react';

// ── Driving ─────────────────────────────────────────────────────────────

// eslint-disable-next-line react-hooks/exhaustive-deps
const useEffectOnce = (run) => useEffect(() => run(), []);

const center = (element) => {
  const box = element.getBoundingClientRect();
  return { x: box.left + box.width / 2, y: box.top + box.height / 2 };
};

const mouse = (target, type, { x, y, button = 0, buttons, ...rest } = {}) =>
  target.dispatchEvent(
    new MouseEvent(type, {
      bubbles: true,
      cancelable: true,
      view: window,
      clientX: x,
      clientY: y,
      button,
      buttons: buttons ?? (type === 'mouseup' || type === 'click' ? 0 : 1 << button),
      ...rest,
    })
  );

const wheel = (target, { x = 400, y = 300, deltaX = 0, deltaY = 0, ...rest }) =>
  target.dispatchEvent(
    new WheelEvent('wheel', { bubbles: true, cancelable: true, view: window, clientX: x, clientY: y, deltaX, deltaY, ...rest })
  );

const keyboard = (type, key, code = key) =>
  document.activeElement?.dispatchEvent(new KeyboardEvent(type, { key, code, bubbles: true, cancelable: true })) ??
  document.body.dispatchEvent(new KeyboardEvent(type, { key, code, bubbles: true, cancelable: true }));

const node = (container, id) => container.querySelector(`.react-flow__node[data-id="${id}"]`);
const pane = (container) => container.querySelector('.react-flow__pane');
const handle = (container, id, type) => node(container, id).querySelector(`.react-flow__handle.${type}`);

// A press, `steps` moves of `dx`, `dy` each, and a release, with a frame
// after each step so d3 and the drag handlers see them as a browser would
// deliver them.
async function drag(context, target, { dx = 40, dy = 30, steps = 4, button = 0, from, release = true, modifiers = {} } = {}) {
  const start = from ?? center(target);
  mouse(target, 'mousedown', { ...start, button, ...modifiers });
  await context.frame();
  for (let i = 1; i <= steps; i++) {
    mouse(window, 'mousemove', { x: start.x + (dx * i) / steps, y: start.y + (dy * i) / steps, button, ...modifiers });
    await context.frame();
  }
  if (release) mouse(window, 'mouseup', { x: start.x + dx, y: start.y + dy, button, ...modifiers });
  await context.frame();
}

// A connection drag from a's source handle toward b's target handle, held
// (`release: false`) so the connection line is in the DOM when the case is
// read, or released to connect.
async function connect(context, { release = true, offset = { x: 0, y: 0 }, steps = 4 } = {}) {
  const { container } = context;
  const from = center(handle(container, 'a', 'source'));
  const to = center(handle(container, 'b', 'target'));
  const source = handle(container, 'a', 'source');
  mouse(source, 'mousedown', from);
  await context.frame();
  for (let i = 1; i <= steps; i++) {
    const x = from.x + ((to.x + offset.x - from.x) * i) / steps;
    const y = from.y + ((to.y + offset.y - from.y) * i) / steps;
    mouse(document, 'mousemove', { x, y });
    await context.frame();
  }
  if (release) mouse(document, 'mouseup', { x: to.x + offset.x, y: to.y + offset.y });
  await context.frame();
}

const select = async (context, ids) => {
  context.seen.api.getState().addSelectedNodes(ids);
  await context.settle();
};

const pressKey = async (context, key, code = key) => {
  keyboard('keydown', key, code);
  await context.frame();
  keyboard('keyup', key, code);
  await context.frame();
};

// ── The table ───────────────────────────────────────────────────────────

const cases = [{ name: 'defaults', props: () => ({}) }];

// One case per value: the field set to it and nothing else driven.
function values(field, list, extra = {}) {
  for (const value of list) {
    const label = value === undefined ? 'undefined' : typeof value === 'function' ? value.label ?? 'a function' : JSON.stringify(value);
    cases.push({
      name: `${field}: ${label}`,
      props: (context) => ({ ...(extra.props?.(context) ?? {}), [field]: typeof value === 'function' && value.build ? value.build(context) : value }),
      ...(extra.drive ? { drive: extra.drive } : {}),
      ...(extra.children ? { children: extra.children } : {}),
    });
  }
}
const built = (label, build) => Object.assign(() => {}, { label, build });

// A falsification probe: the two sides mount different props, so the test
// requires this case to differ. A harness that compared nothing would pass
// every other case and fail this one.
cases.push({ name: 'falsification: the sides mount different props', props: ({ side }) => (side === 'psflow' ? { nodesDraggable: false } : {}) });

// Flags the store holds.
for (const field of [
  'nodesDraggable',
  'nodesConnectable',
  'nodesFocusable',
  'edgesFocusable',
  'edgesReconnectable',
  'elementsSelectable',
  'elevateNodesOnSelect',
  'elevateEdgesOnSelect',
  'snapToGrid',
  'connectOnClick',
  'autoPanOnConnect',
  'autoPanOnNodeDrag',
  'autoPanOnNodeFocus',
  'selectNodesOnDrag',
  'debug',
  'fitView',
  'disableKeyboardA11y',
  'onlyRenderVisibleElements',
]) {
  values(field, [undefined, true, false]);
}

// Numbers the store holds, across the domain `number` admits.
values('minZoom', [undefined, 0.1, 1, 1.75, 0, 3]);
values('maxZoom', [undefined, 0.25, 0.75, 4, 1]);
values('nodeDragThreshold', [undefined, 0, 4.5]);
values('connectionDragThreshold', [undefined, 0, 2.5]);
values('autoPanSpeed', [undefined, 0, 7.5, 30]);
values('connectionRadius', [undefined, 0, 12.5, 200]);
values('paneClickDistance', [undefined, 0, 5]);
values('nodeClickDistance', [undefined, 0, 3]);
values('reconnectRadius', [undefined, 0, 2.5, 25], { props: () => ({ onReconnect: () => {} }) });
values('width', [undefined, 400, 0, 333.5]);
values('height', [undefined, 300, 0, 222.5]);

// Tuples and extents.
values('snapGrid', [undefined, [25, 25], [10, 20], [0.5, 2.5]], { props: () => ({ snapToGrid: true }) });
values('nodeOrigin', [undefined, [0, 0], [0.5, 0.5], [1, 1], [0.25, 0.75]]);
values('nodeExtent', [undefined, [[-50, -50], [150, 150]], [[-Infinity, -Infinity], [Infinity, Infinity]], [[0, 0], [0, 0]]]);
values('translateExtent', [undefined, [[-50, -50], [150, 150]], [[-Infinity, -Infinity], [Infinity, Infinity]], [[0, 0], [800, 600]]]);
values('defaultViewport', [undefined, { x: 10, y: 20, zoom: 1.5 }, { x: -5.5, y: 0, zoom: 0.25 }, { x: 0, y: 0, zoom: 10 }]);
values('viewport', [undefined, { x: 10, y: 20, zoom: 1.5 }, { x: 0, y: 0, zoom: 10 }]);

// Enumerations and strings.
values('connectionMode', [undefined, 'strict', 'loose']);
values('colorMode', [undefined, 'light', 'dark', 'system']);
values('zIndexMode', [undefined, 'basic', 'auto', 'manual'], {
  props: ({ graph }) => {
    const { nodes, edges } = graph();
    return {
      nodes: [
        ...nodes.map((n) => (n.id === 'b' ? { ...n, selected: true } : n)),
        { id: 'child', parentId: 'a', position: { x: 10, y: 10 }, data: { label: 'child' }, zIndex: 2 },
      ],
      edges: edges.map((e) => (e.id === 'a-b' ? { ...e, selected: true } : e)),
    };
  },
});
values('attributionPosition', [
  undefined,
  'top-left',
  'top-center',
  'top-right',
  'bottom-left',
  'bottom-center',
  'bottom-right',
  'center-left',
  'center-right',
]);
values('proOptions', [undefined, { hideAttribution: true }, { hideAttribution: false }, { hideAttribution: false, account: 'paid-pro' }]);
values('defaultMarkerColor', [undefined, '#ff0000', null, ''], {
  props: () => ({ edges: [{ id: 'a-b', source: 'a', target: 'b', markerEnd: 'arrowclosed', markerStart: { type: 'arrow' } }] }),
});
values('noPanClassName', [undefined, 'pan-blocker']);
values('noDragClassName', [undefined, 'drag-blocker']);
values('noWheelClassName', [undefined, 'wheel-blocker']);
values('className', [undefined, 'mine', '']);
values('style', [undefined, { background: 'red', width: 10 }]);
values('id', [undefined, 'flow-x', '']);
values('data-testid', ['custom']);
values('aria-label', ['A flow']);
values('ariaLabelConfig', [
  undefined,
  { 'node.a11yDescription.default': 'Node help', 'edge.a11yDescription.default': 'Edge help' },
  { 'controls.ariaLabel': 'Ctl', 'minimap.ariaLabel': 'Map', 'handle.ariaLabel': 'H' },
  { 'node.a11yDescription.keyboardDisabled': 'No keys' },
  {},
], {
  children: ({ library, h }) => [h(library.Controls, { key: 'c' }), h(library.MiniMap, { key: 'm' })],
});
values('ariaLabelConfig', [{ 'node.a11yDescription.keyboardDisabled': 'No keys, disabled' }], {
  props: () => ({ disableKeyboardA11y: true }),
});
values('fitViewOptions', [
  undefined,
  { padding: 0.5 },
  { padding: 0 },
  { padding: '20px' },
  { padding: '10%' },
  { padding: { top: 10, x: '5%' } },
  { padding: { top: '30px', right: 0.1, bottom: '5%', left: 40 } },
  { minZoom: 1, maxZoom: 1 },
  { maxZoom: 0.6 },
  { nodes: [{ id: 'a' }] },
  { nodes: [{ id: 'missing' }] },
  { nodes: [] },
  { includeHiddenNodes: true },
  { includeHiddenNodes: false },
  { duration: 0 },
], {
  props: ({ graph }) => {
    const { nodes, edges } = graph();
    return { fitView: true, nodes: [...nodes, { id: 'hidden', position: { x: 900, y: 900 }, data: { label: 'H' }, hidden: true }], edges };
  },
});

// ── Callbacks at mount ──────────────────────────────────────────────────

for (const name of ['onNodesChange', 'onEdgesChange', 'onInit', 'onMove', 'onMoveStart', 'onMoveEnd', 'onViewportChange', 'onError', 'onSelectionChange']) {
  cases.push({ name: `${name}: called at mount`, props: ({ record }) => ({ [name]: record(name) }) });
}
cases.push({
  name: 'onMove and onViewportChange with fitView',
  props: ({ record }) => ({ fitView: true, onMove: record('onMove'), onMoveEnd: record('onMoveEnd'), onViewportChange: record('onViewportChange') }),
});

// The error codes a mount can raise.
const errorCase = (name, props) =>
  cases.push({ name: `onError: ${name}`, props: (context) => ({ onError: context.record('onError'), ...props(context) }) });
errorCase('an unknown node type', ({ graph }) => ({ nodes: [{ ...graph().nodes[0], type: 'nope' }] }));
errorCase('an unknown edge type', ({ graph }) => ({ edges: [{ ...graph().edges[0], type: 'nope' }] }));
errorCase('an edge to a missing node', () => ({ edges: [{ id: 'x', source: 'a', target: 'missing' }] }));
errorCase('an edge to a missing handle', () => ({ edges: [{ id: 'x', source: 'a', target: 'b', sourceHandle: 'nope' }] }));
errorCase('a missing parent', ({ graph }) => ({ nodes: [...graph().nodes, { id: 'orphan', parentId: 'gone', position: { x: 0, y: 0 }, data: {} }] }));
errorCase('a parent extent without a parent', ({ graph }) => ({ nodes: [...graph().nodes, { id: 'p', extent: 'parent', position: { x: 0, y: 0 }, data: {} }] }));
errorCase('an unknown marker type', () => ({ edges: [{ id: 'x', source: 'a', target: 'b', markerEnd: 'nope' }] }));
errorCase('nodeTypes naming a type no node uses', ({ library, h }) => ({ nodeTypes: { custom: () => h('div', null, 'c') } }));

// ── Interaction: one field's branch per drive ──────────────────────────

const driven = (name, props, drive) => cases.push({ name, props, drive });

// Pan and zoom.
for (const zoomOnScroll of [undefined, true, false]) {
  driven(`zoomOnScroll: ${zoomOnScroll} — a wheel over the pane`, () => ({ zoomOnScroll }), async (c) => {
    wheel(pane(c.container), { deltaY: -100 });
  });
}
for (const zoomOnDoubleClick of [undefined, true, false]) {
  cases.push({
    name: `zoomOnDoubleClick: ${zoomOnDoubleClick} — a double click on the pane`,
    props: () => ({ zoomOnDoubleClick }),
    drive: async (c) => mouse(pane(c.container), 'dblclick', { x: 400, y: 300 }),
    // d3's double-click zoom is a transition, read once it has ended.
    wait: 600,
  });
}
for (const zoomOnPinch of [undefined, true, false]) {
  driven(`zoomOnPinch: ${zoomOnPinch} — a ctrl-wheel pinch`, () => ({ zoomOnPinch, zoomOnScroll: false }), async (c) => {
    wheel(pane(c.container), { deltaY: -20, ctrlKey: true });
  });
}
for (const [panOnScroll, panOnScrollMode] of [
  [true, undefined],
  [true, 'free'],
  [true, 'vertical'],
  [true, 'horizontal'],
  [false, 'vertical'],
  [undefined, undefined],
]) {
  driven(
    `panOnScroll: ${panOnScroll}, panOnScrollMode: ${panOnScrollMode} — a diagonal wheel`,
    () => ({ panOnScroll, panOnScrollMode }),
    async (c) => wheel(pane(c.container), { deltaX: 30, deltaY: 50 })
  );
}
for (const panOnScrollSpeed of [undefined, 0.25, 2]) {
  driven(`panOnScrollSpeed: ${panOnScrollSpeed} — a wheel`, () => ({ panOnScroll: true, panOnScrollSpeed }), async (c) =>
    wheel(pane(c.container), { deltaY: 50 })
  );
}
for (const panOnDrag of [undefined, true, false, [0], [1], [2], [0, 1, 2], []]) {
  for (const button of [0, 1]) {
    driven(`panOnDrag: ${JSON.stringify(panOnDrag)} — a drag with button ${button}`, () => ({ panOnDrag }), async (c) =>
      drag(c, pane(c.container), { from: { x: 700, y: 500 }, button })
    );
  }
}
for (const selectionOnDrag of [undefined, true, false]) {
  for (const selectionMode of [undefined, 'full', 'partial']) {
    driven(
      `selectionOnDrag: ${selectionOnDrag}, selectionMode: ${selectionMode} — a drag over a and part of b`,
      ({ record }) => ({ selectionOnDrag, selectionMode, panOnDrag: false, onSelectionStart: record('onSelectionStart'), onSelectionEnd: record('onSelectionEnd') }),
      async (c) => {
        const a = node(c.container, 'a').getBoundingClientRect();
        const b = node(c.container, 'b').getBoundingClientRect();
        await drag(c, pane(c.container), { from: { x: a.left - 10, y: a.top - 10 }, dx: b.left + 20 - (a.left - 10), dy: b.top + 10 - (a.top - 10) });
      }
    );
  }
}
for (const paneClickDistance of [undefined, 0, 5]) {
  driven(
    `paneClickDistance: ${paneClickDistance} — a 3px drag on the pane`,
    ({ record }) => ({ paneClickDistance, onPaneClick: record('onPaneClick'), panOnDrag: false }),
    async (c) => {
      await drag(c, pane(c.container), { from: { x: 700, y: 500 }, dx: 3, dy: 0, steps: 1, release: false });
      mouse(pane(c.container), 'mouseup', { x: 703, y: 500 });
      mouse(pane(c.container), 'click', { x: 703, y: 500 });
    }
  );
}

// Node interaction.
for (const nodeDragThreshold of [undefined, 0, 10]) {
  driven(`nodeDragThreshold: ${nodeDragThreshold} — a 5px node drag`, ({ record }) => ({ nodeDragThreshold, onNodeDragStart: record('onNodeDragStart') }), async (c) =>
    drag(c, node(c.container, 'b'), { dx: 5, dy: 0, steps: 2 })
  );
}
for (const nodeClickDistance of [undefined, 0, 6]) {
  driven(
    `nodeClickDistance: ${nodeClickDistance} — a 3px node drag`,
    ({ record }) => ({ nodeClickDistance, onNodeClick: record('onNodeClick'), nodeDragThreshold: 10 }),
    async (c) => {
      const b = node(c.container, 'b');
      const at = center(b);
      await drag(c, b, { dx: 3, dy: 0, steps: 1, release: false });
      mouse(b, 'mouseup', { x: at.x + 3, y: at.y });
      mouse(b, 'click', { x: at.x + 3, y: at.y });
    }
  );
}
for (const snapGrid of [undefined, [25, 25], [7.5, 40]]) {
  driven(`snapGrid: ${JSON.stringify(snapGrid)} — a node drag with snapToGrid`, () => ({ snapToGrid: true, snapGrid }), async (c) =>
    drag(c, node(c.container, 'b'), { dx: 33, dy: 17 })
  );
}
for (const nodeExtent of [undefined, [[0, 0], [260, 200]]]) {
  driven(`nodeExtent: ${JSON.stringify(nodeExtent)} — a node drag past it`, () => ({ nodeExtent }), async (c) =>
    drag(c, node(c.container, 'b'), { dx: 200, dy: 200 })
  );
}
for (const selectNodesOnDrag of [undefined, true, false]) {
  driven(`selectNodesOnDrag: ${selectNodesOnDrag} — a node drag`, () => ({ selectNodesOnDrag }), async (c) =>
    drag(c, node(c.container, 'b'), { dx: 40, dy: 0 })
  );
}
for (const noDragClassName of [undefined, 'drag-blocker']) {
  driven(
    `noDragClassName: ${noDragClassName} — a drag on a node marked nodrag`,
    ({ graph }) => ({ noDragClassName, nodes: graph().nodes.map((n) => (n.id === 'b' ? { ...n, className: 'drag-blocker nodrag' } : n)) }),
    async (c) => drag(c, node(c.container, 'b'), { dx: 40, dy: 0 })
  );
}

// Keys. The flow is uncontrolled, so a selection and a deletion apply and
// the key's effect shows in the nodes themselves.
const uncontrolled = ({ graph }) => {
  const { nodes, edges } = graph();
  return { nodes: undefined, edges: undefined, defaultNodes: nodes, defaultEdges: edges };
};
for (const deleteKeyCode of [undefined, 'Backspace', 'Delete', ['Delete', 'x'], [], null]) {
  for (const key of ['Backspace', 'Delete']) {
    driven(
      `deleteKeyCode: ${JSON.stringify(deleteKeyCode)} — ${key} with a selected`,
      (context) => ({ ...uncontrolled(context), deleteKeyCode, onNodesDelete: context.record('onNodesDelete'), onDelete: context.record('onDelete') }),
      async (c) => {
        await select(c, ['a']);
        await pressKey(c, key);
      }
    );
  }
}
for (const multiSelectionKeyCode of [undefined, 'Shift', ['Shift', 'Alt'], null]) {
  driven(
    `multiSelectionKeyCode: ${JSON.stringify(multiSelectionKeyCode)} — click a, then Shift-click b`,
    (context) => ({ ...uncontrolled(context), multiSelectionKeyCode }),
    async (c) => {
      const a = node(c.container, 'a');
      const b = node(c.container, 'b');
      mouse(a, 'mousedown', center(a));
      mouse(a, 'mouseup', center(a));
      mouse(a, 'click', center(a));
      await c.settle();
      keyboard('keydown', 'Shift', 'ShiftLeft');
      await c.frame();
      mouse(b, 'mousedown', { ...center(b), shiftKey: true });
      mouse(b, 'mouseup', { ...center(b), shiftKey: true });
      mouse(b, 'click', { ...center(b), shiftKey: true });
      await c.settle();
      keyboard('keyup', 'Shift', 'ShiftLeft');
    }
  );
}
for (const selectionKeyCode of [undefined, 'Shift', 'a', null]) {
  driven(
    `selectionKeyCode: ${JSON.stringify(selectionKeyCode)} — hold Shift and drag over a`,
    () => ({ selectionKeyCode }),
    async (c) => {
      const a = node(c.container, 'a').getBoundingClientRect();
      keyboard('keydown', 'Shift', 'ShiftLeft');
      await c.frame();
      await drag(c, pane(c.container), { from: { x: a.left - 10, y: a.top - 10 }, dx: a.width + 20, dy: a.height + 20, modifiers: { shiftKey: true } });
      keyboard('keyup', 'Shift', 'ShiftLeft');
    }
  );
}
for (const panActivationKeyCode of [undefined, 'Space', 'a', null]) {
  driven(
    `panActivationKeyCode: ${JSON.stringify(panActivationKeyCode)} — hold Space and drag with panOnDrag off`,
    () => ({ panActivationKeyCode, panOnDrag: false }),
    async (c) => {
      keyboard('keydown', ' ', 'Space');
      await c.frame();
      await drag(c, pane(c.container), { from: { x: 700, y: 500 } });
      keyboard('keyup', ' ', 'Space');
    }
  );
}
for (const zoomActivationKeyCode of [undefined, 'Meta', 'Control', 'a', null]) {
  driven(
    `zoomActivationKeyCode: ${JSON.stringify(zoomActivationKeyCode)} — hold Meta and wheel with zoomOnScroll off`,
    () => ({ zoomActivationKeyCode, zoomOnScroll: false }),
    async (c) => {
      keyboard('keydown', 'Meta', 'MetaLeft');
      await c.frame();
      wheel(pane(c.container), { deltaY: -100, metaKey: true });
      await c.frame();
      keyboard('keyup', 'Meta', 'MetaLeft');
    }
  );
}

// Connections.
// Auto-pan moves the viewport on each frame a held connection is near the
// edge, so it is off wherever a case holds one, and the case releases it once
// it has been read.
const release = async (c) => {
  mouse(document, 'mouseup', { x: 0, y: 0 });
  await c.frame();
};
const held = (name, props, drive) => cases.push({ name, props, drive, after: release });
const connectionProps = (extra) => ({ record }) => ({
  autoPanOnConnect: false,
  onConnectStart: record('onConnectStart'),
  onConnect: record('onConnect'),
  onConnectEnd: record('onConnectEnd'),
  ...extra,
});
for (const connectionLineType of [undefined, 'default', 'straight', 'step', 'smoothstep', 'simplebezier']) {
  held(`connectionLineType: ${connectionLineType} — a held connection`, connectionProps({ connectionLineType }), (c) =>
    connect(c, { release: false, offset: { x: 60, y: 60 } })
  );
}
held(
  'connectionLineStyle and connectionLineContainerStyle — a held connection',
  connectionProps({ connectionLineStyle: { stroke: 'red', strokeWidth: 3 }, connectionLineContainerStyle: { opacity: 0.5 } }),
  (c) => connect(c, { release: false, offset: { x: 60, y: 60 } })
);
held(
  'connectionLineComponent — a held connection',
  ({ record, h }) => ({
    ...connectionProps({})({ record }),
    connectionLineComponent: ({ fromX, fromY, toX, toY, connectionLineType, fromPosition, toPosition, connectionStatus, toNode, toHandle }) =>
      h('path', {
        className: 'mine',
        d: `M${fromX},${fromY} L${toX},${toY}`,
        'data-type': connectionLineType,
        'data-from': fromPosition,
        'data-to': toPosition,
        'data-status': String(connectionStatus),
        'data-to-node': toNode === null ? 'null' : typeof toNode,
        'data-to-handle': toHandle === null ? 'null' : typeof toHandle,
      }),
  }),
  (c) => connect(c, { release: false, offset: { x: 60, y: 60 } })
);
for (const connectionRadius of [undefined, 0, 100]) {
  driven(`connectionRadius: ${connectionRadius} — a release 40px from b's handle`, connectionProps({ connectionRadius }), (c) =>
    connect(c, { offset: { x: 40, y: -10 } })
  );
}
for (const connectionMode of [undefined, 'strict', 'loose']) {
  driven(
    `connectionMode: ${connectionMode} — a source handle dropped on a source handle`,
    connectionProps({ connectionMode }),
    async (c) => {
      const from = center(handle(c.container, 'a', 'source'));
      const to = center(handle(c.container, 'b', 'source'));
      mouse(handle(c.container, 'a', 'source'), 'mousedown', from);
      for (let i = 1; i <= 4; i++) {
        mouse(document, 'mousemove', { x: from.x + ((to.x - from.x) * i) / 4, y: from.y + ((to.y - from.y) * i) / 4 });
        await c.frame();
      }
      mouse(document, 'mouseup', to);
    }
  );
}
for (const isValidConnection of [undefined, () => true, () => false]) {
  driven(`isValidConnection: ${isValidConnection === undefined ? 'undefined' : String(isValidConnection())} — a connection`, connectionProps({ isValidConnection }), (c) => connect(c));
}
for (const connectionDragThreshold of [undefined, 0, 50]) {
  held(`connectionDragThreshold: ${connectionDragThreshold} — a 20px handle drag`, connectionProps({ connectionDragThreshold }), async (c) => {
    const from = center(handle(c.container, 'a', 'source'));
    mouse(handle(c.container, 'a', 'source'), 'mousedown', from);
    mouse(document, 'mousemove', { x: from.x + 20, y: from.y });
    await c.frame();
  });
}
for (const connectOnClick of [undefined, true, false]) {
  driven(`connectOnClick: ${connectOnClick} — click a's source, then b's target`, connectionProps({ connectOnClick }), async (c) => {
    const s = handle(c.container, 'a', 'source');
    const t = handle(c.container, 'b', 'target');
    mouse(s, 'click', center(s));
    await c.settle();
    mouse(t, 'click', center(t));
  });
}
for (const onlyRenderVisibleElements of [undefined, true, false]) {
  driven(
    `onlyRenderVisibleElements: ${onlyRenderVisibleElements} — a node outside the viewport`,
    ({ graph }) => ({ onlyRenderVisibleElements, nodes: [...graph().nodes, { id: 'far', position: { x: 5000, y: 5000 }, data: { label: 'far' } }] }),
    async () => {}
  );
}

// ── NodeToolbar and EdgeToolbar ─────────────────────────────────────────
//
// Both portal into the flow, so only a mounted flow draws them. Node a is a
// custom node that renders a toolbar; edge a-b is a custom edge that renders
// one. `selected` decides visibility when `isVisible` is not a boolean.

const toolbarFlow = ({ graph, library, h }, { node = {}, edge = {}, selectNode = false, selectEdge = false }) => {
  const { nodes, edges } = graph();
  return {
    nodeTypes: {
      tool: () => h('div', { className: 'tool' }, h(library.NodeToolbar, node, 'node tools'), 'T', h(library.Handle, { type: 'source', position: 'bottom' })),
    },
    edgeTypes: {
      tool: (props) => [
        h(library.BaseEdge, { key: 'p', id: props.id, path: `M${props.sourceX},${props.sourceY} L${props.targetX},${props.targetY}` }),
        h(library.EdgeToolbar, { key: 't', edgeId: props.id, x: (props.sourceX + props.targetX) / 2, y: (props.sourceY + props.targetY) / 2, ...edge }, 'edge tools'),
      ],
    },
    nodes: nodes.map((n) => (n.id === 'a' ? { ...n, type: 'tool', selected: selectNode } : n)),
    edges: edges.map((e) => (e.id === 'a-b' ? { ...e, type: 'tool', selected: selectEdge } : e)),
  };
};
const toolbar = (name, options) => cases.push({ name, props: (context) => toolbarFlow(context, options(context)) });

for (const selectNode of [false, true]) {
  for (const isVisible of [undefined, true, false]) {
    toolbar(`NodeToolbar.isVisible: ${isVisible}, node selected: ${selectNode}`, () => ({ node: { isVisible }, selectNode }));
  }
}
for (const nodeId of [undefined, 'a', 'b', ['a', 'b'], ['b', 'missing'], 'missing', []]) {
  toolbar(`NodeToolbar.nodeId: ${JSON.stringify(nodeId)}`, () => ({ node: { nodeId, isVisible: true } }));
}
toolbar('NodeToolbar.nodeId: ["a","b"], both selected', ({ graph }) => ({ node: { nodeId: ['a', 'b'] }, selectNode: true }));
for (const position of [undefined, 'top', 'right', 'bottom', 'left']) {
  for (const align of [undefined, 'start', 'center', 'end']) {
    toolbar(`NodeToolbar.position: ${position}, align: ${align}`, () => ({ node: { position, align, isVisible: true } }));
  }
}
for (const offset of [undefined, 0, 25.5, -10]) {
  toolbar(`NodeToolbar.offset: ${offset}`, () => ({ node: { offset, isVisible: true } }));
}
toolbar('NodeToolbar: className, style and DOM attributes', () => ({
  node: { isVisible: true, className: 'mine', style: { background: 'red', zIndex: 5 }, 'data-testid': 'nt', title: 'Tools', id: 'tools', onMouseEnter: () => {} },
}));

for (const selectEdge of [false, true]) {
  for (const isVisible of [undefined, true, false]) {
    toolbar(`EdgeToolbar.isVisible: ${isVisible}, edge selected: ${selectEdge}`, () => ({ edge: { isVisible }, selectEdge }));
  }
}
for (const alignX of [undefined, 'left', 'center', 'right']) {
  for (const alignY of [undefined, 'top', 'center', 'bottom']) {
    toolbar(`EdgeToolbar.alignX: ${alignX}, alignY: ${alignY}`, () => ({ edge: { alignX, alignY, isVisible: true } }));
  }
}
toolbar('EdgeToolbar.edgeId: a missing edge', () => ({ edge: { edgeId: 'missing', isVisible: true } }));
toolbar('EdgeToolbar: x and y fractional and negative', () => ({ edge: { x: -12.25, y: 7.5, isVisible: true } }));
toolbar('EdgeToolbar: className, style and DOM attributes', () => ({
  edge: { isVisible: true, className: 'mine', style: { background: 'red', zIndex: 9 }, 'data-testid': 'et', title: 'Tools', id: 'etools', onMouseEnter: () => {} },
}));
toolbar('EdgeToolbar: an edge zIndex', ({ graph }) => ({ edge: { isVisible: true } }));

// ── The viewport helpers' options ───────────────────────────────────────

const helper = (name, call, props = () => ({})) =>
  cases.push({ name: `instance.${name}`, props, drive: async (c) => call(c.seen.instance, c), wait: 50 });

helper('zoomIn()', (i) => i.zoomIn());
helper('zoomIn({ duration: 0 })', (i) => i.zoomIn({ duration: 0 }));
helper('zoomOut({ duration: 0 })', (i) => i.zoomOut({ duration: 0 }));
helper('zoomTo(1.5)', (i) => i.zoomTo(1.5));
helper('zoomTo(10) past maxZoom', (i) => i.zoomTo(10));
helper('zoomTo(0) below minZoom', (i) => i.zoomTo(0));
helper('getZoom()', (i) => i.getZoom());
helper('setViewport({ x, y, zoom })', (i) => i.setViewport({ x: 12.5, y: -30, zoom: 1.25 }));
helper('setViewport with zoom past the limits', (i) => i.setViewport({ x: 0, y: 0, zoom: 9 }));
helper('getViewport()', (i) => i.getViewport());
helper('setCenter(x, y)', (i) => i.setCenter(100, 50));
helper('setCenter(x, y, { zoom })', (i) => i.setCenter(100, 50, { zoom: 2 }));
helper('setCenter(x, y, { zoom: 0 })', (i) => i.setCenter(100, 50, { zoom: 0 }));
helper('fitBounds(rect)', (i) => i.fitBounds({ x: 0, y: 0, width: 200, height: 100 }));
helper('fitBounds(rect, { padding: 0.3 })', (i) => i.fitBounds({ x: 0, y: 0, width: 200, height: 100 }, { padding: 0.3 }));
helper("fitBounds(rect, { padding: '15px' })", (i) => i.fitBounds({ x: 0, y: 0, width: 200, height: 100 }, { padding: '15px' }));
helper("fitBounds(rect, { padding: '25%' })", (i) => i.fitBounds({ x: 0, y: 0, width: 200, height: 100 }, { padding: '25%' }));
helper("fitBounds(rect, { padding: { top: '10px', x: 0.2 } })", (i) =>
  i.fitBounds({ x: 0, y: 0, width: 200, height: 100 }, { padding: { top: '10px', x: 0.2 } })
);
helper('fitView()', (i) => i.fitView());
helper("fitView({ padding: { x: '10%', top: 4 } })", (i) => i.fitView({ padding: { x: '10%', top: 4 } }));
helper("fitView({ nodes: ['a', { id: 'b' }] })", (i) => i.fitView({ nodes: [{ id: 'a' }, { id: 'b' }] }));
helper('fitView({ nodes: [] })', (i) => i.fitView({ nodes: [] }));
helper('fitView({ minZoom: 3 })', (i) => i.fitView({ minZoom: 3 }));
helper('screenToFlowPosition', (i) => i.screenToFlowPosition({ x: 120.5, y: 64 }));
helper('screenToFlowPosition({ snapToGrid: true })', (i) => i.screenToFlowPosition({ x: 121, y: 64 }, { snapToGrid: true }), () => ({ snapGrid: [25, 25] }));
helper('screenToFlowPosition({ snapToGrid: false }) with snapToGrid on', (i) => i.screenToFlowPosition({ x: 121, y: 64 }, { snapToGrid: false }), () => ({ snapToGrid: true, snapGrid: [25, 25] }));
helper('screenToFlowPosition() with snapToGrid on', (i) => i.screenToFlowPosition({ x: 121, y: 64 }), () => ({ snapToGrid: true, snapGrid: [25, 25] }));
helper('flowToScreenPosition', (i) => i.flowToScreenPosition({ x: 10, y: -20 }));

// ── The connection hooks' params ────────────────────────────────────────

const hookFlow = (render) => ({ graph, library, h }) => {
  const { nodes, edges } = graph();
  return {
    nodeTypes: { probe: (props) => h('div', { className: 'probe' }, h('pre', null, JSON.stringify(render(library, props))), h(library.Handle, { type: 'target', position: 'top' }), h(library.Handle, { type: 'source', position: 'bottom' })) },
    nodes: nodes.map((n) => (n.id === 'b' ? { ...n, type: 'probe' } : n)),
    edges: [...edges, { id: 'a-b2', source: 'a', target: 'b', targetHandle: null }],
  };
};
const hookCase = (name, render) => cases.push({ name, props: hookFlow(render) });
hookCase('useNodeConnections()', (library) => library.useNodeConnections());
hookCase("useNodeConnections({ handleType: 'target' })", (library) => library.useNodeConnections({ handleType: 'target' }));
hookCase("useNodeConnections({ handleType: 'source' })", (library) => library.useNodeConnections({ handleType: 'source' }));
hookCase("useNodeConnections({ id: 'a' })", (library) => library.useNodeConnections({ id: 'a' }));
hookCase("useNodeConnections({ handleType: 'target', handleId: 'x' })", (library) => library.useNodeConnections({ handleType: 'target', handleId: 'x' }));
hookCase('useNodeConnections({ handleId: null })', (library) => library.useNodeConnections({ handleId: null }));
hookCase("useHandleConnections({ type: 'target' })", (library) => library.useHandleConnections({ type: 'target' }));
hookCase("useHandleConnections({ type: 'source', id: null, nodeId: 'a' })", (library) => library.useHandleConnections({ type: 'source', id: null, nodeId: 'a' }));
hookCase("useHandleConnections({ type: 'target', id: 'x' })", (library) => library.useHandleConnections({ type: 'target', id: 'x' }));

// ── Deletion, selection and store actions ───────────────────────────────

const deletion = (name, onBeforeDelete) =>
  cases.push({
    name: `onBeforeDelete: ${name}`,
    props: ({ record }) => ({ onBeforeDelete, onDelete: record('onDelete'), onNodesChange: record('onNodesChange'), onEdgesChange: record('onEdgesChange') }),
    drive: (c) => c.seen.instance.deleteElements({ nodes: [{ id: 'a' }, { id: 'b' }], edges: [{ id: 'b-c' }] }),
  });
deletion('absent', undefined);
deletion('resolves true', async () => true);
deletion('resolves false', async () => false);
deletion('resolves a subset', async ({ nodes }) => ({ nodes: nodes.slice(0, 1), edges: [] }));
deletion('resolves empty arrays', async () => ({ nodes: [], edges: [] }));

const action = (name, run, props = () => ({})) =>
  cases.push({ name: `store action: ${name}`, props: (c) => ({ ...props(c), onNodesChange: c.record('onNodesChange'), onEdgesChange: c.record('onEdgesChange') }), drive: (c) => run(c.seen.api.getState(), c) });
const selectedFlow = ({ graph }) => {
  const { nodes, edges } = graph();
  return { nodes: nodes.map((n) => ({ ...n, selected: true })), edges: edges.map((e) => ({ ...e, selected: true })) };
};
action('unselectNodesAndEdges()', (s) => s.unselectNodesAndEdges(), selectedFlow);
action('unselectNodesAndEdges({})', (s) => s.unselectNodesAndEdges({}), selectedFlow);
action("unselectNodesAndEdges({ nodes: [a] })", (s) => s.unselectNodesAndEdges({ nodes: [s.nodes[0]] }), selectedFlow);
action("unselectNodesAndEdges({ edges: [a-b] })", (s) => s.unselectNodesAndEdges({ edges: [s.edges[0]] }), selectedFlow);
action('panBy({ x, y })', (s) => s.panBy({ x: 12.5, y: -7 }));
action('panBy({ x: 0, y: 0 })', (s) => s.panBy({ x: 0, y: 0 }));
action('addSelectedNodes([a, missing])', (s) => s.addSelectedNodes(['a', 'missing']));
action('addSelectedEdges([a-b])', (s) => s.addSelectedEdges(['a-b']));

helper('setViewport with a duration, ease and linear interpolate', (i) =>
  i.setViewport({ x: 40, y: 20, zoom: 1.5 }, { duration: 80, ease: (t) => t, interpolate: 'linear' })
);
helper('setViewport with a duration and smooth interpolate', (i) =>
  i.setViewport({ x: 40, y: 20, zoom: 1.5 }, { duration: 80, interpolate: 'smooth' })
);

// `updateNodeInternals(id)` takes one id or an array of them. The probe calls
// it once, from an effect, as a consumer does after changing a node's
// handles; node b renders both handles so the edges resolve.
for (const [label, arg] of [['a node id', 'b'], ['an array of ids', ['a', 'b']], ['a missing id', 'missing']]) {
  cases.push({
    name: `useUpdateNodeInternals: ${label}`,
    props: ({ library, h, graph }) => {
      const Updater = () => {
        const update = library.useUpdateNodeInternals();
        useEffectOnce(() => update(arg));
        return null;
      };
      const u = () =>
        h('div', null, 'U', h(Updater), h(library.Handle, { type: 'target', position: 'top' }), h(library.Handle, { type: 'source', position: 'bottom' }));
      return { nodeTypes: { u }, nodes: graph().nodes.map((n) => (n.id === 'b' ? { ...n, type: 'u' } : n)) };
    },
  });
}

// ── ControlButton's attributes ──────────────────────────────────────────
//
// `ButtonHTMLAttributes<HTMLButtonElement>`: React's `onClick` receives the
// click, and every attribute the component does not destructure is spread
// onto the `<button>` last.
for (const [label, extra] of [
  ['onClick', ({ record }) => ({ onClick: record('ControlButton.onClick') })],
  ['type and onMouseDown', ({ record }) => ({ type: 'submit', onMouseDown: record('ControlButton.onMouseDown') })],
]) {
  cases.push({
    name: `ControlButton: ${label} — a click`,
    children: (context) =>
      context.h(context.library.Controls, { showZoom: false, showFitView: false, showInteractive: false },
        context.h(context.library.ControlButton, { className: 'mine', ...extra(context) }, 'C')),
    drive: async (c) => {
      const button = c.container.querySelector('.react-flow__controls-button.mine');
      mouse(button, 'mousedown', center(button));
      mouse(button, 'mouseup', center(button));
      mouse(button, 'click', center(button));
    },
  });
}

// ── Handle's handlers and attributes ────────────────────────────────────
//
// Upstream's `<Handle />` calls the consumer's `onMouseDown` after it has
// started a connection, and spreads every attribute it does not destructure
// onto its `<div>` last, an `onClick` included.
const handleCase = (label, handleProps, drive) =>
  cases.push({
    name: `Handle: ${label}`,
    props: (context) => ({
      autoPanOnConnect: false,
      onConnectStart: context.record('onConnectStart'),
      nodeTypes: {
        h: () =>
          context.h('div', null, 'H', context.h(context.library.Handle, { type: 'source', position: 'bottom', className: 'probe', ...handleProps(context) })),
      },
      nodes: context.graph().nodes.map((n) => (n.id === 'a' ? { ...n, type: 'h' } : n)),
    }),
    drive,
    after: release,
  });
const pressHandle = async (c) => {
  const el = c.container.querySelector('.react-flow__handle.probe');
  mouse(el, 'mousedown', center(el));
  await c.frame();
};
handleCase('onMouseDown — a press', ({ record }) => ({ onMouseDown: record('Handle.onMouseDown') }), pressHandle);
handleCase('a rest onClick — a click', ({ record }) => ({ onClick: record('Handle.onClick'), title: 'T', 'data-kind': 'k' }), async (c) => {
  const el = c.container.querySelector('.react-flow__handle.probe');
  mouse(el, 'click', center(el));
});

// The hooks' `onConnect` and `onDisconnect`: upstream calls neither at
// mount, then each with the connections that appeared or went, keyed by
// edge id.
for (const [label, hook] of [
  ['useNodeConnections', (library, record) => library.useNodeConnections({ handleType: 'target', onConnect: record('onConnect'), onDisconnect: record('onDisconnect') })],
  ['useHandleConnections', (library, record) => library.useHandleConnections({ type: 'target', onConnect: record('onConnect'), onDisconnect: record('onDisconnect') })],
]) {
  cases.push({
    name: `${label}: onConnect and onDisconnect — mount, then an edge added and one removed`,
    props: (context) => {
      const { nodes, edges, ...rest } = hookFlow((library) => hook(library, context.record))(context);
      return { ...rest, nodes: undefined, edges: undefined, defaultNodes: nodes, defaultEdges: edges };
    },
    drive: async (c) => {
      c.seen.instance.addEdges([{ id: 'c-b', source: 'c', target: 'b' }]);
      await c.settle();
      c.seen.instance.deleteElements({ edges: [{ id: 'a-b' }] });
      await c.settle();
    },
  });
}

export default cases;
