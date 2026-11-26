// Unusual store writes, used after mount: the cases `store-coercion.test.mjs`
// runs on both sides through `browser/harness.mjs`.
//
// Each case mounts the default three-node flow, writes an unusual value into
// the store with `setState`, and then lets the flow use it: a render that
// reads it, a drag, or a queued edge update. What it reads back is what a
// consumer can: the store, the DOM, the callbacks fired and what was printed,
// including an error that escaped, by its kind.

const center = (element) => {
  const box = element.getBoundingClientRect();
  return { x: box.left + box.width / 2, y: box.top + box.height / 2 };
};

const mouse = (target, type, { x, y, button = 0 } = {}) =>
  target.dispatchEvent(
    new MouseEvent(type, {
      bubbles: true,
      cancelable: true,
      view: window,
      clientX: x,
      clientY: y,
      button,
      buttons: type === 'mouseup' || type === 'click' ? 0 : 1 << button,
    })
  );

const node = (container, id) => container.querySelector(`.react-flow__node[data-id="${id}"]`);

async function drag(context, target, { dx = 40, dy = 30, steps = 4 } = {}) {
  const start = center(target);
  mouse(target, 'mousedown', start);
  await context.frame();
  for (let i = 1; i <= steps; i++) {
    mouse(window, 'mousemove', { x: start.x + (dx * i) / steps, y: start.y + (dy * i) / steps });
    await context.frame();
  }
  mouse(window, 'mouseup', { x: start.x + dx, y: start.y + dy });
  await context.frame();
}

const handle = (container, id, type) => node(container, id).querySelector(`.react-flow__handle.${type}`);

// A connection drag from a's source handle to b's target handle.
async function connect(context, { steps = 4 } = {}) {
  const { container } = context;
  const source = handle(container, 'a', 'source');
  const from = center(source);
  const to = center(handle(container, 'b', 'target'));
  mouse(source, 'mousedown', from);
  await context.frame();
  for (let i = 1; i <= steps; i++) {
    mouse(document, 'mousemove', { x: from.x + ((to.x - from.x) * i) / steps, y: from.y + ((to.y - from.y) * i) / steps });
    await context.frame();
  }
  mouse(document, 'mouseup', to);
  await context.frame();
}

// `context.record` serializes its arguments; a drag event is too large to
// compare whole, so the drag callbacks record what they were called for.
const dragRecorder = (context, label) => (_event, current, all) =>
  context.record(label)(current?.id ?? null, all.map((n) => n.id));

const write = async (context, partial) => {
  context.seen.api.setState(partial);
  await context.settle();
};

const cases = [];

// A falsification probe: the two sides write different values, so the test
// requires this case to differ.
cases.push({
  name: 'falsification: the sides write different values',
  drive: async (c) => write(c, { nodesDraggable: c.side === 'psflow' }),
});

// ── Numbers outside their type ─────────────────────────────────────────

// The minimap's view box takes `Math.max` of the two scaled sides, so a
// height that is not a number is `NaN` there whichever side it is on.
for (const [label, value] of [
  ['NaN', NaN],
  ['undefined', undefined],
  ['a numeric string', '300'],
]) {
  cases.push({
    name: `the minimap with a height of ${label}`,
    children: ({ h, library }) => h(library.MiniMap, { pannable: false, zoomable: false }),
    drive: async (c) => write(c, { height: value }),
  });
}

// `Controls` compares the zoom with each limit, `>=` and `<=`.
for (const [label, value] of [
  ['NaN', NaN],
  ['undefined', undefined],
]) {
  cases.push({
    name: `the controls with a maxZoom of ${label}`,
    children: ({ h, library }) => h(library.Controls),
    drive: async (c) => write(c, { maxZoom: value }),
  });
}

// ── Falsy callbacks ────────────────────────────────────────────────────

// Upstream's drag runs its drag callbacks only when one of them is truthy,
// and then calls each that is not `null` or `undefined`.
for (const [label, value] of [
  ['0', 0],
  ['false', false],
  ['an empty string', ''],
]) {
  cases.push({
    name: `a node drag with onNodeDrag set to ${label}`,
    drive: async (c) => {
      c.seen.api.setState({
        onNodeDrag: value,
        onNodeDragStart: dragRecorder(c, 'onNodeDragStart'),
        onNodeDragStop: dragRecorder(c, 'onNodeDragStop'),
      });
      await c.settle();
      await drag(c, node(c.container, 'b'));
    },
  });
}

cases.push({
  name: 'a node drag with onNodeDragStart set to 0',
  drive: async (c) => {
    c.seen.api.setState({ onNodeDragStart: 0, onNodeDrag: dragRecorder(c, 'onNodeDrag') });
    await c.settle();
    await drag(c, node(c.container, 'b'));
  },
  omit: ['onNodeDrag', 'onNodeDragStart'],
});

// A connection calls `onConnectStart?.(…)`, `onConnect?.(…)` and
// `onConnectEnd?.(…)`, so a falsy one throws where it is called, and what the
// connection had done by then stays done.
for (const member of ['onConnectStart', 'onConnect', 'onConnectEnd']) {
  cases.push({
    name: `a connection with ${member} set to 0`,
    drive: async (c) => {
      const others = { onConnectStart: c.record('onConnectStart'), onConnect: c.record('onConnect'), onConnectEnd: c.record('onConnectEnd') };
      c.seen.api.setState({ ...others, [member]: 0 });
      await c.settle();
      await connect(c);
      await c.settle();
      const connection = c.seen.api.getState().connection;
      return { inProgress: connection.inProgress, from: connection.fromNode?.id ?? null };
    },
  });
}

// The edge queue reports its diff only when `onEdgesChange` is truthy.
for (const [label, value] of [
  ['false', false],
  ['0', 0],
]) {
  cases.push({
    name: `instance.setEdges with onEdgesChange set to ${label}`,
    drive: async (c) => {
      c.seen.api.setState({ onEdgesChange: value });
      c.seen.instance.setEdges((edges) => edges.slice(0, 1));
      await c.settle();
    },
  });
}

// The node queue calls `onNodesChange?.(changes)`, which throws for a falsy
// value that is not `null` or `undefined`.
cases.push({
  name: 'instance.setNodes with onNodesChange set to false',
  drive: async (c) => {
    c.seen.api.setState({ onNodesChange: false });
    c.seen.instance.setNodes((nodes) => nodes.slice(0, 2));
    await c.settle();
  },
  omit: ['onNodesChange'],
});

// An error's message names the expression that threw, which is a variable of
// each side's own code, and React's report of it carries each bundle's
// source positions. What is compared is where an error was printed, and its
// kind: the first line, with the callee's name left out.
const errorKind = (text) => text.split('\n')[0].replace(/\S+ is not a function/, 'a value is not a function');

for (const contract of cases) {
  contract.observe = (result) => ({
    ...result,
    console: result.console.map(({ level, text }) => ({ level, text: errorKind(text) })),
  });
}

export default cases;
