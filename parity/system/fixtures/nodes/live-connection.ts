import { DetachedNode, ConnectionWitness } from '../shared/DebtWitnesses';
export default {
  flowProps: {
    nodes: [
      { id: 'source', type: 'detached', position: { x: 200, y: 100 }, data: { label: 'source' } },
      { id: 'target', type: 'detached', position: { x: 500, y: 400 }, data: { label: 'target' } },
    ], edges: [], nodeTypes: { detached: DetachedNode }, nodeDragThreshold: 0, autoPanOnConnect: false,
  }, witness: ConnectionWitness,
};
