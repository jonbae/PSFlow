-- | `<GraphView />` — the orchestrator that lives between `<ReactFlow />`
-- | and the rendering layer. Mirrors
-- | `xyflow-main/packages/react/src/container/GraphView/index.tsx`.
-- |
-- | Composes:
-- |
-- |   * `<FlowRenderer>` (which internally hosts `<ZoomPane>` → `<Pane>`)
-- |   * `<Viewport>` (CSS-transform child)
-- |     * `<EdgeRenderer />` — SVG edge layer
-- |     * `<ConnectionLine />` — in-progress connection overlay
-- |     * `<div className="react-flow__edgelabel-renderer" />` — portal
-- |       target populated by ticket 044
-- |     * `<NodeRenderer />` — node layer
-- |     * `<div className="react-flow__viewport-portal" />` — portal
-- |       target populated by ticket 044
-- |
-- | **Fidelity notes.**
-- |   * `memo` is applied to the public export, matching TS.
-- |   * The two dev-time warning hooks (`useNodeOrEdgeTypesWarning`,
-- |     `useStylesLoadedWarning`) gate on `state.debug` rather than
-- |     `process.env.NODE_ENV` — see each hook's header for rationale.
-- |   * `useOnInitHandler` and `useViewportSync` are unchanged from
-- |     their existing implementations.
-- |   * `isControlledViewport` derives from `isJust props.viewport` (TS
-- |     `!!viewport`).
module React.Container.GraphView
  ( graphView
  ) where

import Prelude

import Data.Maybe (Maybe(..), isJust)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (memo, reactChildrenFromArray, reactComponent)
import React.Basic.Hooks as React
import React.Component.ConnectionLine (connectionLine)
import React.Container.EdgeRenderer (edgeRenderer)
import React.Container.FlowRenderer (flowRenderer)
import React.Container.NodeRenderer (nodeRenderer)
import React.Container.Viewport (viewport)
import React.FFI.DOM (div_)
import React.Hook.Listeners (useOnInitHandler)
import React.Hook.NodeOrEdgeTypesWarning (useNodeOrEdgeTypesWarning)
import React.Hook.StylesLoadedWarning (useStylesLoadedWarning)
import React.Hook.ViewportSync (useViewportSync)
import React.Types.Component (GraphViewProps)
import Effect (Effect)
import Unsafe.Coerce (unsafeCoerce)
import Web.UIEvent.WheelEvent (WheelEvent)

-- | Treat the opaque `NodeTypesMap` / `EdgeTypesMap` as `Foreign` for the
-- | warning hooks — they only need per-key identity, not the structured
-- | shape.
toForeign :: forall a. a -> Foreign
toForeign = unsafeCoerce

