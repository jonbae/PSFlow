// FFI for `Boundary.purs`. Two things live here and nothing else.
//
//   * `freeze` — the enum objects the boundary module publishes are built in
//     PureScript, where the record type checks their member names against
//     upstream's shape, and frozen on the way out. Immutability is not
//     expressible in a PureScript type, so it lands here.
//
//   * `manifest` — the machine-readable record of which exports have crossed:
//     which have a JS-shaped wrapper, so a JavaScript caller gets upstream's
//     shape, and which are re-exported from the PureScript barrel raw, resolving
//     but carrying whatever shape the PureScript value happens to have. Crossed
//     is independent of gated — an export can be crossed with nothing proving
//     the conversion is right.
//
//     It is deliberately dependency-free plain data so a gate can read it with
//     a bare `import` of *this* file: no `spago build`, no PureScript runtime,
//     no compiled `output/`. Consumers should treat `crossed ∪ passthrough` as
//     the full JS surface; `parity/surface/extract-psflow.mjs` fails if that
//     union stops matching `index.js`.

export const freeze = (record) => Object.freeze(record);

export const manifest = Object.freeze({
  // The highest boundary stage that has landed. Stage 1 crossed the exports
  // upstream's fixtures and the two drivers import plus the eight enum
  // objects; stage 2 crossed the callback props; stage 3 the imperative
  // instance and the remaining hooks; stage 4 the components no fixture
  // mounts. See the spec's staging table.
  //
  // A stage is counted in **converters**, not exports, which is why stage 2
  // moved this number while adding only two names below: 46 callback props
  // crossed on `ReactFlow` alone, and every one of them is a prop of an export
  // that had already crossed.
  //
  // Stage 3 is the opposite shape — 19 new names for one converter and change.
  // The instance is not an export at all: it is *reached* through
  // `useReactFlow`, which is, and through `onInit`, which is a prop of an
  // export that crossed in stage 1. So the 32 members of `ReactFlowInstance`
  // move no number here and are the largest single piece of work in the
  // staging.
  //
  // **Stage 4 is the last one scheduled.** It empties the component half of
  // `passthrough` and leaves the fourteen pure functions, which no stage
  // crosses — see `src/Boundary.purs` and #62 for the decision, which is a
  // decision and not an omission. So `stage: 4` does not mean the surface has
  // finished crossing; it means every stage that was planned has landed, and
  // what is left is written down as what it is.
  stage: 4,

  // The eight TS enums are plain data on both sides, so crossing them was the
  // whole conversion: no wrapper, no arity change, no representation to
  // translate. `ReactFlow` is the opposite — 125 props, every one of which
  // converts; 124 of them as of stage 4, and `innerRef` when #27 made the
  // component a `forwardRef`. Two were refused outright until stage 4, and
  // `Boundary.Flow` says what landed them. It was listed as crossed from stage
  // 1 anyway, because the claim this list makes is that a JavaScript caller
  // gets upstream's prop shapes or an error, never silence.
  //
  // The three utilities are what a controlled flow's own change handlers call,
  // so they cross with `ReactFlow` rather than after it: `onNodesChange` is
  // useless if `applyNodeChanges(changes, nodes)` returns a function.
  //
  // The four chrome components were in stage 1's set from the start —
  // upstream's `Flow.tsx` mounts each of them — and crossed when a driver
  // first rendered one. `Handle` and `NodeToolbar` are the pair no driver
  // mounts: they are mounted by a consumer's own node component, which the
  // node-toolbar fixture is the first to name. `useNodesState` and
  // `useEdgesState` were the two exceptions to the hooks being stage 3: they
  // return their own bundles and touch no `ReactFlowInstance`, so they did not
  // wait for its converter.
  //
  // Stage 3 adds the other nineteen hooks. Two of them — `useStore` and
  // `useStoreApi` — are listed as crossed on the same terms as everything else
  // here, which is that a JavaScript caller gets upstream's shape or an error
  // and never silence: both are callable at upstream's arity and both throw,
  // because what they would hand over is the internal store state and no
  // converter for it exists. `Boundary.Hooks` says why refusing beat handing it
  // over raw, and `parity/boundary/mount.mjs` holds the refusal directly, by
  // calling each hook and reading the message it throws.
  //
  // Stage 4 adds the fourteen components `passthrough` still held, which is
  // the selection: it is defined by *this list* and not by a fixture, and it
  // is the first stage of which that is true. Every earlier one crossed what
  // something was already about to render, so a mistake in it had a gate
  // waiting, and `coverage/holes.json` names most of these as exports the
  // corpus does not drive — no number here, because that register moves and a
  // count copied out of it would go stale in silence. That is why
  // `parity/boundary/mount.mjs` grew a section for them in the same commit.
  //
  // The hole register decided what stage 4 did *not* do as much as what it
  // did: `NodeResizer` and `NodeResizeControl` are two of its entries and were
  // already crossed, so the stage left them alone. Crossing is not driving —
  // every one of those holes is still open — and this manifest is the register
  // that says so, since `crossed` and `gated` are deliberately independent
  // here.
  crossed: Object.freeze([
    "Background",
    "BackgroundVariant",
    "BaseEdge",
    "BezierEdge",
    "ConnectionLineType",
    "ConnectionMode",
    "ControlButton",
    "Controls",
    "EdgeLabelRenderer",
    "EdgeText",
    "EdgeToolbar",
    "Handle",
    "MarkerType",
    "MiniMap",
    "MiniMapNode",
    "NodeResizeControl",
    "NodeResizer",
    "NodeToolbar",
    "PanOnScrollMode",
    "Panel",
    "Position",
    "ReactFlow",
    "ReactFlowProvider",
    "ResizeControlVariant",
    "SelectionMode",
    "SimpleBezierEdge",
    "SmoothStepEdge",
    "StepEdge",
    "StraightEdge",
    "ViewportPortal",
    "addEdge",
    "applyEdgeChanges",
    "applyNodeChanges",
    "experimental_useOnEdgesChangeMiddleware",
    "experimental_useOnNodesChangeMiddleware",
    "useConnection",
    "useEdges",
    "useEdgesState",
    "useHandleConnections",
    "useInternalNode",
    "useKeyPress",
    "useNodeConnections",
    "useNodeId",
    "useNodes",
    "useNodesData",
    "useNodesInitialized",
    "useNodesState",
    "useOnSelectionChange",
    "useOnViewportChange",
    "useReactFlow",
    "useStore",
    "useStoreApi",
    "useUpdateNodeInternals",
    "useViewport",
  ]),

  // What is left, and after stage 4 it is one kind of thing: the fourteen
  // pure functions no stage crosses. Every one of them resolves and returns
  // the right answer in the wrong shape — curried, or a labelled record where
  // upstream returns a positional array — and surface parity's
  // call-and-compare measures each difference rather than assuming it, which
  // is what makes their entries in `parity/surface/allowlist.json` claims
  // instead of excuses.
  passthrough: Object.freeze([
    "getBezierEdgeCenter",
    "getBezierPath",
    "getConnectedEdges",
    "getEdgeCenter",
    "getIncomers",
    "getNodesBounds",
    "getOutgoers",
    "getSimpleBezierPath",
    "getSmoothStepPath",
    "getStraightPath",
    "getViewportForBounds",
    "isEdge",
    "isNode",
    "reconnectEdge",
  ]),
});
