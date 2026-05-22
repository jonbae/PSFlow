-- | `<FlowRenderer />` — the structural shell that nests the
-- | `<ZoomPane>` (pan/zoom surface) inside the `<Pane>` (lasso /
-- | click handling), surfaces user children, and overlays
-- | `<NodesSelection>` when the store says a multi-selection is
-- | active. Mirrors
-- | `xyflow-main/packages/react/src/container/FlowRenderer/index.tsx`.
-- |
-- | **Fidelity notes.**
-- |   * `memo` is applied to the public export, matching TS.
-- |   * `panOnDrag` is `PanOnDrag` not `Boolean | number[]`; the TS
-- |     idiom `panActivationKeyPressed || _panOnDrag` becomes "if the
-- |     activation key is pressed, force `PanAlways`; otherwise pass
-- |     through". Same translation for `panOnScroll` (which is a plain
-- |     `Boolean`).
-- |   * `_selectionOnDrag = selectionOnDrag && panOnDrag !== true`
-- |     becomes "and not `PanAlways`". `PanOnButtons` still counts as
-- |     a restricted form of pan and allows selection on drag.
-- |   * `onPaneScroll` from `FlowRendererProps` is a `WheelEvent ->`
-- |     handler so it can be threaded into `Pane` directly without an
-- |     intermediate `Maybe Wheel`-adapter.
module React.Container.FlowRenderer
  ( flowRenderer
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (memo, reactChildrenFromArray, reactChildrenToArray, reactComponentWithChildren)
import React.Basic.Hooks as React
import React.Component.NodesSelection (nodesSelection)
import React.Container.Pane (pane)
import React.Container.ZoomPane (zoomPane)
import React.Hook.GlobalKeyHandler (useGlobalKeyHandler)
import React.Hook.KeyPress (useKeyPress)
import React.Hook.Store (useStore)
import React.Types.Component (FlowRendererProps)
import React.Types.Store (ReactFlowState)
import System.Types.PanZoom (PanOnDrag(..))

-- ----------------------------------------------------------------------------
-- Slice
-- ----------------------------------------------------------------------------

type FlowRendererSlice =
  { nodesSelectionActive :: Boolean
  , userSelectionActive :: Boolean
  }

selectSlice :: forall n e. ReactFlowState n e -> FlowRendererSlice
selectSlice s =
  { nodesSelectionActive: s.nodesSelectionActive
  , userSelectionActive: s.userSelectionActive
  }

-- | If the pan-activation key is held, escalate to `PanAlways`;
-- | otherwise use the user-configured `PanOnDrag`. Mirrors TS line 81
-- | (`const panOnDrag = panActivationKeyPressed || _panOnDrag`).
escalatePan :: Boolean -> PanOnDrag -> PanOnDrag
escalatePan pressed configured =
  if pressed then PanAlways else configured

-- | `panOnDrag !== true` in TS. Returns `false` only for `PanAlways`.
isUnrestrictedPan :: PanOnDrag -> Boolean
isUnrestrictedPan = case _ of
  PanAlways -> true
  _ -> false

flowRenderer :: forall n. ReactComponent (FlowRendererProps n)
flowRenderer =
  unsafePerformEffect $ memo $ reactComponentWithChildren "FlowRenderer"
    \(props :: FlowRendererProps n) -> React.do
      slice <- useStore selectSlice
      selectionKeyPressed <- useKeyPress props.selectionKeyCode Nothing
      panActivationKeyPressed <- useKeyPress props.panActivationKeyCode Nothing
      let
        panOnDrag = escalatePan panActivationKeyPressed props.panOnDrag
        panOnScroll = panActivationKeyPressed || props.panOnScroll
        selectionOnDragEff =
          props.selectionOnDrag && not (isUnrestrictedPan panOnDrag)
        isSelecting =
          selectionKeyPressed || slice.userSelectionActive || selectionOnDragEff
        zoomPaneDrag =
          if selectionKeyPressed then NoPan else panOnDrag
      useGlobalKeyHandler
        { deleteKeyCode: props.deleteKeyCode
        , multiSelectionKeyCode: props.multiSelectionKeyCode
        }
      let
        userChildren :: Array JSX
        userChildren = reactChildrenToArray props.children
        selectionOverlay :: Array JSX
        selectionOverlay =
          if slice.nodesSelectionActive then
            [ element nodesSelection
                { onSelectionContextMenu: props.onSelectionContextMenu
                , noPanClassName: Just props.noPanClassName
                , disableKeyboardA11y: props.disableKeyboardA11y
                }
            ]
          else []
        paneChildren :: Array JSX
        paneChildren = userChildren <> selectionOverlay
      pure $
        element zoomPane
          { children: reactChildrenFromArray
              [ element pane
                  { children: reactChildrenFromArray paneChildren
                  , isSelecting
                  , selectionKeyPressed
                  , selectionMode: props.selectionMode
                  , panOnDrag
                  , selectionOnDrag: selectionOnDragEff
                  , autoPanOnSelection: props.autoPanOnSelection
                  , paneClickDistance: props.paneClickDistance
                  , onSelectionStart: props.onSelectionStart
                  , onSelectionEnd: props.onSelectionEnd
                  , onPaneClick: props.onPaneClick
                  , onPaneContextMenu: props.onPaneContextMenu
                  , onPaneScroll: props.onPaneScroll
                  , onPaneMouseEnter: props.onPaneMouseEnter
                  , onPaneMouseMove: props.onPaneMouseMove
                  , onPaneMouseLeave: props.onPaneMouseLeave
                  }
              ]
          , onPaneContextMenu: props.onPaneContextMenu
          , zoomOnScroll: props.zoomOnScroll
          , zoomOnPinch: props.zoomOnPinch
          , zoomOnDoubleClick: props.zoomOnDoubleClick
          , panOnScroll
          , panOnScrollSpeed: props.panOnScrollSpeed
          , panOnScrollMode: props.panOnScrollMode
          , panOnDrag: zoomPaneDrag
          , defaultViewport: props.defaultViewport
          , translateExtent: props.translateExtent
          , minZoom: props.minZoom
          , maxZoom: props.maxZoom
          , zoomActivationKeyCode: props.zoomActivationKeyCode
          , preventScrolling: props.preventScrolling
          , noWheelClassName: props.noWheelClassName
          , noPanClassName: props.noPanClassName
          , onMove: Nothing
          , onMoveStart: Nothing
          , onMoveEnd: Nothing
          , onViewportChange: props.onViewportChange
          , isControlledViewport: props.isControlledViewport
          , paneClickDistance: props.paneClickDistance
          , selectionOnDrag: selectionOnDragEff
          }
