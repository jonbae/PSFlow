// `spago test` has no DOM, so the paths are read off a server render of the
// crossed `<BaseEdge />`, called with a props object the way JSX calls it.
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";

export const renderWith = (component) => (props) => () => renderToStaticMarkup(createElement(component, props));

// The fixture's props (`parity/system/fixtures/edges/components/PathAttributeEdge.tsx`).
export const fixtureProps = {
  id: "custom-1",
  path: "M0,0 L10,10",
  markerEnd: "url(#arrow)",
  strokeDasharray: "6 3",
  strokeLinecap: "round",
  strokeWidth: 3,
  pathLength: 100,
  "data-psflow-edge": "base-edge-path",
  "aria-label": "edge with path attributes",
};

// Members upstream's `BaseEdge` destructures, which go nowhere near the path,
// beside two it sets itself, which a consumer's value can't override.
export const labelledProps = {
  path: "M0,0 L10,10",
  label: "a label",
  labelX: 5,
  labelY: 5,
  interactionWidth: 12,
  className: "mine",
  fill: "red",
};

export const pathOnly = { path: "M0,0 L10,10" };
