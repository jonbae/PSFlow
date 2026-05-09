# 030 — Hooks: `useReactFlow` and viewport helpers

## Title
Port the rich `useReactFlow` instance hook (~20 methods) and its companions: `useViewportHelper`, `useUpdateNodeInternals`, `useHandleConnections`, `useNodeConnections`, `useNodesEdgesState`. This is the heaviest hook ticket.

## Source Files
- `xyflow-main/packages/react/src/hooks/useReactFlow.ts` (~315 LoC)
- `xyflow-main/packages/react/src/hooks/useViewportHelper.ts`
- `xyflow-main/packages/react/src/hooks/useUpdateNodeInternals.ts`
- `xyflow-main/packages/react/src/hooks/useHandleConnections.ts`
- `xyflow-main/packages/react/src/hooks/useNodeConnections.ts`
- `xyflow-main/packages/react/src/hooks/useNodesEdgesState.ts`

## Target Modules
- `React.Hook.ReactFlow` (the main `useReactFlow`)
- `React.Hook.ViewportHelper`
- `React.Hook.UpdateNodeInternals`
- `React.Hook.HandleConnections`
- `React.Hook.NodeConnections`
- `React.Hook.NodesEdgesState`

## Key Types / Functions

### `useReactFlow`

```purescript
useReactFlow :: Hook _ ReactFlowInstance
```

`ReactFlowInstance` is the record defined in ticket 024. The hook composes `useViewportHelper`, the store API, and the batch context, then returns the merged record. Implementation mirrors `useReactFlow.ts` — each method becomes a closure capturing `store` and `batchContext`.

Method sketch (one example — `deleteElements`):

```purescript
deleteElements :: { nodes :: Array Node, edges :: Array Edge }
               -> Aff { deletedNodes :: Array Node, deletedEdges :: Array Edge }
deleteElements { nodes: ns, edges: es } = do
  st <- liftEffect store.getState
  result <- getElementsToRemove
              { nodesToRemove: ns
              , edgesToRemove: es
              , nodes: st.nodes
              , edges: st.edges
              , onBeforeDelete: st.onBeforeDelete
              }
  when (Array.length result.edges > 0) do
    let edgeChanges = map elementToRemoveChange result.edges
    liftEffect $ do
      maybe (pure unit) (\f -> f result.edges) st.onEdgesDelete
      store.dispatch (TriggerEdgeChanges edgeChanges)
  when (Array.length result.nodes > 0) do
    let nodeChanges = map elementToRemoveChange result.nodes
    liftEffect $ do
      maybe (pure unit) (\f -> f result.nodes) st.onNodesDelete
      store.dispatch (TriggerNodeChanges nodeChanges)
  ...
  pure { deletedNodes: result.nodes, deletedEdges: result.edges }
```

### `useViewportHelper`

```purescript
type ViewportHelper =
  { zoomIn :: Maybe ViewportHelperFunctionOptions -> Aff Boolean
  , zoomOut :: Maybe ViewportHelperFunctionOptions -> Aff Boolean
  , zoomTo :: Number -> Maybe ViewportHelperFunctionOptions -> Aff Boolean
  , getZoom :: Effect Number
  , setViewport :: Viewport -> Maybe ViewportHelperFunctionOptions -> Aff Boolean
  , getViewport :: Effect Viewport
  , fitView :: Maybe FitViewOptions -> Aff Boolean
  , setCenter :: Number -> Number -> SetCenterOptions -> Aff Boolean
  , fitBounds :: Rect -> FitBoundsOptions -> Aff Boolean
  , screenToFlowPosition :: XYPosition -> Effect XYPosition
  , flowToScreenPosition :: XYPosition -> Effect XYPosition
  }

useViewportHelper :: Hook _ ViewportHelper
```

Most methods are direct calls into the `panZoom :: PanZoomInstance` field of the store (which is `Maybe`). Each method does `store.getState >>= \s -> case s.panZoom of Just pz -> ...; Nothing -> pure false`.