graphView :: forall n e. ReactComponent (GraphViewProps n e)
graphView =
  unsafePerformEffect $ memo $ reactComponent "GraphView"
    \(props :: GraphViewProps n e) -> React.do
      useNodeOrEdgeTypesWarning (toForeign <$> props.nodeTypes)
      useNodeOrEdgeTypesWarning (toForeign <$> props.edgeTypes)
      useStylesLoadedWarning
      useOnInitHandler props.onInit
      useViewportSync props.viewport
      let
        viewportChildren :: Array JSX
        viewportChildren =
          [ element edgeRenderer
              { onlyRenderVisibleElements: props.onlyRenderVisibleElements
              , defaultMarkerColor: Just props.defaultMarkerColor
              , rfId: props.rfId
              , noPanClassName: props.noPanClassName
              , disableKeyboardA11y: props.disableKeyboardA11y
              , reconnectRadius: props.reconnectRadius
              , edgeTypes: props.edgeTypes
              , onEdgeClick: props.onEdgeClick
              , onEdgeDoubleClick: props.onEdgeDoubleClick
              , onEdgeContextMenu: props.onEdgeContextMenu
              , onEdgeMouseEnter: props.onEdgeMouseEnter
              , onEdgeMouseMove: props.onEdgeMouseMove
              , onEdgeMouseLeave: props.onEdgeMouseLeave
              , onReconnect: props.onReconnect
              , onReconnectStart: props.onReconnectStart
              , onReconnectEnd: props.onReconnectEnd
              }
          , element connectionLine
              { connectionLineComponent: props.connectionLineComponent
              , connectionLineStyle: props.connectionLineStyle
              , connectionLineType: Just props.connectionLineType
              , connectionLineContainerStyle: props.connectionLineContainerStyle
              }
          , div_ { className: "react-flow__edgelabel-renderer" } []
          , element nodeRenderer
              { onlyRenderVisibleElements: props.onlyRenderVisibleElements
              , noPanClassName: props.noPanClassName
              , noDragClassName: props.noDragClassName
              , rfId: props.rfId
              , disableKeyboardA11y: props.disableKeyboardA11y
              , nodeExtent: props.nodeExtent
              , nodeTypes: props.nodeTypes
              , nodeClickDistance: Just props.nodeClickDistance
              , onNodeClick: props.onNodeClick
              , onNodeDoubleClick: props.onNodeDoubleClick
              , onNodeMouseEnter: props.onNodeMouseEnter
              , onNodeMouseMove: props.onNodeMouseMove
              , onNodeMouseLeave: props.onNodeMouseLeave
              , onNodeContextMenu: props.onNodeContextMenu
              }
          , div_ { className: "react-flow__viewport-portal" } []
          ]
      pure $ element flowRenderer
        { children: reactChildrenFromArray
            [ element viewport
                { children: reactChildrenFromArray viewportChildren }
            ]
        , isControlledViewport: isJust props.viewport
        -- Pane mouse / scroll
        , onPaneClick: props.onPaneClick
        , onPaneMouseEnter: props.onPaneMouseEnter
        , onPaneMouseMove: props.onPaneMouseMove
        , onPaneMouseLeave: props.onPaneMouseLeave
        , onPaneContextMenu: props.onPaneContextMenu
        , onPaneScroll: paneScrollAdapter props.onPaneScroll
        , paneClickDistance: props.paneClickDistance
        -- Selection
        , deleteKeyCode: props.deleteKeyCode
        , selectionKeyCode: props.selectionKeyCode
        , selectionOnDrag: props.selectionOnDrag
        , selectionMode: props.selectionMode
        , onSelectionStart: props.onSelectionStart
        , onSelectionEnd: props.onSelectionEnd
        , onSelectionContextMenu: props.onSelectionContextMenu
        , multiSelectionKeyCode: props.multiSelectionKeyCode
        , panActivationKeyCode: props.panActivationKeyCode
        , zoomActivationKeyCode: props.zoomActivationKeyCode
        , elementsSelectable: props.elementsSelectable
        -- Zoom / pan
        , zoomOnScroll: props.zoomOnScroll
        , zoomOnPinch: props.zoomOnPinch
        , panOnScroll: props.panOnScroll
        , panOnScrollSpeed: props.panOnScrollSpeed
        , panOnScrollMode: props.panOnScrollMode
        , zoomOnDoubleClick: props.zoomOnDoubleClick
        , panOnDrag: props.panOnDrag
        , autoPanOnSelection: props.autoPanOnSelection
        -- Viewport
        , defaultViewport: props.defaultViewport
        , translateExtent: props.translateExtent
        , minZoom: props.minZoom
        , maxZoom: props.maxZoom
        , preventScrolling: props.preventScrolling
        , noWheelClassName: props.noWheelClassName
        , noPanClassName: props.noPanClassName
        , disableKeyboardA11y: props.disableKeyboardA11y
        , onViewportChange: props.onViewportChange
        }

-- | `FlowRendererProps.onPaneScroll` is `Maybe (WheelEvent -> Effect Unit)`
-- | (pure-event handler) while `ReactFlowProps`/`GraphViewProps` mirror the
-- | TS `Maybe (Maybe WheelEvent -> Effect Unit)` shape (the inner `Maybe`
-- | covers the scroll-from-keyboard case where there is no wheel event).
-- | Adapt by lifting the event into `Just`.
paneScrollAdapter
  :: Maybe (Maybe WheelEvent -> Effect Unit)
  -> Maybe (WheelEvent -> Effect Unit)
paneScrollAdapter = case _ of
  Nothing -> Nothing
  Just f -> Just (\we -> f (Just we))
