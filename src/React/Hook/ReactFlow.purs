-- | `useReactFlow` — returns the rich `ReactFlowInstance` record that
-- | host components use to read state, push updates, and drive the
-- | viewport. Mirrors
-- | `xyflow-main/packages/react/src/hooks/useReactFlow.ts`.
-- |
-- | **Composition.** Internally composes `useViewportHelper`,
-- | `useStoreApi`, `useBatchContext`, and a `useStore` slice tracking
-- | `viewportInitialized = isJust panZoom`. The returned record is
-- | wrapped in `useMemo` keyed on `viewportInitialized` so callers that
-- | take the instance as a `useEffect` dep don't re-run between init
-- | renders.
-- |
-- | **`setNodes` / `setEdges` / `addNodes` / `addEdges` queue into
-- | `BatchProvider`.** Each pushes a `QueueUpdate` into the batch
-- | context's queues, which the provider (ticket 043) flushes per
-- | render into a single `SetNodes` / `SetEdges` action.
-- |
-- | **`fitView` returns an `Aff Boolean` backed by an AVar.** The
-- | reducer's `ResolveFitView` effect descriptor `put`s into the
-- | resolver once the viewport animation completes; we `read` it here
-- | so the result stays available for any other listeners.
module React.Hook.ReactFlow
  ( UseReactFlow(..)
  , GeneralHelpers
  , useReactFlow
  ) where

import Prelude

import Data.Array (filter, find, fromFoldable, length, mapMaybe) as Array
import Data.Either (Either(..))
import Data.Foldable (for_)
import Data.Map (lookup) as Map
import Data.Map.Internal (values) as Map
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.Newtype (class Newtype)
import Effect (Effect)
import Effect.AVar as AVar
import Effect.Aff (Aff)
import Effect.Aff.AVar as AffAVar
import Effect.Class (liftEffect)
import React.Basic.Hooks (Hook, UseContext, UseMemo, coerceHook, useMemo)
import React.Basic.Hooks as React
import React.Context.Batch (BatchContext, QueueItem(..), useBatchContext, OpaqueEdgeBatch, OpaqueNodeBatch)
import React.Hook.Store (UseStore, UseStoreApi, useStore, useStoreApi)
import React.Hook.ViewportHelper (UseViewportHelper, useViewportHelper)
import React.Store.Action (Action(..))
import React.Store.Shell (Store)
import React.Types.Edges (Edge)
import React.Types.General (FitView, OnBeforeDelete)
import React.Types.Instance
  ( DeleteElementsOptions
  , NodeOrIdOrRect(..)
  , NodeRefForBounds(..)
  , ReactFlowInstance
  , ReactFlowJsonObject
  , UpdateOptions
  , ViewportHelperFunctions
  )
import React.Types.Nodes (InternalNode, Node)
import React.Types.Store (ReactFlowState)
import System.Types.Connection (HandleConnection, NodeConnection)
import System.Types.Edge (EdgeChange(..))
import System.Types.Geometry (Rect, Transform(..))
import System.Types.Handle (HandleType(..))
import System.Types.Node (NodeChange(..), NodeBase, InternalNodeBase, NodeLookup)
import System.Utils.General (evaluateAbsolutePosition, getOverlappingArea, nodeToRect)
import System.Utils.Graph (getElementsToRemove, getNodesBounds) as Graph
import Unsafe.Coerce (unsafeCoerce)

newtype UseReactFlow n e hooks =
  UseReactFlow
    ( UseMemo Boolean (ReactFlowInstance n e)
        ( UseStore Boolean
            ( UseMemo Unit (GeneralHelpers n e)
                ( UseContext (Maybe BatchContext)
                    ( UseViewportHelper
                        (UseStoreApi hooks)
                    )
                )
            )
        )
    )

derive instance newtypeUseReactFlow :: Newtype (UseReactFlow n e hooks) _

