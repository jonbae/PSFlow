// `spago test` has no DOM, so the edge is rendered on the server. Its edge
// type records the props the wrapper hands it, and renders nothing.
import { renderToStaticMarkup } from "react-dom/server";

export const renderMarkup = (jsx) => () => renderToStaticMarkup(jsx);

const recorded = [];

export const recordingEdgeTypes = {
  recording: (props) => {
    recorded.push(props);
    return null;
  },
};

export const takeRecorded = () => recorded.splice(0);
