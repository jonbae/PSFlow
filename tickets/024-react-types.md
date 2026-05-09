# 024 — React Types

## Title
Port the React-layer prop and state type definitions: `ReactFlowProps`, `ReactFlowState`, `ReactFlowInstance`, plus per-component prop types.

## Source Files
- `xyflow-main/packages/react/src/types/index.ts`
- `xyflow-main/packages/react/src/types/general.ts`
- `xyflow-main/packages/react/src/types/component-props.ts`
- `xyflow-main/packages/react/src/types/store.ts`
- `xyflow-main/packages/react/src/types/instance.ts`
- `xyflow-main/packages/react/src/types/nodes.ts`
- `xyflow-main/packages/react/src/types/edges.ts`

## Target Modules
- `React.Types` (re-export aggregator)
- `React.Types.Component` (prop types)
- `React.Types.Store` (`ReactFlowState` shape)
- `React.Types.Instance` (`ReactFlowInstance` interface)
- `React.Types.Nodes` (React-layer node aliases)
- `React.Types.Edges` (React-layer edge aliases)
- `React.Types.General`

## Key Types

### `React.Types.Store` — `ReactFlowState`

A record with ~160 fields. Imports from `System.Types.*`. Includes every field from the TS interface; group into nested records only where the TS source does. Preserve field names exactly.

| TypeScript | Proposed PureScript |
|---|---|
| `nodes: Node[]` | `nodes :: Array Node` |
| `nodeLookup: Map<string, InternalNode>` | `nodeLookup :: Map String InternalNode` |
| `parentLookup: Map<string, ...>` | `parentLookup :: ParentLookup` |
| `edges: Edge[]` | `edges :: Array Edge` |
| `edgeLookup: Map<string, Edge>` | `edgeLookup :: Map String Edge` |
| `connectionLookup: ConnectionLookup` | `connectionLookup :: ConnectionLookup` |
| `transform: Transform` | `transform :: Transform` |
| `width: number; height: number` | `width :: Number, height :: Number` |
| `panZoom: PanZoomInstance \| null` | `panZoom :: Maybe PanZoomInstance` |
| `minZoom, maxZoom, translateExtent, nodeExtent` | `Number`, `Number`, `CoordinateExtent`, `CoordinateExtent` |
| `connection: ConnectionState` | `connection :: ConnectionState` |
| `nodesSelectionActive, userSelectionActive` | `Boolean` each |
| `userSelectionRect: SelectionRect \| null` | `userSelectionRect :: Maybe SelectionRect` |
| ~25 boolean configuration flags | `Boolean` each |
| ~20 callback fields (`onNodesChange`, etc.) | `Maybe (... -> Effect Unit)` each |
| `fitViewQueued: boolean` | `Boolean` |
| `fitViewResolver: Resolver \| null` | `Maybe (AVar Boolean)` or `Maybe { resolve :: Boolean -> Effect Unit, promise :: Aff Boolean }` |
| `onNodesChangeMiddlewareMap: Map<symbol, ...>` | `Map MiddlewareKey (Action -> Action -> Effect Unit)` (newtype `MiddlewareKey`) |
| `domNode: HTMLDivElement \| null` | `Maybe HTMLDivElement` |
| `lib: 'react'` | `lib :: String` (always `"react"`) |
| `debug: boolean` | `debug :: Boolean` |

### `React.Types.Instance` — `ReactFlowInstance`

The rich return type of `useReactFlow()`. A record of `Effect`/`Aff`-typed functions plus the viewport helper functions.

