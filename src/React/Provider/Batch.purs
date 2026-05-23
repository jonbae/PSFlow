-- | `<BatchProvider />` — installs the node/edge update queues into
-- | `batchContext` and drains them on every layout effect. Mirrors
-- | `xyflow-main/packages/react/src/components/BatchProvider/index.tsx`.
-- |
-- | Responsibilities:
-- |
-- |   1. Allocate two `Queue`s (one for nodes, one for edges) once per
-- |      mount via `useMemo unit`.
-- |   2. Track a `serial` integer; bump it on every push.
-- |   3. `useIsomorphicLayoutEffect serial`: read both queues, fold the
-- |      payloads, compute changes, and dispatch through the store
-- |      (`SetNodes`/`SetEdges` if `hasDefaultNodes`/`hasDefaultEdges`
-- |      respectively; `TriggerNodeChanges`/`TriggerEdgeChanges` otherwise).
-- |   4. Reset the queue after draining.
-- |
-- | **PS divergence: `Int` serial, not `BigInt`.** TS uses `BigInt(0)`
-- | to dodge React's automatic batching identity check; PureScript uses
-- | a plain `Int`. Wraparound at 2³¹ pushes is fine — this counter just
-- | needs to differ from one push to the next, not be globally unique.
-- |
-- | **PS divergence: middleware not applied here.** TS folds
-- | `onNodesChangeMiddlewareMap` over the diffed changes before firing
-- | `onNodesChange`. In PS, the equivalent middleware fold happens
-- | inside the reducer's `TriggerNodeChanges` action handler (see
-- | `React.Store.Reduce`). Dispatching the action is enough.
module React.Provider.Batch
  ( batchProvider
  ) where

import Prelude

import Data.Array (null) as Array
import Data.Foldable (foldl)
import Data.Maybe (Maybe(..))
import Data.Tuple.Nested ((/\))
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
      let bumpSerial = setSerial (_ + 1)
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
            if s.hasDefaultNodes then
              store.dispatch (SetNodes nextNodes)
            else
              let changes = getNodeElementsDiffChanges (Just nextNodes) s.nodeLookup
              in store.dispatch (TriggerNodeChanges changes)
            nodeQueue.reset
          when (not (Array.null edgeItems)) do
            if s.hasDefaultEdges then
              store.dispatch (SetEdges nextEdges)
            else
              let changes = getEdgeElementsDiffChanges (Just nextEdges) s.edgeLookup
              in store.dispatch (TriggerEdgeChanges changes)
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
