// Boundary drift — a staleness gate over the outbound conversions.
//
// The inbound direction of the boundary module is compiler-checked for free:
// building a PureScript record forces a value for every field, so a field
// added to `NodeBaseRow` breaks `Boundary.Elements` until someone reads it off
// the JavaScript object.
//
// The outbound direction has no such check. Nothing makes `JsNode` name every
// field `NodeBaseRow` has, so a field added to the PureScript record and
// forgotten in the JS-shaped one is silently dropped on the way out — and a
// round-trip property would not find it either, because the repo's generators
// vary 5 of that record's 28 fields and would happily agree about the other 23
// while one of them vanished.
//
// So this compares the two type declarations' label sets directly. There is no
// recorded baseline to re-bless: both sides are read live from source, and the
// gate fails on the field that appears in one and not the other. The only
// hand-written data is the rename and refusal tables, and both are themselves
// checked — an entry naming a field that no longer exists, or a refusal whose
// PureScript counterpart has since appeared, fails as stale.
//
// `NodeChange` and `EdgeChange` are handled separately, because their JS shape
// is a flattened discriminated union rather than one record's mirror. Their
// variants are read off the `data` declaration, so a seventh change member
// added to the sum is picked up here rather than waiting for a list to be
// extended.
//
// The run ends with a falsification probe. A green differential result proves
// nothing until it has been shown it can go red, and this one has seven
// failure classes to demonstrate, so it demonstrates all seven on every run.
//
// Usage: node parity/boundary/drift.mjs

import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { constructorFields, dataConstructors, fail, recordFields } from "./purs.mjs";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "..", "..");

// ── The pairs ───────────────────────────────────────────────────────────
//
// `renames` maps a PureScript label to the JS label it crosses as. Every one
// of them is a deliberate divergence with a reason: PureScript keeps `type`
// free for the element's own tag, so a nested type tag is `nodeType` /
// `edgeType` / `handleType` / `markerType`; and upstream keys its aria-label
// config by dotted path, which is not a PureScript identifier.

