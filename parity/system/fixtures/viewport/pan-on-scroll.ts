// `panOnScroll` with a zoom activation key that Control does not press
// (#93, ticket #129).
//
// ## The class
//
// With `panOnScroll` on, a wheel pans, but a wheel with `ctrlKey` set is a
// pinch: macOS sets it for a trackpad pinch. The pan-on-scroll handler then
// scales about the pointer, through `d3Zoom.scaleTo(selection, zoom, point,
// event)`. #124 fixed the point and the event ps-flow handed d3 there,
// against a local proxy, and found the corpus could not reach the branch:
// `wheel-pans-with-panonscroll` never holds Control.
//
// ## Why `zoomActivationKeyCode` is `Alt`
//
// Holding the zoom activation key switches the pane from the pan-on-scroll
// handler to the zoom handler, and the key defaults to Control off macOS, so
// on the net's platform a Ctrl-wheel would never reach the pinch branch at
// all. Moving the key anywhere Control does not press keeps the
// pan-on-scroll handler in place. `null`, which upstream reads as "no key",
// is not used: ps-flow refuses it at the boundary, because its key-code type
// has no disabled state, and that refusal is a different question.
//
// ## Why these numbers
//
// The viewport starts at the identity, so the pointer's screen position is
// its flow position and an off-centre zoom moves the translation by an
// amount that can be read straight off the trace.

import { edges, nodes } from '../shared/graph';

export default {
  flowProps: {
    nodes: nodes(),
    edges: edges(),
    defaultViewport: { x: 0, y: 0, zoom: 1 },
    panOnScroll: true,
    zoomActivationKeyCode: 'Alt',
  },
};
