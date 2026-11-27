// Structured store members written with a value of the wrong shape, used
// after the write: the cases `store-unreadable.test.mjs` runs on both sides
// through `browser/harness.mjs`.
//
// Upstream's store holds whatever `setState` is handed, so `nodes: 'x'` is
// the string `'x'` everywhere its code reads `nodes`, and each read does to
// it what JavaScript does: `.map` throws, `for…of` walks its characters, a
// default parameter replaces `undefined`. Each case writes one such value into
// one member of an uncontrolled flow and then runs a list of steps, recording
// what each returned or the kind of error it threw, which callbacks fired, what
// was printed, and what the store and the DOM hold at the end.
import { Component } from 'react';
import { click, connect, drag, node, pane, pressKey } from './browser/gestures.mjs';

const common = [
  ['a string', () => 'x'],
  ['a number', () => 5],
  ['null', () => null],
  ['undefined', () => undefined],
  ['an empty object', () => ({})],
];

// Each member, with the values its converter rejects.
const members = {
  nodes: [...common, ['a Map', () => new Map()], ['an array holding null', () => [null]]],
  edges: [...common, ['a Map', () => new Map()], ['an array holding null', () => [null]]],
  onSelectionChangeHandlers: [...common, ['a Map', () => new Map()], ['an array holding null', () => [null]]],
  nodeLookup: [...common, ['an array', () => []], ['a Set', () => new Set()]],
  parentLookup: [...common, ['an array', () => []], ['a Set', () => new Set()]],
  edgeLookup: [...common, ['an array', () => []], ['a Set', () => new Set()]],
  connectionLookup: [...common, ['an array', () => []], ['a Set', () => new Set()]],
  onNodesChangeMiddlewareMap: [...common, ['an array', () => []], ['a Set', () => new Set()]],
  onEdgesChangeMiddlewareMap: [...common, ['an array', () => []], ['a Set', () => new Set()]],
  transform: [...common, ['a Map', () => new Map()]],
  translateExtent: [...common, ['an empty array', () => []], ['a one-item array', () => [1]]],
  nodeExtent: [...common, ['an empty array', () => []], ['a one-item array', () => [1]]],
  nodeOrigin: [...common, ['an empty array', () => []], ['a one-item array', () => [1]]],
  snapGrid: [...common, ['an empty array', () => []], ['a one-item array', () => [1]]],
  connection: [
    ['null', () => null],
    ['undefined', () => undefined],
    ['in progress and nothing else', () => ({ inProgress: true })],
  ],
  connectionClickStartHandle: [
    ['a string', () => 'x'],
    ['a number', () => 5],
    ['an empty object', () => ({})],
  ],
  ariaLabelConfig: [
    ['null', () => null],
    ['undefined', () => undefined],
  ],
};

const ids = (list) => list.map((item) => item.id);

// An uncontrolled flow, so a change the store applies shows in its nodes,
// with recorders for the callbacks a step can fire.
const flow = (extra = {}) => ({ graph, record }) => {
  const { nodes, edges } = graph();
  return {
    nodes: undefined,
    edges: undefined,
    defaultNodes: nodes,
    defaultEdges: edges,
    onNodesChange: record('onNodesChange'),
    onEdgesChange: record('onEdgesChange'),
    onConnect: record('onConnect'),
    onDelete: ({ nodes: n, edges: e }) => record('onDelete')(ids(n), ids(e)),
    onNodeClick: (_event, n) => record('onNodeClick')(n.id),
    onPaneClick: () => record('onPaneClick')(),
    ...extra,
  };
};

// What a hook returned, in a word: the DOM carries it, so a hook that
// renders more often on one side records nothing twice.
const summary = (value) => {
  if (Array.isArray(value)) return `array(${value.length})`;
  if (value === null || value === undefined) return String(value);
  if (typeof value === 'object') return `object(${Object.keys(value).sort().join(',')})`;
  return `${typeof value}(${String(value)})`;
};

