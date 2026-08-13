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
  // The highest boundary stage that has landed. Stage 1 crosses the exports
  // upstream's fixtures and the two drivers import plus the eight enum
  // objects; stages 2-4 are the callbacks, the imperative instance with the
  // remaining hooks, and the components no fixture mounts. See the spec's
  // staging table.
  //
  // Stage 1's set is twenty, and all twenty are below. `Handle` and
  // `NodeToolbar` were the last two: they are mounted by the node component
  // the node-toolbar fixture names rather than by either driver, and crossed
  // when that fixture moved onto the JS surface (#47).
  stage: 1,

  // The eight TS enums are plain data on both sides, so crossing them was the
  // whole conversion: no wrapper, no arity change, no representation to
  // translate. `ReactFlow` is the opposite — 124 props, of which 75 convert
  // (72 non-callback fields plus the three change callbacks) and 49 are
  // refused outright until the stage that lands them (see `Boundary.Flow`).
  // It is listed as crossed because a JavaScript caller now gets upstream's
  // prop shapes or an error, never silence.
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
  // `useEdgesState` are the two exceptions to the hooks being stage 3: they
  // return their own bundles and touch no `ReactFlowInstance`, so they do not
  // wait for its converter.
  crossed: Object.freeze([
    "Background",
    "BackgroundVariant",
    "ConnectionLineType",
    "ConnectionMode",
    "Controls",
    "Handle",
    "MarkerType",
    "MiniMap",
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
    "useEdgesState",
    "useNodesState",
  ]),

  passthrough: Object.freeze([
    "BaseEdge",
    "BezierEdge",
    "ControlButton",
    "EdgeLabelRenderer",
    "EdgeText",
    "EdgeToolbar",
    "NodeResizeControl",
    "NodeResizer",
    "ReactFlowProvider",
    "ReactFlowWithRef",
    "SimpleBezierEdge",
    "SmoothStepEdge",
    "StepEdge",
    "StraightEdge",
    "ViewportPortal",
    "experimental_useOnEdgesChangeMiddleware",
    "experimental_useOnNodesChangeMiddleware",
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
    "useConnection",
    "useEdges",
    "useHandleConnections",
    "useInternalNode",
    "useKeyPress",
    "useNodeConnections",
    "useNodeId",
    "useNodes",
    "useNodesData",
    "useNodesInitialized",
    "useOnSelectionChange",
    "useOnViewportChange",
    "useReactFlow",
    "useStore",
    "useStoreApi",
    "useUpdateNodeInternals",
    "useViewport",
  ]),
});
