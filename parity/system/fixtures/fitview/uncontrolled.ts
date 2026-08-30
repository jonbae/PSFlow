// An uncontrolled flow with no change handlers at all (#5120, #5127, #5132).
//
// One fixture for three rows, and the vendored store is why. `fitView: true`
// queues a fit that has to be resolved once the nodes have been measured, and
// upstream used to resolve it only in `setNodes` — the path a *consumer* drives
// by feeding changes back. All three rows are the same absence from three
// directions: an uncontrolled flow has no consumer to feed anything back
// (#5120); a consumer whose `onNodesChange` returns early feeds nothing back
// (#5127); a consumer with no `onNodesChange` was never asked (#5132). The fix
// is one line in `store/index.ts` — `updateNodeInternals` resolves the queued
// fit too — and it is on the path all three take.
//
// So the flow is uncontrolled: `defaultNodes` and `defaultEdges` with no
// `nodes` prop, which is how the driver decides not to install change handlers
// at all. From the store's side that is the second condition as well as the
// first — nothing calls `setNodes` after the mount, so the queued fit has to be
// resolved by `updateNodeInternals` or not at all.
//
// One caveat worth writing down rather than leaving to be rediscovered: the net
// observes callbacks by installing **every** prop upstream declares, so from
// `<ReactFlow>`'s own point of view `onNodesChange` is never literally
// undefined here — an observing wrapper is always there, recording the call and
// deferring to a handler that is not. #5132's literal condition is therefore
// out of reach of this harness, and what is driven is the store path it shares
// with #5127: a handler that changes nothing.
//
// It is also what `uncontrolled-update-node` (#5249) drives, and for a reason
// that belongs to this fixture rather than to that scenario: `updateNode` on an
// uncontrolled flow has to raise `onNodesChange` itself, because there is no
// prop for the caller to have changed.

import { edges, nodes } from '../shared/graph';

export default {
  flowProps: {
    fitView: true,
    defaultNodes: nodes(),
    defaultEdges: edges(),
    nodeDragThreshold: 0,
  },
};
