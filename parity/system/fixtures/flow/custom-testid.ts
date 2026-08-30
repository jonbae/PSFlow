// `<ReactFlow data-testid>` (#4844).
//
// The scenario that drives this aims its one action **at the custom id**, so
// the driving log is the witness: the target resolves only if the attribute
// reached the rendered element, and an implementation that dropped it records
// an unresolved action rather than a quietly identical DOM.

import { edges, nodes } from '../shared/graph';

export default {
  flowProps: { fitView: true, nodes: nodes(), edges: edges(), 'data-testid': 'psflow-custom-flow' },
};
