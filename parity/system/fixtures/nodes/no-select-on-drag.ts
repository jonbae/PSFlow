// `selectNodesOnDrag: false` (#5682 — no unnecessary updates under it).
//
// Upstream's fixtures never set it, so the default is what every trace in the
// corpus records. The row is about updates that should *not* happen, and an
// update that does not happen has no DOM residue at all: what carries it is the
// `callbacks` section's exact sequence, where a superfluous selection change
// appears as a call the other side did not make.
//
// `nodeDragThreshold: 0` is upstream's own setting in `nodes/general.ts`, kept
// so a drag here starts on the same event a lifted drag does.

import { edges, nodes } from '../shared/graph';

export default {
  flowProps: {
    fitView: true,
    nodes: nodes(),
    edges: edges(),
    nodeDragThreshold: 0,
    selectNodesOnDrag: false,
  },
};
