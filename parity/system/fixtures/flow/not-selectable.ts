// A selection the consumer passed in, on a flow whose elements are not
// selectable (#93, ticket #141).
//
// ## The class
//
// Upstream's `resetSelectedElements` returns before it reads a node or an
// edge when `elementsSelectable` is false, so a pane click leaves a
// selection alone. Nothing the user does can select an element here, and the
// only selection is the one the consumer passed in. A port that resets
// anyway hands `onNodesChange` and `onEdgesChange` a deselection that the
// driver applies, and the node and edge render unselected.
//
// ## Why it is a fixture of its own
//
// `flow/props-change.ts` turns `elementsSelectable` off after mount, with a
// node selected by a click before the change. It could carry the class with a
// pane click added to `flow-props-change-after-mount`, but that scenario holds
// the StoreUpdater rows, and a new act would re-baseline every one of them.
// Here the flag is off from the mount, and the selection comes in on the
// controlled `nodes` and `edges`, which is the shape #141 names.
//
// One node and one edge are selected, because the reset walks the two
// separately and calls a handler for each.

import { edges, nodes } from '../shared/graph';

export default {
  flowProps: {
    fitView: true,
    nodes: nodes().map((node) => (node.id === 'Node-1' ? { ...node, selected: true } : node)),
    edges: edges().map((edge) => (edge.id === '1-2' ? { ...edge, selected: true } : edge)),
    elementsSelectable: false,
  },
};