-- | The non-viewport half of `ReactFlowInstance`. Kept as a separate
-- | type so the inner `useMemo unit` can name it.
type GeneralHelpers n e =
  { getNodes :: Effect (Array (Node n))
  , setNodes :: (Array (Node n) -> Array (Node n)) -> Effect Unit
  , addNodes :: Array (Node n) -> Effect Unit
  , getNode :: String -> Effect (Maybe (Node n))
  , getInternalNode :: String -> Effect (Maybe (InternalNode n))
  , getEdges :: Effect (Array (Edge e))
  , setEdges :: (Array (Edge e) -> Array (Edge e)) -> Effect Unit
  , addEdges :: Array (Edge e) -> Effect Unit
  , getEdge :: String -> Effect (Maybe (Edge e))
  , toObject :: Effect (ReactFlowJsonObject n e)
  , deleteElements ::
      DeleteElementsOptions n e
      -> Aff { deletedNodes :: Array (Node n), deletedEdges :: Array (Edge e) }
  , getIntersectingNodes ::
      NodeOrIdOrRect n
      -> Maybe Boolean
      -> Maybe (Array (Node n))
      -> Effect (Array (Node n))
  , isNodeIntersecting :: NodeOrIdOrRect n -> Rect -> Maybe Boolean -> Effect Boolean
  , updateNode :: String -> (Node n -> Node n) -> UpdateOptions -> Effect Unit
  , updateNodeData :: String -> (Node n -> Node n) -> UpdateOptions -> Effect Unit
  , updateEdge :: String -> (Edge e -> Edge e) -> UpdateOptions -> Effect Unit
  , updateEdgeData :: String -> (Edge e -> Edge e) -> UpdateOptions -> Effect Unit
  , getNodesBounds :: Array (NodeRefForBounds n) -> Effect Rect
  , getHandleConnections ::
      { handleType :: HandleType, nodeId :: String, id :: Maybe String }
      -> Effect (Array HandleConnection)
  , getNodeConnections ::
      { handleType :: Maybe HandleType, nodeId :: String, handleId :: Maybe String }
      -> Effect (Array NodeConnection)
  , fitView :: FitView
  }

useReactFlow :: forall n e. Hook (UseReactFlow n e) (ReactFlowInstance n e)
useReactFlow = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi (Store n e))
  viewportHelper <- useViewportHelper
  batchContext <- useBatchContext
  generalHelper <- useMemo unit \_ -> mkGeneralHelpers store batchContext
  viewportInitialized <- useStore selectInitialized
  instance_ <- useMemo viewportInitialized \_ ->
    merge generalHelper viewportHelper viewportInitialized
  pure instance_
  where
  selectInitialized :: ReactFlowState n e -> Boolean
  selectInitialized s = isJust s.panZoom

-- | Combine the two halves into the final `ReactFlowInstance` record.
merge
  :: forall n e
   . GeneralHelpers n e
  -> ViewportHelperFunctions
  -> Boolean
  -> ReactFlowInstance n e
merge g v viewportInitialized =
  { getNodes: g.getNodes
  , setNodes: g.setNodes
  , addNodes: g.addNodes
  , getNode: g.getNode
  , getInternalNode: g.getInternalNode
  , getEdges: g.getEdges
  , setEdges: g.setEdges
  , addEdges: g.addEdges
  , getEdge: g.getEdge
  , toObject: g.toObject
  , deleteElements: g.deleteElements
  , getIntersectingNodes: g.getIntersectingNodes
  , isNodeIntersecting: g.isNodeIntersecting
  , updateNode: g.updateNode
  , updateNodeData: g.updateNodeData
  , updateEdge: g.updateEdge
  , updateEdgeData: g.updateEdgeData
  , getNodesBounds: g.getNodesBounds
  , getHandleConnections: g.getHandleConnections
  , getNodeConnections: g.getNodeConnections
  , fitView: g.fitView
  , zoomIn: v.zoomIn
  , zoomOut: v.zoomOut
  , zoomTo: v.zoomTo
  , getZoom: v.getZoom
  , setViewport: v.setViewport
  , getViewport: v.getViewport
  , setCenter: v.setCenter
  , fitBounds: v.fitBounds
  , screenToFlowPosition: v.screenToFlowPosition
  , flowToScreenPosition: v.flowToScreenPosition
  , viewportInitialized
  }

