// A `translateExtent` that narrows after the flow has mounted (#93, ticket #105).
//
// ## Why this fixture exists rather than a prop on `props-change.ts`
//
// `flow/props-change.ts` already changes `minZoom` and `maxZoom` after mount,
// and its rows are the sharpest StoreUpdater concentration in the corpus. Adding
// a `translateExtent` to it would re-baseline that reading to cover a different
// class, so the pan half gets its own flow and the zoom half stays where it is.
//
// ## Why the extent narrows rather than widens
//
// The class under test is a limit that never left the store. `SetTranslateExtent`
// wrote state and returned no effect until #103, so `createXYPanZoom`'s
// mount-time extent was the only one d3 ever held, and a flow that changed the
// prop afterwards kept panning against the old bound. A **widened** extent
// cannot show that: the old bound is the tighter one, so a pan clamped by it
// looks the same whether or not the new value arrived. Narrowing inverts it —
// the new bound is the one that bites, and a viewport that ignores it pans
// straight past.
//
// ## Why these numbers
//
// The net runs in 1280x720. The mount extent is wider than the window in both
// axes, so the first pan is free and the pan the scenario drives is not being
// refused for a reason that predates the control. The after-mount extent is
// **narrower than the window**, which is what makes the end state a function of
// the extent rather than of the gesture: d3 has to fit a 400x400 region into a
// 1280x720 viewport, so there is exactly one transform that satisfies it and the
// pointer cannot move the viewport off it however far it travels. The same
// property `nodes/autopan.ts` gets from saturation, without needing a clock.
//
// The nodes are the shared graph so the `dom` section has something to compare,
// and `defaultViewport` is the identity so the pan starts from a known place
// rather than from whatever `fitView` chose.

import { edges, nodes } from '../shared/graph';

export default {
  flowProps: {
    nodes: nodes(),
    edges: edges(),
    defaultViewport: { x: 0, y: 0, zoom: 1 },
    translateExtent: [
      [-4000, -4000],
      [4000, 4000],
    ],
  },
  afterMount: {
    translateExtent: [
      [-200, -200],
      [200, 200],
    ],
  },
};
