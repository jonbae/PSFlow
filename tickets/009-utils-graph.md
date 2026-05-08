# 009 — Graph Utility Functions

## Title
Port graph traversal, node bounds, fit-view, and deletion utilities

## Source Files
- `xyflow-main/packages/system/src/utils/graph.ts`

## Target Module
`XYFlow.Utils.Graph`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `isEdgeBase :: (element) -> boolean` | `isEdgeBase :: forall r. { id :: String, source :: String, target :: String \| r } -> Boolean` — or simply accept `EdgeBase edgeData`; see notes |
| `isNodeBase :: (element) -> boolean` | As above — not needed in PS |
| `isInternalNodeBase :: (element) -> boolean` | Not needed in PS |
| `getOutgoers :: (node, nodes, edges) -> NodeType[]` | `getOutgoers :: forall nodeData edgeData. { id :: String } -> Array (NodeBase nodeData) -> Array (EdgeBase edgeData) -> Array (NodeBase nodeData)` |
| `getIncomers :: (node, nodes, edges) -> NodeType[]` | `getIncomers :: forall nodeData edgeData. { id :: String } -> Array (NodeBase nodeData) -> Array (EdgeBase edgeData) -> Array (NodeBase nodeData)` |
| `getNodePositionWithOrigin :: (node, nodeOrigin?) -> XYPosition` | `getNodePositionWithOrigin :: NodeBase nodeData -> NodeOrigin -> XYPosition` |
| `getNodesBounds :: (nodes, params?) -> Rect` | `getNodesBounds :: Array (NodeBase nodeData) -> Maybe (NodeLookup nodeData) -> NodeOrigin -> Rect` |
| `getInternalNodesBounds :: (nodeLookup, params?) -> Rect` | `getInternalNodesBounds :: Map String (InternalNodeBase nodeData) -> Maybe (InternalNodeBase nodeData -> Boolean) -> Rect` |
| `getNodesInside :: (nodes, rect, transform?, partially?, excludeNonSelectable?) -> InternalNodeBase[]` | `getNodesInside :: Map String (InternalNodeBase nodeData) -> Rect -> Transform -> Boolean -> Boolean -> Array (InternalNodeBase nodeData)` |
| `getConnectedEdges :: (nodes, edges) -> EdgeType[]` | `getConnectedEdges :: forall nodeData edgeData. Array (NodeBase nodeData) -> Array (EdgeBase edgeData) -> Array (EdgeBase edgeData)` |
| `fitViewport :: (params, options?) -> Promise<boolean>` | `fitViewport :: FitViewParams nodeData -> Maybe FitViewOptions -> Aff Boolean` |
| `calculateNodePosition :: ({nodeId, nextPosition, nodeLookup, ...}) -> { position, positionAbsolute }` | `calculateNodePosition :: String -> XYPosition -> NodeLookup nodeData -> NodeOrigin -> Maybe CoordinateExtent -> Maybe (String -> String -> Effect Unit) -> Maybe { position :: XYPosition, positionAbsolute :: XYPosition }` |
| `getElementsToRemove :: ({nodesToRemove, edgesToRemove, nodes, edges, onBeforeDelete?}) -> Promise<{nodes, edges}>` | `getElementsToRemove :: forall nodeData edgeData. { nodesToRemove :: Array (Partial (NodeBase nodeData)), edgesToRemove :: Array (Partial (EdgeBase edgeData)), nodes :: Array (NodeBase nodeData), edges :: Array (EdgeBase edgeData), onBeforeDelete :: Maybe (OnBeforeDelete nodeData edgeData) } -> Aff { nodes :: Array (NodeBase nodeData), edges :: Array (EdgeBase edgeData) }` |
| `GetNodesBoundsParams` | `type GetNodesBoundsParams nodeData = { nodeOrigin :: Maybe NodeOrigin, nodeLookup :: Maybe (NodeLookup nodeData) }` |
| `GetInternalNodesBoundsParams` | `type GetInternalNodesBoundsParams nodeData = { useRelativePosition :: Boolean, filter :: Maybe (InternalNodeBase nodeData -> Boolean) }` |

## Idiomatic Notes

- **`isEdgeBase`, `isNodeBase`, `isInternalNodeBase`.** These are runtime type guards for `any`-typed data. PS has no `any`. The guards exist because TS cannot enforce structural types at runtime. In PS, the compiler enforces types statically — these functions should not be ported as general-purpose guards. Wherever they are called internally, replace with explicit pattern matching or ADT constructors.
- **`getOutgoers` / `getIncomers`.** TS uses `Set` for `outgoerIds` then filters. In PS, use `Data.Set.fromFoldable` on the edge array and `Array.filter`. The function body can be expressed idiomatically as a fold or with comprehension style.
- **`getNodesBounds` warning about `nodeLookup`.** The TS function logs a console warning if `nodeLookup` is not provided. In PS, make `nodeLookup` an explicit `Maybe (NodeLookup nodeData)` argument — the function remains pure; callers make the tradeoff explicit. Remove the console warning.
- **`getNodesInside`.** The TS function has five parameters with defaults for the last three. In PS, pass all parameters explicitly. The Transform defaults to `[0, 0, 1]` in TS; provide `identityTransform :: Transform` as a constant (in ticket 001).
- **`fitViewport`.** Returns `Promise<boolean>`. This is `Aff Boolean` in PS. It calls `panZoom.setViewport(...)` which is itself effectful. The entire function body becomes a `do` block in `Aff`.
- **`calculateNodePosition`.** This TS function calls `nodeLookup.get(nodeId)!` (non-null assertion). The PS version must be total: return `Maybe { position :: XYPosition, positionAbsolute :: XYPosition }` — returning `Nothing` if the node is not found. Callers can use `fromMaybe` to supply a fallback.
- **`getElementsToRemove`.** The `onBeforeDelete` callback returns `Promise<boolean | { nodes, edges }>`. In PS:
  ```purescript
  type OnBeforeDelete nodeData edgeData =
    { nodes :: Array (NodeBase nodeData), edges :: Array (EdgeBase edgeData) }
    -> Aff (Either Boolean { nodes :: Array (NodeBase nodeData), edges :: Array (EdgeBase edgeData) })
  ```
  The `Either Boolean` models the two return types. `Left true` = proceed; `Left false` = cancel all; `Right {nodes, edges}` = proceed with this subset.
- **`Partial<NodeType>` arguments.** TS `Partial<T>` (all fields optional) is used as `nodesToRemove` / `edgesToRemove` types, but only `id` is accessed. In PS, accept `Array { id :: String }` — be explicit that only the `id` is needed.
- **`getFitViewNodes` (internal).** The internal helper that filters nodes for fit-view is not exported. Implement it as a private `where` binding inside `fitViewport`.

## New Spago Dependencies
- `aff`
- `either`
- `maybe`
- `ordered-collections` (for `Set`, `Map`)

## Prerequisite Tickets
- 001 (Geometry)
- 003 (Connection — `FitViewOptionsBase`)
- 004 (Node types)
- 005 (Edge types)
- 006 (PanZoom — `PanZoomInstance`)
- 007 (Constants)
- 008 (Utils.General)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `getOutgoers` and `getIncomers` are pure functions.
- `calculateNodePosition` returns `Maybe` — not partial.
- `fitViewport` has type `Aff Boolean`.
- `getElementsToRemove` uses `Aff` and accepts the `OnBeforeDelete` callback as `Maybe`.
- Tests: `getOutgoers` on a simple graph returns the correct set of nodes; `getIncomers` returns the correct set.
