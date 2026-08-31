-- | `<reactFlow />` — the public top-level component. Mirrors
-- | `xyflow-main/packages/react/src/container/ReactFlow/index.tsx`.
-- |
-- | Structure:
-- |
-- |   ```
-- |   <div className="react-flow ..." onScroll={wrapperOnScroll}>
-- |     <Wrapper>
-- |       <StoreUpdater />
-- |       <GraphView ... />
-- |       {children}
-- |       <SelectionListener />
-- |       <Attribution />
-- |       <A11yDescriptions />
-- |     </Wrapper>
-- |   </div>
-- |   ```
-- |
-- | **Defaults.** TS scatters `= defaultValue` across the destructuring
-- | clause; PS collects them in a `resolved` record that's then spread
-- | into the GraphView and provider call sites. The defaults match
-- | `xyflow-main/.../ReactFlow/index.tsx` lines 64-152 exactly.
-- |
-- | **Mac-aware default key codes.** `multiSelectionKeyCode` and
-- | `zoomActivationKeyCode` default to `"Meta"` on macOS (`Cmd`-key) and
-- | `"Control"` elsewhere. Detection runs once at module load via
-- | `unsafePerformEffect isMacOs`; `navigator.userAgent` doesn't change
-- | between page loads, so the constant is sound.
-- |
-- | **`innerRef`.** TS exports `<ReactFlow>` wrapped in `fixedForwardRef`
-- | so consumers can grab the outer-div ref. PS reaches the same place
-- | through a props field: `props.innerRef` goes on the outer `<div>`,
-- | and `Boundary.Flow` publishes it to JavaScript under React's own
-- | spelling. `PanelProps.innerRef` says why the field cannot be called
-- | `ref`.
-- |
-- | This is one component, matching TS. It was two — `reactFlow` and a
-- | `forwardRef`-wrapped `reactFlowWithRef` — because `react-basic-hooks`
-- | cannot express "one component that optionally accepts a ref" as a
-- | single value, and the split cost more than it saved: `<ReactFlow>`
-- | dropped any `ref` handed to it without a word, and the component that
-- | did take one nested every prop a level down and dropped its JSX
-- | children, so it substituted for neither TS's component nor this one.
-- | Making the ref a prop removes the thing `forwardRef` was needed for
-- | here, and with it the second component
-- | ([#27](https://github.com/jonbae/PSFlow/issues/27)).
-- |
-- | **`wrapperOnScroll`.** The outer div installs a scroll handler that
-- | immediately resets the wrapper's scroll position to `(0, 0)`. Without
-- | this, browser tab-focus logic can scroll the wrapper when a focused
-- | node is offscreen — leaving the canvas misaligned with its
-- | transform. The user can observe the scroll via the optional
-- | `onScroll :: Maybe (Effect Unit)` prop.
-- |
-- | **Skipped from TS.** The `id` prop: not present on `ReactFlowProps`
-- | in the PS port; `rfId` is hard-coded to `"1"`. Add the field and
-- | `fromMaybe` when a use case appears.
module React.Container.ReactFlow
  ( reactFlow
  ) where

import Prelude

import Control.Alt ((<|>))
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (reactChildrenFromArray, reactChildrenToArray, reactComponentWithChildren)
import React.Basic.Hooks as React
import React.Container.A11yDescriptions (a11yDescriptions)
import React.Container.Attribution (attribution)
import React.Container.GraphView (graphView)
import React.Container.InitValues (defaultNodeOrigin, defaultViewport) as Init
import React.Container.Wrapper (wrapper)
import React.FFI.DOM (div_, scrollResetHandler)
import React.Hook.ColorModeClass (useColorModeClass)
import React.Provider.SelectionListener (selectionListener)
import React.Provider.StoreUpdater (storeUpdater)
import React.Types.Component (ReactFlowProps)
import System.Constants (infiniteExtent)
import System.Types.Connection
  ( ColorModeClass(..)
  , KeyCode(..)
  , PanOnScrollMode(..)
  , SelectionMode(..)
  )
import System.Types.Edge (ConnectionLineType(..))
import System.Types.PanZoom (PanOnDrag(..))
import System.Utils.General (isMacOs)
import Unsafe.Coerce (unsafeCoerce)

-- | Stable outer-div style. Mirrors the inline `wrapperStyle` constant
-- | in TS.
wrapperStyle :: Foreign
wrapperStyle = (unsafeCoerce :: forall r. Record r -> Foreign)
  { width: "100%"
  , height: "100%"
  , overflow: "hidden"
  , position: "relative"
  , zIndex: 0
  }

mergeStyle :: Maybe Foreign -> Foreign
mergeStyle = case _ of
  Just userStyle -> mergeStyleImpl userStyle wrapperStyle
  Nothing -> wrapperStyle

-- | FFI: shallow-merge two style objects (TS `{ ...style, ...wrapperStyle }`).
foreign import mergeStyleImpl :: Foreign -> Foreign -> Foreign

-- | Map `Maybe ColorModeClass` back to its className string. `Nothing`
-- | (system mode while the media query hasn't resolved) renders no
-- | extra class, matching TS.
colorModeClass :: Maybe ColorModeClass -> String
colorModeClass = case _ of
  Just Light -> "light"
  Just Dark -> "dark"
  Nothing -> ""

-- | Build the outer-div className with optional user class slot.
buildOuterClass :: String -> Maybe String -> String
buildOuterClass cmc userClass =
  let
    parts =
      [ "react-flow"
      , fromMaybe "" userClass
      , cmc
      ]
    -- Trim empty entries and join with single spaces (mirrors `cc(...)`).
    nonEmpty = filterEmpty parts
  in
    joinWithSpace nonEmpty
  where
  filterEmpty = filterEmptyImpl
  joinWithSpace = joinWithSpaceImpl

foreign import filterEmptyImpl :: Array String -> Array String
foreign import joinWithSpaceImpl :: Array String -> String

-- | `isMacOs` is `Effect Boolean` because it reads `navigator.userAgent`,
-- | but the value is stable for the page lifetime. We cache it once at
-- | module load so default key codes can be a pure constant.
isMacOsCached :: Boolean
isMacOsCached = unsafePerformEffect isMacOs

defaultMultiSelKey :: KeyCode
defaultMultiSelKey =
  SingleKey (if isMacOsCached then "Meta" else "Control")

-- ────────────────────────────────────────────────────────────────────────
-- The component
--
-- Holds the entire render body, and takes the user's `ReactFlowProps`
-- flat. There was a `reactFlowInner` under here holding the same body,
-- nesting these props under an `rfProps` field and carrying a separate
-- `Maybe` ref slot beside them. It existed to be shared by two public
-- components; #27 leaves one, so the nesting had nothing left to serve.
-- ────────────────────────────────────────────────────────────────────────

reactFlow :: forall n e. ReactComponent (ReactFlowProps n e)
reactFlow =
  unsafePerformEffect $ reactComponentWithChildren "ReactFlow"
    \(props :: ReactFlowProps n e) -> React.do
      colorModeCls <- useColorModeClass props.colorMode
      let
        rfId = "1"
        -- Resolved defaults — matches TS destructure-with-defaults.
        connectionLineType = fromMaybe BezierLine props.connectionLineType
        deleteKeyCode = props.deleteKeyCode <|> Just (SingleKey "Backspace")
        selectionKeyCode = props.selectionKeyCode <|> Just (SingleKey "Shift")
        selectionOnDrag = fromMaybe false props.selectionOnDrag
        selectionMode = fromMaybe Full props.selectionMode
        panActivationKeyCode = props.panActivationKeyCode <|> Just (SingleKey "Space")
        multiSelectionKeyCode = props.multiSelectionKeyCode <|> Just defaultMultiSelKey
        zoomActivationKeyCode = props.zoomActivationKeyCode <|> Just defaultMultiSelKey
        onlyRenderVisibleElements = fromMaybe false props.onlyRenderVisibleElements
        nodeOrigin = fromMaybe Init.defaultNodeOrigin props.nodeOrigin
        elementsSelectable = fromMaybe true props.elementsSelectable
        defaultViewport = fromMaybe Init.defaultViewport props.defaultViewport
        minZoom = fromMaybe 0.5 props.minZoom
        maxZoom = fromMaybe 2.0 props.maxZoom
        translateExtent = fromMaybe infiniteExtent props.translateExtent
        preventScrolling = fromMaybe true props.preventScrolling
        defaultMarkerColor = fromMaybe "#b1b1b7" props.defaultMarkerColor
        zoomOnScroll = fromMaybe true props.zoomOnScroll
        zoomOnPinch = fromMaybe true props.zoomOnPinch
        panOnScroll = fromMaybe false props.panOnScroll
        panOnScrollSpeed = fromMaybe 0.5 props.panOnScrollSpeed
        panOnScrollMode = fromMaybe Free props.panOnScrollMode
        zoomOnDoubleClick = fromMaybe true props.zoomOnDoubleClick
        panOnDrag = fromMaybe PanAlways props.panOnDrag
        paneClickDistance = fromMaybe 1.0 props.paneClickDistance
        nodeClickDistance = fromMaybe 0.0 props.nodeClickDistance
        reconnectRadius = props.reconnectRadius <|> Just 10.0
        noDragClassName = fromMaybe "nodrag" props.noDragClassName
        noWheelClassName = fromMaybe "nowheel" props.noWheelClassName
        noPanClassName = fromMaybe "nopan" props.noPanClassName
        disableKeyboardA11y = fromMaybe false props.disableKeyboardA11y
        autoPanOnSelection = fromMaybe true props.autoPanOnSelection

        outerClass = buildOuterClass (colorModeClass colorModeCls) Nothing

        graphViewEl :: JSX
        graphViewEl = element graphView
          { rfId
          , connectionLineType
          , onlyRenderVisibleElements
          , translateExtent
          , minZoom
          , maxZoom
          , defaultMarkerColor
          , noDragClassName
          , noWheelClassName
          , noPanClassName
          , defaultViewport
          , disableKeyboardA11y
          , paneClickDistance
          , nodeClickDistance
          , selectionMode
          , selectionOnDrag
          , panOnDrag
          , panOnScroll
          , panOnScrollSpeed
          , panOnScrollMode
          , zoomOnScroll
          , zoomOnPinch
          , zoomOnDoubleClick
          , preventScrolling
          , elementsSelectable
          , autoPanOnSelection
          , selectionKeyCode
          , deleteKeyCode
          , multiSelectionKeyCode
          , panActivationKeyCode
          , zoomActivationKeyCode
          , onInit: props.onInit
          , viewport: props.viewport
          , onViewportChange: props.onViewportChange
          , nodeTypes: props.nodeTypes
          , edgeTypes: props.edgeTypes
          , nodeExtent: props.nodeExtent
          , connectionLineStyle: props.connectionLineStyle
          , connectionLineComponent: props.connectionLineComponent
          , connectionLineContainerStyle: props.connectionLineContainerStyle
          , onNodeClick: props.onNodeClick
          , onNodeDoubleClick: props.onNodeDoubleClick
          , onNodeMouseEnter: props.onNodeMouseEnter
          , onNodeMouseMove: props.onNodeMouseMove
          , onNodeMouseLeave: props.onNodeMouseLeave
          , onNodeContextMenu: props.onNodeContextMenu
          , onEdgeClick: props.onEdgeClick
          , onEdgeDoubleClick: props.onEdgeDoubleClick
          , onEdgeContextMenu: props.onEdgeContextMenu
          , onEdgeMouseEnter: props.onEdgeMouseEnter
          , onEdgeMouseMove: props.onEdgeMouseMove
          , onEdgeMouseLeave: props.onEdgeMouseLeave
          , onReconnect: props.onReconnect
          , onReconnectStart: props.onReconnectStart
          , onReconnectEnd: props.onReconnectEnd
          , reconnectRadius
          , onSelectionContextMenu: props.onSelectionContextMenu
          , onSelectionStart: props.onSelectionStart
          , onSelectionEnd: props.onSelectionEnd
          , onPaneClick: props.onPaneClick
          , onPaneMouseEnter: props.onPaneMouseEnter
          , onPaneMouseMove: props.onPaneMouseMove
          , onPaneMouseLeave: props.onPaneMouseLeave
          , onPaneContextMenu: props.onPaneContextMenu
          , onPaneScroll: props.onPaneScroll
          }

        storeUpdaterEl :: JSX
        storeUpdaterEl = element storeUpdater
          { rfId
          , nodes: props.nodes
          , edges: props.edges
          , defaultNodes: props.defaultNodes
          , defaultEdges: props.defaultEdges
          , onConnect: props.onConnect
          , onConnectStart: props.onConnectStart
          , onConnectEnd: props.onConnectEnd
          , onClickConnectStart: props.onClickConnectStart
          , onClickConnectEnd: props.onClickConnectEnd
          , nodesDraggable: props.nodesDraggable
          , autoPanOnNodeFocus: props.autoPanOnNodeFocus
          , nodesConnectable: props.nodesConnectable
          , nodesFocusable: props.nodesFocusable
          , edgesFocusable: props.edgesFocusable
          , edgesReconnectable: props.edgesReconnectable
          , elevateNodesOnSelect: props.elevateNodesOnSelect
          , elevateEdgesOnSelect: props.elevateEdgesOnSelect
          , minZoom: props.minZoom
          , maxZoom: props.maxZoom
          , nodeExtent: props.nodeExtent
          , onNodesChange: props.onNodesChange
          , onEdgesChange: props.onEdgesChange
          , elementsSelectable: props.elementsSelectable
          , connectionMode: props.connectionMode
          , snapGrid: props.snapGrid
          , snapToGrid: props.snapToGrid
          , translateExtent: props.translateExtent
          , connectOnClick: props.connectOnClick
          , defaultEdgeOptions: props.defaultEdgeOptions
          , fitView: props.fitView
          , fitViewOptions: props.fitViewOptions
          , onNodesDelete: props.onNodesDelete
          , onEdgesDelete: props.onEdgesDelete
          , onDelete: props.onDelete
          , onNodeDrag: props.onNodeDrag
          , onNodeDragStart: props.onNodeDragStart
          , onNodeDragStop: props.onNodeDragStop
          , onSelectionDrag: props.onSelectionDrag
          , onSelectionDragStart: props.onSelectionDragStart
          , onSelectionDragStop: props.onSelectionDragStop
          , onMoveStart: props.onMoveStart
          , onMove: props.onMove
          , onMoveEnd: props.onMoveEnd
          , noPanClassName: props.noPanClassName
          , nodeOrigin: Just nodeOrigin
          , autoPanOnConnect: props.autoPanOnConnect
          , autoPanOnNodeDrag: props.autoPanOnNodeDrag
          , onError: props.onError
          , connectionRadius: props.connectionRadius
          , isValidConnection: props.isValidConnection
          , selectNodesOnDrag: props.selectNodesOnDrag
          , nodeDragThreshold: props.nodeDragThreshold
          , connectionDragThreshold: props.connectionDragThreshold
          , onBeforeDelete: props.onBeforeDelete
          , debug: props.debug
          , autoPanSpeed: props.autoPanSpeed
          , ariaLabelConfig: props.ariaLabelConfig
          , zIndexMode: props.zIndexMode
          }

        innerChildren :: Array JSX
        innerChildren =
          [ storeUpdaterEl
          , graphViewEl
          ]
          <> reactChildrenToArray props.children
          <>
          [ element selectionListener
              { onSelectionChange: props.onSelectionChange }
          , element attribution
              { proOptions: props.proOptions
              , position: props.attributionPosition
              }
          , element a11yDescriptions
              { rfId, disableKeyboardA11y }
          ]

        wrapperEl :: JSX
        wrapperEl = element wrapper
          { initialNodes: props.nodes
          , initialEdges: props.edges
          , defaultNodes: props.defaultNodes
          , defaultEdges: props.defaultEdges
          , initialWidth: props.width
          , initialHeight: props.height
          , fitView: props.fitView
          , initialFitViewOptions: props.fitViewOptions
          , initialMinZoom: props.minZoom
          , initialMaxZoom: props.maxZoom
          , nodeOrigin: Just nodeOrigin
          , nodeExtent: props.nodeExtent
          , zIndexMode: props.zIndexMode
          , children: reactChildrenFromArray innerChildren
          }

        wrapperOnScroll = scrollResetHandler (fromMaybe (pure unit) props.onScroll)
      pure $
        div_
          { "data-testid": "rf__wrapper"
          , style: mergeStyle Nothing
          , className: outerClass
          , role: "application"
          -- Straight through, `null` included: React reads a null ref as no
          -- ref, which is exactly what the caller who passed none meant.
          , ref: props.innerRef
          , onScroll: wrapperOnScroll
          }
          [ wrapperEl ]
