import { Panel, useStoreApi } from '@xyflow/react';
import { installObservationLog } from '../../../../driver/observations.mjs';

// These are consumer inputs, shared unchanged by both bundles. The observation
// bridge invokes the action on the current getState() and records its arguments
// before the action can mutate them. Mounting this control records no call.
export function UnselectWitness() {
  const store = useStoreApi();
  const unselect = (kind: string) => {
    const state = store.getState();
    const args = kind === 'no-argument' ? [] : [
      kind === 'nodes' ? { nodes: [state.nodes[0]] } :
      kind === 'edges' ? { edges: [state.edges[0]] } : {},
    ];
    installObservationLog(window).callStore(store, 'unselectNodesAndEdges', args);
  };
  return <Panel position="top-left">
    {['no-argument', 'empty-options', 'nodes', 'edges'].map(kind =>
      <button key={kind} type="button" data-testid={`unselect-${kind}`} onClick={() => unselect(kind)}>
        unselect {kind}
      </button>
    )}
  </Panel>;
}
