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
  // objects; stage 2 crossed the callback props; stage 3 crosses the imperative
  // instance and the remaining hooks; stage 4 is the components no fixture
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
  stage: 3,

  // The eight TS enums are plain data on both sides, so crossing them was the
  // whole conversion: no wrapper, no arity change, no representation to
  // translate. `ReactFlow` is the opposite — 124 props, of which 121 convert
  // and three are refused outright until the stage that lands them (see
  // `Boundary.Flow`). It is listed as crossed because a JavaScript caller now
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
  // over raw, and `parity/boundary/mount.mjs` holds the refusal the same way it
  // holds the deferred props'.
  crossed: Object.freeze([
    "Background",
    "BackgroundVariant",
    "ConnectionLineType",
    "ConnectionMode",
    "Controls",
    "Handle",
    "MarkerType",
    "MiniMap",
    "NodeResizeControl",
    "NodeResizer",
    "NodeToolbar",
    "PanOnScrollMode",
    "Panel",
    "Position",
    "ReactFlow",
    "ResizeControlVariant",
    "SelectionMode",
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

  passthrough: Object.freeze([
    "BaseEdge",
    "BezierEdge",
    "ControlButton",
    "EdgeLabelRenderer",
    "EdgeText",
    "EdgeToolbar",
    "ReactFlowProvider",
    "ReactFlowWithRef",
    "SimpleBezierEdge",
    "SmoothStepEdge",
    "StepEdge",
    "StraightEdge",
    "ViewportPortal",
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
