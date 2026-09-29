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

export const mkMouseSourcedZoomEvent = (x) => (y) => (k) => ({
  transform: { x, y, k },
  // WheelEvent follows the MouseEvent fallback in EventHandler, just as the
  // browser's pan-on-scroll event does.
  sourceEvent: { type: "wheel" },
});

export const mkTouchSourcedZoomEvent = (x) => (y) => (k) => ({
  transform: { x, y, k },
  sourceEvent: { [Symbol.toStringTag]: "TouchEvent" },
});

export const mkTranslateBySpy = () => {
  const selection = {};
  let call = null;
  const behavior = {
    translateBy(actualSelection, dx, dy, sourceEvent) {
      call = { actualSelection, dx, dy, sourceEvent };
    },
  };

  return {
    behavior,
    selection,
    sawExpectedCall: () =>
      call !== null &&
      call.actualSelection === selection &&
      call.dx === 3 &&
      call.dy === 4 &&
      call.sourceEvent?.internal === true,
  };
};
