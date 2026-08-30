// Flow props that change after the flow has mounted (#5769, #5733, #5368).
//
// The three StoreUpdater rows are the sharpest concentration in the corpus and
// they are all about *timing*: which effect copies a changed prop into the
// store, and in what order relative to the render that reads it. ps-flow
// diverges structurally here — one `useEffect` per tracked prop against
// upstream's single effect over a field list (`StoreUpdater.purs:5-8`) — which
// is exactly the divergence those rows could perturb.
//
// So what is changed is a **spread of tracked fields at once**, not one: a
// single field cannot show an ordering difference, because there is no second
// thing for it to be ordered against. Each is also chosen to be *visible* —
// every one of them changes the DOM, a callback, or both — since a tracked
// field whose new value renders identically would prove the effect ran and
// nothing about when.
//
// These rows are reachable only because callbacks compare as an exact sequence:
// order, count and interleaving. A weakening in `weakenings.json` against any
// of the handlers below would make all three invisible.

import { edges, nodes } from '../shared/graph';

export default {
  flowProps: {
    fitView: true,
    nodes: nodes(),
    edges: edges(),
    minZoom: 0.5,
    maxZoom: 2,
    nodesDraggable: true,
    nodesConnectable: true,
    elementsSelectable: true,
    elevateNodesOnSelect: true,
    connectionMode: 'strict',
    snapToGrid: false,
    snapGrid: [1, 1],
    autoPanOnNodeDrag: true,
    autoPanOnConnect: true,
    nodeDragThreshold: 0,
    connectionRadius: 20,
  },
  afterMount: {
    minZoom: 0.1,
    maxZoom: 8,
    nodesDraggable: false,
    nodesConnectable: false,
    elementsSelectable: false,
    elevateNodesOnSelect: false,
    connectionMode: 'loose',
    snapToGrid: true,
    snapGrid: [25, 25],
    autoPanOnNodeDrag: false,
    autoPanOnConnect: false,
    nodeDragThreshold: 5,
    connectionRadius: 60,
  },
};