const pairs = [
  {
    what: "Node",
    ps: { file: "src/System/Types/Node.purs", type: "NodeBaseRow" },
    js: { file: "src/Boundary/Elements.purs", type: "JsNodeRow" },
    renames: { nodeType: "type" },
  },
  // An internal node is a node plus `internals`, on both sides and by the same
  // mechanism: each extends the row above rather than restating it. The reader
  // expands that composition, so this pair compares all 29 — the 28 the pair
  // above holds and the one this one adds — which is why it repeats that pair's
  // rename. It read as a one-field pair until the reader learned to follow a
  // row, and a pair comparing one field out of 29 is a pair that would have
  // agreed with almost anything.
  {
    what: "InternalNode",
    ps: { file: "src/System/Types/Node.purs", type: "InternalNodeBase" },
    js: { file: "src/Boundary/Elements.purs", type: "JsInternalNode" },
    renames: { nodeType: "type" },
  },
  {
    what: "NodeInternals",
    ps: { file: "src/System/Types/Node.purs", type: "NodeInternals" },
    js: { file: "src/Boundary/Elements.purs", type: "JsNodeInternals" },
    renames: {},
  },
  {
    what: "NodeHandleBounds",
    ps: { file: "src/System/Types/Node.purs", type: "NodeHandleBounds" },
    js: { file: "src/Boundary/Elements.purs", type: "JsNodeHandleBounds" },
    renames: {},
  },
  {
    what: "NodeBounds",
    ps: { file: "src/System/Types/Node.purs", type: "NodeBounds" },
    js: { file: "src/Boundary/Elements.purs", type: "JsNodeBounds" },
    renames: {},
  },
  // A measured handle, which is `NodeHandle` plus the node it belongs to. Its
  // rename is the one `NodeHandle` carries and for the same reason.
  {
    what: "Handle",
    ps: { file: "src/System/Types/Handle.purs", type: "Handle" },
    js: { file: "src/Boundary/Elements.purs", type: "JsHandle" },
    renames: { handleType: "type" },
  },
  {
    what: "Edge",
    ps: { file: "src/System/Types/Edge.purs", type: "EdgeBase" },
    js: { file: "src/Boundary/Elements.purs", type: "JsEdge" },
    renames: { edgeType: "type" },
  },
  {
    what: "NodeProps",
    ps: { file: "src/React/Types/Nodes.purs", type: "NodeProps" },
    js: { file: "src/Boundary/Elements.purs", type: "JsNodeProps" },
    renames: {},
  },
  {
    what: "NodeHandle",
    ps: { file: "src/System/Types/Node.purs", type: "NodeHandle" },
    js: { file: "src/Boundary/Elements.purs", type: "JsNodeHandle" },
    renames: { handleType: "type" },
  },
  {
    what: "EdgeMarker",
    ps: { file: "src/System/Types/Edge.purs", type: "EdgeMarker" },
    js: { file: "src/Boundary/Elements.purs", type: "JsEdgeMarker" },
    renames: { markerType: "type" },
  },
  {
    what: "Connection",
    ps: { file: "src/System/Types/Connection.purs", type: "Connection" },
    js: { file: "src/Boundary/Elements.purs", type: "JsConnection" },
    renames: {},
  },
  // `innerRef` -> `ref` is the same rename `PanelProps` and `HandleProps`
  // carry, and it arrived here last: #27 made `<ReactFlow />` the third
  // component to take a ref, after boundary stage 4 did the other two.
  {
    what: "ReactFlowProps",
    ps: { file: "src/React/Types/Component.purs", type: "ReactFlowProps" },
    js: { file: "src/Boundary/Flow.purs", type: "JsFlowProps" },
    renames: { innerRef: "ref" },
  },
  {
    what: "DefaultEdgeOptions",
    ps: { file: "src/React/Types/Edges.purs", type: "DefaultEdgeOptions" },
    js: { file: "src/Boundary/Flow.purs", type: "JsDefaultEdgeOptions" },
    renames: {},
    // Upstream's `DefaultEdgeOptions` is `Edge` minus its identity fields, and
    // ps-flow's carries ten of those 23. The other thirteen are named on the JS
    // side on purpose, so `Boundary.Flow.guardEdgeOptions` can refuse them —
    // dropping them silently is the failure the whole module exists to remove.
    // One of them gaining a PureScript counterpart fails as stale below.
    refused: [
      "type",
      "markerStart",
      "markerEnd",
      "style",
      "className",
      "label",
      "labelStyle",
      "labelShowBg",
      "labelBgStyle",
      "labelBgPadding",
      "labelBgBorderRadius",
      "ariaRole",
      "domAttributes",
    ],
  },
  {
    what: "Viewport",
    ps: { file: "src/System/Types/Connection.purs", type: "Viewport" },
    js: { file: "src/Boundary/Elements.purs", type: "JsViewport" },
    renames: {},
  },
  // The shapes a callback carries out. Every one of them is outbound-only, so
  // the compiler forces nothing about them and this is the whole check —
  // the same position `Node` and `Edge` are in, one argument along.
  {
    what: "ConnectionState",
    ps: { file: "src/System/Types/Connection.purs", type: "ConnectionInProgressData" },
    js: { file: "src/Boundary/Callbacks.purs", type: "JsConnectionState" },
    renames: {},
  },
  {
    what: "ConnectStartParams",
    ps: { file: "src/System/XYHandle.purs", type: "OnConnectStartParams" },
    js: { file: "src/Boundary/Callbacks.purs", type: "JsConnectStartParams" },
    renames: {},
  },
  {
    what: "GraphSelection",
    ps: { file: "src/React/Types/General.purs", type: "OnSelectionChangeParams" },
    js: { file: "src/Boundary/Elements.purs", type: "JsGraphSelection" },
    renames: {},
  },
  {
    what: "ResizeParams",
    ps: { file: "src/System/XYResizer.purs", type: "ResizeParams" },
    js: { file: "src/Boundary/Callbacks.purs", type: "JsResizeParams" },
    renames: {},
  },
  {
    what: "ResizeParamsDir",
    ps: { file: "src/System/XYResizer.purs", type: "ResizeParamsWithDirection" },
    js: { file: "src/Boundary/Callbacks.purs", type: "JsResizeParamsWithDirection" },
    renames: {},
  },
  // The component props — the four chrome ones below, and the two a custom
  // node mounts further down. Their crossings are inbound-only — nothing hands
  // a `PanelProps` back to a JavaScript caller — so the compiler already
  // forces every PureScript field to be constructed. What it does not force is
  // the other direction: a field *removed* from the PureScript record leaves
  // an orphan on the JS side that a consumer can still set and nothing reads,
  // which is the silent-drop failure wearing the other hat.
  // `innerRef` -> `ref` is the third kind of rename in this table, after the
  // nested type tags and upstream's dotted aria keys: React reserves `ref` and
  // strips it out of a props object before the component sees it, so a
  // PureScript record that wants one has to spell it something else. The JS
  // side names it `ref` because that is what a consumer writes, and boundary
  // stage 4 made both components `forwardRef`s so the value actually arrives.
  {
    what: "PanelProps",
    ps: { file: "src/React/Types/Component.purs", type: "PanelProps" },
    js: { file: "src/Boundary/Chrome.purs", type: "JsPanelProps" },
    renames: { innerRef: "ref" },
  },
  {
    what: "BackgroundProps",
    ps: { file: "src/React/Types/Component.purs", type: "BackgroundProps" },
    js: { file: "src/Boundary/Chrome.purs", type: "JsBackgroundProps" },
    renames: {},
  },
  {
    what: "ControlsProps",
    ps: { file: "src/React/Types/Component.purs", type: "ControlsProps" },
    js: { file: "src/Boundary/Chrome.purs", type: "JsControlsProps" },
    renames: {},
  },
  {
    what: "MiniMapProps",
    ps: { file: "src/React/Types/Component.purs", type: "MiniMapProps" },
    js: { file: "src/Boundary/Chrome.purs", type: "JsMiniMapProps" },
    renames: {},
  },
  // The two a custom node mounts. `HandleProps`' rename is the same one
  // `NodeHandle` carries and for the same reason: PureScript keeps `type` for
  // the element's own tag, so the handle's kind is `handleType`.
  {
    what: "HandleProps",
    ps: { file: "src/React/Types/Component.purs", type: "HandleProps" },
    js: { file: "src/Boundary/NodeChrome.purs", type: "JsHandleProps" },
    renames: { handleType: "type", innerRef: "ref" },
  },
  {
    what: "NodeToolbarProps",
    ps: { file: "src/React/Types/Component.purs", type: "NodeToolbarProps" },
    js: { file: "src/Boundary/NodeChrome.purs", type: "JsNodeToolbarProps" },
    renames: {},
  },
  // The other pair a custom node mounts, crossed with the callbacks because
  // their lifecycle handlers are callback props.
  {
    what: "NodeResizerProps",
    ps: { file: "src/React/Types/Component.purs", type: "NodeResizerProps" },
    js: { file: "src/Boundary/Resizer.purs", type: "JsNodeResizerProps" },
    renames: {},
  },
  {
    what: "ResizeControlProps",
    ps: { file: "src/React/Types/Component.purs", type: "NodeResizeControlProps" },
    js: { file: "src/Boundary/Resizer.purs", type: "JsNodeResizeControlProps" },
    renames: {},
  },
  {
    what: "FitViewOptions",
    ps: { file: "src/System/Utils/Graph.purs", type: "FitViewOptions" },
    js: { file: "src/Boundary/FitView.purs", type: "JsFitViewOptions" },
    renames: {},
  },
  {
    what: "ProOptions",
    ps: { file: "src/React/Types/General.purs", type: "ProOptions" },
    js: { file: "src/Boundary/Flow.purs", type: "JsProOptions" },
    renames: {},
  },
  {
    what: "AriaLabelConfig",
    ps: { file: "src/System/Constants.purs", type: "AriaLabelConfigOverride" },
    js: { file: "src/Boundary/Flow.purs", type: "JsAriaLabelConfig" },
    renames: {
      nodeA11yDescriptionDefault: "node.a11yDescription.default",
      nodeA11yDescriptionKeyboardDisabled: "node.a11yDescription.keyboardDisabled",
      nodeA11yDescriptionAriaLiveMessage: "node.a11yDescription.ariaLiveMessage",
      edgeA11yDescriptionDefault: "edge.a11yDescription.default",
      controlsAriaLabel: "controls.ariaLabel",
      controlsZoomInAriaLabel: "controls.zoomIn.ariaLabel",
      controlsZoomOutAriaLabel: "controls.zoomOut.ariaLabel",
      controlsFitViewAriaLabel: "controls.fitView.ariaLabel",
      controlsInteractiveAriaLabel: "controls.interactive.ariaLabel",
      minimapAriaLabel: "minimap.ariaLabel",
      handleAriaLabel: "handle.ariaLabel",
    },
  },
  // ── Boundary stage 4: the components no fixture mounts ────────────────
  //
  // Eighteen pairs, and they split three ways.
  //
  // **Inbound only** — fifteen: eleven component props records and the three
  // per-variant path-option records inside three of them, plus the provider's.
  // The compiler already forces every PureScript field to be constructed; what
  // it does not force is a field *removed* from the PureScript record leaving
  // an orphan on the JS side that a consumer can set and nothing reads. Same
  // claim as the chrome props above.
  //
  // **Outbound only** — `EdgeProps`, `ConnectionLineComponentProps`, and
  // `MiniMapNodeProps` in its second direction. These are the props ps-flow
  // hands a component the *consumer* wrote, so they are in the position `Node`
  // and `Edge` are in and this comparison is the whole check that the crossing
  // names every member.
  //
  // **Both** — `MiniMapNodeProps`, which is the only record on this surface
  // that crosses each way: `<MiniMapNode />` is an export a consumer renders,
  // and `MiniMap.nodeComponent` is ps-flow rendering their replacement for it.
  //
  // The five built-in edge props records are spelled as rows on both sides, so
  // the reader expands the composition before comparing: `StraightEdgeProps`
  // is seventeen fields, the four bending variants are those plus two, and
  // three of those four are those plus a `pathOptions` whose own record is a
  // pair further down.
  {
    what: "EdgeTextProps",
    ps: { file: "src/React/Types/Edges.purs", type: "EdgeTextProps" },
    js: { file: "src/Boundary/Edges.purs", type: "JsEdgeTextProps" },
    renames: {},
  },
  {
    what: "BaseEdgeProps",
    ps: { file: "src/React/Types/Edges.purs", type: "BaseEdgeProps" },
    js: { file: "src/Boundary/Edges.purs", type: "JsBaseEdgeProps" },
    renames: {},
  },
  {
    what: "StraightEdgeProps",
    ps: { file: "src/React/Types/Edges.purs", type: "StraightEdgeProps" },
    js: { file: "src/Boundary/Edges.purs", type: "JsStraightEdgeProps" },
    renames: {},
  },
  {
    what: "SimpleBezierEdgeProps",
    ps: { file: "src/React/Types/Edges.purs", type: "SimpleBezierEdgeProps" },
    js: { file: "src/Boundary/Edges.purs", type: "JsSimpleBezierEdgeProps" },
    renames: {},
  },
  {
    what: "BezierEdgeProps",
    ps: { file: "src/React/Types/Edges.purs", type: "BezierEdgeProps" },
    js: { file: "src/Boundary/Edges.purs", type: "JsBezierEdgeProps" },
    renames: {},
  },
  {
    what: "SmoothStepEdgeProps",
    ps: { file: "src/React/Types/Edges.purs", type: "SmoothStepEdgeProps" },
    js: { file: "src/Boundary/Edges.purs", type: "JsSmoothStepEdgeProps" },
    renames: {},
  },
  {
    what: "StepEdgeProps",
    ps: { file: "src/React/Types/Edges.purs", type: "StepEdgeProps" },
    js: { file: "src/Boundary/Edges.purs", type: "JsStepEdgeProps" },
    renames: {},
  },
  {
    what: "BezierPathOptions",
    ps: { file: "src/System/Types/Edge.purs", type: "BezierPathOptions" },
    js: { file: "src/Boundary/Edges.purs", type: "JsBezierPathOptions" },
    renames: {},
  },
  {
    what: "SmoothStepPathOptions",
    ps: { file: "src/System/Types/Edge.purs", type: "SmoothStepPathOptions" },
    js: { file: "src/Boundary/Edges.purs", type: "JsSmoothStepPathOptions" },
    renames: {},
  },
  {
    what: "StepPathOptions",
    ps: { file: "src/System/Types/Edge.purs", type: "StepPathOptions" },
    js: { file: "src/Boundary/Edges.purs", type: "JsStepPathOptions" },
    renames: {},
  },
  {
    what: "EdgeToolbarProps",
    ps: { file: "src/React/Types/Component.purs", type: "EdgeToolbarProps" },
    js: { file: "src/Boundary/Edges.purs", type: "JsEdgeToolbarProps" },
    renames: {},
  },
  // The props a consumer's own edge component receives — `edgeTypes`' whole
  // conversion, and the edge-side twin of the `NodeProps` pair above.
  {
    what: "EdgeProps",
    ps: { file: "src/React/Types/Edges.purs", type: "EdgeProps" },
    js: { file: "src/Boundary/Edges.purs", type: "JsEdgeProps" },
    renames: {},
  },
  {
    what: "ConnectionLineComponentProps",
    ps: { file: "src/React/Types/Edges.purs", type: "ConnectionLineComponentProps" },
    js: { file: "src/Boundary/Edges.purs", type: "JsConnectionLineComponentProps" },
    renames: {},
  },
  {
    what: "ControlButtonProps",
    ps: { file: "src/React/Types/Component.purs", type: "ControlButtonProps" },
    js: { file: "src/Boundary/Chrome.purs", type: "JsControlButtonProps" },
    renames: {},
  },
  {
    what: "MiniMapNodeProps",
    ps: { file: "src/React/Types/Component.purs", type: "MiniMapNodeProps" },
    js: { file: "src/Boundary/Chrome.purs", type: "JsMiniMapNodeProps" },
    renames: {},
  },
  {
    what: "EdgeLabelRendererProps",
    ps: { file: "src/React/Types/Component.purs", type: "EdgeLabelRendererProps" },
    js: { file: "src/Boundary/Portals.purs", type: "JsEdgeLabelRendererProps" },
    renames: {},
  },
  {
    what: "ViewportPortalProps",
    ps: { file: "src/React/Types/Component.purs", type: "ViewportPortalProps" },
    js: { file: "src/Boundary/Portals.purs", type: "JsViewportPortalProps" },
    renames: {},
  },
  {
    what: "ReactFlowProviderProps",
    ps: { file: "src/React/Types/Component.purs", type: "ReactFlowProviderProps" },
    js: { file: "src/Boundary/Flow.purs", type: "JsReactFlowProviderProps" },
    renames: {},
  },
  // ── Boundary stage 3: the imperative instance ─────────────────────────
  //
  // `ReactFlowInstance` is the pair that matters most here: it is the only
  // record on this surface whose *every* member is produced outbound, so the
  // compiler forces nothing at all about it and this comparison is the whole
  // check that the crossing names all thirty-two.
  //
  // Two shapes it carries are deliberately absent below, both for the same
  // reason: `getHandleConnections`' argument and `deleteElements`' result are
  // written inline inside `ReactFlowInstance` rather than as named types, so
  // there is nothing for this gate to name on the PureScript side. The hook
  // parameters further down cover the first of them under a different name —
  // `useHandleConnections` takes the same record and does declare it.
  {
    what: "ReactFlowInstance",
    ps: { file: "src/React/Types/Instance.purs", type: "ReactFlowInstance" },
    js: { file: "src/Boundary/Instance.purs", type: "JsReactFlowInstance" },
    renames: {},
  },
  {
    what: "ReactFlowJsonObject",
    ps: { file: "src/React/Types/Instance.purs", type: "ReactFlowJsonObject" },
    js: { file: "src/Boundary/Instance.purs", type: "JsReactFlowJsonObject" },
    renames: {},
  },
  {
    what: "DeleteElementsOptions",
    ps: { file: "src/React/Types/Instance.purs", type: "DeleteElementsOptions" },
    js: { file: "src/Boundary/Instance.purs", type: "JsDeleteElementsOptions" },
    renames: {},
  },
  {
    what: "UpdateOptions",
    ps: { file: "src/React/Types/Instance.purs", type: "UpdateOptions" },
    js: { file: "src/Boundary/Instance.purs", type: "JsUpdateOptions" },
    renames: {},
  },
  {
    what: "Rect",
    ps: { file: "src/System/Types/Geometry.purs", type: "Rect" },
    js: { file: "src/Boundary/Instance.purs", type: "JsRect" },
    renames: {},
  },
  // ps-flow's `NodeConnection` is a synonym for its `HandleConnection`, and
  // upstream's two are the same shape, so one pair covers both queries.
  {
    what: "HandleConnection",
    ps: { file: "src/System/Types/Connection.purs", type: "HandleConnection" },
    js: { file: "src/Boundary/Instance.purs", type: "JsHandleConnection" },
    renames: {},
  },
  {
    what: "ZoomOptions",
    ps: { file: "src/React/Types/Instance.purs", type: "ZoomOptions" },
    js: { file: "src/Boundary/Instance.purs", type: "JsViewportHelperOptions" },
    renames: {},
  },
  {
    what: "SetCenterOptions",
    ps: { file: "src/System/Types/Connection.purs", type: "SetCenterOptions" },
    js: { file: "src/Boundary/Instance.purs", type: "JsSetCenterOptions" },
    renames: {},
  },
  {
    what: "FitBoundsOptions",
    ps: { file: "src/React/Types/Instance.purs", type: "FitBoundsOptions" },
    js: { file: "src/Boundary/Instance.purs", type: "JsFitBoundsOptions" },
    renames: {},
  },
  {
    what: "ScreenToFlowOptions",
    ps: { file: "src/React/Types/Instance.purs", type: "ScreenToFlowOptions" },
    js: { file: "src/Boundary/Instance.purs", type: "JsScreenToFlowOptions" },
    renames: {},
  },
  // ── Boundary stage 3: the hooks' parameter records ────────────────────
  //
  // Inbound, so the compiler already forces every PureScript field to be
  // constructed; what it does not force is a field *removed* from the
  // PureScript record leaving an orphan on the JS side that a consumer can set
  // and nothing reads. Same claim as the component props above.
  //
  // The two renames are upstream disagreeing with itself rather than with
  // ps-flow: `useHandleConnections` calls the handle kind `type` and the node
  // `nodeId`, while `useNodeConnections` calls the handle kind `handleType`
  // and the node `id`. ps-flow spells both consistently, so each hook needs
  // one rename and the two point in opposite directions.
  {
    what: "UseKeyPressOptions",
    ps: { file: "src/React/Hook/KeyPress.purs", type: "UseKeyPressOptions" },
    js: { file: "src/Boundary/Hooks.purs", type: "JsUseKeyPressOptions" },
    renames: {},
  },
  {
    what: "UseNodesInitializedOptions",
    ps: { file: "src/React/Hook/Selectors.purs", type: "UseNodesInitializedOptions" },
    js: { file: "src/Boundary/Hooks.purs", type: "JsUseNodesInitializedOptions" },
    renames: {},
  },
  {
    what: "UseOnViewportChangeOptions",
    ps: { file: "src/React/Hook/Listeners.purs", type: "UseOnViewportChangeOptions" },
    js: { file: "src/Boundary/Hooks.purs", type: "JsUseOnViewportChangeOptions" },
    renames: {},
  },
  {
    what: "UseOnSelectionChangeOptions",
    ps: { file: "src/React/Hook/Listeners.purs", type: "UseOnSelectionChangeOptions" },
    js: { file: "src/Boundary/Hooks.purs", type: "JsUseOnSelectionChangeOptions" },
    renames: {},
  },
  {
    what: "UseHandleConnectionsParams",
    ps: { file: "src/React/Hook/HandleConnections.purs", type: "UseHandleConnectionsParams" },
    js: { file: "src/Boundary/Hooks.purs", type: "JsUseHandleConnectionsParams" },
    renames: { handleType: "type" },
  },
  {
    what: "UseNodeConnectionsParams",
    ps: { file: "src/React/Hook/NodeConnections.purs", type: "UseNodeConnectionsParams" },
    js: { file: "src/Boundary/Hooks.purs", type: "JsNodeConnectionsParams" },
    renames: { nodeId: "id" },
  },
];

