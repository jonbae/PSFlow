// `defaultEdgeOptions` over edges that declare none of what it sets.
//
// The options have no DOM of their own; they are merged into each edge as
// `{ ...defaultEdgeOptions, ...edge }`. So the witness is the merge's result: a
// smoothstep edge carrying the class only the options give it. One edge declares
// its own type and class, and the merge must keep both, which is the half of the
// spread a port that copied the options wholesale would get wrong.
//
// Runtime defaults also include keys outside upstream's `DefaultEdgeOptions`
// type: pathOptions changes the bends, selected changes the class and stacking,
// and custom keys reach edge callbacks unless the edge supplies its own value.

export default {
  flowProps: {
    fitView: true,
    defaultEdgeOptions: {
      type: 'smoothstep',
      className: 'from-default-edge-options',
      animated: true,
      label: 'default',
      markerEnd: { type: 'arrowclosed' },
      style: { strokeWidth: 2 },
      pathOptions: { offset: 42, borderRadius: 0 },
      selected: true,
      owner: 'defaults',
      defaultOnly: 'from-options',
    },
    // `owner` is a key no type declares. Upstream hands an edge handler the
    // merged edge and a node handler a copy of the node, and both keep it.
    nodes: [
      { id: 'Node-1', data: { label: 'Node-1' }, position: { x: 0, y: 0 }, type: 'input', owner: 'consumer' },
      { id: 'Node-2', data: { label: 'Node-2' }, position: { x: -140, y: 160 }, owner: 'consumer' },
      { id: 'Node-3', data: { label: 'Node-3' }, position: { x: 140, y: 160 } },
      { id: 'Node-4', data: { label: 'Node-4' }, position: { x: 0, y: 320 }, type: 'output' },
    ],
    edges: [
      { id: '1-2', source: 'Node-1', target: 'Node-2', owner: 'consumer' },
      { id: '1-3', source: 'Node-1', target: 'Node-3' },
      { id: '2-4', source: 'Node-2', target: 'Node-4', type: 'straight', className: 'own-class', label: 'own' },
    ],
  },
};
