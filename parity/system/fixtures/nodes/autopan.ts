// A drag that reaches the pane edge and starts the viewport panning itself
// (#5450 — `onNodeDrag` keeps being called while autopan is ongoing).
//
// ## Why this fixture exists rather than a plain drag
//
// Autopan runs on `requestAnimationFrame` and calls `onNodeDrag` once per frame
// that actually pans. Left unbounded it never stops: the viewport keeps moving
// for as long as the pointer is held near the edge, so the page never settles,
// and how far it got would be a function of elapsed frames — which the net
// records nowhere and each side reaches on its own clock. That is exactly why
// the conformance seed **declined** upstream's two autoPan specs (#55): they
// hold the pointer for 500ms and assert the viewport moved, and a scenario
// lifted from them could not reproduce itself across its own two captures.
//
// A `translateExtent` is what makes the behaviour observable without a clock.
// The pan is bounded, so autopan runs until it reaches the boundary and then
// `panBy` reports that nothing moved, `onNodeDrag` stops being called, and the
// viewport settles — at the boundary, which is the same place however many
// frames it took to get there. The **end state is a function of the extent
// rather than of elapsed time**, which is the property every scenario in the
// corpus needs and the one the upstream specs could not have.
//
// `autoPanSpeed` is far above its default of 15 for the same reason from the
// other end: a fast pan spends fewer frames in the region where the count of
// `onNodeDrag` calls is still growing, so the callback sequence is short and
// reproducible rather than long and nearly so. The extent is well wider than
// the 1280x720 window the net runs in, so there is real panning to do before
// there is an end to it.
//
// Measured against this fixture, upstream reaches the boundary within one frame
// and holds there. ps-flow's viewport clamps with it and its **node does not**:
// the dragged node keeps moving for as long as the pointer is held, thousands
// of pixels a second, which is what a frame loop that updates node positions
// whether or not the pan actually moved looks like from outside. That is a real
// divergence of the kind this fixture exists to find, and it is also why the
// scenario releases the pointer instead of settling on it.

export default {
  flowProps: {
    nodeDragThreshold: 0,
    autoPanOnNodeDrag: true,
    autoPanSpeed: 400,
    translateExtent: [
      [-2000, -2000],
      [2000, 2000],
    ],
    defaultViewport: { x: 0, y: 0, zoom: 1 },
    nodes: [
      { id: 'Node-1', data: { label: 'Node-1' }, position: { x: 0, y: 0 }, type: 'input' },
      { id: 'Node-2', data: { label: 'Node-2' }, position: { x: -100, y: 100 } },
      { id: 'Node-3', data: { label: 'Node-3' }, position: { x: 100, y: 100 } },
    ],
    edges: [
      { id: '1-2', source: 'Node-1', target: 'Node-2' },
      { id: '1-3', source: 'Node-1', target: 'Node-3' },
    ],
  },
};
