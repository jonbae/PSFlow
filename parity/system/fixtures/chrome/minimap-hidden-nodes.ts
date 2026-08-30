// A MiniMap over a flow whose every node is hidden (#5546, #5692).
//
// Both rows are crashes rather than differences: a minimap with no visible node
// has no bounds to compute, and an undefined node reaching the minimap's node
// renderer throws. So the observation lands in whichever of two sections the
// implementation puts it in, and the scenario drives for either — a minimap that
// renders is a `dom` observation, which is where ticket 080 filed these, and one
// that throws leaves no DOM and no callback at all and is carried by `console`
// through `pageerror`. A side that crashes where the other draws differs in both
// sections at once.
//
// Every node hidden, not merely an empty list: an empty `nodes` array is a flow
// that was never given anything, where this is a flow that has nodes and can
// show none of them. The two take different paths through the minimap.

export default {
  flowProps: {
    fitView: true,
    nodes: [
      { id: 'Node-1', data: { label: 'Node-1' }, position: { x: 0, y: 0 }, type: 'input', hidden: true },
      { id: 'Node-2', data: { label: 'Node-2' }, position: { x: -100, y: 100 }, hidden: true },
      { id: 'Node-3', data: { label: 'Node-3' }, position: { x: 100, y: 100 }, hidden: true },
    ],
    edges: [{ id: '1-2', source: 'Node-1', target: 'Node-2' }],
  },
  minimapProps: { pannable: true, zoomable: true },
};
