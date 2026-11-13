// A child that pushes its parent open as it is dragged (#5043 — read the
// *current* `expandParent`, so it can be changed mid-drag).
//
// `debt-live-expand-parent` presses e during a drag. The consumer witness
// updates the child's expandParent flag through the public instance; later
// drag steps must consult that current node. The older growth-only scenario
// retains the constant flag and cannot distinguish the two implementations.
// No parent extent is set: clamping would prevent expansion altogether.

import { ExpandParentWitness } from '../shared/DebtWitnesses';
export default {
  witness: ExpandParentWitness,
  flowProps: {
    fitView: true,
    nodeDragThreshold: 0,
    nodes: [
      {
        id: 'parent',
        data: { label: 'parent' },
        position: { x: 0, y: 0 },
        style: { width: 320, height: 220, backgroundColor: 'rgba(80, 120, 200, 0.12)' },
      },
      {
        id: 'child',
        data: { label: 'child' },
        position: { x: 40, y: 40 },
        parentId: 'parent',
        expandParent: true,
      },
      { id: 'outside', data: { label: 'outside' }, position: { x: 420, y: 0 } },
    ],
    edges: [{ id: 'child-outside', source: 'child', target: 'outside' }],
  },
};
