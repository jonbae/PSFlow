import { edges, nodes } from '../shared/graph';
export default {
  flowProps: { nodes: nodes(), edges: edges() },
  nodeChanges: 'absent',
  omitObservedCallbacks: ['onNodesChange'],
};
