// ps-flow — the JS surface, and the door `package.json` `main` points at.
//
// A bare re-export of the compiled boundary module (`src/Boundary.purs`).
// Every JS-facing conversion lives there, in PureScript, against the real
// types, so it is compiler-checked. This file has no logic of its own: the
// one thing it does that the boundary module cannot is rename, because
// PureScript value identifiers must start with a lowercase letter while the
// TS contract is PascalCase for components and enum objects.
//
// JavaScript consumers see the surface `@xyflow/react` exposes; PureScript
// consumers continue to import the `React` module (camelCase per PS grammar),
// which the boundary module leaves untouched.
//
// Maintenance: ordered to mirror `xyflow/packages/react/src/index.ts` so
// future audits are mechanical. `src/Boundary.js`'s `manifest` records which
// of these have *crossed* — have a JS-shaped wrapper — and which are still
// passing through as raw PureScript values; `npm run parity:surface` fails if
// it stops matching the list below.

export {
  // ─── Components ────────────────────────────────────────────────────────
  reactFlow as ReactFlow,
  handle as Handle,
  edgeText as EdgeText,
  straightEdge as StraightEdge,
  stepEdge as StepEdge,
  bezierEdge as BezierEdge,
  simpleBezierEdge as SimpleBezierEdge,
  smoothStepEdge as SmoothStepEdge,
  baseEdge as BaseEdge,
  reactFlowProvider as ReactFlowProvider,
  panel as Panel,
  edgeLabelRenderer as EdgeLabelRenderer,
  viewportPortal as ViewportPortal,

  // ─── Hooks (TS-named lowercase; no rename needed) ──────────────────────
  useReactFlow,
  useUpdateNodeInternals,
  useNodes,
  useEdges,
  useViewport,
  useKeyPress,
  useNodesState,
  useEdgesState,
  useStore,
  useStoreApi,
  useOnViewportChange,
  useOnSelectionChange,
  useNodesInitialized,
  useHandleConnections,
  useNodeConnections,
  useNodesData,
  useConnection,
  useInternalNode,
  useNodeId,
  experimental_useOnNodesChangeMiddleware,
  experimental_useOnEdgesChangeMiddleware,

  // ─── Utilities ─────────────────────────────────────────────────────────
  applyNodeChanges,
  applyEdgeChanges,
  isNode,
  isEdge,

  // ─── Enum objects from `@xyflow/system` (TS lines 46-113) ──────────────
  connectionLineType as ConnectionLineType,
  markerType as MarkerType,
  connectionMode as ConnectionMode,
  panOnScrollMode as PanOnScrollMode,
  selectionMode as SelectionMode,
  position as Position,
  resizeControlVariant as ResizeControlVariant,

  // ─── System functions (TS lines 127-143) ───────────────────────────────
  getBezierEdgeCenter,
  getBezierPath,
  getEdgeCenter,
  getSmoothStepPath,
  getStraightPath,
  getViewportForBounds,
  getNodesBounds,
  getIncomers,
  getOutgoers,
  addEdge,
  reconnectEdge,
  getConnectedEdges,
  getSimpleBezierPath,

  // ─── Additional components ─────────────────────────────────────────────
  background as Background,
  controls as Controls,
  controlButton as ControlButton,
  miniMap as MiniMap,
  miniMapNode as MiniMapNode,
  nodeToolbar as NodeToolbar,
  nodeResizer as NodeResizer,
  nodeResizeControl as NodeResizeControl,
  edgeToolbar as EdgeToolbar,
  backgroundVariant as BackgroundVariant,
} from "./output/Boundary/index.js";
