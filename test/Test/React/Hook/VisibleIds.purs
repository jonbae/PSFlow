-- | Pure-property tests for `React.Hook.VisibleIds`'s `selectVisibleNodeIds`
-- | and `selectVisibleEdgeIds` selectors. The hook bodies themselves are
-- | thin `useStore` wrappers and need a real React context to run; the
-- | underlying selectors are pure and verify the visible-filter logic
-- | end-to-end.
module Test.React.Hook.VisibleIds
  ( runVisibleIdsTests
  ) where

import Prelude

import Data.Array (length, sort) as Array
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Class.Console (log)
import React.Hook.VisibleIds.Pure (selectVisibleEdgeIds, selectVisibleNodeIds)
import React.Store.InitialState (defaultInitialStateOptions, initialState)
import React.Types.Store (ReactFlowState)
import System.Types.Edge (EdgeBase)
import System.Types.Ids (NodeId(..))
import System.Types.Node (InternalNodeBase)

assert :: String -> Boolean -> Effect Unit
assert label ok =
  if ok then log ("  PASS " <> label)
  else log ("  FAIL " <> label)

-- | Build an internal node with the supplied position + size, with
-- | `handleBounds` already resolved so `getNodesInside` doesn't
-- | short-circuit via `forceInitialRender`.
mkNode :: String -> Number -> Number -> Number -> Number -> InternalNodeBase Unit
mkNode nodeId px py w h =
  { id: NodeId nodeId
  , position: { x: px, y: py }
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: false
  , selected: false
  , dragging: false
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
  , expandParent: false
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Just w, height: Just h }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  , internals:
      { positionAbsolute: { x: px, y: py }
      , z: 0.0
      , rootParentIndex: Nothing
      , handleBounds: Just { source: [], target: [] }
      , bounds: Nothing
      }
  }

mkEdge :: String -> String -> String -> EdgeBase Unit
mkEdge edgeId src tgt =
  { id: edgeId
  , edgeType: Nothing
  , source: NodeId src
  , target: NodeId tgt
  , sourceHandle: Nothing
  , targetHandle: Nothing
  , animated: false
  , hidden: false
  , deletable: Nothing
  , selectable: Nothing
  , data: Nothing
  , selected: false
  , markerStart: Nothing
  , markerEnd: Nothing
  , zIndex: Nothing
  , ariaLabel: Nothing
  , interactionWidth: Nothing
  , className: Nothing
  , style: Nothing
  }

-- | Viewport 0..100 × 0..100 at identity transform.
-- |   a (10,10, 50×50)  — inside
-- |   c (30,30, 50×50)  — inside
-- |   b (500,500, 50×50) — outside
-- |   d (600,600, 50×50) — outside
sampleState :: ReactFlowState Unit Unit
sampleState =
  let
    base :: ReactFlowState Unit Unit
    base = initialState defaultInitialStateOptions
    nodes =
      [ mkNode "a" 10.0 10.0 50.0 50.0
      , mkNode "c" 30.0 30.0 50.0 50.0
      , mkNode "b" 500.0 500.0 50.0 50.0
      , mkNode "d" 600.0 600.0 50.0 50.0
      ]
    edges =
      [ mkEdge "ac" "a" "c"       -- both inside
      , mkEdge "bd" "b" "d"       -- both outside
      , mkEdge "missing" "a" "zzz" -- target absent
      ]
  in
    base
      { width = 100.0
      , height = 100.0
      , nodeLookup = Map.fromFoldable (map (\n -> Tuple n.id n) nodes)
      , edges = edges
      , edgeLookup = Map.fromFoldable (map (\e -> Tuple e.id e) edges)
      }

runVisibleIdsTests :: Effect Unit
runVisibleIdsTests = do
  log "ticket 040: React.Hook.VisibleIds selectors"
  -- nodes: false returns every key, true filters by viewport overlap.
  let
    nodesAll = Array.sort (selectVisibleNodeIds false sampleState)
    nodesVisible = Array.sort (selectVisibleNodeIds true sampleState)
  assert "selectVisibleNodeIds false returns 4 IDs"
    (Array.length nodesAll == 4)
  assert "selectVisibleNodeIds true keeps only a + c"
    (nodesVisible == [ NodeId "a", NodeId "c" ])
  -- edges: false returns every edge id; true keeps only the visible
  -- edge with both endpoints resolved.
  let
    edgesAll = Array.sort (selectVisibleEdgeIds false sampleState)
    edgesVisible = Array.sort (selectVisibleEdgeIds true sampleState)
  assert "selectVisibleEdgeIds false returns 3 IDs"
    (Array.length edgesAll == 3)
  assert "selectVisibleEdgeIds true keeps only ac"
    (edgesVisible == [ "ac" ])