### `useUpdateNodeInternals`

```purescript
useUpdateNodeInternals :: Hook _ (Array String -> Effect Unit)
```

Returns a function that dispatches `UpdateNodeInternals` with the given IDs.

### `useHandleConnections` / `useNodeConnections`

```purescript
useHandleConnections :: HandleConnectionQuery -> Hook _ (Array HandleConnection)
useNodeConnections :: NodeConnectionQuery -> Hook _ (Array NodeConnection)
```

Both are thin `useStore` wrappers selecting from `connectionLookup`. Build the lookup key as `${nodeId}-${type}-${handleId}` mirroring the TS source.

### `useNodesEdgesState`

```purescript
useNodesEdgesState :: Array Node -> Array Edge ->
  Hook _ { nodes :: Array Node, setNodes :: (Array Node -> Array Node) -> Effect Unit
         , edges :: Array Edge, setEdges :: (Array Edge -> Array Edge) -> Effect Unit
         , onNodesChange :: Array NodeChange -> Effect Unit
         , onEdgesChange :: Array EdgeChange -> Effect Unit
         }
```

The TS exports two hooks (`useNodesState`, `useEdgesState`) returned as a tuple-like; PS combines into one record-returning hook for symmetry. The public API (ticket 049) re-exports two helpers `useNodesState` and `useEdgesState` that destructure this record so the contract is preserved.

## Idiomatic Notes

- **`useReactFlow` returns a memoised record.** TS uses `useMemo([viewportInitialized])` so the record reference is stable. PS does the same — wrap the merge in `useMemo`.
- **All `Effect Unit`/`Aff` discipline.** No method is pure — every one reads state or dispatches.
- **`Aff` for `Promise`-returning methods.** `fitView`, `deleteElements`, `setCenter`, `setViewport`, `zoomIn`, `zoomOut`, `zoomTo`, `fitBounds`. The `fitViewResolver` AVar (set up in ticket 026) is what these `Aff`s wait on.
- **`getInternalNode`/`getNode`/`getEdge` return `Maybe`.** TS returns `T | undefined`. PS returns `Effect (Maybe T)`.
- **Helpers reuse system functions.** `getNodesBounds` calls `System.Utils.Graph.getNodesBounds`. `getIntersectingNodes` calls `System.Utils.General.getOverlappingArea`. Don't reimplement.
- **`setNodes`/`setEdges` queue into `BatchProvider`.** Match TS — they push into `batchContext.nodeQueue`/`edgeQueue` rather than dispatching an action immediately. The `BatchProvider` (ticket 043) flushes the queue per render.
- **`useUpdateNodeInternals` accepts `Array String`.** TS supports a single string or an array; PS chooses array-only and the `useUpdateNodeInternals id` style becomes `useUpdateNodeInternals [id]`. Document divergence.
- **`useHandleConnections`/`useNodeConnections` have a key construction quirk.** Mirror TS's empty-handle behaviour: when `id` is undefined the key is `${nodeId}-${type}` (no trailing `-`); when present it is `${nodeId}-${type}-${id}`. Same for `useNodeConnections` with `type`/`handleId`.

## New Spago Dependencies
- None new beyond 027 and `aff`/`avar` from 026

## Prerequisite Tickets
- 027 (`useStore`, `useStoreApi`)
- 028 (`useViewport` reused inside)
- 029 (listener pattern reference)
- 026 (Action constructors)
- 024 (`ReactFlowInstance` shape)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `useReactFlow` returns a record with every field listed in `ReactFlowInstance` (ticket 024).
- The returned record reference is stable across re-renders that don't change `viewportInitialized`.
- `fitView` returns an `Aff Boolean` that resolves once the viewport animation completes.
- `useUpdateNodeInternals` triggers a `UpdateNodeInternals` action via dispatch.
- All viewport helpers gracefully no-op (returning `false`/sentinel) when `panZoom` is `Nothing`.
