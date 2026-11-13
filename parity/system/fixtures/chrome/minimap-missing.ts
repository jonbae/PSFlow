import { edges, nodes } from '../shared/graph';
import { MissingMiniMapNodeWitness } from '../shared/DebtWitnesses';
export default {
  flowProps: { fitView: true, nodes: nodes(), edges: edges() },
  minimapProps: {},
  witness: MissingMiniMapNodeWitness,
};
