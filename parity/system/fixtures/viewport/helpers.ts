// A flow that snaps, so a viewport helper called with no options says something
// (#5012, #5722, #5723).
//
// Two of the three rows are about `screenToFlowPosition` taking a `snapGrid`
// option and defaulting `snapToGrid` to **false** rather than inheriting the
// flow's setting. That default is only observable against a flow whose own
// setting is the opposite, which is why this fixture snaps and upstream's
// `pane/general.ts` does not: on a flow that never snapped, a helper that
// inherited the setting and one that ignored it answer identically.
//
// It matters that the observation is of the *no-options* call. The imperative
// `call` primitive drives mutators only — read-only members are sampled
// together after the scenario settles, so that a query can never become an
// intermediate checkpoint — and `screenToFlowPosition` is a query. So the
// option cannot be passed from a scenario at all, and what is compared is the
// answer the settled snapshot took, on a flow where the default is the whole
// question.
//
// The nodes are spread wide enough that `fitBounds` and `setCenter` have
// somewhere to go that `fitView` would not have chosen for them.

export default {
  flowProps: {
    fitView: true,
    minZoom: 0.1,
    maxZoom: 8,
    snapToGrid: true,
    snapGrid: [25, 25],
    nodes: [
      { id: '1', data: { label: '1' }, position: { x: 0, y: 0 }, type: 'input' },
      { id: '2', data: { label: '2' }, position: { x: -260, y: 240 } },
      { id: '3', data: { label: '3' }, position: { x: 260, y: 240 } },
      { id: '4', data: { label: '4' }, position: { x: 0, y: 520 }, type: 'output' },
    ],
    edges: [
      { id: 'first-edge', source: '1', target: '2' },
      { id: 'second-edge', source: '1', target: '3' },
      { id: 'third-edge', source: '2', target: '4' },
    ],
  },
};
