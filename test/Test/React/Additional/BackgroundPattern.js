// `spago test` has no DOM, so the background is read off a server render of
// the crossed `<ReactFlow />` with a crossed `<Background />` inside it, the
// way a consumer mounts one. The background reads the viewport from the store
// the flow provides, which is why it can't be rendered on its own.
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";

// `ResizeObserver` is a browser global the node renderer allocates one of per
// mount; nothing here observes a size. It is stubbed for the render only, as
// `parity/boundary/mount.mjs` stubs it, and put back so no other module sees it.
class NoResizeObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
}

// The background's `<svg>`, from its opening tag to its close.
export const renderBackground = (flow) => (background) => (props) => () => {
  const had = Object.prototype.hasOwnProperty.call(globalThis, "ResizeObserver");
  const previous = globalThis.ResizeObserver;
  if (!had) globalThis.ResizeObserver = NoResizeObserver;
  try {
    const markup = renderToStaticMarkup(
      createElement(flow, { nodes: [], edges: [] }, createElement(background, props))
    );
    const start = markup.indexOf("<svg class=\"react-flow__background");
    return start < 0 ? "" : markup.slice(start, markup.indexOf("</svg>", start) + "</svg>".length);
  } finally {
    if (!had) delete globalThis.ResizeObserver;
    else globalThis.ResizeObserver = previous;
  }
};

export const noProps = {};

export const dots = { variant: "dots", id: "2" };