// ── The comparison ──────────────────────────────────────────────────────

// Pure, so the falsification probe below can hand it perturbed field lists
// without touching a file.
export function compare({ psType, jsType, psFields, jsFields, renames, refused = [] }) {
  const psSet = new Set(psFields);
  const jsSet = new Set(jsFields);
  const refusedSet = new Set(refused);
  const problems = [];

  // A refused field is one the JS side names so it can be rejected. It must
  // still exist there, and it must still have no PureScript counterpart — once
  // it gains one it can be converted, and going on refusing it would be a
  // working prop turned into an error.
  for (const name of refused) {
    if (!jsSet.has(name)) {
      problems.push(`stale refusal: \`${name}\` is not a field of ${jsType}`);
    }
    if (psSet.has(name)) {
      problems.push(
        `stale refusal: \`${name}\` is refused but ${psType} now has it — convert it instead`
      );
    }
  }

  // A rename must name a field that exists on both sides. One that stops
  // matching means the divergence it documents is gone, and a rename table
  // outliving its cause is how the next silent drop gets missed.
  for (const [psName, jsName] of Object.entries(renames)) {
    if (!psSet.has(psName)) {
      problems.push(
        `stale rename: \`${psName}\` -> \`${jsName}\` names a field ${psType} no longer has`
      );
    }
    if (!jsSet.has(jsName)) {
      problems.push(
        `stale rename: \`${psName}\` -> \`${jsName}\` names a field ${jsType} no longer has`
      );
    }
  }

  const crossed = (name) => renames[name] ?? name;
  const psCrossed = new Set(psFields.map(crossed));
  const reverse = new Map(Object.entries(renames).map(([ps, js]) => [js, ps]));

  for (const name of psFields) {
    if (!jsSet.has(crossed(name))) {
      problems.push(`${psType}.${name} has no field in ${jsType} — it is dropped on the way out`);
    }
  }
  for (const name of jsFields) {
    if (!psCrossed.has(name) && !refusedSet.has(name)) {
      const origin = reverse.get(name);
      problems.push(
        `${jsType}.${name} has no field in ${psType}` +
          (origin ? ` (renamed from \`${origin}\`, which is also missing)` : "")
      );
    }
  }

  return problems;
}