-- | Build the closure-record of general (non-viewport) methods. Each
-- | method closes over `store` and `batchContext`. The TS source uses
-- | `useMemo` with `[]` deps so the record reference is stable; we do
-- | the same.
mkGeneralHelpers :: forall n e. Store n e -> BatchContext -> GeneralHelpers n e
mkGeneralHelpers store batchContext =
  { getNodes: do
      s <- store.getState
      pure s.nodes

  , setNodes: \updater ->
      pushNodeQueue batchContext (QueueUpdate (coerceNodeFn updater))

  , addNodes: \newNodes ->
      pushNodeQueue batchContext
        (QueueUpdate (coerceNodeFn \existing -> existing <> newNodes))

  , getNode: \id -> do
      s <- store.getState
      pure (Array.find (\n -> n.id == id) s.nodes)

  , getInternalNode: \id -> do
      s <- store.getState
      pure (Map.lookup id s.nodeLookup)

  , getEdges: do
      s <- store.getState
      pure s.edges

  , setEdges: \updater ->
      pushEdgeQueue batchContext (QueueUpdate (coerceEdgeFn updater))

  , addEdges: \newEdges ->
      pushEdgeQueue batchContext
        (QueueUpdate (coerceEdgeFn \existing -> existing <> newEdges))

  , getEdge: \id -> do
      s <- store.getState
      pure (Map.lookup id s.edgeLookup)

  , toObject: do
      s <- store.getState
      let Transform t = s.transform
      pure
        { nodes: s.nodes
        , edges: s.edges
        , viewport: { x: t.tx, y: t.ty, zoom: t.scale }
        }

  , deleteElements: \opts -> do
      s <- liftEffect store.getState
      let
        nodesToRemove =
          Array.mapMaybe toIdOnly (fromMaybe [] opts.nodes)
        edgesToRemove =
          Array.mapMaybe toIdOnly (fromMaybe [] opts.edges)
      result <- Graph.getElementsToRemove
        { nodesToRemove
        , edgesToRemove
        , nodes: s.nodes
        , edges: s.edges
        , onBeforeDelete: map adaptOnBeforeDelete s.onBeforeDelete
        }
      liftEffect do
        when (Array.length result.edges > 0) do
          for_ s.onEdgesDelete \cb -> cb result.edges
          store.dispatch
            ( TriggerEdgeChanges
                (map (\e -> EdgeRemoveChange { id: e.id }) result.edges)
            )
        when (Array.length result.nodes > 0) do
          for_ s.onNodesDelete \cb -> cb result.nodes
          store.dispatch
            ( TriggerNodeChanges
                (map (\n -> NodeRemoveChange { id: n.id }) result.nodes)
            )
        when (Array.length result.nodes > 0 || Array.length result.edges > 0) do
          for_ s.onDelete \cb ->
            cb { nodes: result.nodes, edges: result.edges }
      pure
        { deletedNodes: result.nodes
        , deletedEdges: result.edges
        }

  , getIntersectingNodes: \nodeOrRect mPartially mNodesOverride -> do
      s <- store.getState
      let partially = fromMaybe true mPartially
      mNodeRect <- getNodeRect store nodeOrRect
      case mNodeRect of
        Nothing -> pure []
        Just nodeRect -> do
          let
            -- `hasNodesOption` mirrors TS: when the override list is
            -- provided we treat each entry as user-shaped and use its
            -- logical position; otherwise we lookup the internal
            -- counterpart to get the absolute position.
            candidates :: Array (Node n)
            candidates = case mNodesOverride of
              Just ns -> ns
              Nothing -> s.nodes
            isRect = case nodeOrRect of
              RectArg _ -> true
              _ -> false
            keep n =
              case Map.lookup n.id s.nodeLookup of
                Just internal ->
                  if (not isRect) && excludesSelf internal nodeOrRect
                  then false
                  else
                    let
                      curr = nodeToRect
                        ( case mNodesOverride of
                            Just _ -> Left n
                            Nothing -> Right internal
                        )
                        s.nodeOrigin
                      area = getOverlappingArea curr nodeRect
                      partiallyVisible = partially && area > 0.0
                    in
                      partiallyVisible
                        || area >= curr.width * curr.height
                        || area >= nodeRect.width * nodeRect.height
                Nothing -> false
          pure (Array.filter keep candidates)

  , isNodeIntersecting: \nodeOrRect area mPartially -> do
      let partially = fromMaybe true mPartially
      mNodeRect <- getNodeRect store nodeOrRect
      case mNodeRect of
        Nothing -> pure false
        Just nodeRect ->
          let
            overlapping = getOverlappingArea nodeRect area
            partiallyVisible = partially && overlapping > 0.0
          in
            pure
              ( partiallyVisible
                  || overlapping >= area.width * area.height
                  || overlapping >= nodeRect.width * nodeRect.height
              )

  -- The `replace` option is a TS-side merge-vs-replace switch over
  -- partial-object updates. PS only accepts function updaters that
  -- already return a full node/edge, so `replace` is structurally a
  -- no-op here. The option is accepted for upstream parity.
  , updateNode: \id updater _opts ->
      pushNodeQueue batchContext
        ( QueueUpdate
            ( coerceNodeFn \nodes ->
                map (\n -> if n.id == id then updater n else n) nodes
            )
        )

  , updateNodeData: \id updater _opts ->
      pushNodeQueue batchContext
        ( QueueUpdate
            ( coerceNodeFn \nodes ->
                map (\n -> if n.id == id then updater n else n) nodes
            )
        )

  , updateEdge: \id updater _opts ->
      pushEdgeQueue batchContext
        ( QueueUpdate
            ( coerceEdgeFn \edges ->
                map (\e -> if e.id == id then updater e else e) edges
            )
        )

  , updateEdgeData: \id updater _opts ->
      pushEdgeQueue batchContext
        ( QueueUpdate
            ( coerceEdgeFn \edges ->
                map (\e -> if e.id == id then updater e else e) edges
            )
        )

  , getNodesBounds: \nodeRefs -> do
      s <- store.getState
      let
        resolved :: Array (NodeBase n)
        resolved = Array.mapMaybe (resolveBoundsRef s.nodeLookup) nodeRefs
      pure (Graph.getNodesBounds resolved (Just s.nodeLookup) s.nodeOrigin)

  , getHandleConnections: \{ handleType, nodeId, id } -> do
      s <- store.getState
      let
        key = nodeId <> "-" <> handleTypeName handleType <> case id of
          Just h -> "-" <> h
          Nothing -> ""
      pure $ connectionsForKey s key

  , getNodeConnections: \{ handleType, nodeId, handleId } -> do
      s <- store.getState
      let
        key = case handleType of
          Nothing -> nodeId
          Just t -> nodeId <> "-" <> handleTypeName t <> case handleId of
            Just h -> "-" <> h
            Nothing -> ""
      pure $ connectionsForKey s key

  , fitView: fitView store batchContext
  }

