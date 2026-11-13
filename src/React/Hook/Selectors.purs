-- | Thin selector hooks that wrap `useStore` (ticket 027). Each is a
-- | one-to-five-line projection on the `ReactFlowState`. Mirrors the
-- | individual TS hooks under `xyflow/packages/react/src/hooks/`:
-- | `useNodes`, `useEdges`, `useViewport`, `useConnection`,
-- | `useNodesData`, `useInternalNode`, `useNodesInitialized`.
-- |
-- | **Equality is via type-class `Eq`.** The TS `equalityFn` argument
-- | is gone; consumers either derive `Eq` on their node/edge data row
-- | or wrap it in a `newtype`. `useStore` re-renders only when the
-- | selector projection changes per its `Eq` instance — see ticket 027.
-- | `useNodesData` compares what upstream's `shallowNodeData` compares,
-- | each node's `id`, `type` and `data`, with `Eq` on the data.
-- |
-- | JavaScript consumers don't come through these hooks' equalities.
-- | `Boundary.Hooks` runs upstream's own: zustand's `shallow`, and
-- | `shallowNodeData` with `data` compared by `Object.is`.
-- |
-- | **`useConnection` is split into two functions.** TS overloads
-- | `useConnection()` (full state) and `useConnection(selector, eq?)`
-- | (slice) into one symbol. PS gives them distinct names —
-- | `useConnection` for the no-arg form and `useConnectionWith` for the
-- | selector form. Documented divergence.
-- |
-- | **Type-parameter pinning.** Each TS hook is generic in the user's
-- | node/edge data rows; PS reuses the same `OpaqueStore` cast that
-- | `useStore` performs. Tyvars that do not appear in the result are
-- | pinned to `Unit` at the hook seam — sound because the store's JS
-- | runtime object is identical regardless of the type-level row
-- | parameters, and the selectors here never touch the pinned slot.
-- | The result-bearing parameter (typically `n` for node hooks, `e`
-- | for edge hooks) remains polymorphic so callsite type-ascription
-- | works as expected.
module React.Hook.Selectors
  ( UseNodesInitializedOptions
  , useNodes
  , useEdges
  , useViewport
  , useConnection
  , useConnectionWith
  , selectConnection
  , selectViewport
  , selectNodesData
  , useNodesData
  , useInternalNode
  , useNodesInitialized
  ) where

import Prelude

import Data.Array (length, mapMaybe) as Array
import Data.List (List)
import Data.List (foldl) as List
import Data.Map (lookup, values) as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import React.Basic.Hooks (Hook)
import React.Hook.Store (UseStore, useStore, useStoreWith)
import React.Types.Edges (Edge)
import React.Types.Nodes (InternalNode, Node)
import React.Types.Store (ReactFlowState)
import System.Types.Connection (ConnectionState(..), Viewport)
import System.Types.Ids (NodeId)
import System.Types.Node (InternalNodeBase)
import System.Utils.General (pointToRendererPoint)
import System.Utils.ShallowNodeData (NodeSummary, shallowNodeData)

-- | Mirrors the TS `UseNodesInitializedOptions = { includeHiddenNodes?: boolean }`.
-- | TS optional becomes a `Boolean` with a default of `false` chosen at
-- | the call site (pass `{ includeHiddenNodes: false }` if you do not
-- | care).
type UseNodesInitializedOptions =
  { includeHiddenNodes :: Boolean
  }

-- | All nodes in the flow. Re-renders when the node array changes per
-- | structural equality on the user node data row `n`.
useNodes
  :: forall n
   . Eq n
  => Hook (UseStore (Array (Node n))) (Array (Node n))
useNodes = useStore selectNodes
  where
  selectNodes :: ReactFlowState n Unit -> Array (Node n)
  selectNodes s = s.nodes

-- | All edges in the flow. Re-renders when the edge array changes per
-- | structural equality on the user edge data row `e`.
useEdges
  :: forall e
   . Eq e
  => Hook (UseStore (Array (Edge e))) (Array (Edge e))
useEdges = useStore selectEdges
  where
  selectEdges :: ReactFlowState Unit e -> Array (Edge e)
  selectEdges s = s.edges

-- | The viewport `{ x, y, zoom }` projection of the store's `Transform`
-- | newtype. Re-renders when any of the three numbers change.
useViewport :: Hook (UseStore Viewport) Viewport
useViewport = useStore (selectViewport :: ReactFlowState Unit Unit -> Viewport)

-- | TS's `viewportSelector`: the store's transform as `{ x, y, zoom }`.
selectViewport :: forall n e. ReactFlowState n e -> Viewport
selectViewport s =
  let
    t = unwrap s.transform
  in
    { x: t.tx, y: t.ty, zoom: t.scale }

