-- | The store's selection reset, in a flow whose elements are not
-- | selectable.
-- |
-- | The local proxy for "Leave the selection alone on a pane click when
-- | elementsSelectable is false" (#141). Upstream's `resetSelectedElements`
-- | returns before it reads a node or an edge when `elementsSelectable` is
-- | false (`xyflow/packages/react/src/store/index.ts`). ps-flow's reducer
-- | had no guard, so a pane click deselected whatever the consumer had
-- | selected, such as a controlled node passed in with `selected: true`,
-- | and upstream left it selected.
-- |
-- | Each check runs `reduce` on a flow with one node and one edge
-- | selected. A reducer without the guard fails the first two. The last
-- | check runs the same flow with `elementsSelectable` true, so the first
-- | two cannot pass on a flow that had nothing to reset.
module Test.React.Store.ResetSelection
  ( runResetSelectionTests
  ) where

import Prelude

import Data.Array (all, length, null) as Array
import Data.Map as Map
import Data.Maybe (Maybe(..), maybe)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import React.Store.Reduce (reduce)
import React.Types.Store (ReactFlowState)
import System.Types.Edge (EdgeBase)
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeBase)
import Unsafe.Reference (unsafeRefEq)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

selectedNode :: NodeBase Unit
selectedNode =
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
  }

selectedEdge :: EdgeBase Unit
selectedEdge =
  { id: "e1"
  , edgeType: Nothing
  , source: NodeId "n1"
  , target: NodeId "n1"
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

-- | A controlled flow: the consumer owns `nodes` and `edges`.
controlled :: Boolean -> ReactFlowState Unit Unit
controlled selectable =
  ( initialState
      ( (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
          { nodes = Just [ selectedNode ], edges = Just [ selectedEdge ] }
      )
  ) { elementsSelectable = selectable }

-- | An uncontrolled flow: the store owns them, and commits a change itself.
uncontrolled :: Boolean -> ReactFlowState Unit Unit
uncontrolled selectable =
  ( initialState
      ( (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
          { defaultNodes = Just [ selectedNode ], defaultEdges = Just [ selectedEdge ] }
      )
  ) { elementsSelectable = selectable }

stillSelected :: ReactFlowState Unit Unit -> Boolean
stillSelected s =
  maybe false _.selected (Map.lookup (NodeId "n1") s.nodeLookup)
    && maybe false _.selected (Map.lookup "e1" s.edgeLookup)
    && Array.all _.selected s.nodes
    && Array.all _.selected s.edges

runResetSelectionTests :: Effect Unit
runResetSelectionTests = do
  log "\n=== Store: a selection reset in a flow that is not selectable (#141) ==="

  let
    before = controlled false
    reset = reduce before ResetSelectedElements
  assert "a pane click in a controlled flow calls neither onNodesChange nor onEdgesChange"
    (Array.null reset.effects && unsafeRefEq reset.state before)

  let
    beforeU = uncontrolled false
    resetU = reduce beforeU ResetSelectedElements
  assert "a pane click in an uncontrolled flow commits nothing, so the node and edge stay selected"
    (Array.null resetU.effects && unsafeRefEq resetU.state beforeU && stillSelected resetU.state)

  let selectable = reduce (controlled true) ResetSelectedElements
  assert "the same flow with selectable elements does reset, so the checks above had a selection to keep"
    (Array.length selectable.effects == 2)
