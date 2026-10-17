-- | The changes a drag reports, as upstream's `updateNodePositions` builds
-- | them.
-- |
-- | The local proxy for `reduceUpdateNodePositions` on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93),
-- | which `drag-child-expand-parent` and 93 `positionAbsolute` rows showed to
-- | be a partial port. Upstream's position change carries `dragging` and no
-- | `positionAbsolute`. A child whose current `expandParent` and `parentId`
-- | are set, read from the lookup, is clamped to its parent's top-left and
-- | grows its parent through `handleExpandParent`. A connection drawn from a
-- | dragged node follows it, and the nodes-change middleware runs last.
-- | ps-flow's reported `positionAbsolute`, and did none of the rest.
module Test.React.Store.UpdateNodePositions
  ( runUpdateNodePositionsTests
  ) where

import Prelude

import Data.Array (filter, length) as Array
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Store.Action (Action(..), Effect_(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import React.Store.Reduce (reduce)
import React.Types.Store (MiddlewareKey(..), ReactFlowState)
import System.Types.Connection (ConnectionState(..))
import System.Types.Geometry (Position(..), XYPosition)
import System.Types.Handle (HandleIdField(..), HandleType(..))
import System.Types.Ids (NodeId(..), nodeToParent)
import System.Types.Node (NodeBase, NodeChange(..), NodeDragItem)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

nodeAt :: String -> XYPosition -> { width :: Number, height :: Number } -> NodeBase Unit
nodeAt id at size =
  { id: NodeId id
  , position: at
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: Nothing
  , selected: Nothing
  , dragging: Nothing
  , draggable: Nothing
  , selectable: Nothing
  , connectable: Nothing
  , deletable: Nothing
  , dragHandle: Nothing
  , width: Nothing
  , height: Nothing
  , initialWidth: Nothing
  , initialHeight: Nothing
  , parentId: Nothing
  , zIndex: Nothing
  , extent: Nothing
  , expandParent: Nothing
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Just size.width, height: Just size.height }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

-- | A 100 by 80 parent at the origin, a 50 by 40 child inside it, and a
-- | loose node off to the right.
stateWith :: Maybe Boolean -> ReactFlowState Unit Unit
stateWith expandParent =
  initialState
    ( (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
        { nodes = Just
            [ nodeAt "parent" { x: 0.0, y: 0.0 } { width: 100.0, height: 80.0 }
            , (nodeAt "child" { x: 10.0, y: 10.0 } { width: 50.0, height: 40.0 })
                { parentId = Just (nodeToParent (NodeId "parent")), expandParent = expandParent }
            , nodeAt "loose" { x: 200.0, y: 0.0 } { width: 50.0, height: 40.0 }
            ]
        }
    )

-- | A drag item as `XYDrag` builds one. Its own `expandParent` is unset, so
-- | only the lookup's can make the child grow its parent.
dragItem :: String -> XYPosition -> XYPosition -> NodeDragItem
dragItem id position absolute =
  { id: NodeId id
  , position
  , distance: { x: 0.0, y: 0.0 }
  , measured: { width: 50.0, height: 40.0 }
  , internals: { positionAbsolute: absolute }
  , extent: Nothing
  , parentId: Nothing
  , origin: Nothing
  , expandParent: Nothing
  , dragging: Nothing
  }

reported :: ReactFlowState Unit Unit -> Array NodeDragItem -> Array (NodeChange Unit)
reported state items =
  case (reduce state (UpdateNodePositions items true)).effects of
    [ FireOnNodesChange changes ] -> changes
    _ -> []

positionOf :: String -> Array (NodeChange Unit) -> Maybe { position :: Maybe XYPosition, absolute :: Maybe XYPosition, dragging :: Maybe Boolean }
positionOf id changes = case Array.filter isFor changes of
  [ NodePositionChange c ] -> Just { position: c.position, absolute: c.positionAbsolute, dragging: c.dragging }
  _ -> Nothing
  where
  isFor = case _ of
    NodePositionChange c -> c.id == NodeId id
    _ -> false

grewTo :: Array (NodeChange Unit) -> Maybe { width :: Number, height :: Number }
grewTo changes = case Array.filter isParentGrowth changes of
  [ NodeDimensionChange c ] -> c.dimensions
  _ -> Nothing
  where
  isParentGrowth = case _ of
    NodeDimensionChange c -> c.id == NodeId "parent"
    _ -> false

runUpdateNodePositionsTests :: Effect Unit
runUpdateNodePositionsTests = do
  log "\n=== updateNodePositions: the changes a drag reports ==="

  let
    looseMove = reported (stateWith Nothing) [ dragItem "loose" { x: 210.0, y: 5.0 } { x: 210.0, y: 5.0 } ]
  assert "a drag change carries dragging and no positionAbsolute"
    (positionOf "loose" looseMove == Just { position: Just { x: 210.0, y: 5.0 }, absolute: Nothing, dragging: Just true })

  let
    pastCorner = dragItem "child" { x: 90.0, y: 70.0 } { x: 90.0, y: 70.0 }
    grown = reported (stateWith (Just true)) [ pastCorner ]
  assert "dragging an expandParent child past its parent's corner grows the parent, read from the lookup"
    (grewTo grown == Just { width: 140.0, height: 110.0 })
  assert "a child without expandParent doesn't grow its parent"
    (grewTo (reported (stateWith Nothing) [ pastCorner ]) == Nothing)

  let
    pastOrigin = reported (stateWith (Just true)) [ dragItem "child" { x: -5.0, y: -8.0 } { x: -5.0, y: -8.0 } ]
  assert "an expandParent child's position is clamped at its parent's top-left"
    (map _.position (positionOf "child" pastOrigin) == Just (Just { x: 0.0, y: 0.0 }))
  assert "a child without expandParent isn't clamped"
    ( map _.position (positionOf "child" (reported (stateWith Nothing) [ dragItem "child" { x: -5.0, y: -8.0 } { x: -5.0, y: -8.0 } ]))
        == Just (Just { x: -5.0, y: -8.0 })
    )

  let
    withMiddleware = (stateWith Nothing)
      { onNodesChangeMiddlewareMap = Map.singleton (MiddlewareKey 1) (\_ -> []) }
  assert "the nodes-change middleware runs on the changes"
    (Array.length (reported withMiddleware [ dragItem "loose" { x: 210.0, y: 5.0 } { x: 210.0, y: 5.0 } ]) == 0)

  let
    base = stateWith Nothing
    connecting = case Map.lookup (NodeId "loose") base.nodeLookup of
      Just loose -> base
        { connection = ConnectionInProgress
            { isValid: Nothing
            , from: { x: 0.0, y: 0.0 }
            , fromHandle:
                { id: HandleIdNull
                , nodeId: NodeId "loose"
                , x: 40.0
                , y: 10.0
                , position: PosRight
                , handleType: Source
                , width: 10.0
                , height: 10.0
                }
            , fromPosition: PosRight
            , fromNode: loose
            , to: { x: 0.0, y: 0.0 }
            , toHandle: Nothing
            , toPosition: PosLeft
            , toNode: Nothing
            , pointer: { x: 0.0, y: 0.0 }
            }
        }
      Nothing -> unsafeCrashWith "the loose node didn't adopt"
    after = (reduce connecting (UpdateNodePositions [ dragItem "loose" { x: 210.0, y: 5.0 } { x: 210.0, y: 5.0 } ] true)).state
  -- The loose node sits at (200, 0) in the lookup, and its handle's center
  -- is 45 and 15 into it.
  assert "a connection drawn from a dragged node follows it"
    ( case after.connection of
        ConnectionInProgress p -> p.from == { x: 245.0, y: 15.0 }
        NoConnection -> false
    )
  assert "a connection drawn from another node stays where it was"
    ( case (reduce connecting (UpdateNodePositions [ dragItem "child" { x: 20.0, y: 20.0 } { x: 20.0, y: 20.0 } ] true)).state.connection of
        ConnectionInProgress p -> p.from == { x: 0.0, y: 0.0 }
        NoConnection -> false
    )
