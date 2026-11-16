// Upstream's minimap rendering hint, read on each render as upstream's is:
// crisp edges on a server, where there is no `window`, and in Chrome, which
// sets `window.chrome`; geometric precision elsewhere.
export const shapeRenderingNow = () =>
  typeof window === "undefined" || !!window.chrome ? "crispEdges" : "geometricPrecision";
