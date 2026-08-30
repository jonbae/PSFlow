// A flow holding a node that is never measured (#5052).
//
// Upstream prints an error when a drag reaches a node whose `measured` width
// and height are still undefined, and its text ("Please use onNodesChange as
// explained in the docs") points at a controlled flow that never applies its
// dimension changes. That is not in fact what produces one: measurement is
// internal, written straight into the node lookup by the resize observer, and
// it happens whether or not the consumer feeds anything back.
//
// What *does* leave a node unmeasured is never rendering it. A hidden node is
// skipped by `updateNodeInternals` before any element is measured, so its
// `measured` stays `{ undefined, undefined }` for as long as it is hidden — and
// a hidden node that is also **selected** is picked up by `getDragItems` along
// with whatever the pointer grabbed, because drag items are every selected node
// rather than only the one under the cursor. Dragging the ordinary node beside
// it therefore runs the unmeasured one through `calculateNodePosition`, which is
// where the error is raised.
//
// Selected in the fixture rather than by the scenario, and it has to be: a
// hidden node has no box, so no action in the vocabulary could reach it to
// select it. `selectNodesOnDrag` is off for the same reason — grabbing a node
// under the default selects it and clears everything else *before* the drag
// items are collected, which was measured here: the hidden node went from
// selected to unselected across the gesture and never joined it.
//
// And the node the scenario grabs starts selected too, which is the same wall a
// step further along: with `selectNodesOnDrag` off, `XYDrag.startDrag` clears
// the selection anyway unless the node being grabbed is *already* in it. Two
// selected nodes, one of them hidden, is the smallest arrangement that survives
// the start of a drag with both of them in it.
//
// The error is raised through `onError`, which the driver installs and observes
// like every other callback prop, so it lands in `callbacks` rather than in
// `console`. Ticket 080 filed this row under `console` on the assumption that
// upstream's default `devWarn` would print it; the driver's own observation
// intercepts it first, which is a better witness — the call is compared with
// its arguments and its position in the sequence.

export default {
  flowProps: {
    fitView: true,
    nodeDragThreshold: 0,
    selectNodesOnDrag: false,
    nodes: [
      { id: 'Node-1', data: { label: 'Node-1' }, position: { x: 0, y: 0 }, type: 'input', selected: true },
      { id: 'Node-2', data: { label: 'Node-2' }, position: { x: -100, y: 100 } },
      { id: 'unmeasured', data: { label: 'unmeasured' }, position: { x: 100, y: 100 }, hidden: true, selected: true },
    ],
    edges: [{ id: '1-2', source: 'Node-1', target: 'Node-2' }],
  },
};
