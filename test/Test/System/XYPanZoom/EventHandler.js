"use strict";

// A d3 `D3ZoomEvent` shaped just enough for the three handlers under test:
// a `transform` with (x, y, k) and a `sourceEvent` of `null`, which is what
// d3-zoom's synthesized "start"/"zoom"/"end" carry when `zoom.transform()`
// is called with no fourth `event` argument — exactly how
// `System.XYPanZoom.setViewportConstrainedImpl` calls it.
export const mkTransformOnlyZoomEvent = (x) => (y) => (k) => ({
  transform: { x, y, k },
  sourceEvent: null,
});
