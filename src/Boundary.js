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
//     the full JS surface; `parity/layer0-api/extract-psflow.mjs` fails if that
//     union stops matching `index.js`.

export const freeze = (record) => Object.freeze(record);

export const manifest = Object.freeze({
  // The highest boundary stage that has landed. Stage 1 crosses the twelve
  // exports upstream's fixtures and driver import plus the eight enum objects;
  // stages 2-4 are the callbacks, the imperative instance with the hooks, and
  // the components no fixture mounts. See the spec's staging table.
  stage: 1,

  // The eight TS enums are plain data on both sides, so crossing them was the
  // whole conversion: no wrapper, no arity change, no representation to
  // translate. `ReactFlow` is the opposite — 124 props, of which 75 convert
  // (72 non-callback fields plus the three change callbacks) and 49 are
  // refused outright until the stage that lands them (see `Boundary.Flow`).
  // It is listed as crossed because a JavaScript caller now gets upstream's
  // prop shapes or an error, never silence.
  crossed: Object.freeze([
    "BackgroundVariant",
    "ConnectionLineType",
    "ConnectionMode",
    "MarkerType",
    "PanOnScrollMode",
    "Position",
    "ReactFlow",
    "ResizeControlVariant",
    "SelectionMode",
  ]),

  passthrough: Object.freeze([
    "Background",
    "BaseEdge",
    "BezierEdge",
    "ControlButton",
    "Controls",
    "EdgeLabelRenderer",
    "EdgeText",
    "EdgeToolbar",
    "Handle",
    "MiniMap",
    "NodeResizeControl",
    "NodeResizer",
    "NodeToolbar",
    "Panel",
    "ReactFlowProvider",
    "ReactFlowWithRef",
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
});
