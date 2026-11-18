// Issues #207 and #208, through the same mounted JavaScript API on both sides.
import { useRef } from 'react';

const nodes = () => [{ id: 'a', position: { x: 0, y: 0 }, data: { label: 'A' } }];
const selected = (c) => ({
  internal: c.seen.api.getState().nodeLookup.get('a').selected,
  user: c.seen.api.getState().nodes[0].selected,
  drawn: c.container.querySelector('.react-flow__node[data-id="a"]').classList.contains('selected'),
});

const cases = [];
for (const handler of [false, true]) {
  cases.push({
    name: `selection: an ignored controlled change, ${handler ? 'with' : 'without'} onNodesChange`,
    props: (c) => ({ nodes: nodes(), edges: [], ...(handler ? { onNodesChange: c.record('onNodesChange') } : {}) }),
    async drive(c) {
      const before = c.seen.api.getState().nodeLookup.get('a');
      const lookup = c.seen.api.getState().nodeLookup;
      const internals = before.internals;
      const steps = [{ step: 'mount', ...selected(c) }];
      c.seen.api.getState().addSelectedNodes(['a']);
      await c.settle();
      steps.push({ step: 'select without applying the change', ...selected(c), same: c.seen.api.getState().nodeLookup.get('a') === before, retainedSelected: before.selected,
        sameLookup: c.seen.api.getState().nodeLookup === lookup, sameInternals: before.internals === internals });
      c.seen.api.setState({ nodesSelectionActive: false });
      await c.settle();
      steps.push({ step: 'notify about another member', ...selected(c), same: c.seen.api.getState().nodeLookup.get('a') === before, retainedSelected: before.selected,
        sameLookup: c.seen.api.getState().nodeLookup === lookup, sameInternals: before.internals === internals });
      c.seen.api.getState().setNodes(nodes().map((n) => ({ ...n, selected: true })));
      await c.settle();
      steps.push({ step: 'apply a new user node', ...selected(c), same: c.seen.api.getState().nodeLookup.get('a') === before });
      return steps;
    },
    observe: ({ driven, calls }) => ({ driven, calls }),
  });
}

cases.push({
  name: 'selection: Backspace after selecting a controlled node',
  props: () => ({ nodes: nodes(), edges: [] }),
  async drive(c) {
    c.seen.api.getState().addSelectedNodes(['a']);
    await c.settle();
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Backspace', code: 'Backspace', bubbles: true }));
    await c.frame();
    document.dispatchEvent(new KeyboardEvent('keyup', { key: 'Backspace', code: 'Backspace', bubbles: true }));
    await c.settle();
    return selected(c);
  },
  observe: ({ driven }) => driven,
});

// The other store actions that write selected in place must keep the node
// reference too, including the inverse transition from selected to unselected.
for (const action of ['addSelectedEdges', 'unselectNodesAndEdges']) {
  cases.push({
    name: `selection: ${action} followed by another notification`,
    props: () => ({ nodes: nodes().map((n) => ({ ...n, selected: true })), edges: [{ id: 'aa', source: 'a', target: 'a' }] }),
    async drive(c) {
      const before = c.seen.api.getState().nodeLookup.get('a');
      const lookup = c.seen.api.getState().nodeLookup;
      const internals = before.internals;
      if (action === 'addSelectedEdges') c.seen.api.getState().addSelectedEdges(['aa']);
      else c.seen.api.getState().unselectNodesAndEdges();
      await c.settle();
      c.seen.api.setState({ nodesSelectionActive: false });
      await c.settle();
      return { ...selected(c), retainedSelected: before.selected, same: c.seen.api.getState().nodeLookup.get('a') === before,
        sameLookup: c.seen.api.getState().nodeLookup === lookup, sameInternals: before.internals === internals };
    },
    observe: ({ driven }) => driven,
  });
}

cases.push({
  name: 'selection: click then Shift-click with ignored changes',
  props: () => ({ nodes: [...nodes(), { id: 'b', position: { x: 200, y: 0 }, data: { label: 'B' } }], edges: [], selectNodesOnDrag: false, multiSelectionKeyCode: 'Shift' }),
  async drive(c) {
    const click = (id, shiftKey = false) => c.container.querySelector(`.react-flow__node[data-id="${id}"]`)
      .dispatchEvent(new MouseEvent('click', { bubbles: true, view: window, shiftKey }));
    click('a');
    await c.settle();
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Shift', code: 'ShiftLeft', bubbles: true }));
    await c.frame();
    click('b', true);
    await c.settle();
    document.dispatchEvent(new KeyboardEvent('keyup', { key: 'Shift', code: 'ShiftLeft', bubbles: true }));
    await c.settle();
    return selected(c);
  },
  observe: ({ driven }) => driven,
});

for (const mode of ['controlled', 'uncontrolled', 'no edges', 'sized', 'NaN click distance']) {
  cases.push({
    name: `custom node: ${mode}`,
    props(c) {
      function Counted({ data }) {
        const renders = useRef(0);
        renders.current++;
        return c.h('div', { className: 'render-count', 'data-renders': renders.current, style: { width: 100, height: 40 } }, data.label);
      }
      const graph = nodes().map((n) => ({ ...n, type: 'counted', ...(mode === 'sized' ? { width: 100, height: 40 } : {}) }));
      const edges = mode === 'no edges' ? [] : [{ id: 'aa', source: 'a', target: 'a' }];
      return {
        nodeTypes: { counted: Counted },
        ...(mode === 'NaN click distance' ? { nodeClickDistance: NaN } : {}),
        ...(mode === 'uncontrolled' ? { nodes: undefined, edges: undefined, defaultNodes: graph, defaultEdges: edges } : { nodes: graph, edges }),
      };
    },
    async drive(c) {
      const read = () => ({ renders: Number(c.container.querySelector('.render-count').dataset.renders), label: c.container.querySelector('.render-count').textContent });
      const steps = [read()];
      c.seen.api.getState().setNodes(c.seen.api.getState().nodes.map((n) => ({ ...n, data: { label: 'updated' } })));
      await c.settle();
      steps.push(read());
      return steps;
    },
    observe: ({ driven }) => driven,
  });
}

export default cases;
