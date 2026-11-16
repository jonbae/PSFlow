-- | A drag of several nodes keeps the group inside `nodeExtent`.
-- |
-- | Upstream's `XYDrag` takes the dragged nodes' bounds once per move, as
-- | `nodesBox`. Each node without its own `extent` is clamped to `nodeExtent`
-- | narrowed by how far the group reaches past the node on each side, so the
-- | group stops as a whole when its bounds reach the edge. A node with its
-- | own `extent` keeps it. ps-flow's drag clamped each node to `nodeExtent` on
-- | its own, so the nodes nearest the edge stopped and the rest caught up
-- | with them.
-- |
-- | The test starts a drag on a real store, with the store items that
-- | `NodeWrapper` gives it, and moves it once. The expected positions are
-- | upstream's arithmetic: two nodes 50 wide, 100 apart, in an extent 300
-- | wide, stop at 150 and 250 on the right and at 0 and 100 on the left.
module Test.System.XYDrag.DragGroupExtent
  ( runDragGroupExtentTests
  ) where

import Prelude

import Control.Monad.State (execStateT)
import Data.Array (sortWith) as Array
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Component.NodeWrapper (mkDragStoreItems)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (createStore)
import React.Types.Nodes (Node)
import System.FFI.D3Drag (D3DragEvent)
import System.Types.Geometry (CoordinateExtent(..), XYPosition)
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeExtent(..))
import System.XYDrag (initialDragState, startDrag, updateNodes)
import Test.Parity.Builders (mkNode)
import Web.DOM.Element (Element)

foreign import dragEventAtOrigin :: D3DragEvent
foreign import unusedElement :: Element

assertPositions :: String -> Array { id :: String, position :: XYPosition } -> Array { id :: String, position :: XYPosition } -> Effect Unit
assertPositions label actual expected =
  if actual == expected then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label <> "\n  got " <> show actual <> "\n  expected " <> show expected)

-- | A selected node measured 50×25.
selectedAt :: String -> Number -> Node Unit
selectedAt id x = (mkNode id) { position = { x, y: 0.0 }, selected = Just true }

-- | `[[0, 0], [300, 300]]`.
extent300 :: CoordinateExtent
extent300 = CoordinateExtent { minX: 0.0, minY: 0.0, maxX: 300.0, maxY: 300.0 }

-- | Start a drag on `a` at the origin in a flow of `nodes`, under `nodeExtent`,
-- | and move the pointer to `to`. Returns each dragged node's position, by id.
drag
  :: Maybe CoordinateExtent
  -> Array (Node Unit)
  -> XYPosition
  -> Effect (Array { id :: String, position :: XYPosition })
drag nodeExtent nodes to = do
  store <- createStore
    ( (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
        { nodes = Just nodes, nodeExtent = nodeExtent }
    )
  let
    params =
      { getStoreItems: mkDragStoreItems store
      , onDragStart: Nothing
      , onDrag: Nothing
      , onDragStop: Nothing
      , onNodeMouseDown: Nothing
      , autoPanSpeed: Nothing
      }
  s <- execStateT
    ( startDrag params
        { noDragClassName: Nothing
        , handleSelector: Nothing
        , isSelectable: true
        , nodeId: Just (NodeId "a")
        , domNode: unusedElement
        , nodeClickDistance: 0.0
        }
        dragEventAtOrigin
        *> updateNodes params (Just (NodeId "a")) to
    )
    initialDragState
  pure (Array.sortWith _.id (map (\i -> { id: unwrap i.id, position: i.position }) s.dragItems))

at :: String -> Number -> { id :: String, position :: XYPosition }
at id x = { id, position: { x, y: 0.0 } }

runDragGroupExtentTests :: Effect Unit
runDragGroupExtentTests = do
  log "\n=== updateNodes: a drag of several nodes keeps the group inside nodeExtent ==="

  let pair = [ selectedAt "a" 0.0, selectedAt "b" 100.0 ]

  right <- drag (Just extent300) pair { x: 1000.0, y: 0.0 }
  assertPositions "past the right edge, the group stops when its right edge reaches it"
    right [ at "a" 150.0, at "b" 250.0 ]

  left <- drag (Just extent300) pair { x: -1000.0, y: 0.0 }
  assertPositions "past the left edge, the group stops when its left edge reaches it"
    left [ at "a" 0.0, at "b" 100.0 ]

  ownExtent <- drag (Just extent300)
    [ selectedAt "a" 0.0
    , (selectedAt "b" 100.0)
        { extent = Just (CoordExtent (CoordinateExtent { minX: 0.0, minY: 0.0, maxX: 1000.0, maxY: 1000.0 })) }
    ]
    { x: 1000.0, y: 0.0 }
  assertPositions "a node with its own extent keeps it, and still widens the group"
    ownExtent [ at "a" 150.0, at "b" 950.0 ]

  alone <- drag (Just extent300) [ selectedAt "a" 0.0, (selectedAt "b" 100.0) { selected = Nothing } ]
    { x: 1000.0, y: 0.0 }
  assertPositions "a node dragged alone is clamped to nodeExtent itself"
    alone [ at "a" 250.0 ]

  unbounded <- drag Nothing pair { x: 1000.0, y: 0.0 }
  assertPositions "the default, infinite extent doesn't stop the group"
    unbounded [ at "a" 1000.0, at "b" 1100.0 ]