// Each hook in its own component under its own error boundary, so one that
// throws leaves the others to be read.
class Boundary extends Component {
  constructor(props) {
    super(props);
    this.state = { error: null };
  }
  static getDerivedStateFromError(error) {
    return { error };
  }
  render() {
    const { error } = this.state;
    if (error) return this.props.h('span', { 'data-hook': this.props.name }, `threw ${error?.constructor?.name}`);
    return this.props.children;
  }
}

const hookProbes = ({ h, library, record, seen }) => {
  const probe = (name, use) => {
    function Probe() {
      return h('span', { 'data-hook': name }, summary(use()));
    }
    return h(Boundary, { key: name, name, h }, h(Probe));
  };
  return [
    probe('useNodes', () => library.useNodes()),
    probe('useEdges', () => library.useEdges()),
    probe('useViewport', () => library.useViewport()),
    probe('useNodesData', () => library.useNodesData('a')),
    probe('useInternalNode', () => library.useInternalNode('a')),
    probe('useNodesInitialized', () => library.useNodesInitialized()),
    probe('useConnection', () => library.useConnection()),
    probe('useNodeConnections', () => library.useNodeConnections({ id: 'a' })),
    probe('useHandleConnections', () => library.useHandleConnections({ type: 'source', nodeId: 'a' })),
    probe('useOnSelectionChange', () => {
      library.useOnSelectionChange({ onChange: ({ nodes: n, edges: e }) => record('onSelectionChange hook')(ids(n), ids(e)) });
      return null;
    }),
    probe('useUpdateNodeInternals', () => {
      seen.updateNodeInternals = library.useUpdateNodeInternals();
      return null;
    }),
  ];
};

// The groups of steps, each run after the write.
const groups = {
  // A render with the components that read the store beside the flow's own,
  // and the instance's readers.
  readers: {
    props: flow({ onSelectionChange: () => {} }),
    children: ({ h, library }) => [
      h(library.MiniMap, { key: 'minimap' }),
      h(library.Controls, { key: 'controls' }),
      h(library.Background, { key: 'background' }),
    ],
    steps: [
      ['getNodes', (c) => c.seen.instance.getNodes()],
      ['getEdges', (c) => c.seen.instance.getEdges()],
      ['toObject', (c) => c.seen.instance.toObject()],
      ['getNode', (c) => c.seen.instance.getNode('a')],
      ['getInternalNode', (c) => c.seen.instance.getInternalNode('a')],
      ['getEdge', (c) => c.seen.instance.getEdge('a-b')],
      ['getViewport', (c) => c.seen.instance.getViewport()],
      ['getZoom', (c) => c.seen.instance.getZoom()],
      ['getNodesBounds', (c) => c.seen.instance.getNodesBounds(['a', 'b'])],
      ['getIntersectingNodes', (c) => c.seen.instance.getIntersectingNodes({ id: 'a' })],
      ['getHandleConnections', (c) => c.seen.instance.getHandleConnections({ type: 'source', nodeId: 'a' })],
      ['screenToFlowPosition', (c) => c.seen.instance.screenToFlowPosition({ x: 100, y: 100 })],
    ],
  },
  // Pointer and keyboard input on the flow.
  input: {
    props: flow(),
    steps: [
      ['pane click', (c) => click(pane(c.container))],
      ['node click', (c) => click(node(c.container, 'b'))],
      ['node drag', (c) => drag(c, node(c.container, 'b'))],
      ['connection', (c) => connect(c)],
      ['Backspace', (c) => pressKey(c, 'Backspace')],
      ['selection box', (c) => drag(c, pane(c.container), { from: { x: 700, y: 500 }, dx: -120, dy: -90, modifiers: { shiftKey: true } })],
    ],
  },
  // The hooks a consumer reads the store through, and the writes that
  // reach them.
  hooks: {
    props: flow(),
    children: hookProbes,
    steps: [
      ['addSelectedNodes', (c) => c.seen.api.getState().addSelectedNodes(['a'])],
      ['updateNodeInternals', (c) => c.seen.updateNodeInternals('a')],
    ],
  },
  // The instance's and the store's writing actions.
  actions: {
    props: flow(),
    steps: [
      ['setNodes with an updater', (c) => c.seen.instance.setNodes((current) => (c.record('setNodes received')(current), current))],
      ['setEdges with an updater', (c) => c.seen.instance.setEdges((current) => (c.record('setEdges received')(current), current))],
      ['addSelectedNodes', (c) => c.seen.api.getState().addSelectedNodes(['a'])],
      ['unselectNodesAndEdges', (c) => c.seen.api.getState().unselectNodesAndEdges()],
      ['resetSelectedElements', (c) => c.seen.api.getState().resetSelectedElements()],
      ['updateNode', (c) => c.seen.instance.updateNode('a', { data: { label: 'A2' } })],
      ['fitView', (c) => c.seen.instance.fitView()],
      ['zoomIn', (c) => c.seen.instance.zoomIn({ duration: 0 })],
      ['setCenter', (c) => c.seen.instance.setCenter(10, 10, { duration: 0 })],
      ['deleteElements', (c) => c.seen.instance.deleteElements({ nodes: [{ id: 'b' }] })],
      ['addNodes', (c) => c.seen.instance.addNodes({ id: 'd', position: { x: 300, y: 300 }, data: { label: 'D' } })],
    ],
  },
};

