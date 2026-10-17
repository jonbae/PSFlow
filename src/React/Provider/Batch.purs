-- | `<BatchProvider />` — installs the node/edge update queues into
-- | `batchContext` and drains them on every layout effect. Mirrors
-- | `xyflow/packages/react/src/components/BatchProvider/index.tsx`.
-- |
-- | Responsibilities:
-- |
-- |   1. Allocate two `Queue`s (one for nodes, one for edges) once per
-- |      mount via `useMemo unit`.
-- |   2. Track a `serial` integer; bump it on every push.
-- |   3. `useIsomorphicLayoutEffect serial`: read both queues, fold the
-- |      payloads, and hand the result on as upstream's two queue
-- |      handlers do.
-- |   4. Reset the queue after draining.
-- |
-- | Upstream's node handler diffs the next nodes against the lookup, runs
-- | the nodes-change middleware over the diff, calls `setNodes` if the
-- | nodes are uncontrolled, and fires `onNodesChange` with the diff either
-- | way. With no changes and a `fitView` queued, it calls `setNodes` again
-- | on the next frame, to re-render. Its edge handler calls `setEdges` if
-- | the edges are uncontrolled, and fires `onEdgesChange` with the diff
-- | otherwise, even an empty one. Nothing upstream runs the edges-change
-- | middleware.
-- |
-- | **PS divergence: `Int` serial, not `BigInt`.** TS uses `BigInt(0)`
-- | to dodge React's automatic batching identity check; PureScript uses
-- | a plain `Int`. Wraparound at 2³¹ pushes is fine — this counter just
-- | needs to differ from one push to the next, not be globally unique.
module React.Provider.Batch
  ( batchProvider
  , NodeQueuePlan
  , planNodeQueue
  , EdgeQueuePlan
  , planEdgeQueue
  ) where

import Prelude

import Data.Array (null) as Array
import Data.Foldable (foldl, for_)
import Data.Map (values) as Map
import Data.Maybe (Maybe(..))
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent, provider)
import React.Basic.Hooks (reactChildrenToArray, reactComponentWithChildren, useMemo, useState)
import React.Basic.Hooks as React
import React.Context.Batch (BatchContext, OpaqueEdgeBatch, OpaqueNodeBatch, Queue, QueueItem(..), batchContext, createQueue)
import React.Hook.IsomorphicLayoutEffect (useIsomorphicLayoutEffect)
import React.Hook.Store (useStoreApi)
import React.Store.Action (Action(..))
import React.Store.Changes (getEdgeElementsDiffChanges, getNodeElementsDiffChanges)
import React.Types.Component (BatchProviderProps)
import React.Types.Edges (Edge)
import React.Types.Nodes (Node)
import React.Types.Store (ReactFlowState)
import System.Types.Edge (EdgeChange)
import System.Types.Node (NodeChange)
import System.FFI.AnimationFrame (requestAnimationFrame)
import Unsafe.Coerce (unsafeCoerce)

-- | The queue's type parameter is the *element* type (a `Node` / `Edge`,
-- | not the container). Each `QueueItem a` carries either an `Array a`
-- | replacement or an `Array a -> Array a` updater. The `BatchContext`
-- | uses opaque placeholders so it can be monomorphic; we cast at the
-- | seam — same pattern as `OpaqueStore` in `React.Context.Store`.
coerceNodeQueue :: forall n. Queue (Node n) -> Queue OpaqueNodeBatch
coerceNodeQueue = unsafeCoerce

coerceEdgeQueue :: forall e. Queue (Edge e) -> Queue OpaqueEdgeBatch
coerceEdgeQueue = unsafeCoerce

-- | Apply a single queued payload over the current array. `QueueReplace`
-- | overwrites; `QueueUpdate` runs an updater.
applyQueueItem :: forall a. Array a -> QueueItem a -> Array a
applyQueueItem current = case _ of
  QueueReplace next -> next
  QueueUpdate f -> f current

