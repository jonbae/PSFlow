// A MiniMap over a flow whose every node is hidden (#5546, #5692).
//
// Both rows are crashes rather than differences: a minimap with no visible node
// has no bounds to compute, and an undefined node reaching the minimap's node
// renderer throws. A thrown render leaves no DOM and no callback — it is the
// `console` section, via `pageerror`, that carries it, which is the same
// section the two mount-time rows use and the reason it exists.
//
// Every node hidden, not merely an empty list: an empty `nodes` array is a flow
// that was never given anything, where this is a flow that has nodes and can
// show none of them. The two take different paths through the minimap.

export default {
  flowProps: {
    fitView: true,
    nodes: [
      { id: 'Node-1', data: { label: 'Node-1' }, position: { x: 0, y: 0 }, type: 'input', hidden: true },
      { id: 'Node-2', data: { label: 'Node-2' }, position: { x: -100, y: 100 }, hidden: true },
      { id: 'Node-3', data: { label: 'Node-3' }, position: { x: 100, y: 100 }, hidden: true },
    ],
    edges: [{ id: '1-2', source: 'Node-1', target: 'Node-2' }],
  },
  minimapProps: { pannable: true, zoomable: true },
};
