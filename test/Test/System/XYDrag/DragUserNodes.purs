-- | The nodes a drag's callbacks report: the user's, not the internal ones.
-- |
-- | The local proxy for the report's `fitview-onnodeschange-variants`
-- | scenario, which
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name. Upstream's `getEventHandlerParams` spreads each drag
-- | item's `internals.userNode`: the node object from the store's last
-- | `setNodes`. A selection changes the internal node in place, and reaches
-- | the user's node only through `setNodes`. So in an uncontrolled flow,
-- | which applies the change to its own nodes at once, `onNodeDragStart`
-- | reports the node it just selected as selected. In a controlled flow, the
-- | consumer's update comes later, so it doesn't. ps-flow reported its
-- | internal nodes, from before the selection, so an uncontrolled flow's
-- | callbacks missed it, and a controlled flow's `onNodeDrag` reported a
-- | selection the consumer hadn't made.
-- |
-- | The test starts a drag on a real store, with the store items and the
-- | `onNodeMouseDown` that `NodeWrapper` gives it, and moves it once.
module Test.System.XYDrag.DragUserNodes
  ( runDragUserNodesTests
  ) where

import Prelude

import Control.Monad.State (execStateT, modify_)
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
import System.Types.Geometry (XYPosition)
import System.Types.Ids (NodeId(..))
import System.XYDrag (initialDragState, startDrag, updateNodes)
import Web.DOM.Element (Element)
import Web.HTML.HTMLDivElement (HTMLDivElement)
import Web.UIEvent.MouseEvent (MouseEvent)

foreign import dragEventAtOrigin :: D3DragEvent
foreign import sourceEvent :: MouseEvent
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

-- | How a callback's nodes read: each id, with a `*` on each reported as
-- | selected.
shown :: Array (Node Unit) -> Array String
shown = map \n -> unwrap n.id <> (if n.selected == Just true then "*" else "")

-- | Start a drag on `a` in a flow of `nodes`, controlled or not, and move it
-- | once to (20, 20). Returns the nodes `onNodeDragStart` and `onNodeDrag`
-- | report, the `dragging` of the first, and the positions of the second.
dragA
  :: { controlled :: Boolean }
  -> Array (Node Unit)
  -> Effect
       { started :: Array String
       , dragged :: Array String
       , startedDragging :: Array (Maybe Boolean)
       , draggedAt :: Array XYPosition
       }
dragA o nodes = do
  store <- createStore
    ( if o.controlled then (defaultInitialStateOptions :: InitialStateOptions Unit Unit) { nodes = Just nodes }
      else (defaultInitialStateOptions :: InitialStateOptions Unit Unit) { defaultNodes = Just nodes }
    )
  started <- Ref.new ([] :: Array (Node Unit))
  dragged <- Ref.new ([] :: Array (Node Unit))
  store.setState \s -> s
    { onNodeDragStart = Just \_ _ ns -> Ref.write ns started
    , onNodeDrag = Just \_ _ ns -> Ref.write ns dragged
    }
  let
    params =
      { getStoreItems: mkDragStoreItems store
      , onDragStart: Nothing
      , onDrag: Nothing
      , onDragStop: Nothing
      , onNodeMouseDown: Just \nid ->
          handleNodeClick { id: nid, store, unselect: false, nodeRef: emptyNodeRef }
      , autoPanSpeed: Nothing
      }
  _ <- execStateT
    ( do
        startDrag params
          { noDragClassName: Nothing
          , handleSelector: Nothing
          , isSelectable: true
          , nodeId: Just (NodeId "a")
          , domNode: unusedElement
          , nodeClickDistance: 0.0
          }
          dragEventAtOrigin
        -- What the drag handler does before it moves the nodes.
        modify_ _ { dragEvent = Just sourceEvent }
        updateNodes params (Just (NodeId "a")) { x: 20.0, y: 20.0 }
    )
    initialDragState
  s <- Ref.read started
  d <- Ref.read dragged
  pure
    { started: shown s
    , dragged: shown d
    , startedDragging: map _.dragging s
    , draggedAt: map _.position d
    }

runDragUserNodesTests :: Effect Unit
runDragUserNodesTests = do
  log "\n=== XYDrag: a drag's callbacks report the user's nodes ==="

  uncontrolled <- dragA { controlled: false } [ node "a" false, node "b" true ]
  assert "in an uncontrolled flow, onNodeDragStart reports the node the drag just selected as selected"
    (uncontrolled.started == [ "a*" ])
  assert "in an uncontrolled flow, onNodeDrag reports it as selected"
    (uncontrolled.dragged == [ "a*" ])
  assert "onNodeDragStart reports the user's node as dragging, as the spread sets it"
    (uncontrolled.startedDragging == [ Just true ])
  assert "onNodeDrag reports the user's node at its drag item's position"
    (uncontrolled.draggedAt == [ { x: 20.0, y: 20.0 } ])

  controlled <- dragA { controlled: true } [ node "a" false, node "b" true ]
  assert "in a controlled flow, onNodeDragStart reports the node as the consumer gave it"
    (controlled.started == [ "a" ])
  assert "in a controlled flow, onNodeDrag reports it as the consumer gave it, until the consumer applies the selection"
    (controlled.dragged == [ "a" ])

  together <- dragA { controlled: true } [ node "a" true, node "b" true ]
  assert "a drag of the consumer's selection reports each node as selected"
    (together.started == [ "a*", "b*" ] && together.dragged == [ "a*", "b*" ])