-- | Read the current connection-lookup slice for a given key and turn
-- | the inner `Map String HandleConnection` into a flat array.
connectionsForKey :: forall n e. ReactFlowState n e -> String -> Array HandleConnection
connectionsForKey s key = case Map.lookup key s.connectionLookup of
  Nothing -> []
  Just inner -> Array.fromFoldable (Map.values inner)

-- | `fitView` schedules a viewport-fit cycle: it sets the
-- | `fitViewQueued` flag (read by the reducer when nodes are next
-- | applied) and pushes a no-op into the node queue to force the
-- | `BatchProvider` to flush this render. The returned `Aff` blocks on
-- | the resolver AVar; the reducer's `ResolveFitView` effect descriptor
-- | `put`s into it when the d3 transition completes.
fitView :: forall n e. Store n e -> BatchContext -> FitView
fitView store batchContext mOpts = do
  s <- liftEffect store.getState
  resolver <- liftEffect case s.fitViewResolver of
    Just existing -> pure existing
    Nothing -> AVar.empty
  liftEffect $ store.dispatch
    ( PatchState \st -> st
        { fitViewQueued = true
        , fitViewOptions = mOpts
        , fitViewResolver = Just resolver
        }
    )
  liftEffect $ batchContext.nodeQueue.push (QueueUpdate \xs -> xs)
  -- `read` rather than `take` so the resolver can be observed by other
  -- listeners and so the AVar remains visible to subsequent
  -- `getState().fitViewResolver` callers.
  AffAVar.read resolver

-- | Project a `Node n` or `{ id :: String }` payload to the
-- | id-only shape `Array (NodeBase ?)` accepted by
-- | `System.Utils.Graph.getElementsToRemove`. The Either-string-or-node
-- | tag is collapsed by reading `.id` in both branches.
toIdOnly
  :: forall r
   . Either String { id :: String | r }
  -> Maybe { id :: String }
toIdOnly = case _ of
  Left s -> Just { id: s }
  Right r -> Just { id: r.id }

-- | Adapter: React's `OnBeforeDelete` returns
-- | `Aff (OnBeforeDeleteResult n e)` whereas the System version
-- | (`System.Utils.Graph.OnBeforeDelete`) returns
-- | `Aff (Either Boolean { nodes, edges })`. The two encode the same
-- | three-valued response (`allow` / `veto` / `filtered`); convert
-- | between them at the call seam to `getElementsToRemove`.
adaptOnBeforeDelete
  :: forall n e
   . OnBeforeDelete n e
  -> { nodes :: Array (NodeBase n), edges :: Array (Edge e) }
  -> Aff (Either Boolean { nodes :: Array (NodeBase n), edges :: Array (Edge e) })
