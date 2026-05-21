-- | `<NodesSelection />` — the bounding-box overlay around currently
-- | selected nodes. Draggable as a group; arrow-key nudge moves all
-- | selected nodes. Mirrors
-- | `xyflow-main/packages/react/src/components/NodesSelection/index.tsx`.
-- |
-- | Responsibilities:
-- |
-- |   1. Project the bounding-box geometry + transform string of the
-- |      currently selected nodes via `useStore`. The selector calls
-- |      `getInternalNodesBounds` filtered to `node.selected = true`.
-- |   2. Hide (`mempty`) when a user lasso is active or the bounds
-- |      are degenerate (zero width/height, or non-finite from an
-- |      empty selection).
-- |   3. Mount `useDrag` with `nodeId = Nothing` so the XYDrag
-- |      controller takes the selection-drag branch (its `isNothing
-- |      nodeId` predicate gates `onSelectionDrag*` callbacks).
-- |   4. Mount `useMoveSelectedNodes` to drive arrow-key nudges.
-- |   5. Render two nested `<div>`s: an outer transform-positioned
-- |      wrapper and an inner sized rectangle that carries the drag
-- |      ref, context-menu handler, and keyboard handler.
-- |
-- | **Fidelity notes.**
-- |   * `useDrag` is always called (rules-of-hooks); when
-- |     `shouldRender = false` we return `mempty` before mounting the
-- |     wrapper, so the ref stays null and the drag controller's
-- |     `update` short-circuits. The controller object is still
-- |     allocated — same fidelity gap as other wrappers in this port.
-- |   * The "virtual node id `__nodes_selection__`" suggested by the
-- |     ticket text isn't present in the TS source — TS passes no
-- |     `nodeId` at all, and the XYDrag controller routes the absence
-- |     to its selection-drag branch. We follow the TS behaviour.
-- |   * Autofocus on mount uses a small foreign helper
-- |     (`focusWithoutScrollImpl`) because there is no PS binding for
-- |     `HTMLElement.focus({ preventScroll })` yet.
module React.Component.NodesSelection
  ( nodesSelection
  ) where

import Prelude

import Data.Array (filter, fromFoldable) as Array
import Data.Foldable (for_)
import Data.Map (lookup, values) as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.Nullable (Nullable, toNullable)
import Data.Number (isFinite, isNaN) as Number
import Data.Number.Format (toString) as NumberFormat
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Basic (ReactComponent)
import React.Basic.Events (EventHandler, handler, handler_, syntheticEvent)
import React.Basic.Hooks (UnsafeReference(..), memo, reactComponent, readRef, useEffect, useRef)
import React.Basic.Hooks as React
import React.Component.NodeWrapper.Util (arrowKeyDiffs)
import React.FFI.DOM (div_)
import React.Hook.Drag (useDrag)
import React.Hook.MoveSelectedNodes (useMoveSelectedNodes)
import React.Hook.Store (UseStoreApi, useStore, useStoreApi)
import React.Store.Action (Action(..))
import React.Store.Shell (Store)
import React.Types.Component (NodesSelectionProps)
import React.Types.Store (ReactFlowState)
import System.Utils.Graph (getInternalNodesBounds)
import System.XYDrag (DragStoreItems)
import Unsafe.Coerce (unsafeCoerce)
import Web.Event.Event (preventDefault)
import Web.HTML.HTMLDivElement (HTMLDivElement, toElement)
import Web.UIEvent.KeyboardEvent (KeyboardEvent)
import Web.UIEvent.KeyboardEvent (key, shiftKey, toEvent) as KE
import Web.UIEvent.MouseEvent (MouseEvent)

foreign import focusWithoutScrollImpl :: Nullable HTMLDivElement -> Effect Unit

toForeignStyle :: forall r. Record r -> Foreign
toForeignStyle = unsafeCoerce

showN :: Number -> String
showN = NumberFormat.toString

isNumericN :: Number -> Boolean
isNumericN n = not (Number.isNaN n) && Number.isFinite n

-- ----------------------------------------------------------------------------
-- Slice
-- ----------------------------------------------------------------------------

type NodesSelectionSlice =
  { width :: Number
  , height :: Number
  , hasBounds :: Boolean
  , transformString :: String
  , userSelectionActive :: Boolean
  }

selectSlice :: forall n e. ReactFlowState n e -> NodesSelectionSlice
selectSlice s =
  let
    rect = getInternalNodesBounds s.nodeLookup (Just \n -> n.selected)
    t = unwrap s.transform
    transformString =
      "translate(" <> showN t.tx <> "px," <> showN t.ty <> "px)"
        <> " scale(" <> showN t.scale <> ")"
        <> " translate(" <> showN rect.x <> "px," <> showN rect.y <> "px)"
  in
    { width: rect.width
    , height: rect.height
    , hasBounds: isNumericN rect.width && isNumericN rect.height
        && rect.width > 0.0
        && rect.height > 0.0
    , transformString
    , userSelectionActive: s.userSelectionActive
    }

