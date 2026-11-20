// A selected controlled graph makes both emitted changes and their applied
// selection observable. More than one selected node/edge distinguishes a
// supplied subset from the default (all nodes/all edges). One unselected node
// also makes an accidental change to the rest of the graph visible.
import { edges, nodes } from '../shared/graph';
import { UnselectWitness } from './components/UnselectWitness';

export default {
  flowProps: {
    fitView: true,
    nodes: nodes().map((node, i) => ({ ...node, selected: i < 3 })),
    edges: edges().map(edge => ({ ...edge, selected: true })),
  },
  witness: UnselectWitness,
};
