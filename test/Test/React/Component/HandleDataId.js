// `spago test` has no DOM, so the handle's attributes are read off a server
// render.
import { renderToStaticMarkup } from "react-dom/server";

export const renderMarkup = (jsx) => () => renderToStaticMarkup(jsx);
