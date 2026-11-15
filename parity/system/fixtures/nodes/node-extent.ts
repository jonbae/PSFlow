// A finite `nodeExtent`, with two nodes selected so a drag takes both.
//
// Upstream's `XYDrag` keeps a drag of several nodes inside `nodeExtent` as a
// group: it narrows each node's extent by how far the group reaches past the
// node, so the pair stops as a whole and keeps the gap between them. Step 4
// row 9 found that ps-flow clamped each node to the extent on its own. No
// other fixture sets `nodeExtent`, so no scenario could see the difference.
//
// The extent leaves a little room on every side of the four nodes. `Node-1`
// and `Node-3` start selected, so dragging `Node-1` drags both. Auto-pan is
// off: the drag is about where the nodes stop, not about the viewport.

import { edges, nodes } from '../shared/graph';

const selected = new Set(['Node-1', 'Node-3']);

export default {
  flowProps: {
    fitView: true,
    nodes: nodes().map((node) => (selected.has(node.id) ? { ...node, selected: true } : node)),
    edges: edges(),
    nodeDragThreshold: 0,
    autoPanOnNodeDrag: false,
    nodeExtent: [
      [-120, -20],
      [280, 260],
    ],
  },
};
