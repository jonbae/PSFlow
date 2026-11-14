// Styles changed by #5139, #5153, #5252, #5259, #5362 and #5638.
// Both variable candidates are present, so the background precedence is live.
import { edges, nodes } from '../shared/graph';
import { styleWitness } from '../shared/DebtWitnesses';

export default {
  flowProps: { fitView: true, nodes: nodes(), edges: edges(), style: { '--xy-background-color': '#dd0000' } },
  backgroundProps: { bgColor: '#101820' },
  minimapProps: {},
  controlsProps: { orientation: 'horizontal' },
  panelProps: ['top-center', 'bottom-center', 'center-left', 'center-right'].map(position => ({ position, children: position })),
  witness: styleWitness({
    '.react-flow': ['--xy-minimap-mask-background-color-default'],
    '.react-flow__minimap-mask': ['fill'],
    '.react-flow__controls-button': ['border-right-width', 'border-bottom-width'],
    '.react-flow__panel': ['transform', 'pointer-events'],
    '[data-testid="nested-selection-panel"]': ['pointer-events'],
    '.react-flow__background': ['background-color'],
    '.react-flow__pane': ['touch-action'],
  }),
};
