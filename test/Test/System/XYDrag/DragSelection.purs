-- | Which nodes a drag takes, after the selection its start makes.
-- |
-- | The local proxy for the report's `drag-node-release` scenario, which
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name. Upstream's `startDrag` destructures `nodeLookup` from
-- | the store, then selects: `onNodeMouseDown` runs `addSelectedNodes`, or,
-- | with `selectNodesOnDrag` off, it runs `unselectNodesAndEdges`. Both set
-- | `selected` on the lookup's nodes in place, so the `getDragItems` that
-- | follows takes only the nodes selected now. ps-flow's `startDrag` read
-- | its drag items from a snapshot taken before the selection, so a drag on
-- | an unselected node also took the nodes that were selected before it,
-- | and `unselectNodesAndEdges` didn't unselect the lookup's nodes at all.
-- |
-- | Upstream's `onNodeDragStart` reports the nodes' `internals.userNode`,
-- | which the selection doesn't touch, so the node it reports keeps the
-- | `selected` the user gave it.
-- |
-- | The test runs `startDrag` on a real store, with the store items and the
-- | `onNodeMouseDown` that `NodeWrapper` gives it.
module Test.System.XYDrag.DragSelection
  ( runDragSelectionTests
  ) where

import Prelude

import Control.Monad.State (execStateT)
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.Nullable (Nullable)
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (Ref)
import React.Component.NodeWrapper (mkDragStoreItems)
import React.Node.Util (handleNodeClick)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (createStore)
import React.Types.Nodes (Node)
import System.FFI.D3Drag (D3DragEvent)
import System.Types.Ids (NodeId(..))
import System.XYDrag (initialDragState, startDrag)
import Web.DOM.Element (Element)
import Web.HTML.HTMLDivElement (HTMLDivElement)

foreign import dragEventAtOrigin :: D3DragEvent
foreign import emptyNodeRef :: Ref (Nullable HTMLDivElement)
foreign import unusedElement :: Element

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

-- | Start a drag on `a` in a controlled flow of `nodes`. Returns the ids of
-- | the drag items, and of the nodes `onNodeDragStart` reports, with a `*`
-- | on each it reports as selected.
dragA :: { selectNodesOnDrag :: Boolean } -> Array (Node Unit) -> Effect { items :: Array String, reported :: Array String }
dragA o nodes = do
  store <- createStore
    ((defaultInitialStateOptions :: InitialStateOptions Unit Unit) { nodes = Just nodes })
  reported <- Ref.new ([] :: Array String)
  store.setState \s -> s
    { selectNodesOnDrag = o.selectNodesOnDrag
    , onNodeDragStart = Just \_ _ ns -> Ref.write (map (\n -> unwrap n.id <> (if n.selected == Just true then "*" else "")) ns) reported
    }
  state <- execStateT
    ( startDrag
        { getStoreItems: mkDragStoreItems store
        , onDragStart: Nothing
        , onDrag: Nothing
        , onDragStop: Nothing
        , onNodeMouseDown: Just \nid ->
            handleNodeClick { id: nid, store, unselect: false, nodeRef: emptyNodeRef }
        , autoPanSpeed: Nothing
        }
        { noDragClassName: Nothing
        , handleSelector: Nothing
        , isSelectable: true
        , nodeId: Just (NodeId "a")
        , domNode: unusedElement
        , nodeClickDistance: 0.0
        }
        dragEventAtOrigin
    )
    initialDragState
  { items: map (unwrap <<< _.id) state.dragItems, reported: _ } <$> Ref.read reported

runDragSelectionTests :: Effect Unit
runDragSelectionTests = do
  log "\n=== startDrag: a drag takes the selection its start makes ==="

  selecting <- dragA { selectNodesOnDrag: true } [ node "a" false, node "b" true ]
  assert "dragging an unselected node selects it, and drags it alone"
    (selecting.items == [ "a" ])
  assert "onNodeDragStart reports it alone, with the selected the user gave it"
    (selecting.reported == [ "a" ])

  unselecting <- dragA { selectNodesOnDrag: false } [ node "a" false, node "b" true ]
  assert "with selectNodesOnDrag off, dragging an unselected node unselects the rest, and drags it alone"
    (unselecting.items == [ "a" ])

  together <- dragA { selectNodesOnDrag: true } [ node "a" true, node "b" true ]
  assert "dragging a selected node still drags the whole selection"
    (together.items == [ "a", "b" ])
