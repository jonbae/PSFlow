// A snapping flow with settled query observations for #5012 and #5722.
// ViewportQueries samples the inherited store grid, an explicit disabled snap,
// and a distinct custom grid. The mutator scenarios separately exercise #5723
// with non-default interpolation over multiple frames.

import { ViewportQueries } from '../shared/DebtWitnesses';
export default {
  witness: ViewportQueries,
  flowProps: {
    fitView: true,
    minZoom: 0.1,
    maxZoom: 8,
    snapToGrid: true,
    snapGrid: [25, 25],
    nodes: [
      { id: '1', data: { label: '1' }, position: { x: 0, y: 0 }, type: 'input' },
      { id: '2', data: { label: '2' }, position: { x: -260, y: 240 } },
      { id: '3', data: { label: '3' }, position: { x: 260, y: 240 } },
      { id: '4', data: { label: '4' }, position: { x: 0, y: 520 }, type: 'output' },
    ],
    edges: [
      { id: 'first-edge', source: '1', target: '2' },
      { id: 'second-edge', source: '1', target: '3' },
      { id: 'third-edge', source: '2', target: '4' },
    ],
  },
};
