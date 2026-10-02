// A controlled `viewport` that changes after the flow has mounted (#93,
// ticket #128).
//
// ## The class
//
// d3 keeps a transform of its own, and a gesture starts from that one, not
// from the store's. Upstream's `useViewportSync` hands a controlled viewport
// to `panZoom.syncViewport` before it writes the store, so the two agree. A
// port that writes the store alone renders the new viewport and leaves d3
// where it was, and the next pan starts from there.
//
// ## Why nothing feeds the viewport back
//
// The driver hands a fixture no `onViewportChange` of its own, so this
// viewport is controlled and never follows a gesture. That is what makes the
// class visible. A pan still runs d3, and d3 reports its own transform to the
// observed `onMove` and `onViewportChange` while the rendered viewport stays
// put, so the `callbacks` section reads d3's transform directly. A viewport
// that followed the gesture would hide a stale d3 behind whatever the next
// render wrote.
//
// ## Why these numbers
//
// `defaultViewport` is the identity and the mount viewport is not, so even
// the mount has a sync to make: `<ZoomPane />` seeds d3 with
// `defaultViewport`, and only the sync moves it to the controlled value. The
// after-mount viewport changes all three components, the zoom included, so a
// sync that dropped one would show. Under both viewports the centre of the
// 1280x720 pane is empty, so a pan started there drags the pane and not a
// node.

import { edges, nodes } from '../shared/graph';

export default {
  flowProps: {
    nodes: nodes(),
    edges: edges(),
    defaultViewport: { x: 0, y: 0, zoom: 1 },
    viewport: { x: 100, y: 50, zoom: 1 },
  },
  afterMount: {
    viewport: { x: -200, y: 80, zoom: 1.5 },
  },
};
