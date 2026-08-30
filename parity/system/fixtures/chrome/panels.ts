// Two panels at once — `top-center` and `bottom-center`.
//
// `panel-center-positions` (#5252) is a claim about centring, and centring is
// only visible against the thing it is centred in: one panel proves its own
// left offset is *some* number. Two, on opposite edges, are the same
// computation twice and disagree the moment it is wrong in one direction only.
// The driver renders one `<Panel>` per entry, which is why this is a list.
//
// It also carries the flow `selection-box-mid-gesture` (#5362) drives: that row
// is about a Panel's pointer events while a selection is being dragged, so a
// pane with no panel on it could not show the difference either way.

import { edges, nodes } from '../shared/graph';

export default {
  flowProps: { fitView: true, nodes: nodes(), edges: edges() },
  panelProps: [
    { position: 'top-center', children: 'top centre' },
    { position: 'bottom-center', children: 'bottom centre' },
  ],
};
