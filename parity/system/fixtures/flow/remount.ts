import { edges, nodes } from '../shared/graph';
import { StoreTimingWitness, StoreReaderNode } from '../shared/DebtWitnesses';
export default {
  flowProps: { nodes: nodes().map(n => ({ ...n, type: 'reader' })), edges: edges(), minZoom: 0.2, nodeTypes: { reader: StoreReaderNode } },
  afterMount: { key: 'second-flow' },
  persistentProvider: true,
  witness: StoreTimingWitness,
};