adaptOnBeforeDelete f input = do
  r <- f input
  pure case r of
    { allow: false } -> Left false
    { allow: true, nodes: Nothing, edges: Nothing } -> Left true
    { allow: true, nodes: mn, edges: me } ->
      Right
        { nodes: fromMaybe input.nodes mn
        , edges: fromMaybe input.edges me
        }

-- | TS dispatches on `nodeOrRect.id === node.id` to exclude the
-- | intersection-source from the result. PS port: if the argument is a
-- | `NodeArg`/`IdArg` and its id matches `internal.id`, exclude.
excludesSelf :: forall n. InternalNodeBase n -> NodeOrIdOrRect n -> Boolean
excludesSelf internal = case _ of
  NodeArg n -> n.id == internal.id
  IdArg s -> s == internal.id
  RectArg _ -> false

-- | Compute the `Rect` for a `NodeOrIdOrRect`:
-- |
-- | * `RectArg r` — pass through.
-- | * `IdArg id` — lookup in `nodeLookup`; on miss, `Nothing`.
-- | * `NodeArg n` — compute the absolute position from `parentId`
-- |    chain via `evaluateAbsolutePosition`, then `nodeToRect`.
getNodeRect
  :: forall n e
   . Store n e
  -> NodeOrIdOrRect n
  -> Effect (Maybe Rect)
getNodeRect store = case _ of
  RectArg r -> pure (Just r)
  IdArg id -> do
    s <- store.getState
    pure $ case Map.lookup id s.nodeLookup of
      Nothing -> Nothing
      Just internal -> Just (nodeToRect (Right internal) s.nodeOrigin)
  NodeArg n -> do
    s <- store.getState
    let
      dims =
        { width: fromMaybe 0.0 n.measured.width
        , height: fromMaybe 0.0 n.measured.height
        }
      pos = case n.parentId of
        Just pid -> evaluateAbsolutePosition n.position dims pid s.nodeLookup
          s.nodeOrigin
        Nothing -> n.position
      rect =
        { x: pos.x
        , y: pos.y
        , width: dims.width
        , height: dims.height
        }
    pure (Just rect)

-- | Convert a `NodeRefForBounds` into a `NodeBase`. `BoundsId` may
-- | return `Nothing` when the id isn't present in the lookup.
resolveBoundsRef
  :: forall n
   . NodeLookup n
  -> NodeRefForBounds n
  -> Maybe (NodeBase n)
resolveBoundsRef lookup = case _ of
  BoundsNode n -> Just n
  BoundsInternal internal -> Just (stripInternals internal)
  BoundsId id -> map stripInternals (Map.lookup id lookup)

-- | Drop the `internals` field from an `InternalNodeBase` to recover a
-- | `NodeBase`. The two share `NodeBaseRow nodeData`, so the runtime
-- | object already satisfies the smaller row at the type level — the
-- | extra `internals` field is simply hidden. `unsafeCoerce` matches
-- | the convention used elsewhere in the codebase for sound
-- | row-narrowing.
stripInternals :: forall n. InternalNodeBase n -> NodeBase n
stripInternals = unsafeCoerce

handleTypeName :: HandleType -> String
handleTypeName Source = "source"
handleTypeName Target = "target"

-- BatchContext shimming ---------------------------------------------------

-- | Cast a user-supplied `(Array (Node n) -> Array (Node n))` updater
-- | to the queue's opaque type. `OpaqueNodeBatch` is a phantom — the
-- | runtime function is unchanged.
coerceNodeFn :: forall n. (Array (Node n) -> Array (Node n)) -> Array OpaqueNodeBatch -> Array OpaqueNodeBatch
coerceNodeFn = unsafeCoerce

coerceEdgeFn :: forall e. (Array (Edge e) -> Array (Edge e)) -> Array OpaqueEdgeBatch -> Array OpaqueEdgeBatch
coerceEdgeFn = unsafeCoerce

pushNodeQueue :: BatchContext -> QueueItem OpaqueNodeBatch -> Effect Unit
pushNodeQueue ctx item = ctx.nodeQueue.push item

pushEdgeQueue :: BatchContext -> QueueItem OpaqueEdgeBatch -> Effect Unit
pushEdgeQueue ctx item = ctx.edgeQueue.push item