-- | What upstream's node queue handler does with the next nodes. It diffs
-- | them against the lookup before `setNodes` and runs the nodes-change
-- | middleware over the diff. `setNodes` is `Just` for uncontrolled nodes,
-- | `onNodesChange` is `Just` when the diff isn't empty, in either mode, and
-- | `refitNextFrame` is set when it is empty and a `fitView` is queued.
type NodeQueuePlan n =
  { setNodes :: Maybe (Array (Node n))
  , onNodesChange :: Maybe (Array (NodeChange n))
  , refitNextFrame :: Boolean
  }

planNodeQueue :: forall n e. ReactFlowState n e -> Array (Node n) -> NodeQueuePlan n
planNodeQueue s nextNodes =
  let
    changes =
      foldl (\cs middleware -> middleware cs)
        (getNodeElementsDiffChanges (Just nextNodes) s.nodeLookup s.nodes)
        (Map.values s.onNodesChangeMiddlewareMap)
  in
    { setNodes: if s.hasDefaultNodes then Just nextNodes else Nothing
    , onNodesChange: if Array.null changes then Nothing else Just changes
    , refitNextFrame: Array.null changes && s.fitViewQueued
    }

-- | What upstream's edge queue handler does with the next edges: `setEdges`
-- | for uncontrolled edges, and otherwise `onEdgesChange` with the diff,
-- | even an empty one. No middleware runs here, or anywhere upstream, for
-- | edges.
type EdgeQueuePlan e =
  { setEdges :: Maybe (Array (Edge e))
  , onEdgesChange :: Maybe (Array (EdgeChange e))
  }

planEdgeQueue :: forall n e. ReactFlowState n e -> Array (Edge e) -> EdgeQueuePlan e
planEdgeQueue s nextEdges =
  if s.hasDefaultEdges then { setEdges: Just nextEdges, onEdgesChange: Nothing }
  else { setEdges: Nothing, onEdgesChange: Just (getEdgeElementsDiffChanges (Just nextEdges) s.edgeLookup) }

-- | The internal `n`/`e` are erased at the seam: queues are stored as
-- | `Queue OpaqueNodeBatch` / `Queue OpaqueEdgeBatch` in the context and
-- | the `useStoreApi` result is monomorphic (its `n`/`e` are inferred
-- | per call). No phantom parameters needed.
batchProvider :: ReactComponent BatchProviderProps
batchProvider =
  unsafePerformEffect $ reactComponentWithChildren "BatchProvider"
    \(props :: BatchProviderProps) -> React.do
      store <- useStoreApi
      serial /\ setSerial <- useState 0
      let
        bumpSerial = setSerial (_ + 1)

        -- TS re-reads the store on the frame and sets the nodes it holds.
        refitNodes :: Effect Unit
        refitNodes = do
          now <- store.getState
          when now.fitViewQueued (store.dispatch (SetNodes now.nodes))
      nodeQueue <- useMemo unit \_ ->
        unsafePerformEffect (createQueue bumpSerial)
      edgeQueue <- useMemo unit \_ ->
        unsafePerformEffect (createQueue bumpSerial)
      useIsomorphicLayoutEffect serial do
        nodeItems <- nodeQueue.get
        edgeItems <- edgeQueue.get
        when (not (Array.null nodeItems) || not (Array.null edgeItems)) do
          s <- store.getState
          let
            nextNodes = foldl applyQueueItem s.nodes nodeItems
            nextEdges = foldl applyQueueItem s.edges edgeItems
          when (not (Array.null nodeItems)) do
            let plan = planNodeQueue s nextNodes
            for_ plan.setNodes (store.dispatch <<< SetNodes)
            for_ plan.onNodesChange \changes -> for_ s.onNodesChange (_ $ changes)
            when plan.refitNextFrame (void (requestAnimationFrame refitNodes))
            nodeQueue.reset
          when (not (Array.null edgeItems)) do
            let plan = planEdgeQueue s nextEdges
            for_ plan.setEdges (store.dispatch <<< SetEdges)
            for_ plan.onEdgesChange \changes -> for_ s.onEdgesChange (_ $ changes)
            edgeQueue.reset
        pure (pure unit)
      let
        ctxValue :: BatchContext
        ctxValue =
          { nodeQueue: coerceNodeQueue nodeQueue
          , edgeQueue: coerceEdgeQueue edgeQueue
          }
      pure $ provider batchContext (Just ctxValue)
        (reactChildrenToArray props.children)
