-- | Pure-property tests for `React.Store.Reduce` and `React.Store.Changes`.
-- |
-- | We build a minimal `ReactFlowState Unit Unit` and exercise the
-- | properties listed in ticket 026:
-- |
-- |   1. `reduce s ResetSelectedElements` emits selection-change effects.
-- |   2. `reduce s (PatchState identity)` returns the state unchanged.
-- |   3. `applyNodeChanges` round-trips with create/remove pairs.
-- |   4. `applyEdgeChanges` round-trips with create/remove pairs.
module Test.React.Store.Reduce
  ( runReactStoreTests
  ) where

import Prelude

import Data.Array (length, null) as Array
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import React.Store.Action (Action(..))
import React.Store.Changes (applyEdgeChanges, applyNodeChanges)
import React.Store.InitialState (defaultInitialStateOptions, initialState)
import React.Store.Reduce (reduce)
import React.Types.Store (ReactFlowState)
import System.Types.Edge (EdgeBase, EdgeChange(..))
import System.Types.Ids (NodeId(..))
import System.Types.Node (InternalNodeBase, NodeBase, NodeChange(..))

assert :: String -> Boolean -> Effect Unit
assert label ok =
  if ok then log ("  PASS " <> label)
  else log ("  FAIL " <> label)

sampleNode :: InternalNodeBase Unit
sampleNode =
  { id: NodeId "n1"
  , position: { x: 0.0, y: 0.0 }
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: false
  , selected: true
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
  , measured: { width: Nothing, height: Nothing }
  , nodeType: Nothing
  , internals:
      { positionAbsolute: { x: 0.0, y: 0.0 }
      , z: 0.0
      , rootParentIndex: Nothing
      , handleBounds: Nothing
      , bounds: Nothing
      }
  }

sampleEdge :: EdgeBase Unit
sampleEdge =
  { id: "e1"
  , edgeType: Nothing
  , source: NodeId "n1"
  , target: NodeId "n2"
  , sourceHandle: Nothing
  , targetHandle: Nothing
  , animated: false
  , hidden: false
  , deletable: Nothing
  , selectable: Nothing
  , data: Nothing
  , selected: true
  , markerStart: Nothing
  , markerEnd: Nothing
  , zIndex: Nothing
  , ariaLabel: Nothing
  , interactionWidth: Nothing
  }

freshNode :: NodeBase Unit
freshNode =
  { id: NodeId "n42"
  , position: { x: 1.0, y: 2.0 }
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
  , measured: { width: Nothing, height: Nothing }
  , nodeType: Nothing
  }

freshEdge :: EdgeBase Unit
freshEdge =
  { id: "e42"
  , edgeType: Nothing
  , source: NodeId "a"
  , target: NodeId "b"
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
  }

sampleState :: ReactFlowState Unit Unit
sampleState =
  let
    base :: ReactFlowState Unit Unit
    base = initialState defaultInitialStateOptions
  in
    base
      { nodeLookup = Map.singleton (NodeId "n1") sampleNode
      , edgeLookup = Map.singleton "e1" sampleEdge
      }

-- 1. ResetSelectedElements emits selection-change effects ------------

testResetSelected :: Effect Unit
testResetSelected =
  let
    r = reduce sampleState ResetSelectedElements
  in
    assert "ResetSelectedElements emits selection changes"
      (not (Array.null r.effects))

-- 2. PatchState identity leaves state size unchanged + no effects ----

testPatchStateIdentity :: Effect Unit
testPatchStateIdentity =
  let
    r = reduce sampleState (PatchState identity)
    sameSize =
      Map.size r.state.nodeLookup == Map.size sampleState.nodeLookup
        && Map.size r.state.edgeLookup == Map.size sampleState.edgeLookup
  in
    do
      assert "PatchState identity preserves lookup sizes" sameSize
      assert "PatchState identity emits no effects" (Array.null r.effects)

-- 3. applyNodeChanges: add then remove round-trips ------------------

testApplyNodeChangesRoundTrip :: Effect Unit
testApplyNodeChangesRoundTrip =
  let
    added = applyNodeChanges
      [ NodeAddChange { item: freshNode, index: Nothing } ]
      []
    removed = applyNodeChanges
      [ NodeRemoveChange { id: NodeId "n42" } ]
      added
  in
    do
      assert "applyNodeChanges NodeAddChange appends one"
        (Array.length added == 1)
      assert "applyNodeChanges NodeRemoveChange drops it"
        (Array.length removed == 0)

-- 4. applyEdgeChanges: add then remove round-trips ------------------

testApplyEdgeChangesRoundTrip :: Effect Unit
testApplyEdgeChangesRoundTrip =
  let
    added = applyEdgeChanges
      [ EdgeAddChange { item: freshEdge, index: Nothing } ]
      []
    removed = applyEdgeChanges
      [ EdgeRemoveChange { id: "e42" } ]
      added
  in
    do
      assert "applyEdgeChanges EdgeAddChange appends one"
        (Array.length added == 1)
      assert "applyEdgeChanges EdgeRemoveChange drops it"
        (Array.length removed == 0)

runReactStoreTests :: Effect Unit
runReactStoreTests = do
  log ""
  log "React.Store.Reduce property tests:"
  testResetSelected
  testPatchStateIdentity
  testApplyNodeChangesRoundTrip
  testApplyEdgeChangesRoundTrip
  log ""
