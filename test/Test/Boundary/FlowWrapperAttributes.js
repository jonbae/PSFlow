// `spago test` has no DOM, so the wrapper is read off a server render of the
// crossed `<ReactFlow />`, called with a props object the way JSX calls it.
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

// Only the wrapper's opening tag. A server render runs no effects, which is
// all this needs: the attributes are set on the first render.
export const renderWrapper = (component) => (props) => () => {
  const had = Object.prototype.hasOwnProperty.call(globalThis, "ResizeObserver");
  const previous = globalThis.ResizeObserver;
  if (!had) globalThis.ResizeObserver = NoResizeObserver;
  try {
    return renderToStaticMarkup(createElement(component, { nodes: [], edges: [], ...props })).split(">")[0];
  } finally {
    if (!had) delete globalThis.ResizeObserver;
    else globalThis.ResizeObserver = previous;
  }
};

export const noProps = {};

// The fixture's id, as `parity/system/fixtures` hands it.
export const customTestId = { "data-testid": "psflow-custom-flow" };

// Attributes only the rest can carry, beside members `JsFlowProps` names and
// the attributes the wrapper sets itself, which a consumer can't replace.
export const mixed = {
  "aria-label": "my flow",
  "data-owner": "tests",
  id: "flow-a",
  className: "mine",
  role: "none",
  fitView: true,
  minZoom: 0.25,
};

// Upstream's `{ ...style, ...wrapperStyle }`: a consumer's style sits under
// the wrapper's sizing, so its `background` stays and its `width` doesn't.
export const styled = { style: { background: "red", width: "50%" } };
