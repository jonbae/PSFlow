-- | How far an arrow key moves the selected nodes, and which ones.
-- |
-- | The local proxy for the report's `arrow-key-selected-node` scenario,
-- | which [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name. Upstream's `useMoveSelectedNodes` moves a node 5 px
-- | a press, or one grid cell with `snapToGrid` on, from its absolute
-- | position, snapped and clamped by `calculateNodePosition`. It picks the
-- | selected, draggable nodes from `nodeLookup`, and writes each one's new
-- | position into the lookup before it computes the next. ps-flow's moved
-- | the nodes `nodes` held selected by 1 px a press, from their relative
-- | positions, with no grid, no extent, and no regard for `draggable`. In
-- | the scenario, four presses moved Node-1 to (10, 20) upstream and to
-- | (2, 4) in ps-flow.
module Test.React.Hook.MoveSelectedNodes
  ( runMoveSelectedNodesTests
  ) where

import Prelude

import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Hook.MoveSelectedNodes (moveSelectedNodes)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import React.Types.Nodes (Node)
import React.Types.Store (ReactFlowState)
import System.Types.Geometry (XYPosition, mkCoordinateExtent)
import System.Types.Ids (NodeId(..), ParentId(..))
import System.Types.Node (NodeChange(..))

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

node :: String -> XYPosition -> Node Unit
node id position =
  { id: NodeId id
  , position
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: Nothing
  , selected: Just true
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
  , measured: { width: Just 150.0, height: Just 40.0 }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

type Flow =
  { store :: Store Unit Unit
  -- | Each error, position change, and selection change, in the order the flow saw them,
  -- | with the lookup's position for the node as `onNodesChange` reads it.
  , events :: Effect (Array String)
  }

-- | A controlled flow of `nodes`, whose `onNodesChange` records the changes
-- | and doesn't apply them. `options` sets what the store adopts the nodes
-- | under, and `settings` the rest.
flow
  :: (InitialStateOptions Unit Unit -> InitialStateOptions Unit Unit)
  -> (ReactFlowState Unit Unit -> ReactFlowState Unit Unit)
  -> Array (Node Unit)
  -> Effect Flow
flow options settings nodes = do
  store <- createStore (options ((defaultInitialStateOptions :: InitialStateOptions Unit Unit) { nodes = Just nodes }))
  store.setState settings
  events <- Ref.new ([] :: Array String)
  let
    describe s = case _ of
      NodePositionChange c ->
        let
          at p = "(" <> show p.x <> ", " <> show p.y <> ")"
          held = case Map.lookup c.id s.nodeLookup of
            Just n -> at n.position
            Nothing -> "nowhere"
        in
          unwrap c.id <> " to " <> (case c.position of
            Just p -> at p
            Nothing -> "?") <> (if c.dragging == Just false then "" else " dragging") <> ", held at " <> held
      NodeSelectionChange c -> unwrap c.id <> (if c.selected then " selected" else " unselected")
      _ -> "another change"
  store.setState _
    { onNodesChange = Just \cs -> do
        s <- store.getState
        Ref.modify_ (_ <> map (describe s) cs) events
    , onError = Just \code _ -> Ref.modify_ (_ <> [ "error " <> code ]) events
    }
  pure { store, events: Ref.read events }

right :: XYPosition
right = { x: 1.0, y: 0.0 }

down :: XYPosition
down = { x: 0.0, y: 1.0 }

runMoveSelectedNodesTests :: Effect Unit
runMoveSelectedNodesTests = do
  log "\n=== useMoveSelectedNodes: how far an arrow key moves the selected nodes, and which ones ==="

  plain <- flow identity identity [ node "a" { x: 0.0, y: 0.0 } ]
  moveSelectedNodes plain.store down 1.0
  plainEvents <- plain.events
  assert "a press moves a selected node 5 px"
    (plainEvents == [ "a to (0.0, 5.0), held at (0.0, 5.0)" ])

  shifted <- flow identity identity [ node "a" { x: 0.0, y: 0.0 } ]
  moveSelectedNodes shifted.store right 4.0
  shiftedEvents <- shifted.events
  assert "and Shift's factor of 4 moves it 20 px"
    (shiftedEvents == [ "a to (20.0, 0.0), held at (20.0, 0.0)" ])

  gridded <- flow identity (_ { snapToGrid = true }) [ node "a" { x: 7.0, y: 0.0 } ]
  moveSelectedNodes gridded.store right 1.0
  griddedEvents <- gridded.events
  assert "with snapToGrid, a press moves it a grid cell, and snaps where it lands"
    (griddedEvents == [ "a to (15.0, 0.0), held at (15.0, 0.0)" ])

  extent <- flow (_ { nodeExtent = Just (mkCoordinateExtent 0.0 0.0 200.0 200.0) }) identity [ node "a" { x: 48.0, y: 0.0 } ]
  moveSelectedNodes extent.store right 1.0
  extentEvents <- extent.events
  assert "the node extent clamps the move"
    (extentEvents == [ "a to (50.0, 0.0), held at (50.0, 0.0)" ])

  draggable <- flow identity (_ { nodesDraggable = false })
    [ node "a" { x: 0.0, y: 0.0 }
    , (node "b" { x: 0.0, y: 0.0 }) { draggable = Just true }
    ]
  moveSelectedNodes draggable.store right 1.0
  draggableEvents <- draggable.events
  assert "with nodesDraggable off, only a node draggable itself moves"
    (draggableEvents == [ "b to (5.0, 0.0), held at (5.0, 0.0)" ])

  undraggable <- flow identity identity [ (node "a" { x: 0.0, y: 0.0 }) { draggable = Just false }, node "b" { x: 0.0, y: 0.0 } ]
  moveSelectedNodes undraggable.store right 1.0
  undraggableEvents <- undraggable.events
  assert "and a node that isn't draggable stays put"
    (undraggableEvents == [ "b to (5.0, 0.0), held at (5.0, 0.0)" ])

  inPlace <- flow identity identity [ (node "a" { x: 0.0, y: 0.0 }) { selected = Nothing } ]
  inPlace.store.dispatch (AddSelectedNodes [ NodeId "a" ])
  moveSelectedNodes inPlace.store right 1.0
  inPlaceEvents <- inPlace.events
  assert "a node the lookup holds selected moves, though nodes doesn't hold it selected yet"
    (inPlaceEvents == [ "a selected", "a to (5.0, 0.0), held at (5.0, 0.0)" ])

  ordered <- flow identity identity [ node "b" { x: 0.0, y: 0.0 }, node "a" { x: 0.0, y: 0.0 } ]
  moveSelectedNodes ordered.store right 1.0
  orderedEvents <- ordered.events
  assert "the changes come in nodes' order, not the ids'"
    (orderedEvents == [ "b to (5.0, 0.0), held at (5.0, 0.0)", "a to (5.0, 0.0), held at (5.0, 0.0)" ])

  parented <- flow identity identity
    [ node "p" { x: 100.0, y: 100.0 }
    , (node "c" { x: 10.0, y: 10.0 }) { parentId = Just (ParentId "p") }
    ]
  moveSelectedNodes parented.store right 1.0
  parentedEvents <- parented.events
  assert "a selected child moves with its selected parent, and keeps its place in it"
    (parentedEvents == [ "p to (105.0, 100.0), held at (105.0, 100.0)", "c to (10.0, 10.0), held at (10.0, 10.0)" ])

  unmeasured <- flow identity identity [ (node "a" { x: 0.0, y: 0.0 }) { measured = { width: Nothing, height: Nothing } } ]
  moveSelectedNodes unmeasured.store right 1.0
  unmeasuredEvents <- unmeasured.events
  assert "an unmeasured node reports error 015 before its change"
    (unmeasuredEvents == [ "error 015", "a to (5.0, 0.0), held at (5.0, 0.0)" ])

  none <- flow identity identity [ (node "a" { x: 0.0, y: 0.0 }) { selected = Nothing } ]
  moveSelectedNodes none.store right 1.0
  noneEvents <- none.events
  assert "with nothing selected, nothing changes"
    (noneEvents == [])