-- | The full `ConnectionState`, through `selectConnection` (TS no-arg
-- | `useConnection()`). Re-renders
-- | only when the connection state changes — typically driven by drag
-- | events while the user is wiring an edge.
useConnection
  :: forall n
   . Eq n
  => Hook
       (UseStore (ConnectionState (InternalNodeBase n)))
       (ConnectionState (InternalNodeBase n))
useConnection = useStore selectConnection

-- | Selector form of `useConnection` (TS `useConnection(selector, eq?)`).
-- | Use when you want only a slice of the connection state to avoid
-- | unnecessary re-renders.
useConnectionWith
  :: forall n a
   . Eq a
  => (ConnectionState (InternalNodeBase n) -> a)
  -> Hook (UseStore a) a
useConnectionWith selector = useStore selectConn
  where
  selectConn :: ReactFlowState n Unit -> a
  selectConn s = selector (selectConnection s)

-- | TS's `storeSelector`: the store's connection, with `to` in the flow's
-- | coordinates while it's in progress.
-- |
-- | `XYHandle` keeps `to` where the pointer is in the container, as TS's
-- | does, and this converts it with the transform the store holds now. So
-- | the line's end follows the pointer when the viewport moves under it,
-- | and the connection line and `useConnection` read the same point.
-- | `pointer` stays in the container's coordinates, as TS's does.
selectConnection :: forall n e. ReactFlowState n e -> ConnectionState (InternalNodeBase n)
selectConnection s = case s.connection of
  ConnectionInProgress d -> ConnectionInProgress d { to = pointToRendererPoint d.to s.transform Nothing }
  NoConnection -> NoConnection

-- | The `id`, `type` and `data` of each node asked for, as TS's
-- | `useNodesData` selects them. Ids not in the lookup are skipped, and an
-- | id asked for twice answers twice, in the order asked.
-- |
-- | Re-renders when `shallowNodeData` finds a difference: a node moving
-- | or being selected changes none of the three, so it renders nothing.
useNodesData
  :: forall n
   . Eq n
  => Array NodeId
  -> Hook (UseStore (Array (NodeSummary n))) (Array (NodeSummary n))
useNodesData ids = useStoreWith select same
  where
  select :: ReactFlowState n Unit -> Array (NodeSummary n)
  select = selectNodesData ids

  same a b = shallowNodeData (Just a) (Just b)

-- | TS's `useNodesData` selector: for each id in order, the node's three
-- | fields, when the lookup has the node.
selectNodesData :: forall n e. Array NodeId -> ReactFlowState n e -> Array (NodeSummary n)
selectNodesData ids s =
  Array.mapMaybe
    ( \i -> Map.lookup i s.nodeLookup <#> \n ->
        { id: unwrap n.id, nodeType: n.nodeType, data: n.data }
    )
    ids

-- | Look up a single node by id. Returns `Nothing` if no such node is
-- | currently in the lookup.
useInternalNode
  :: forall n
   . Eq n
  => NodeId
  -> Hook (UseStore (Maybe (InternalNode n))) (Maybe (InternalNode n))
useInternalNode nodeId = useStore selectOne
  where
  selectOne :: ReactFlowState n Unit -> Maybe (InternalNode n)
  selectOne s = Map.lookup nodeId s.nodeLookup

-- | TS port. Returns `true` when every non-hidden node has measured
-- | `handleBounds`. Short-circuits on the first node with missing
-- | measurements. Honours `includeHiddenNodes` — pass `true` to count
-- | hidden nodes as well.
-- |
-- | Returns `false` if there are no nodes at all (matches the TS
-- | `s.nodes.length > 0` guard).
useNodesInitialized
  :: UseNodesInitializedOptions
  -> Hook (UseStore Boolean) Boolean
useNodesInitialized opts = useStore selectInitialized
  where
  selectInitialized :: ReactFlowState Unit Unit -> Boolean
  selectInitialized s =
    let
      nodes :: List (InternalNodeBase Unit)
      nodes = Map.values s.nodeLookup

      -- Mirror the TS loop: start at `false`, flip to `true` on the first
      -- visible measured node, hard-stop at `false` on any visible
      -- missing-measurement node. `acc.broken` carries the hard-stop.
      step acc n =
        if n.hidden == Just true && not opts.includeHiddenNodes then acc
        else if acc.broken then acc
        else case n.internals.handleBounds of
          Nothing -> { initialised: false, broken: true }
          Just _ -> { initialised: true, broken: false }

      result = List.foldl step { initialised: false, broken: false } nodes
    in
      Array.length s.nodes > 0 && result.initialised
