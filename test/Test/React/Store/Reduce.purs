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
import Data.Maybe (Maybe(..), maybe)
import Data.Tuple (Tuple(..))
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
  , className: Nothing
  , style: Nothing
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
  , label: Nothing
  , ariaLabel: Nothing
  , interactionWidth: Nothing
  , className: Nothing
  , style: Nothing
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
  , className: Nothing
  , style: Nothing
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
  , label: Nothing
  , ariaLabel: Nothing
  , interactionWidth: Nothing
  , className: Nothing
  , style: Nothing
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

-- Fixtures for the selection/lookup-sync cases (ticket 066) -----------
--
-- `sampleNode` (id n1, selected) doubles as the n1 lookup entry; `n2Internal`
-- is the same shape with a fresh id and no selection. `n1Base`/`n2Base` are the
-- matching user-facing `NodeBase` entries the uncontrolled adopt path rebuilds
-- the lookup from. Same idea on the edge side with `sampleEdge`.

n1Base :: NodeBase Unit
n1Base = freshNode { id = NodeId "n1", selected = true }

n2Base :: NodeBase Unit
n2Base = freshNode { id = NodeId "n2", selected = false }

n2Internal :: InternalNodeBase Unit
n2Internal = sampleNode { id = NodeId "n2", selected = false }

e1Unsel :: EdgeBase Unit
e1Unsel = sampleEdge { selected = false }

e2Unsel :: EdgeBase Unit
e2Unsel = sampleEdge { id = "e2", selected = false }

baseState :: ReactFlowState Unit Unit
baseState = initialState defaultInitialStateOptions

nodeSelected :: ReactFlowState Unit Unit -> String -> Boolean
nodeSelected st nid = maybe false _.selected (Map.lookup (NodeId nid) st.nodeLookup)

edgeSelected :: ReactFlowState Unit Unit -> String -> Boolean
edgeSelected st eid = maybe false _.selected (Map.lookup eid st.edgeLookup)

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

-- 5. AddSelectedNodes honors multiSelectionActive (ticket 066 item 1) ---
--
-- Meta-click multi-select: with a node already selected, selecting *another*
-- node must keep the first selected. The pre-fix reducer ran the "replace" path
-- unconditionally and deselected n1.

testAddSelectedNodesMultiSelect :: Effect Unit
testAddSelectedNodesMultiSelect =
  let
    st = baseState
      { hasDefaultNodes = true
      , multiSelectionActive = true
      , nodes = [ n1Base, n2Base ]
      , nodeLookup = Map.fromFoldable
          [ Tuple (NodeId "n1") sampleNode
          , Tuple (NodeId "n2") n2Internal
          ]
      }
    r = reduce st (AddSelectedNodes [ NodeId "n2" ])
  in
    do
      assert "AddSelectedNodes (multi) keeps previously-selected n1"
        (nodeSelected r.state "n1")
      assert "AddSelectedNodes (multi) selects n2"
        (nodeSelected r.state "n2")

-- 6. AddSelectedEdges select reaches the edgeLookup (063 fix) -----------

testAddSelectedEdgesReachesLookup :: Effect Unit
testAddSelectedEdgesReachesLookup =
  let
    st = baseState
      { hasDefaultEdges = true
      , multiSelectionActive = false
      , edges = [ e1Unsel ]
      , edgeLookup = Map.singleton "e1" e1Unsel
      }
    r = reduce st (AddSelectedEdges [ "e1" ])
  in
    assert "AddSelectedEdges marks e1 selected in edgeLookup"
      (edgeSelected r.state "e1")

-- 7. AddSelectedEdges honors multiSelectionActive (063 fix) -------------

testAddSelectedEdgesMultiSelect :: Effect Unit
testAddSelectedEdgesMultiSelect =
  let
    st = baseState
      { hasDefaultEdges = true
      , multiSelectionActive = true
      , edges = [ sampleEdge, e2Unsel ]
      , edgeLookup = Map.fromFoldable
          [ Tuple "e1" sampleEdge
          , Tuple "e2" e2Unsel
          ]
      }
    r = reduce st (AddSelectedEdges [ "e2" ])
  in
    do
      assert "AddSelectedEdges (multi) keeps previously-selected e1"
        (edgeSelected r.state "e1")
      assert "AddSelectedEdges (multi) selects e2"
        (edgeSelected r.state "e2")

-- 8. TriggerEdgeChanges remove drops from edgeLookup (063 fix) ----------

testTriggerEdgeRemoveDropsLookup :: Effect Unit
testTriggerEdgeRemoveDropsLookup =
  let
    st = baseState
      { hasDefaultEdges = true
      , edges = [ sampleEdge ]
      , edgeLookup = Map.singleton "e1" sampleEdge
      }
    r = reduce st (TriggerEdgeChanges [ EdgeRemoveChange { id: "e1" } ])
  in
    assert "TriggerEdgeChanges EdgeRemoveChange drops e1 from edgeLookup"
      (not (Map.member "e1" r.state.edgeLookup))

runReactStoreTests :: Effect Unit
runReactStoreTests = do
  log ""
  log "React.Store.Reduce property tests:"
  testResetSelected
  testPatchStateIdentity
  testApplyNodeChangesRoundTrip
  testApplyEdgeChangesRoundTrip
  testAddSelectedNodesMultiSelect
  testAddSelectedEdgesReachesLookup
  testAddSelectedEdgesMultiSelect
  testTriggerEdgeRemoveDropsLookup
  log ""