function pairInput(pair) {
  return {
    psType: pair.ps.type,
    jsType: pair.js.type,
    psFields: recordFields(join(repoRoot, pair.ps.file), pair.ps.type),
    jsFields: recordFields(join(repoRoot, pair.js.file), pair.js.type),
    renames: pair.renames,
    refused: pair.refused ?? [],
  };
}

// ── The change unions ───────────────────────────────────────────────────
//
// `NodeChange` and `EdgeChange` are sums, and their JS shape is the flattened
// discriminated union upstream declares — one record whose members are present
// only on the variants that have them. So there is no set equality to check;
// there are three separate claims, and the first is the one that matters,
// because `nodeChangeOut` builds each variant by record *update* on a
// prototype and would drop a new field with no complaint from the compiler.

const unions = [
  {
    what: "NodeChange",
    ps: { file: "src/System/Types/Node.purs", type: "NodeChange" },
    js: { file: "src/Boundary/Elements.purs", type: "JsNodeChange" },
    // The discriminant. PureScript carries it as the constructor itself, so no
    // variant declares it as a field.
    jsOnly: ["type"],
  },
  {
    what: "EdgeChange",
    ps: { file: "src/System/Types/Edge.purs", type: "EdgeChange" },
    js: { file: "src/Boundary/Elements.purs", type: "JsEdgeChange" },
    jsOnly: ["type"],
  },
];

