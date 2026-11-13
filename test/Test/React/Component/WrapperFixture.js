// `spago test` has no DOM, so a wrapper's output is read off a server render.
// `react-dom/server` runs no effects, so the markup is the first render's.
import { renderToStaticMarkup } from "react-dom/server";

export const renderMarkup = (jsx) => () => renderToStaticMarkup(jsx);
