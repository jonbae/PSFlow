// A MiniMap given every colour it takes (#5139 — `rgba` rather than `rgb` for a
// mask colour carrying opacity).
//
// The mask colour is deliberately one **with** an alpha channel: that is the
// case the row is about, and a fully opaque colour would round-trip through
// either spelling identically and prove nothing. `MiniMap.purs` emits these as
// inline CSS custom properties, so they land in the `dom` section as authored
// text rather than as anything a stylesheet resolves — which is why ticket 079's
// reading of this row as stylesheet-only was wrong.

import { edges, nodes } from '../shared/graph';

export default {
  flowProps: { fitView: true, nodes: nodes(), edges: edges() },
  minimapProps: {
    maskColor: 'rgba(240, 100, 20, 0.35)',
    maskStrokeColor: 'rgba(10, 20, 30, 0.8)',
    maskStrokeWidth: 2,
    nodeColor: () => '#ff0072',
    nodeStrokeColor: () => '#1a192b',
    nodeBorderRadius: 4,
    bgColor: '#eef2ff',
  },
};