export function compareUnion({ psType, jsType, variants, jsFields, jsOnly }) {
  const jsSet = new Set(jsFields);
  const problems = [];
  const used = new Set(jsOnly);

  for (const [ctor, fields] of Object.entries(variants)) {
    for (const name of fields) {
      used.add(name);
      if (!jsSet.has(name)) {
        problems.push(
          `${psType}.${ctor}.${name} has no field in ${jsType} — it is dropped on the way out`
        );
      }
    }
  }

  for (const name of jsFields) {
    if (!used.has(name)) {
      problems.push(`${jsType}.${name} is carried by no ${psType} variant`);
    }
  }

  for (const name of jsOnly) {
    if (!jsSet.has(name)) {
      problems.push(`stale discriminant: \`${name}\` is not a field of ${jsType}`);
    }
  }

  return problems;
}

function unionInput(union) {
  const psPath = join(repoRoot, union.ps.file);
  const ctors = dataConstructors(psPath, union.ps.type);
  return {
    psType: union.ps.type,
    jsType: union.js.type,
    // Read from the declaration, so a variant added to the sum is picked up
    // here rather than waiting for someone to extend a list.
    variants: Object.fromEntries(
      ctors.map((ctor) => [ctor, constructorFields(psPath, union.ps.type, ctor)])
    ),
    jsFields: recordFields(join(repoRoot, union.js.file), union.js.type),
    jsOnly: union.jsOnly,
  };
}

