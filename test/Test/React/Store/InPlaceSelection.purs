-- | Selections that write into the store in place, and what
-- | `onSelectionChange` reports of them.
-- |
-- | The local proxy for the report's `shift-drag-selects-nodes` scenario,
-- | which
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name. Upstream's `<Pane />`, `addSelectedNodes`,
-- | `addSelectedEdges`, and `unselectNodesAndEdges` set `selected` on the
-- | lookup's internal nodes in place before the changes go out. Zustand
-- | notifies only on a new state object, so nobody hears of it until the
-- | next `set`. Upstream's `<SelectionListener />` picks the nodes whose
-- | internal node is selected, reports each one's `internals.userNode`, and
-- | fires when the selected ids change. So in a controlled flow, a selection
-- | box's own `setState` makes `onSelectionChange` report the boxed nodes as
-- | the consumer gave them, and a click's selection reaches it with the
-- | consumer's nodes, selected. ps-flow's box left the lookup alone, and its
-- | listener reported the user's nodes by their own `selected`, read when
-- | its effect ran, so it fired once for a box, with everything selected.
-- |
-- | The test runs the reducer's selections, `selectNodesInBox`, and
-- | `selectSelected` on a real store. `useStore` re-reads the store only
-- | when it's notified or its state changes identity, so a selection that
-- | does neither is one `onSelectionChange` doesn't see yet. That
-- | `<Pane />` and `<SelectionListener />` use them is the net's to check:
-- | `spago test` has no DOM to drag a selection box in.
module Test.React.Store.InPlaceSelection
  ( runInPlaceSelectionTests
  ) where

import Prelude

import Data.Array (fromFoldable) as Array
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.Set as Set
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Container.Pane (selectNodesInBox)
import React.Provider.SelectionListener (Selected(..), selectSelected)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import React.Types.Edges (Edge)
import React.Types.Nodes (Node)
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeChange(..))
import Unsafe.Reference (unsafeRefEq)

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
  , sent :: Effect (Array String)
  , notified :: Effect Int
  }

-- | A flow of `nodes` and the edge `ab`, controlled or not, that records the
-- | node changes it sends and counts the times it notifies `useStore`.
flow :: { controlled :: Boolean } -> Array (Node Unit) -> Effect Flow
flow o nodes = do
  let
    defaults = defaultInitialStateOptions :: InitialStateOptions Unit Unit
  store <- createStore
    if o.controlled then defaults { nodes = Just nodes, edges = Just [ edgeAB false ] }
    else defaults { defaultNodes = Just nodes, defaultEdges = Just [ edgeAB false ] }
  changes <- Ref.new ([] :: Array String)
  store.setState \s -> s
    { onNodesChange = Just \cs -> Ref.modify_ (_ <> map describe cs) changes }
  notifications <- Ref.new 0
  _ <- store.subscribeAll (Ref.modify_ (_ + 1) notifications)
  pure { store, sent: Ref.read changes, notified: Ref.read notifications }
  where
  describe = case _ of
    NodeSelectionChange c -> unwrap c.id <> (if c.selected then " selected" else " unselected")
    _ -> "another change"

-- | Box `ids` in `store`, as a selection box's move does.
box :: Store Unit Unit -> Array String -> Effect Unit
box store ids = do
  s <- store.getState
  selectNodesInBox store s.nodeLookup (Set.fromFoldable (map NodeId ids))

