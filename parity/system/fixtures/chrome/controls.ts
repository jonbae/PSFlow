// Controls laid out horizontally (#5153 — separators between the buttons).
//
// The orientation is the whole fixture: upstream's four fixtures never set
// `controlsProps` at all, so the vertical default is what every other trace in
// the corpus records and the horizontal one has no witness anywhere else.

import { edges, nodes } from '../shared/graph';

export default {
  flowProps: { fitView: true, nodes: nodes(), edges: edges() },
  controlsProps: { orientation: 'horizontal' },
};