// ── The falsification probe ─────────────────────────────────────────────
//
// Three failure classes, three perturbations, checked against the real field
// lists so the probe cannot pass on a shape the gate never sees.

function falsify(inputs, unionInputs) {
  const base = inputs[0];
  const optionsPair = inputs.find((i) => i.refused.length > 0);
  const union = unionInputs[0];
  const firstVariant = Object.keys(union.variants)[0];

  const checks = [
    [
      "a field added to the PureScript record and not to the JS one",
      () => compare({ ...base, psFields: [...base.psFields, "psOnlyFieldForProbe"] }),
    ],
    [
      "a field added to the JS record and not to the PureScript one",
      () => compare({ ...base, jsFields: [...base.jsFields, "jsOnlyFieldForProbe"] }),
    ],
    [
      "a rename naming a field neither side has",
      () => compare({ ...base, renames: { ...base.renames, goneFromBoth: "alsoGone" } }),
    ],
    [
      "a refusal that no longer names a JS field",
      () => compare({ ...optionsPair, refused: [...optionsPair.refused, "goneFromJs"] }),
    ],
    [
      "a refused field the PureScript record has since gained",
      () =>
        compare({
          ...optionsPair,
          psFields: [...optionsPair.psFields, optionsPair.refused[0]],
        }),
    ],
    [
      "a field added to a change variant and not to its JS union",
      () =>
        compareUnion({
          ...union,
          variants: {
            ...union.variants,
            [firstVariant]: [...union.variants[firstVariant], "variantOnlyFieldForProbe"],
          },
        }),
    ],
    [
      "a field on the JS union that no variant carries",
      () => compareUnion({ ...union, jsFields: [...union.jsFields, "jsOnlyUnionFieldForProbe"] }),
    ],
  ];

  for (const [what, run] of checks) {
    if (run().length === 0) {
      fail(`falsification probe failed — the drift check stays green on ${what}`);
    }
  }

  if (compare(base).length !== 0 || compareUnion(union).length !== 0) {
    fail("falsification probe failed — the unperturbed baseline is not green");
  }
}

