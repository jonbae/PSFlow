-- | `useMoveSelectedNodes` — returns a function that moves every selected,
-- | draggable node one step in a direction, scaled by a factor. A node's
-- | and the nodes selection's arrow-key handlers call it. Mirrors
-- | `xyflow/packages/react/src/hooks/useMoveSelectedNodes.ts`.
-- |
-- | The returned function reads live state from the store on each call.
-- |
-- | **The step.** A node moves 5 px a press, or one grid cell when
-- | `snapToGrid` is on, and the factor scales it: the handlers pass 4 for
-- | Shift. The step is added to the node's absolute position, which is
-- | snapped to the grid and then clamped to the node's extent by
-- | `calculateNodePosition`, as a drag's is.
-- |
-- | **Which nodes.** TS walks `nodeLookup`, so the selection it reads is
-- | the lookup's, which a selection writes into in place, and not
-- | `nodes`'. A node moves when it's selected and either draggable itself
-- | or, with `draggable` unset, in a flow whose `nodesDraggable` is on.
-- | A JavaScript `Map` iterates in insertion order, which is `nodes`'
-- | order, so this walks `nodes` and looks each node up by id.
-- |
-- | **In place.** TS writes each node's new position into the lookup as it
-- | goes, before it calls `updateNodePositions`, and before it reaches the
-- | next node. A selected child's position is computed against its parent
-- | as already moved, so the child keeps its place in the parent rather
-- | than moving twice as far. The lookup is threaded through the fold for
-- | that, and written back with `MutateState`, which notifies nobody, as
-- | TS's mutation doesn't.
module React.Hook.MoveSelectedNodes
  ( useMoveSelectedNodes
  , moveSelectedNodes
  ) where

import Prelude

import Data.Array (foldl, snoc) as Array
import Data.Foldable (for_)
import Data.Map (insert, lookup) as Map
import Data.Maybe (Maybe(..), fromMaybe, isNothing)
import Effect (Effect)
import React.Basic.Hooks (Hook)
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Action (Action(..))
import React.Store.Shell (Store)
import System.Constants (errorId, errorMessage)
import System.Types.Geometry (SnapGrid(..), XYPosition)
import System.Types.Node (InternalNodeBase, NodeDragItem)
import System.Utils.General (snapPosition)
import System.Utils.Graph (calculateNodePosition)

useMoveSelectedNodes
  :: Hook UseStoreApi (XYPosition -> Number -> Effect Unit)
useMoveSelectedNodes = map moveSelectedNodes useStoreApi

-- | TS's `moveSelectedNodes({ direction, factor })`, on `store`.
moveSelectedNodes :: forall n e. Store n e -> XYPosition -> Number -> Effect Unit
moveSelectedNodes store direction factor = do
  st <- store.getState
  let
    SnapGrid grid = st.snapGrid
    xVelo = if st.snapToGrid then grid.gx else 5.0
    yVelo = if st.snapToGrid then grid.gy else 5.0
    xDiff = direction.x * xVelo * factor
    yDiff = direction.y * yVelo * factor

    isSelected :: InternalNodeBase n -> Boolean
    isSelected node =
      node.selected == Just true
        && (node.draggable == Just true || (st.nodesDraggable && isNothing node.draggable))

    step acc { id } = case Map.lookup id acc.nodeLookup of
      Just node | isSelected node ->
        let
          next =
            { x: node.internals.positionAbsolute.x + xDiff
            , y: node.internals.positionAbsolute.y + yDiff
            }
          nextPosition = if st.snapToGrid then snapPosition next st.snapGrid else next
        in
          case
            calculateNodePosition
              { nodeId: id
              , nextPosition
              , nodeLookup: acc.nodeLookup
              , nodeOrigin: st.nodeOrigin
              , nodeExtent: Just st.nodeExtent
              }
            of
            Just r ->
              let
                moved = node
                  { position = r.position
                  , internals = node.internals { positionAbsolute = r.positionAbsolute }
                  }
              in
                { nodeLookup: Map.insert id moved acc.nodeLookup
                , updates: Array.snoc acc.updates (dragItem moved)
                , errors: acc.errors <> r.errors
                }
            Nothing -> acc
      _ -> acc

    stepped = Array.foldl step { nodeLookup: st.nodeLookup, updates: [], errors: [] } st.nodes

  -- TS's `calculateNodePosition` raises each node's errors in the loop,
  -- before `updateNodePositions`.
  for_ stepped.errors \e ->
    for_ st.onError \cb -> cb (errorId e) (errorMessage e)
  store.dispatch (MutateState _ { nodeLookup = stepped.nodeLookup })
  store.dispatch (UpdateNodePositions stepped.updates false)

-- | TS hands `updateNodePositions` the internal node itself, which reads
-- | its `position`, `internals.positionAbsolute`, and `measured`.
dragItem :: forall n. InternalNodeBase n -> NodeDragItem
dragItem node =
  { id: node.id
  , position: node.position
  , distance: { x: 0.0, y: 0.0 }
  , measured:
      { width: fromMaybe 0.0 node.measured.width
      , height: fromMaybe 0.0 node.measured.height
      }
  , internals: { positionAbsolute: node.internals.positionAbsolute }
  , extent: node.extent
  , parentId: node.parentId
  , origin: node.origin
  , expandParent: node.expandParent
  , dragging: Nothing
  }