-- | Run `act` on `f`'s store, and say whether it kept the state's identity
-- | and notified nobody: whether `useStore` would miss it.
silently :: Flow -> Effect Unit -> Effect Boolean
silently f act = do
  before <- f.store.getState
  count <- f.notified
  act
  after <- f.store.getState
  count' <- f.notified
  pure (unsafeRefEq before after && count == count')

-- | Each node in the store's lookup, with a `*` on each selected.
internal :: Store Unit Unit -> Effect (Array String)
internal store = do
  s <- store.getState
  pure $ Array.fromFoldable $ Map.values s.nodeLookup <#> \n ->
    unwrap n.id <> (if n.selected == Just true then "*" else "")

-- | What `onSelectionChange` would receive if it read the store now: each
-- | node's id, with a `*` on each reported as selected, and each edge's id.
reported :: Store Unit Unit -> Effect { selection :: Selected Unit Unit, nodes :: Array String, edges :: Array String }
reported store = do
  selection@(Selected sel) <- selectSelected <$> store.getState
  pure
    { selection
    , nodes: map (\n -> unwrap n.id <> (if n.selected == Just true then "*" else "")) sel.nodes
    , edges: map _.id sel.edges
    }

runInPlaceSelectionTests :: Effect Unit
runInPlaceSelectionTests = do
  log "\n=== Store: selections write into the lookup in place ==="

  controlled <- flow { controlled: true } [ node "a" false, node "b" false ]
  quiet <- silently controlled (box controlled.store [ "a", "b" ])
  sent <- controlled.sent
  assert "a selection box sends a change for each node it holds"
    (sent == [ "a selected", "b selected" ])
  boxedLookup <- internal controlled.store
  assert "a selection box selects the lookup's nodes"
    (boxedLookup == [ "a*", "b*" ])
  assert "and does so in place, notifying nobody"
    quiet

  -- The move's `setState` that follows the box.
  controlled.store.setState _ { userSelectionActive = true }
  boxed <- reported controlled.store
  assert "in a controlled flow, the listener reports the boxed nodes as the consumer gave them, before the consumer applies the changes"
    (boxed.nodes == [ "a", "b" ] && boxed.edges == [])

  controlled.store.dispatch (SetNodes [ node "a" true, node "b" true ])
  applied <- reported controlled.store
  assert "once the consumer applies the node changes, the listener reports the nodes selected"
    (applied.nodes == [ "a*", "b*" ])
  assert "and the selection compares equal to the one before, so the listener doesn't fire again"
    (applied.selection == boxed.selection)

  controlled.store.dispatch (SetEdges [ edgeAB true ])
  withEdges <- reported controlled.store
  assert "once the consumer applies the edge changes, the listener reports the edge too, and fires again"
    (withEdges.edges == [ "ab" ] && withEdges.selection /= applied.selection)

  uncontrolled <- flow { controlled: false } [ node "a" false, node "b" false ]
  box uncontrolled.store [ "a", "b" ]
  own <- reported uncontrolled.store
  assert "in an uncontrolled flow, the listener reports the boxed nodes selected at once"
    (own.nodes == [ "a*", "b*" ])

  reversed <- flow { controlled: true } [ node "b" false, node "a" false ]
  box reversed.store [ "a", "b" ]
  ordered <- reported reversed.store
  assert "the listener reports the nodes in the nodes array's order, as the lookup's insertion order is"
    (ordered.nodes == [ "b", "a" ])

  clicked <- flow { controlled: true } [ node "a" false, node "b" true ]
  quietClick <- silently clicked (clicked.store.dispatch (AddSelectedNodes [ NodeId "a" ]))
  clickedLookup <- internal clicked.store
  assert "a click in a controlled flow selects the lookup's node, and unselects the others"
    (clickedLookup == [ "a*", "b" ])
  assert "and does so in place, notifying nobody"
    quietClick
  clicked.store.dispatch (SetNodes [ node "a" true, node "b" false ])
  clickedReport <- reported clicked.store
  assert "so the listener first reports the clicked node when the consumer's update lands, selected"
    (clickedReport.nodes == [ "a*" ])

  edgeClicked <- flow { controlled: true } [ node "a" true, node "b" false ]
  quietEdge <- silently edgeClicked (edgeClicked.store.dispatch (AddSelectedEdges [ "ab" ]))
  edgeLookup <- internal edgeClicked.store
  assert "an edge click in a controlled flow unselects the lookup's nodes, in place, notifying nobody"
    (edgeLookup == [ "a", "b" ] && quietEdge)

  unselected <- flow { controlled: true } [ node "a" true, node "b" false ]
  quietUnselect <- silently unselected
    (unselected.store.dispatch (UnselectNodesAndEdges { nodes: Nothing, edges: Nothing }))
  unselectedLookup <- internal unselected.store
  assert "unselecting in a controlled flow unselects the lookup's nodes, in place, notifying nobody"
    (unselectedLookup == [ "a", "b" ] && quietUnselect)

  own' <- flow { controlled: false } [ node "a" false, node "b" false ]
  quietOwn <- silently own' (own'.store.dispatch (AddSelectedNodes [ NodeId "a" ]))
  assert "a click in an uncontrolled flow commits the selection, and notifies"
    (not quietOwn)