// ── Run ─────────────────────────────────────────────────────────────────

const inputs = pairs.map(pairInput);
const unionInputs = unions.map(unionInput);

let failures = 0;
const rows = [];

const report = (what, problems, summary) => {
  if (problems.length > 0) {
    failures += problems.length;
    console.error(`\n✗ ${what}`);
    for (const problem of problems) console.error(`    ${problem}`);
  } else {
    rows.push(`  ✓ ${what.padEnd(20)} ${summary}`);
  }
};

pairs.forEach((pair, i) => {
  const refused = inputs[i].refused.length;
  report(
    pair.what,
    compare(inputs[i]),
    `${inputs[i].psFields.length} fields` + (refused ? `, ${refused} refused` : "")
  );
});

unions.forEach((union, i) => {
  const input = unionInputs[i];
  report(
    union.what,
    compareUnion(input),
    `${Object.keys(input.variants).length} variants, ${input.jsFields.length} fields`
  );
});

if (failures > 0) {
  console.error(
    `\n${failures} boundary drift problem(s). A field on one side of the crossing ` +
      `and not the other is either silently dropped outbound or invented inbound; ` +
      `add it to the JS-shaped record in src/Boundary/ and convert it, or record ` +
      `the rename in parity/boundary/drift.mjs.\n`
  );
  process.exit(1);
}

falsify(inputs, unionInputs);

console.log("boundary drift: every crossed record agrees, field for field.");
console.log(rows.join("\n"));
console.log("\n  ✓ falsification probe — the check goes red on all seven failure classes.");
