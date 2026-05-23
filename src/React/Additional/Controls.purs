-- | `<Controls />` — the floating zoom/fit/lock button bar. Mirrors
-- | `xyflow-main/.../Controls/Controls.tsx`.
module React.Additional.Controls
  ( controls
  , module React.Types.Component
  ) where

import Prelude

import Data.Foldable (for_)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Newtype (class Newtype)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent, element)
import React.Basic.Hooks (UnsafeReference(..), memo, reactChildrenFromArray, reactChildrenToArray, reactComponentWithChildren)
import React.Basic.Hooks as React
import React.Additional.Controls.Button (controlButton)
import React.Additional.Controls.Icons
  ( iconFitView
  , iconLock
  , iconMinus
  , iconPlus
  , iconUnlock
  )
import React.Hook.ReactFlow (useReactFlow)
import React.Hook.Store (UseStoreApi, useStore, useStoreApi)
import React.Portal.Panel (panel)
import React.Types.Component (ControlsProps, Orientation(..))
import React.Types.Instance (ZoomOptions)
import React.Types.Store (ReactFlowState)
import System.Constants (AriaLabelConfig)
import System.Types.Connection (PanelPosition(..))
import System.Types.Geometry (Transform(..))

newtype CtrlSlice = CtrlSlice
  { isInteractive :: Boolean
  , minZoomReached :: Boolean
  , maxZoomReached :: Boolean
  , ariaLabelConfig :: UnsafeReference AriaLabelConfig
  }

derive instance newtypeCtrlSlice :: Newtype CtrlSlice _
derive newtype instance eqCtrlSlice :: Eq CtrlSlice

selector :: forall n e. ReactFlowState n e -> CtrlSlice
selector s = CtrlSlice
  { isInteractive: s.nodesDraggable || s.nodesConnectable || s.elementsSelectable
  , minZoomReached: (case s.transform of Transform t -> t.scale) <= s.minZoom
  , maxZoomReached: (case s.transform of Transform t -> t.scale) >= s.maxZoom
  , ariaLabelConfig: UnsafeReference s.ariaLabelConfig
  }

orientationClass :: Orientation -> String
orientationClass = case _ of
  Horizontal -> "horizontal"
  Vertical -> "vertical"

defaultOpts :: ZoomOptions
defaultOpts = { duration: Nothing, ease: Nothing, interpolate: Nothing }

controls :: ReactComponent ControlsProps
controls =
  unsafePerformEffect $ memo $ reactComponentWithChildren "Controls"
    \(props :: ControlsProps) -> React.do
      store <- (useStoreApi :: React.Hook UseStoreApi _)
      CtrlSlice slice <- useStore selector
      flow <- useReactFlow
      let
        showZoom = fromMaybe true props.showZoom
        showFitView = fromMaybe true props.showFitView
        showInteractive = fromMaybe true props.showInteractive
        orient = fromMaybe Vertical props.orientation
        pos = fromMaybe BottomLeft props.position
        UnsafeReference aria = slice.ariaLabelConfig

        onZoomInHandler :: Effect Unit
        onZoomInHandler = do
          launchAff_ (void (flow.zoomIn defaultOpts))
          for_ props.onZoomIn identity

        onZoomOutHandler :: Effect Unit
        onZoomOutHandler = do
          launchAff_ (void (flow.zoomOut defaultOpts))
          for_ props.onZoomOut identity

        onFitViewHandler :: Effect Unit
        onFitViewHandler = do
          launchAff_ (void (flow.fitView props.fitViewOptions))
          for_ props.onFitView identity

        onToggleInteractivity :: Effect Unit
        onToggleInteractivity = do
          let next = not slice.isInteractive
          store.setState \s -> s
            { nodesDraggable = next
            , nodesConnectable = next
            , elementsSelectable = next
            }
          for_ props.onInteractiveChange \cb -> cb next

        userClass = fromMaybe "" props.className
        panelClassName = "react-flow__controls " <> orientationClass orient
          <> (if userClass == "" then "" else " " <> userClass)

        zoomButtons =
          if showZoom then
            [ element controlButton
                { onClick: Just onZoomInHandler
                , className: Just "react-flow__controls-zoomin"
                , title: Just aria.controlsZoomInAriaLabel
                , "aria-label": Just aria.controlsZoomInAriaLabel
                , disabled: Just slice.maxZoomReached
                , style: Nothing
                , children: reactChildrenFromArray [ iconPlus ]
                }
            , element controlButton
                { onClick: Just onZoomOutHandler
                , className: Just "react-flow__controls-zoomout"
                , title: Just aria.controlsZoomOutAriaLabel
                , "aria-label": Just aria.controlsZoomOutAriaLabel
                , disabled: Just slice.minZoomReached
                , style: Nothing
                , children: reactChildrenFromArray [ iconMinus ]
                }
            ]
          else []

        fitViewButton =
          if showFitView then
            [ element controlButton
                { onClick: Just onFitViewHandler
                , className: Just "react-flow__controls-fitview"
                , title: Just aria.controlsFitViewAriaLabel
                , "aria-label": Just aria.controlsFitViewAriaLabel
                , disabled: Nothing
                , style: Nothing
                , children: reactChildrenFromArray [ iconFitView ]
                }
            ]
          else []

        interactiveButton =
          if showInteractive then
            [ element controlButton
                { onClick: Just onToggleInteractivity
                , className: Just "react-flow__controls-interactive"
                , title: Just aria.controlsInteractiveAriaLabel
                , "aria-label": Just aria.controlsInteractiveAriaLabel
                , disabled: Nothing
                , style: Nothing
                , children: reactChildrenFromArray
                    [ if slice.isInteractive then iconUnlock else iconLock ]
                }
            ]
          else []

        extraChildren = reactChildrenToArray props.children

        allChildren = zoomButtons <> fitViewButton <> interactiveButton <> extraChildren

      pure $ element panel
        { position: pos
        , className: Just panelClassName
        , style: props.style
        , "aria-label": Just
            (fromMaybe aria.controlsAriaLabel props."aria-label")
        , "data-testid": Just "rf__controls"
        , children: reactChildrenFromArray allChildren
        }
