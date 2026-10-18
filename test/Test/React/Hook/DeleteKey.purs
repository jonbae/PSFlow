-- | What the delete key does to the selection.
-- |
-- | The local proxy for the report's delete-key scenarios, which
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name: `delete-key-removes-edge`,
-- | `delete-key-removes-node-and-edges`, and the two
-- | `delete-key-spares-undeletable-*`. Upstream's `useGlobalKeyHandler`
-- | runs
-- |
-- |     const { edges, nodes } = store.getState();
-- |     deleteElements({ nodes: nodes.filter(selected), edges: edges.filter(selected) });
-- |     store.setState({ nodesSelectionActive: false });
-- |
-- | with `useReactFlow`'s `deleteElements`, so a delete goes through
-- | `onBeforeDelete`, takes a deleted node's edges with it, and fires
-- | `onEdgesDelete`, `onNodesDelete`, and `onDelete`. ps-flow's handler
-- | dispatched the selected elements' remove changes itself, so none of
-- | the four callbacks fired, and a deleted node's edges stayed.
-- |
-- | The test runs `deleteSelectedElements`, the handler's effect body,
-- | with a real store and the `deleteElements` `useReactFlow` builds from
-- | it. That the hook calls it when the key goes down is the net's to
-- | check: `spago test` has no DOM to press a key in.
module Test.React.Hook.DeleteKey
  ( runDeleteKeyTests
  ) where

import Prelude

import Data.Array (intercalate)
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Hook.GlobalKeyHandler (deleteSelectedElements)
import React.Hook.ReactFlow (mkGeneralHelpers)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (createStore)
import React.Types.Edges (Edge)
import React.Types.Nodes (Node)
import System.Types.Edge (EdgeChange(..))
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeChange(..))
import Unsafe.Coerce (unsafeCoerce)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

node :: String -> { selected :: Boolean, deletable :: Boolean } -> Node Unit
node id flags =
  { id: NodeId id
  , position: { x: 0.0, y: 0.0 }
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: Nothing
  , selected: if flags.selected then Just true else Nothing
  , dragging: Nothing
  , draggable: Nothing
  , selectable: Nothing
  , connectable: Nothing
  , deletable: if flags.deletable then Nothing else Just false
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
  , measured: { width: Nothing, height: Nothing }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

edge :: String -> String -> Boolean -> Edge Unit
edge source target selected =
  { id: source <> "-" <> target
  , edgeType: Nothing
  , source: NodeId source
  , target: NodeId target
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

plain :: { selected :: Boolean, deletable :: Boolean }
plain = { selected: false, deletable: true }

ids :: forall r. Array { id :: String | r } -> String
ids xs = "[" <> intercalate "," (map _.id xs) <> "]"

nodeIds :: forall r. Array { id :: NodeId | r } -> String
nodeIds xs = "[" <> intercalate "," (map (unwrap <<< _.id) xs) <> "]"

-- | Press delete on a controlled flow of `nodes` and `edges`, with a
-- | multi-node selection box showing. Returns the callbacks the press
-- | fired, in order, and whether the selection box is still showing.
pressDelete
  :: Array (Node Unit)
  -> Array (Edge Unit)
  -> Effect { fired :: Array String, nodesSelectionActive :: Boolean }
pressDelete nodes edges = do
  store <- createStore
    ((defaultInitialStateOptions :: InitialStateOptions Unit Unit) { nodes = Just nodes, edges = Just edges })
  fired <- Ref.new ([] :: Array String)
  let record entry = Ref.modify_ (_ <> [ entry ]) fired
  store.setState \s -> s
    { nodesSelectionActive = true
    , onBeforeDelete = Just \r -> do
        liftEffect (record ("onBeforeDelete " <> nodeIds r.nodes <> " " <> ids r.edges))
        pure { allow: true, nodes: Nothing, edges: Nothing }
    , onEdgesDelete = Just \es -> record ("onEdgesDelete " <> ids es)
    , onNodesDelete = Just \ns -> record ("onNodesDelete " <> nodeIds ns)
    , onDelete = Just \r -> record ("onDelete " <> nodeIds r.nodes <> " " <> ids r.edges)
    , onEdgesChange = Just \cs -> record ("onEdgesChange " <> intercalate "," (map edgeChange cs))
    , onNodesChange = Just \cs -> record ("onNodesChange " <> intercalate "," (map nodeChange cs))
    }
  deleteSelectedElements store (mkGeneralHelpers store (unsafeCoerce unit)).deleteElements
  { fired: _, nodesSelectionActive: _ }
    <$> Ref.read fired
    <*> map _.nodesSelectionActive store.getState
  where
  nodeChange = case _ of
    NodeRemoveChange c -> "remove " <> unwrap c.id
    _ -> "other"
  edgeChange = case _ of
    EdgeRemoveChange c -> "remove " <> c.id
    _ -> "other"

runDeleteKeyTests :: Effect Unit
runDeleteKeyTests = do
  log "\n=== The delete key deletes the selection through deleteElements ==="

  let
    nodes = [ node "a" (plain { selected = true }), node "b" plain, node "c" plain ]
    edges = [ edge "a" "b" false, edge "b" "c" false ]
  removedNode <- pressDelete nodes edges
  assert "a selected node's delete fires upstream's callbacks, in its order, with the node's edges"
    ( removedNode.fired ==
        [ "onBeforeDelete [a] [a-b]"
        , "onEdgesDelete [a-b]"
        , "onEdgesChange remove a-b"
        , "onNodesDelete [a]"
        , "onNodesChange remove a"
        , "onDelete [a] [a-b]"
        ]
    )
  assert "the delete hides the selection box"
    (not removedNode.nodesSelectionActive)

  removedEdge <- pressDelete [ node "b" plain, node "c" plain ] [ edge "b" "c" true ]
  assert "a selected edge's delete fires the edge callbacks and onDelete"
    ( removedEdge.fired ==
        [ "onBeforeDelete [] [b-c]"
        , "onEdgesDelete [b-c]"
        , "onEdgesChange remove b-c"
        , "onDelete [] [b-c]"
        ]
    )

  spared <- pressDelete [ node "a" { selected: true, deletable: false } ] []
  assert "an undeletable selection still asks onBeforeDelete, with nothing, and deletes nothing"
    (spared.fired == [ "onBeforeDelete [] []" ])
