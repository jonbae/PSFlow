// `spago test` has no DOM, so the panel's markup is read off a server render.
import { renderToStaticMarkup } from "react-dom/server";

export const renderMarkup = (jsx) => () => renderToStaticMarkup(jsx);
