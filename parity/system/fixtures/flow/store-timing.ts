import { edges, nodes } from '../shared/graph';
import { StoreTimingWitness } from '../shared/DebtWitnesses';
export default {
  flowProps: { nodes: nodes(), edges: edges(), minZoom: 0.5, ariaLabelConfig: { 'controls.zoomIn.ariaLabel': 'initial zoom' } },
  afterMount: { minZoom: 0.2, ariaLabelConfig: { 'controls.zoomOut.ariaLabel': 'changed zoom' } },
  witness: StoreTimingWitness,
  controlsProps: {},
};