| TypeScript | Proposed PureScript |
|---|---|
| `getNodes(): Node[]` | `getNodes :: Effect (Array Node)` |
| `getEdges(): Edge[]` | `getEdges :: Effect (Array Edge)` |
| `getNode(id: string): Node \| undefined` | `getNode :: String -> Effect (Maybe Node)` |
| `getEdge(id: string): Edge \| undefined` | `getEdge :: String -> Effect (Maybe Edge)` |
| `getInternalNode(id): InternalNode \| undefined` | `getInternalNode :: String -> Effect (Maybe InternalNode)` |
| `setNodes(payload)` | `setNodes :: SetNodesPayload -> Effect Unit` |
| `setEdges(payload)` | `setEdges :: SetEdgesPayload -> Effect Unit` |
| `addNodes(payload)` | `addNodes :: NodeOrArray -> Effect Unit` |
| `addEdges(payload)` | `addEdges :: EdgeOrArray -> Effect Unit` |
| `toObject()` | `toObject :: Effect FlowExportObject` |
| `deleteElements(args): Promise<{deletedNodes, deletedEdges}>` | `deleteElements :: { nodes :: Array Node, edges :: Array Edge } -> Aff { deletedNodes :: Array Node, deletedEdges :: Array Edge }` |
| `getIntersectingNodes(...)` | `getIntersectingNodes :: NodeOrRect -> Boolean -> Maybe (Array Node) -> Effect (Array Node)` |
| `isNodeIntersecting(...)` | `isNodeIntersecting :: NodeOrRect -> Rect -> Boolean -> Effect Boolean` |
| `updateNode/Data/Edge/EdgeData(id, update, opts?)` | `String -> Update -> { replace :: Boolean } -> Effect Unit` (one fn each) |
| `getNodesBounds(nodes)` | `getNodesBounds :: Array NodeRef -> Effect Rect` |
| `getHandleConnections({...})` | `getHandleConnections :: HandleQuery -> Effect (Array HandleConnection)` |
| `getNodeConnections({...})` | `getNodeConnections :: NodeQuery -> Effect (Array NodeConnection)` |
| `fitView(opts?): Promise<boolean>` | `fitView :: Maybe FitViewOptions -> Aff Boolean` |
| viewport helpers (`zoomIn`, `zoomOut`, `setViewport`, etc.) | `Effect`/`Aff`-typed methods (see ticket 030) |
| `viewportInitialized: boolean` | `viewportInitialized :: Boolean` |

### `React.Types.Component` — Prop records

One record type per source component. Names mirror the TS exactly:

- `ReactFlowProps` (~100 fields — see `xyflow-main/packages/react/src/types/general.ts`)
- `HandleProps`, `PanelProps`, `EdgeLabelRendererProps`, `ViewportPortalProps`
- `BaseEdgeProps`, `StraightEdgeProps`, `BezierEdgeProps`, `SimpleBezierEdgeProps`, `StepEdgeProps`, `SmoothStepEdgeProps`, `EdgeTextProps`
- `NodeWrapperProps`, `EdgeWrapperProps`, `ConnectionLineProps`
- `BackgroundProps`, `ControlsProps`, `ControlButtonProps`, `MiniMapProps`, `NodeToolbarProps`, `NodeResizerProps`, `EdgeToolbarProps`

### Other types

| TypeScript | Proposed PureScript |
|---|---|
| `FitViewOptions` | record with `Maybe`-wrapped fields |
| `UnselectNodesAndEdgesParams` | record |
| `FlowExportObject` | `{ nodes, edges, viewport }` |
| `GeneralHelpers<NodeType, EdgeType>` | not exposed publicly; internal type |
| `ReactFlowJsonObject<NodeType, EdgeType>` | `{ nodes, edges, viewport }` |

## Idiomatic Notes

- **Field names match TS exactly.** No renaming `nodeLookup` → `nodeMap` etc. The TS-source diffability is more valuable than PS-style renames.
- **Generics flatten.** TS uses `<NodeType extends Node = Node>` everywhere. PS uses concrete `Node` (already a row-typed record from `System.Types.Node`). The user-facing data row is exposed via the `data` field on `Node`.
- **`Maybe` for optional.** Every TS optional field (`field?: T`) becomes `field :: Maybe T`. Do not "default to a sentinel" — leave `Nothing` and let the consumer pattern-match.
- **`Effect`/`Aff` discipline.** Anything reading from React state, the store, or the DOM is `Effect`. Anything returning a `Promise<T>` (notably `fitView`, `deleteElements`) is `Aff`.
- **Callbacks as `Effect Unit`.** TS `onNodesChange?: (changes: NodeChange[]) => void` becomes `onNodesChange :: Maybe (Array NodeChange -> Effect Unit)`.
- **`Map` and `Set` from `Data.Map`/`Data.Set`.** Already imported by the system layer.
- **`MiddlewareKey` newtype.** TS uses `symbol` keys for the middleware map to give each consumer a unique handle. In PS, use `newtype MiddlewareKey = MiddlewareKey Int` and a per-mount counter; or use `unique` from `purescript-symbols` if available. Document the divergence.
- **No `class instances`.** `ReactFlowInstance` is a plain record of methods, not a typeclass.

## New Spago Dependencies
- `react-basic` — for `JSX` (used in prop records that take children)
- `react-basic-hooks` — for `Hook` (used in hook prop types)
- All system-layer deps remain available

## Prerequisite Tickets
- 022 (rename XYFlow → System)
- All system tickets 001–020 (types are imported)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- All exported type names from `xyflow-main/packages/react/src/types/index.ts` exist in `React.Types`.
- Field names on `ReactFlowState` match the TS source exactly.
- Field names on `ReactFlowInstance` match the TS source exactly.
- No type uses `Foreign` or `unsafeCoerce` in this ticket.
- `React.Types.Component` exports one record type per public component listed in the ticket.