-- ----------------------------------------------------------------------------
-- Drag-store-items adapter (local copy; see plan)
-- ----------------------------------------------------------------------------

mkDragStoreItems
  :: forall n e
   . Store n e
  -> Effect (DragStoreItems n e)
mkDragStoreItems store = do
  s <- store.getState
  pure
    { nodes: s.nodes
    , nodeLookup: s.nodeLookup
    , edges: s.edges
    , nodeExtent: s.nodeExtent
    , snapGrid: s.snapGrid
    , snapToGrid: s.snapToGrid
    , nodeOrigin: s.nodeOrigin
    , multiSelectionActive: s.multiSelectionActive
    , domNode: map toElement s.domNode
    , transform: s.transform
    , autoPanOnNodeDrag: s.autoPanOnNodeDrag
    , nodesDraggable: s.nodesDraggable
    , selectNodesOnDrag: s.selectNodesOnDrag
    , nodeDragThreshold: s.nodeDragThreshold
    , panBy: panByAdapter store
    , unselectNodesAndEdges:
        store.dispatch
          (UnselectNodesAndEdges { nodes: Nothing, edges: Nothing })
    , onError: s.onError
    , onNodeDragStart: s.onNodeDragStart
    , onNodeDrag: s.onNodeDrag
    , onNodeDragStop: s.onNodeDragStop
    , onSelectionDragStart: s.onSelectionDragStart
    , onSelectionDrag: s.onSelectionDrag
    , onSelectionDragStop: s.onSelectionDragStop
    , updateNodePositions: \items dragging ->
        store.dispatch
          ( UpdateNodePositions
              (Array.fromFoldable (Map.values items))
              dragging
          )
    , autoPanSpeed: Just s.autoPanSpeed
    }

panByAdapter
  :: forall n e
   . Store n e
  -> { x :: Number, y :: Number }
  -> Aff Boolean
panByAdapter store delta =
  liftEffect (store.dispatch (PanBy delta)) *> pure true

-- ----------------------------------------------------------------------------
-- The component
-- ----------------------------------------------------------------------------

nodesSelection :: forall n. ReactComponent (NodesSelectionProps n)
nodesSelection =
  unsafePerformEffect $ memo $ reactComponent "NodesSelection"
    \(props :: NodesSelectionProps n) -> React.do
      slice <- useStore selectSlice
      store <- (useStoreApi :: React.Hook UseStoreApi _)
      nodeRef <- useRef (toNullable Nothing :: Nullable HTMLDivElement)
      moveSelectedNodes <- useMoveSelectedNodes

      let
        shouldRender = not slice.userSelectionActive && slice.hasBounds

      useEffect (UnsafeReference props.disableKeyboardA11y) do
        unless props.disableKeyboardA11y do
          cur <- readRef nodeRef
          focusWithoutScrollImpl cur
        pure (pure unit)

      _dragging <- useDrag
        { wrapperRef: nodeRef
        , nodeId: Nothing
        , noDragClassName: props.noPanClassName
        , handleSelector: Nothing
        , isSelectable: true
        , nodeClickDistance: 0.0
        , autoPanSpeed: Nothing
        , getStoreItems: mkDragStoreItems store
        , onDragStart: Nothing
        , onDragEnd: Nothing
        }

      let
        wrapperClass =
          "react-flow__nodesselection react-flow__container"
            <> case props.noPanClassName of
                 Just c | c /= "" -> " " <> c
                 _ -> ""

        onContextMenuHandler :: EventHandler
        onContextMenuHandler = handler syntheticEvent \se -> do
          let me = (unsafeCoerce se) :: MouseEvent
          for_ props.onSelectionContextMenu \cb -> do
            st <- store.getState
            let selected = Array.filter _.selected st.nodes
            cb me selected

        onKeyDownHandler :: KeyboardEvent -> Effect Unit
        onKeyDownHandler ke = case Map.lookup (KE.key ke) arrowKeyDiffs of
          Just delta -> do
            preventDefault (KE.toEvent ke)
            moveSelectedNodes delta (if KE.shiftKey ke then 4.0 else 1.0)
          Nothing -> pure unit

        onKeyDownEventHandler :: EventHandler
        onKeyDownEventHandler = handler syntheticEvent \se ->
          onKeyDownHandler ((unsafeCoerce se) :: KeyboardEvent)

      pure $
        if not shouldRender then mempty
        else
          div_
            { className: wrapperClass
            , style: toForeignStyle { transform: slice.transformString }
            }
            [ div_
                { ref: nodeRef
                , className: "react-flow__nodesselection-rect"
                , onContextMenu: onContextMenuHandler
                , tabIndex: if props.disableKeyboardA11y then 0 else -1
                , onKeyDown:
                    if props.disableKeyboardA11y then handler_ (pure unit)
                    else onKeyDownEventHandler
                , style: toForeignStyle
                    { width: showN slice.width
                    , height: showN slice.height
                    }
                }
                []
            ]
