import { edges, nodes } from '../shared/graph';
import { StoreStateWitness } from '../shared/DebtWitnesses';
export default {
  flowProps: { fitView: true, nodes: nodes(), edges: edges(), nodeDragThreshold: 0 },
  witness: StoreStateWitness,
  afterMount: { nodeClickDistance: 20 },
};
