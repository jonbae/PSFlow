-- | The errors a drag raises through the store's `onError`.
-- |
-- | The local proxy for the report's `drag-unmeasured-node` scenario, which
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name. Upstream's drag hands `calculateNodePosition` the
-- | `onError` from `getStoreItems()`, and `calculateNodePosition` raises 005
-- | for a `parent` extent with no parent, then 015 for a node with no
-- | measured width or height. The drag's loop raises them on each move,
-- | before it updates any position, so `onError` comes before
-- | `onNodesChange`. ps-flow's drag had no `onError`, and its
-- | `calculateNodePosition` raised nothing.
-- |
-- | The test starts a drag on a real store, with the store items that
-- | `NodeWrapper` gives it, and moves it once.
module Test.System.XYDrag.DragErrors
  ( runDragErrorsTests
  ) where

import Prelude

import Control.Monad.State (execStateT)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Component.NodeWrapper (mkDragStoreItems)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (createStore)
import React.Types.Nodes (Node)
import System.Constants (ErrorCode(..))
import System.FFI.D3Drag (D3DragEvent)
import System.Types.Geometry (mkNodeOrigin)
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeExtent(..))
import System.Utils.Graph (calculateNodePosition)
import System.XYDrag (initialDragState, startDrag, updateNodes)
import Web.DOM.Element (Element)

foreign import dragEventAtOrigin :: D3DragEvent
foreign import unusedElement :: Element

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | A selected node at the origin, measured `width` by `height`.
node :: String -> Maybe Number -> Maybe Number -> Node Unit
node id width height =
  { id: NodeId id
  , position: { x: 0.0, y: 0.0 }
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: Nothing
  , selected: Just true
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
  , measured: { width, height }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

measuredNode :: String -> Node Unit
measuredNode id = node id (Just 150.0) (Just 40.0)

unmeasuredNode :: String -> Node Unit
unmeasuredNode id = node id Nothing Nothing

error015 :: String
error015 = "015 It seems that you are trying to drag a node that is not initialized. Please use onNodesChange as explained in the docs."

-- | Start a drag on `a` in a controlled flow of `nodes`, and move it once.
-- | Returns the calls to `onError`, as code and message, and to
-- | `onNodesChange`, in the order they came.
moveA :: Array (Node Unit) -> Effect (Array String)
moveA nodes = do
  store <- createStore
    ((defaultInitialStateOptions :: InitialStateOptions Unit Unit) { nodes = Just nodes })
  calls <- Ref.new ([] :: Array String)
  store.setState \s -> s
    { onError = Just \code message -> Ref.modify_ (_ <> [ code <> " " <> message ]) calls
    , onNodesChange = Just \_ -> Ref.modify_ (_ <> [ "onNodesChange" ]) calls
    }
  let
    params =
      { getStoreItems: mkDragStoreItems store
      , onDragStart: Nothing
      , onDrag: Nothing
      , onDragStop: Nothing
      , onNodeMouseDown: Nothing
      , autoPanSpeed: Nothing
      }
  _ <- execStateT
    ( startDrag params
        { noDragClassName: Nothing
        , handleSelector: Nothing
        , isSelectable: true
        , nodeId: Just (NodeId "a")
        , domNode: unusedElement
        , nodeClickDistance: 0.0
        }
        dragEventAtOrigin
        *> updateNodes params (Just (NodeId "a")) { x: 20.0, y: 20.0 }
    )
    initialDragState
  Ref.read calls

-- | The errors `calculateNodePosition` returns for `n`, in a lookup of it
-- | alone.
errorsFor :: Node Unit -> Effect (Maybe (Array ErrorCode))
errorsFor n = do
  store <- createStore
    ((defaultInitialStateOptions :: InitialStateOptions Unit Unit) { nodes = Just [ n ] })
  s <- store.getState
  pure $ _.errors <$> calculateNodePosition
    { nodeId: n.id
    , nextPosition: { x: 0.0, y: 0.0 }
    , nodeLookup: s.nodeLookup
    , nodeOrigin: mkNodeOrigin 0.0 0.0
    , nodeExtent: Nothing
    }

runDragErrorsTests :: Effect Unit
runDragErrorsTests = do
  log "\n=== updateNodes: a drag raises calculateNodePosition's errors ==="

  unmeasured <- moveA [ unmeasuredNode "a" ]
  assert "moving a node with no measured size raises 015, before it moves the node"
    (unmeasured == [ error015, "onNodesChange" ])

  measured <- moveA [ measuredNode "a" ]
  assert "moving a measured node raises nothing"
    (measured == [ "onNodesChange" ])

  both <- moveA [ unmeasuredNode "a", unmeasuredNode "b" ]
  assert "moving two nodes with no measured size raises 015 for each, before it moves either"
    (both == [ error015, error015, "onNodesChange" ])

  halfMeasured <- errorsFor (node "a" (Just 150.0) Nothing)
  assert "a node with a measured width but no height raises 015"
    (halfMeasured == Just [ E015 ])

  orphan <- errorsFor ((unmeasuredNode "a") { extent = Just ParentExtent })
  assert "a parent extent with no parent raises 005, then 015"
    (orphan == Just [ E005, E015 ])

  expanding <- errorsFor ((measuredNode "a") { extent = Just ParentExtent, expandParent = Just true })
  assert "a parent extent that expands its parent raises nothing"
    (expanding == Just [])
