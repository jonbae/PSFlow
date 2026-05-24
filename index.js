// ps-flow JavaScript shim — re-exports the compiled output of `React.purs`
// (the public-API barrel) under TS-identical names. JavaScript consumers
// see exactly the surface that `@xyflow/react` exposes; PureScript
// consumers continue to import from the `React` module (camelCase per
// PS grammar). This is the only place where the TS PascalCase contract
// is enforced.
//
// Maintenance: ordered to mirror `xyflow-main/packages/react/src/index.ts`
// so future audits are mechanical. Symbols deferred by porting tickets
// are tracked in `tickets/054-react-public-api-missing-symbols.md` — do
// NOT add a re-export here unless the corresponding PS symbol exists.

import * as PS from "./output/React/index.js";

// ─── Components ──────────────────────────────────────────────────────────
export const ReactFlow = PS.reactFlow;
export const ReactFlowWithRef = PS.reactFlowWithRef;
export const Handle = PS.handle;
export const EdgeText = PS.edgeText;
export const StraightEdge = PS.straightEdge;
export const StepEdge = PS.stepEdge;
export const BezierEdge = PS.bezierEdge;
export const SimpleBezierEdge = PS.simpleBezierEdge;
export const SmoothStepEdge = PS.smoothStepEdge;
export const BaseEdge = PS.baseEdge;
export const ReactFlowProvider = PS.reactFlowProvider;
export const Panel = PS.panel;
export const EdgeLabelRenderer = PS.edgeLabelRenderer;
export const ViewportPortal = PS.viewportPortal;

// ─── Hooks (TS-named lowercase; pass through unchanged) ──────────────────
export const useReactFlow = PS.useReactFlow;
export const useUpdateNodeInternals = PS.useUpdateNodeInternals;
export const useNodes = PS.useNodes;
export const useEdges = PS.useEdges;
export const useViewport = PS.useViewport;
export const useKeyPress = PS.useKeyPress;
export const useNodesState = PS.useNodesState;
export const useEdgesState = PS.useEdgesState;
export const useStore = PS.useStore;
export const useStoreApi = PS.useStoreApi;
export const useOnViewportChange = PS.useOnViewportChange;
export const useOnSelectionChange = PS.useOnSelectionChange;
export const useNodesInitialized = PS.useNodesInitialized;
export const useHandleConnections = PS.useHandleConnections;
export const useNodeConnections = PS.useNodeConnections;
export const useNodesData = PS.useNodesData;
export const useConnection = PS.useConnection;
export const useInternalNode = PS.useInternalNode;
export const useNodeId = PS.useNodeId;
export const experimental_useOnNodesChangeMiddleware = PS.experimental_useOnNodesChangeMiddleware;
export const experimental_useOnEdgesChangeMiddleware = PS.experimental_useOnEdgesChangeMiddleware;

// ─── Utilities ───────────────────────────────────────────────────────────
export const applyNodeChanges = PS.applyNodeChanges;
export const applyEdgeChanges = PS.applyEdgeChanges;
export const isNode = PS.isNode;
export const isEdge = PS.isEdge;

// ─── System functions (TS lines 127-143) ─────────────────────────────────
export const getBezierEdgeCenter = PS.getBezierEdgeCenter;
export const getBezierPath = PS.getBezierPath;
export const getEdgeCenter = PS.getEdgeCenter;
export const getSmoothStepPath = PS.getSmoothStepPath;
export const getStraightPath = PS.getStraightPath;
export const getViewportForBounds = PS.getViewportForBounds;
export const getNodesBounds = PS.getNodesBounds;
export const getIncomers = PS.getIncomers;
export const getOutgoers = PS.getOutgoers;
export const addEdge = PS.addEdge;
export const reconnectEdge = PS.reconnectEdge;
export const getConnectedEdges = PS.getConnectedEdges;
export const getSimpleBezierPath = PS.getSimpleBezierPath;

// ─── Additional components ───────────────────────────────────────────────
export const Background = PS.background;
export const Controls = PS.controls;
export const ControlButton = PS.controlButton;
export const MiniMap = PS.miniMap;
export const NodeToolbar = PS.nodeToolbar;
export const NodeResizer = PS.nodeResizer;
export const NodeResizeControl = PS.nodeResizeControl;
export const EdgeToolbar = PS.edgeToolbar;