// The kind of an error, without the expression that threw, which names a
// variable of each side's own code.
const kindOf = (error) => error?.constructor?.name ?? typeof error;

// A step's promise that has not settled within `patience` is recorded as
// pending: a fit or a zoom over a store that cannot be read may never settle.
const patience = 200;
const pending = Symbol('pending');

const run = async (c, steps) => {
  const outcomes = [];
  for (const [label, step] of steps) {
    try {
      const value = await Promise.race([step(c), c.sleep(patience).then(() => pending)]);
      if (value === pending) outcomes.push([label, 'pending']);
      else outcomes.push([label, 'returned', value === undefined ? null : value]);
    } catch (error) {
      outcomes.push([label, 'threw', kindOf(error)]);
    }
    await c.settle();
  }
  return outcomes;
};

const cases = [];

// A falsification probe: the two sides write different values, so the test
// requires this case to differ.
cases.push({
  name: 'falsification: the sides write different values',
  props: flow(),
  drive: async (c) => {
    c.seen.api.setState({ nodes: c.side === 'psflow' ? 'x' : 5 });
    await c.settle();
    return run(c, groups.actions.steps.slice(0, 1));
  },
});

// The steps with nothing written, which both sides take alike.
for (const [group, { props, children, steps }] of Object.entries(groups)) {
  cases.push({ name: `nothing written: ${group}`, props, children, drive: (c) => run(c, steps) });
}

for (const [member, values] of Object.entries(members)) {
  for (const [label, value] of values) {
    for (const [group, { props, children, steps }] of Object.entries(groups)) {
      cases.push({
        name: `${member} set to ${label}: ${group}`,
        props,
        children,
        drive: async (c) => {
          c.seen.api.setState({ [member]: value() });
          await c.settle();
          return run(c, steps);
        },
      });
    }
  }
}

// What was printed, by where it was printed and the error's kind: React's
// report of a render error names each side's component and carries each
// bundle's source positions. React reports a render error once for each
// component that threw, and each side's components are its own, so what is
// compared is which kinds were printed where, not how many times.
const printedKind = (text) => {
  const first = text.split('\n')[0];
  if (/^The above error occurred in/.test(first)) return 'React reported a component error';
  const error = first.match(/\b([A-Z]\w*Error)\b/);
  return error ? error[1] : first;
};

for (const contract of cases) {
  contract.observe = (result) => ({
    ...result,
    console: [...new Set(result.console.map(({ level, text }) => `${level}: ${printedKind(text)}`))].sort(),
  });
}

export default cases;
