// `spago test` has no DOM, so a wrapper's attributes are read off a server
// render, as the boundary's mount check reads `<ReactFlow />`'s. `react-dom/server`
// runs no effects, so the markup is the first render's attributes and nothing a
// commit would change.
import { renderToStaticMarkup } from "react-dom/server";

export const renderMarkup = (jsx) => () => renderToStaticMarkup(jsx);
