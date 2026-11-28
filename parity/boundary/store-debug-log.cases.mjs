// `debug: true` after mount: the cases `store-debug-log.test.mjs` runs on both
// sides through `browser/harness.mjs`. A mount measures its nodes, and
// upstream's `updateNodeInternals` logs the measured changes before it hands
// them to `triggerNodeChanges`, which logs them again.
//
// Each case records `console.log` beside the change callbacks, in order, and
// reads back only those.

const listening = (c) => {
  const original = console.log;
  console.log = (...args) => c.record('console.log')(...args);
  c.restore = () => (console.log = original);
  return { onNodesChange: c.record('onNodesChange'), onEdgesChange: c.record('onEdgesChange') };
};

const clickNode = (c, id) => {
  const target = c.container.querySelector(`.react-flow__node[data-id="${id}"]`);
  const box = target.getBoundingClientRect();
  const at = { bubbles: true, cancelable: true, view: window, clientX: box.left + 5, clientY: box.top + 5 };
  target.dispatchEvent(new MouseEvent('mousedown', { ...at, buttons: 1 }));
  target.dispatchEvent(new MouseEvent('mouseup', at));
  target.dispatchEvent(new MouseEvent('click', at));
};

const callsOnly = (result) => ({ calls: result.calls, console: result.console });

const cases = [
  {
    name: 'a controlled mount measures and logs each change list twice',
    props: (c) => ({ debug: true, ...listening(c) }),
    after: (c) => c.restore(),
    observe: callsOnly,
  },
  {
    name: 'an uncontrolled mount measures and logs each change list twice',
    props: (c) => {
      const { nodes, edges } = c.graph();
      return { nodes: undefined, edges: undefined, defaultNodes: nodes, defaultEdges: edges, debug: true, ...listening(c) };
    },
    after: (c) => c.restore(),
    observe: callsOnly,
  },
  {
    name: 'a node click logs the selection changes',
    props: (c) => {
      const { nodes, edges } = c.graph();
      return { nodes: undefined, edges: undefined, defaultNodes: nodes, defaultEdges: edges, debug: true, ...listening(c) };
    },
    drive: async (c) => {
      clickNode(c, 'b');
      await c.frame();
    },
    after: (c) => c.restore(),
    observe: callsOnly,
  },
  {
    name: 'a mount without debug logs nothing',
    props: (c) => listening(c),
    after: (c) => c.restore(),
    observe: callsOnly,
  },
];

export default cases;
