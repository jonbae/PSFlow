-- | What a click on a node ends, and what it leaves alone.
-- |
-- | Upstream's `handleNodeClick` (`components/Nodes/utils.ts`) first calls
-- | `store.setState({ nodesSelectionActive: false })`, so a click after a
-- | selection box hides the box's rectangle. Then it selects or unselects,
-- | and it unselects with `edges: []`, which leaves the selected edges
-- | alone. ps-flow's left `nodesSelectionActive` as it was, so the
-- | rectangle stayed around the node the click selected, and unselected
-- | with `edges: Nothing`, which is every edge in the store: Escape on a
-- | selected node unselected the selected edges too.
-- |
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name this, and no scenario reaches it. The one that clicks
-- | a node after a selection box ends with a pane click, which ends the
-- | nodes selection on both sides, and the one that presses Escape on a
-- | selected node has no edge selected.
module Test.React.Node.HandleNodeClick
  ( runHandleNodeClickTests
  ) where

import Prelude

import Data.Array (filter, fromFoldable) as Array
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.Nullable (Nullable)
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (Ref)
import React.Node.Util (handleNodeClick)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import React.Types.Edges (Edge)
import React.Types.Nodes (Node)
import System.Types.Edge (EdgeChange(..))
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeChange(..))
import Web.HTML.HTMLDivElement (HTMLDivElement)

foreign import emptyNodeRef :: Ref (Nullable HTMLDivElement)
foreign import withFrames :: Effect Unit -> Effect Unit

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

node :: String -> Boolean -> Node Unit
node id selected =
  { id: NodeId id
  , position: { x: 0.0, y: 0.0 }
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: Nothing
  , selected: if selected then Just true else Nothing
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

edgeAB :: Boolean -> Edge Unit
edgeAB selected =
  { id: "ab"
  , edgeType: Nothing
  , source: NodeId "a"
  , target: NodeId "b"
  , sourceHandle: Nothing
  , targetHandle: Nothing
  , animated: Nothing
  , hidden: Nothing
  , deletable: Nothing
  , selectable: Nothing
  , data: Nothing
  , selected: if selected then Just true else Nothing
  , markerStart: Nothing
  , markerEnd: Nothing
  , zIndex: Nothing
  , label: Nothing
  , ariaLabel: Nothing
  , interactionWidth: Nothing
  , className: Nothing
  , style: Nothing
  }

type Flow =
  { store :: Store Unit Unit
  , nodeChanges :: Effect (Array String)
  , edgeChanges :: Effect (Array String)
  , errors :: Effect (Array String)
  -- | The selected nodes in the lookup at each notification.
  , heard :: Effect (Array (Array String))
  }

-- | A controlled flow of `nodes` and `edges`, after a selection box if
-- | `boxed`, that records what it sends and what `useStore` hears.
flow :: { boxed :: Boolean, multi :: Boolean } -> Array (Node Unit) -> Array (Edge Unit) -> Effect Flow
flow o nodes edges = do
  store <- createStore
    ((defaultInitialStateOptions :: InitialStateOptions Unit Unit) { nodes = Just nodes, edges = Just edges })
  nodeChanges <- Ref.new ([] :: Array String)
  edgeChanges <- Ref.new ([] :: Array String)
  errors <- Ref.new ([] :: Array String)
  heard <- Ref.new ([] :: Array (Array String))
  store.setState _
    { nodesSelectionActive = o.boxed
    , multiSelectionActive = o.multi
    , onNodesChange = Just \cs -> Ref.modify_ (_ <> map describeNode cs) nodeChanges
    , onEdgesChange = Just \cs -> Ref.modify_ (_ <> map describeEdge cs) edgeChanges
    , onError = Just \code _ -> Ref.modify_ (_ <> [ code ]) errors
    }
  _ <- store.subscribeAll do
    s <- store.getState
    let selected = map (unwrap <<< _.id) (Array.filter (\n -> n.selected == Just true) (Array.fromFoldable (Map.values s.nodeLookup)))
    Ref.modify_ (_ <> [ selected ]) heard
  pure
    { store
    , nodeChanges: Ref.read nodeChanges
    , edgeChanges: Ref.read edgeChanges
    , errors: Ref.read errors
    , heard: Ref.read heard
    }
  where
  describeNode = case _ of
    NodeSelectionChange c -> unwrap c.id <> (if c.selected then " selected" else " unselected")
    _ -> "another change"
  describeEdge = case _ of
    EdgeSelectionChange c -> c.id <> (if c.selected then " selected" else " unselected")
    _ -> "another change"

click :: Flow -> String -> { unselect :: Boolean } -> Effect Unit
click f id o = withFrames $ handleNodeClick { id: NodeId id, store: f.store, unselect: o.unselect, nodeRef: emptyNodeRef }

nodesSelectionActive :: Flow -> Effect Boolean
nodesSelectionActive f = _.nodesSelectionActive <$> f.store.getState

runHandleNodeClickTests :: Effect Unit
runHandleNodeClickTests = do
  log "\n=== handleNodeClick: what a click on a node ends, and what it leaves alone ==="

  boxed <- flow { boxed: true, multi: false } [ node "a" true, node "b" true, node "c" false ] [ edgeAB false ]
  click boxed "c" { unselect: false }
  boxedActive <- nodesSelectionActive boxed
  assert "a click after a selection box ends the nodes selection"
    (not boxedActive)
  boxedChanges <- boxed.nodeChanges
  assert "and selects the node it's on, unselecting the box's"
    (boxedChanges == [ "a unselected", "b unselected", "c selected" ])
  boxedHeard <- boxed.heard
  assert "and notifies before it selects, so useStore doesn't hear of the selection, which is written in place"
    (boxedHeard /= [] && Array.filter (_ == [ "c" ]) boxedHeard == [])

  again <- flow { boxed: true, multi: false } [ node "a" true, node "b" false ] [ edgeAB false ]
  click again "a" { unselect: false }
  againActive <- nodesSelectionActive again
  againChanges <- again.nodeChanges
  assert "a click on a node already selected, which changes nothing else, still ends the nodes selection"
    (not againActive && againChanges == [])

  escaped <- flow { boxed: false, multi: false } [ node "a" true, node "b" false ] [ edgeAB true ]
  click escaped "a" { unselect: true }
  escapedNodes <- escaped.nodeChanges
  escapedEdges <- escaped.edgeChanges
  assert "Escape on a selected node unselects it"
    (escapedNodes == [ "a unselected" ])
  assert "and leaves the selected edges alone"
    (escapedEdges == [])

  multi <- flow { boxed: false, multi: true } [ node "a" true, node "b" false ] [ edgeAB true ]
  click multi "a" { unselect: false }
  multiNodes <- multi.nodeChanges
  multiEdges <- multi.edgeChanges
  assert "a multi-selection click on a selected node unselects it, and leaves the selected edges alone"
    (multiNodes == [ "a unselected" ] && multiEdges == [])

  missing <- flow { boxed: true, multi: false } [ node "a" false ] []
  click missing "z" { unselect: false }
  missingActive <- nodesSelectionActive missing
  missingErrors <- missing.errors
  assert "a click on a node the store doesn't have reports error 012, and ends nothing"
    (missingErrors == [ "012" ] && missingActive)
