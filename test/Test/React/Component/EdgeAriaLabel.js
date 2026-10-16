// `spago test` has no DOM, so the edge's attributes are read off a server
// render. The rest builds an edge the way a JavaScript consumer writes one,
// with only the keys they set, and reads back what the boundary emits.
import { renderToStaticMarkup } from "react-dom/server";

export const renderMarkup = (jsx) => () => renderToStaticMarkup(jsx);

export const jsEdgeWithAriaLabel = (ariaLabel) => ({ id: "ab", source: "a", target: "b", ariaLabel });

export const jsNull = null;

export const jsUndefined = undefined;

export const ariaLabelIsNull = (edge) => edge.ariaLabel === null;

export const ariaLabelIsUndefined = (edge) => edge.ariaLabel === undefined;
