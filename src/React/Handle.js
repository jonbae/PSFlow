// Upstream's `isMouseEvent`: `'clientX' in event`. A `TouchEvent` has no
// `clientX` of its own; its points carry them.
export const hasClientX = (event) => "clientX" in event;
