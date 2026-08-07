-- | `<ReactFlow />`, crossing.
-- |
-- | This is the indivisible part of stage 1. The flow props are one record of
-- | 124 fields, and a JavaScript consumer who sets seven of them still gets a
-- | props object whose other 117 keys are absent — so the conversion has to
-- | name all 124 whatever any one fixture needs. There is no vertical slice
-- | here to take.
-- |
-- | ## What a prop can be
-- |
-- | **Converted** — 75: 72 of the 74 non-callback fields, plus the three
-- | change callbacks a driver wires (`onNodesChange`, `onEdgesChange`,
-- | `onConnect`).
-- |
-- | **Deferred, and therefore throwing at mount** — 49: the other 47 callbacks,
-- | plus `edgeTypes` and `connectionLineComponent`. A deferred prop that
-- | merely did nothing would be indistinguishable from a prop the consumer
-- | never set, which is the exact failure shape of the unrun `Effect` thunk
-- | that produced this whole effort: `setNodes(fn)` returned a thunk, nobody
-- | ran it, and every gate stayed green. The compiler does not help here —
-- | a record forces you to write *something* per field and `Nothing` compiles
-- | perfectly — so the guard is explicit, it is a table, and it runs before
-- | any conversion so the message names the offending prop rather than
-- | whatever happens to blow up first.
-- |
-- | `edgeTypes` and `connectionLineComponent` are deferred for the same reason
-- | `nodeTypes` is not: their values are the consumer's own components, and
-- | crossing them means an outbound converter for the props those components
-- | receive. `nodeTypes` has one (`Boundary.Elements.nodePropsOut`); edge
-- | props and connection-line props do not yet.
module Boundary.Flow
  ( JsAriaLabelConfig
  , JsDefaultEdgeOptions
  , JsFitViewOptions
  , JsFlowProps
  , JsProOptions
  , JsViewport
  , deferredProps
  , flowPropsIn
  , reactFlow
  ) where

import Prelude

import Boundary.Elements
  ( JsConnection
  , JsEdge
  , JsEdgeChange
  , JsNode
  , JsNodeChange
  , JsNodeProps
  , connectionOut
  , coordinateExtentIn
  , edgeChangeOut
  , edgeIn
  , keyCodeIn
  , nodeChangeOut
  , nodeIn
  , nodeOriginIn
  , nodeTypesIn
  , snapGridIn
  )
import Boundary.Enums
  ( colorModeIn
  , connectionLineTypeIn
  , connectionModeIn
  , handleTypeIn
  , interpolateModeIn
  , panOnScrollModeIn
  , panelPositionIn
  , selectionModeIn
  , zIndexModeIn
  )
import Boundary.Undefined (Undefinable, fromUndefinable, isDefined)
import Boundary.Untagged (asArray, asBoolean, asNumber, asString, typeName)
import Data.Array (find)
import Data.Array.NonEmpty (fromArray) as NEA
import Data.Int (round) as Int
import Data.Maybe (Maybe(..), fromMaybe, fromMaybe')
import Data.Newtype (wrap)
import Data.Number (fromString) as Number
import Data.String (Pattern(..), stripSuffix)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried (EffectFn1, runEffectFn1)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Foreign.Object (Object)
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (ReactChildren, reactComponentWithChildren)
import React.Container.ReactFlow (reactFlow) as PS
import React.Types.Component (ReactFlowProps)
import React.Types.Edges (DefaultEdgeOptions, ReconnectHandleType(..), Style)
import React.Types.General (FitViewOptions, OnEdgesChange, OnNodesChange, ProOptions)
import System.Constants (AriaLabelConfigOverride)
import System.Types.Connection (Padding(..), PaddingValue(..), Viewport)
import System.Types.PanZoom (PanOnDrag(..))
import System.XYHandle (OnConnect)
import Unsafe.Coerce (unsafeCoerce)

-- ────────────────────────────────────────────────────────────────────────
-- Sub-shapes
-- ────────────────────────────────────────────────────────────────────────

type JsViewport = { x :: Number, y :: Number, zoom :: Number }

type JsProOptions =
  { hideAttribution :: Boolean
  , account :: Undefinable String
  }

type JsFitViewOptions =
  { padding :: Undefinable Foreign
  , includeHiddenNodes :: Undefinable Boolean
  , minZoom :: Undefinable Number
  , maxZoom :: Undefinable Number
  , duration :: Undefinable Number
  , ease :: Undefinable (Number -> Number)
  , interpolate :: Undefinable String
  , nodes :: Undefinable (Array { id :: String })
  }

-- | The fields of `System.Types.Edge.DefaultEdgeOptions`. Upstream's type is
-- | `Edge` minus its identity fields, so it also carries the label options,
-- | `style`, `className`, `focusable`, `ariaRole` and `domAttributes` that
-- | PSFlow's `Edge` does not model yet; those are census rows, not boundary
-- | work, and a consumer setting one gets upstream's own silence.
type JsDefaultEdgeOptions =
  { animated :: Undefinable Boolean
  , hidden :: Undefinable Boolean
  , deletable :: Undefinable Boolean
  , selectable :: Undefinable Boolean
  , focusable :: Undefinable Boolean
  , data :: Undefinable Foreign
  , zIndex :: Undefinable Number
  , ariaLabel :: Undefinable String
  , interactionWidth :: Undefinable Number
  , reconnectable :: Undefinable Foreign
  }

-- | Upstream keys this record by dotted path — `'node.a11yDescription.default'`
-- | — and PureScript renamed them to camelCase identifiers. Nothing else on
-- | this surface renames a key that a consumer writes as a literal, so this is
-- | the one place where getting the crossing wrong is invisible: every key
-- | would simply miss, and every label would silently stay at its default.
type JsAriaLabelConfig =
  { "node.a11yDescription.default" :: Undefinable String
  , "node.a11yDescription.keyboardDisabled" :: Undefinable String
  , "node.a11yDescription.ariaLiveMessage" ::
      Undefinable ({ direction :: String, x :: Number, y :: Number } -> String)
  , "edge.a11yDescription.default" :: Undefinable String
  , "controls.ariaLabel" :: Undefinable String
  , "controls.zoomIn.ariaLabel" :: Undefinable String
  , "controls.zoomOut.ariaLabel" :: Undefinable String
  , "controls.fitView.ariaLabel" :: Undefinable String
  , "controls.interactive.ariaLabel" :: Undefinable String
  , "minimap.ariaLabel" :: Undefinable String
  , "handle.ariaLabel" :: Undefinable String
  }

-- ────────────────────────────────────────────────────────────────────────
-- The props record
--
-- One field per `React.Types.Component.ReactFlowProps` field, same order, so
-- the two read side by side. The deferred callbacks are typed `Foreign`
-- deliberately: nothing may call them, and giving them a callable type would
-- invite exactly that.
-- ────────────────────────────────────────────────────────────────────────

type JsFlowProps =
  { children :: ReactChildren JSX
  , nodes :: Undefinable (Array JsNode)
  , edges :: Undefinable (Array JsEdge)
  , defaultNodes :: Undefinable (Array JsNode)
  , defaultEdges :: Undefinable (Array JsEdge)
  , defaultEdgeOptions :: Undefinable JsDefaultEdgeOptions
  , onNodeClick :: Undefinable Foreign
  , onNodeDoubleClick :: Undefinable Foreign
  , onNodeMouseEnter :: Undefinable Foreign
  , onNodeMouseMove :: Undefinable Foreign
  , onNodeMouseLeave :: Undefinable Foreign
  , onNodeContextMenu :: Undefinable Foreign
  , onNodeDragStart :: Undefinable Foreign
  , onNodeDrag :: Undefinable Foreign
  , onNodeDragStop :: Undefinable Foreign
  , onEdgeClick :: Undefinable Foreign
  , onEdgeContextMenu :: Undefinable Foreign
  , onEdgeMouseEnter :: Undefinable Foreign
  , onEdgeMouseMove :: Undefinable Foreign
  , onEdgeMouseLeave :: Undefinable Foreign
  , onEdgeDoubleClick :: Undefinable Foreign
  , onReconnect :: Undefinable Foreign
  , onReconnectStart :: Undefinable Foreign
  , onReconnectEnd :: Undefinable Foreign
  , onNodesChange :: Undefinable (EffectFn1 (Array JsNodeChange) Unit)
  , onEdgesChange :: Undefinable (EffectFn1 (Array JsEdgeChange) Unit)
  , onNodesDelete :: Undefinable Foreign
  , onEdgesDelete :: Undefinable Foreign
  , onDelete :: Undefinable Foreign
  , onSelectionDragStart :: Undefinable Foreign
  , onSelectionDrag :: Undefinable Foreign
  , onSelectionDragStop :: Undefinable Foreign
  , onSelectionStart :: Undefinable Foreign
  , onSelectionEnd :: Undefinable Foreign
  , onSelectionContextMenu :: Undefinable Foreign
  , onSelectionChange :: Undefinable Foreign
  , onConnect :: Undefinable (EffectFn1 JsConnection Unit)
  , onConnectStart :: Undefinable Foreign
  , onConnectEnd :: Undefinable Foreign
  , onClickConnectStart :: Undefinable Foreign
  , onClickConnectEnd :: Undefinable Foreign
  , onInit :: Undefinable Foreign
  , onMove :: Undefinable Foreign
  , onMoveStart :: Undefinable Foreign
  , onMoveEnd :: Undefinable Foreign
  , onScroll :: Undefinable Foreign
  , onPaneScroll :: Undefinable Foreign
  , onPaneClick :: Undefinable Foreign
  , onPaneContextMenu :: Undefinable Foreign
  , onPaneMouseEnter :: Undefinable Foreign
  , onPaneMouseMove :: Undefinable Foreign
  , onPaneMouseLeave :: Undefinable Foreign
  , paneClickDistance :: Undefinable Number
  , nodeClickDistance :: Undefinable Number
  , onBeforeDelete :: Undefinable Foreign
  , isValidConnection :: Undefinable Foreign
  , onError :: Undefinable Foreign
  , nodeTypes :: Undefinable (Object (ReactComponent JsNodeProps))
  , edgeTypes :: Undefinable Foreign
  , connectionLineType :: Undefinable String
  , connectionLineStyle :: Undefinable Foreign
  , connectionLineComponent :: Undefinable Foreign
  , connectionLineContainerStyle :: Undefinable Foreign
  , connectionMode :: Undefinable String
  , deleteKeyCode :: Undefinable Foreign
  , selectionKeyCode :: Undefinable Foreign
  , selectionOnDrag :: Undefinable Boolean
  , selectionMode :: Undefinable String
  , panActivationKeyCode :: Undefinable Foreign
  , multiSelectionKeyCode :: Undefinable Foreign
  , zoomActivationKeyCode :: Undefinable Foreign
  , snapToGrid :: Undefinable Boolean
  , snapGrid :: Undefinable (Array Number)
  , onlyRenderVisibleElements :: Undefinable Boolean
  , nodesDraggable :: Undefinable Boolean
  , nodesConnectable :: Undefinable Boolean
  , nodesFocusable :: Undefinable Boolean
  , nodeDragThreshold :: Undefinable Number
  , nodeOrigin :: Undefinable (Array Number)
  , nodeExtent :: Undefinable (Array (Array Number))
  , autoPanOnNodeFocus :: Undefinable Boolean
  , autoPanOnNodeDrag :: Undefinable Boolean
  , noDragClassName :: Undefinable String
  , edgesFocusable :: Undefinable Boolean
  , edgesReconnectable :: Undefinable Boolean
  , reconnectRadius :: Undefinable Number
  , connectionDragThreshold :: Undefinable Number
  , elementsSelectable :: Undefinable Boolean
  , selectNodesOnDrag :: Undefinable Boolean
  , elevateNodesOnSelect :: Undefinable Boolean
  , elevateEdgesOnSelect :: Undefinable Boolean
  , panOnDrag :: Undefinable Foreign
  , minZoom :: Undefinable Number
  , maxZoom :: Undefinable Number
  , translateExtent :: Undefinable (Array (Array Number))
  , zoomOnScroll :: Undefinable Boolean
  , zoomOnPinch :: Undefinable Boolean
  , zoomOnDoubleClick :: Undefinable Boolean
  , panOnScroll :: Undefinable Boolean
  , panOnScrollSpeed :: Undefinable Number
  , panOnScrollMode :: Undefinable String
  , preventScrolling :: Undefinable Boolean
  , viewport :: Undefinable JsViewport
  , defaultViewport :: Undefinable JsViewport
  , onViewportChange :: Undefinable Foreign
  , fitView :: Undefinable Boolean
  , fitViewOptions :: Undefinable JsFitViewOptions
  , defaultMarkerColor :: Undefinable String
  , width :: Undefinable Number
  , height :: Undefinable Number
  , colorMode :: Undefinable String
  , attributionPosition :: Undefinable String
  , proOptions :: Undefinable JsProOptions
  , noWheelClassName :: Undefinable String
  , noPanClassName :: Undefinable String
  , disableKeyboardA11y :: Undefinable Boolean
  , ariaLabelConfig :: Undefinable JsAriaLabelConfig
  , autoPanOnConnect :: Undefinable Boolean
  , autoPanSpeed :: Undefinable Number
  , autoPanOnSelection :: Undefinable Boolean
  , connectOnClick :: Undefinable Boolean
  , connectionRadius :: Undefinable Number
  , debug :: Undefinable Boolean
  , zIndexMode :: Undefinable String
  }

-- ────────────────────────────────────────────────────────────────────────
-- The deferred-prop guard
-- ────────────────────────────────────────────────────────────────────────

type Deferred =
  { name :: String
  , stage :: Int
  , note :: String
  , supplied :: JsFlowProps -> Boolean
  }

callbackProp :: forall a. String -> (JsFlowProps -> Undefinable a) -> Deferred
callbackProp name get =
  { name
  , stage: 2
  , note: "the callback props"
  , supplied: \p -> isDefined (get p)
  }

componentProp :: forall a. String -> (JsFlowProps -> Undefinable a) -> Deferred
componentProp name get =
  { name
  , stage: 4
  , note: "the props that hand a consumer's own component its props record"
  , supplied: \p -> isDefined (get p)
  }

-- | Every prop that resolves on the JS surface but does not yet cross. Named
-- | rather than counted, because the count is the thing that drifts.
deferredProps :: Array Deferred
deferredProps =
  [ callbackProp "onNodeClick" _.onNodeClick
  , callbackProp "onNodeDoubleClick" _.onNodeDoubleClick
  , callbackProp "onNodeMouseEnter" _.onNodeMouseEnter
  , callbackProp "onNodeMouseMove" _.onNodeMouseMove
  , callbackProp "onNodeMouseLeave" _.onNodeMouseLeave
  , callbackProp "onNodeContextMenu" _.onNodeContextMenu
  , callbackProp "onNodeDragStart" _.onNodeDragStart
  , callbackProp "onNodeDrag" _.onNodeDrag
  , callbackProp "onNodeDragStop" _.onNodeDragStop
  , callbackProp "onEdgeClick" _.onEdgeClick
  , callbackProp "onEdgeContextMenu" _.onEdgeContextMenu
  , callbackProp "onEdgeMouseEnter" _.onEdgeMouseEnter
  , callbackProp "onEdgeMouseMove" _.onEdgeMouseMove
  , callbackProp "onEdgeMouseLeave" _.onEdgeMouseLeave
  , callbackProp "onEdgeDoubleClick" _.onEdgeDoubleClick
  , callbackProp "onReconnect" _.onReconnect
  , callbackProp "onReconnectStart" _.onReconnectStart
  , callbackProp "onReconnectEnd" _.onReconnectEnd
  , callbackProp "onNodesDelete" _.onNodesDelete
  , callbackProp "onEdgesDelete" _.onEdgesDelete
  , callbackProp "onDelete" _.onDelete
  , callbackProp "onSelectionDragStart" _.onSelectionDragStart
  , callbackProp "onSelectionDrag" _.onSelectionDrag
  , callbackProp "onSelectionDragStop" _.onSelectionDragStop
  , callbackProp "onSelectionStart" _.onSelectionStart
  , callbackProp "onSelectionEnd" _.onSelectionEnd
  , callbackProp "onSelectionContextMenu" _.onSelectionContextMenu
  , callbackProp "onSelectionChange" _.onSelectionChange
  , callbackProp "onConnectStart" _.onConnectStart
  , callbackProp "onConnectEnd" _.onConnectEnd
  , callbackProp "onClickConnectStart" _.onClickConnectStart
  , callbackProp "onClickConnectEnd" _.onClickConnectEnd
  , callbackProp "onInit" _.onInit
  , callbackProp "onMove" _.onMove
  , callbackProp "onMoveStart" _.onMoveStart
  , callbackProp "onMoveEnd" _.onMoveEnd
  , callbackProp "onScroll" _.onScroll
  , callbackProp "onPaneScroll" _.onPaneScroll
  , callbackProp "onPaneClick" _.onPaneClick
  , callbackProp "onPaneContextMenu" _.onPaneContextMenu
  , callbackProp "onPaneMouseEnter" _.onPaneMouseEnter
  , callbackProp "onPaneMouseMove" _.onPaneMouseMove
  , callbackProp "onPaneMouseLeave" _.onPaneMouseLeave
  , callbackProp "onBeforeDelete" _.onBeforeDelete
  , callbackProp "isValidConnection" _.isValidConnection
  , callbackProp "onError" _.onError
  , callbackProp "onViewportChange" _.onViewportChange
  , componentProp "edgeTypes" _.edgeTypes
  , componentProp "connectionLineComponent" _.connectionLineComponent
  ]

-- | Throws on the first deferred prop the consumer supplied, and otherwise
-- | hands the props straight back. Returning the record rather than `Unit` is
-- | what makes the guard unskippable: the conversion is written as
-- | `convertProps <<< guardDeferred`, so there is no way to reach a converted
-- | field without having gone through here first.
guardDeferred :: JsFlowProps -> JsFlowProps
guardDeferred p = case find (\d -> d.supplied p) deferredProps of
  Nothing -> p
  Just d ->
    unsafeThrow $
      "ps-flow: the `" <> d.name
        <> "` prop has not crossed the JavaScript boundary yet — it lands in "
        <> "boundary stage "
        <> show d.stage
        <> " ("
        <> d.note
        <> "). It is refused rather than ignored so that a prop ps-flow has "
        <> "not implemented fails loudly instead of looking like a prop you "
        <> "did not set."

-- ────────────────────────────────────────────────────────────────────────
-- The conversion
-- ────────────────────────────────────────────────────────────────────────

flowPropsIn :: JsFlowProps -> ReactFlowProps Foreign Foreign
flowPropsIn = convertProps <<< guardDeferred

convertProps :: JsFlowProps -> ReactFlowProps Foreign Foreign
convertProps p =
  { children: p.children
  , nodes: map (map nodeIn) (fromUndefinable p.nodes)
  , edges: map (map edgeIn) (fromUndefinable p.edges)
  , defaultNodes: map (map nodeIn) (fromUndefinable p.defaultNodes)
  , defaultEdges: map (map edgeIn) (fromUndefinable p.defaultEdges)
  , defaultEdgeOptions: map defaultEdgeOptionsIn (fromUndefinable p.defaultEdgeOptions)
  , onNodeClick: Nothing
  , onNodeDoubleClick: Nothing
  , onNodeMouseEnter: Nothing
  , onNodeMouseMove: Nothing
  , onNodeMouseLeave: Nothing
  , onNodeContextMenu: Nothing
  , onNodeDragStart: Nothing
  , onNodeDrag: Nothing
  , onNodeDragStop: Nothing
  , onEdgeClick: Nothing
  , onEdgeContextMenu: Nothing
  , onEdgeMouseEnter: Nothing
  , onEdgeMouseMove: Nothing
  , onEdgeMouseLeave: Nothing
  , onEdgeDoubleClick: Nothing
  , onReconnect: Nothing
  , onReconnectStart: Nothing
  , onReconnectEnd: Nothing
  , onNodesChange: map onNodesChangeIn (fromUndefinable p.onNodesChange)
  , onEdgesChange: map onEdgesChangeIn (fromUndefinable p.onEdgesChange)
  , onNodesDelete: Nothing
  , onEdgesDelete: Nothing
  , onDelete: Nothing
  , onSelectionDragStart: Nothing
  , onSelectionDrag: Nothing
  , onSelectionDragStop: Nothing
  , onSelectionStart: Nothing
  , onSelectionEnd: Nothing
  , onSelectionContextMenu: Nothing
  , onSelectionChange: Nothing
  , onConnect: map onConnectIn (fromUndefinable p.onConnect)
  , onConnectStart: Nothing
  , onConnectEnd: Nothing
  , onClickConnectStart: Nothing
  , onClickConnectEnd: Nothing
  , onInit: Nothing
  , onMove: Nothing
  , onMoveStart: Nothing
  , onMoveEnd: Nothing
  , onScroll: Nothing
  , onPaneScroll: Nothing
  , onPaneClick: Nothing
  , onPaneContextMenu: Nothing
  , onPaneMouseEnter: Nothing
  , onPaneMouseMove: Nothing
  , onPaneMouseLeave: Nothing
  , paneClickDistance: fromUndefinable p.paneClickDistance
  , nodeClickDistance: fromUndefinable p.nodeClickDistance
  , onBeforeDelete: Nothing
  , isValidConnection: Nothing
  , onError: Nothing
  , nodeTypes: map nodeTypesIn (fromUndefinable p.nodeTypes)
  , edgeTypes: Nothing
  , connectionLineType:
      map (connectionLineTypeIn "connectionLineType")
        (fromUndefinable p.connectionLineType)
  , connectionLineStyle: map asStyle (fromUndefinable p.connectionLineStyle)
  , connectionLineComponent: Nothing
  , connectionLineContainerStyle:
      map asStyle (fromUndefinable p.connectionLineContainerStyle)
  , connectionMode: map (connectionModeIn "connectionMode") (fromUndefinable p.connectionMode)
  , deleteKeyCode: keyCodeIn "deleteKeyCode" p.deleteKeyCode
  , selectionKeyCode: keyCodeIn "selectionKeyCode" p.selectionKeyCode
  , selectionOnDrag: fromUndefinable p.selectionOnDrag
  , selectionMode: map (selectionModeIn "selectionMode") (fromUndefinable p.selectionMode)
  , panActivationKeyCode: keyCodeIn "panActivationKeyCode" p.panActivationKeyCode
  , multiSelectionKeyCode: keyCodeIn "multiSelectionKeyCode" p.multiSelectionKeyCode
  , zoomActivationKeyCode: keyCodeIn "zoomActivationKeyCode" p.zoomActivationKeyCode
  , snapToGrid: fromUndefinable p.snapToGrid
  , snapGrid: map (snapGridIn "snapGrid") (fromUndefinable p.snapGrid)
  , onlyRenderVisibleElements: fromUndefinable p.onlyRenderVisibleElements
  , nodesDraggable: fromUndefinable p.nodesDraggable
  , nodesConnectable: fromUndefinable p.nodesConnectable
  , nodesFocusable: fromUndefinable p.nodesFocusable
  , nodeDragThreshold: fromUndefinable p.nodeDragThreshold
  , nodeOrigin: map (nodeOriginIn "nodeOrigin") (fromUndefinable p.nodeOrigin)
  , nodeExtent: map (coordinateExtentIn "nodeExtent") (fromUndefinable p.nodeExtent)
  , autoPanOnNodeFocus: fromUndefinable p.autoPanOnNodeFocus
  , autoPanOnNodeDrag: fromUndefinable p.autoPanOnNodeDrag
  , noDragClassName: fromUndefinable p.noDragClassName
  , edgesFocusable: fromUndefinable p.edgesFocusable
  , edgesReconnectable: fromUndefinable p.edgesReconnectable
  , reconnectRadius: fromUndefinable p.reconnectRadius
  , connectionDragThreshold: fromUndefinable p.connectionDragThreshold
  , elementsSelectable: fromUndefinable p.elementsSelectable
  , selectNodesOnDrag: fromUndefinable p.selectNodesOnDrag
  , elevateNodesOnSelect: fromUndefinable p.elevateNodesOnSelect
  , elevateEdgesOnSelect: fromUndefinable p.elevateEdgesOnSelect
  , panOnDrag: map panOnDragIn (fromUndefinable p.panOnDrag)
  , minZoom: fromUndefinable p.minZoom
  , maxZoom: fromUndefinable p.maxZoom
  , translateExtent:
      map (coordinateExtentIn "translateExtent") (fromUndefinable p.translateExtent)
  , zoomOnScroll: fromUndefinable p.zoomOnScroll
  , zoomOnPinch: fromUndefinable p.zoomOnPinch
  , zoomOnDoubleClick: fromUndefinable p.zoomOnDoubleClick
  , panOnScroll: fromUndefinable p.panOnScroll
  , panOnScrollSpeed: fromUndefinable p.panOnScrollSpeed
  , panOnScrollMode:
      map (panOnScrollModeIn "panOnScrollMode") (fromUndefinable p.panOnScrollMode)
  , preventScrolling: fromUndefinable p.preventScrolling
  , viewport: viewportIn (fromUndefinable p.viewport)
  , defaultViewport: viewportIn (fromUndefinable p.defaultViewport)
  , onViewportChange: Nothing
  , fitView: fromUndefinable p.fitView
  , fitViewOptions: map fitViewOptionsIn (fromUndefinable p.fitViewOptions)
  , defaultMarkerColor: fromUndefinable p.defaultMarkerColor
  , width: fromUndefinable p.width
  , height: fromUndefinable p.height
  , colorMode: map (colorModeIn "colorMode") (fromUndefinable p.colorMode)
  , attributionPosition:
      map (panelPositionIn "attributionPosition") (fromUndefinable p.attributionPosition)
  , proOptions: map proOptionsIn (fromUndefinable p.proOptions)
  , noWheelClassName: fromUndefinable p.noWheelClassName
  , noPanClassName: fromUndefinable p.noPanClassName
  , disableKeyboardA11y: fromUndefinable p.disableKeyboardA11y
  , ariaLabelConfig: map ariaLabelConfigIn (fromUndefinable p.ariaLabelConfig)
  , autoPanOnConnect: fromUndefinable p.autoPanOnConnect
  , autoPanSpeed: fromUndefinable p.autoPanSpeed
  , autoPanOnSelection: fromUndefinable p.autoPanOnSelection
  , connectOnClick: fromUndefinable p.connectOnClick
  , connectionRadius: fromUndefinable p.connectionRadius
  , debug: fromUndefinable p.debug
  , zIndexMode: map (zIndexModeIn "zIndexMode") (fromUndefinable p.zIndexMode)
  }

-- `Viewport` is `{ x, y, zoom }` on both sides, so this is the identity — but
-- writing it out keeps the drift gate able to see the field.
viewportIn :: Maybe JsViewport -> Maybe Viewport
viewportIn = map \v -> { x: v.x, y: v.y, zoom: v.zoom }

asStyle :: Foreign -> Style
asStyle = unsafeCoerce

onNodesChangeIn :: EffectFn1 (Array JsNodeChange) Unit -> OnNodesChange Foreign
onNodesChangeIn f = \changes -> runEffectFn1 f (map nodeChangeOut changes)

onEdgesChangeIn :: EffectFn1 (Array JsEdgeChange) Unit -> OnEdgesChange Foreign
onEdgesChangeIn f = \changes -> runEffectFn1 f (map edgeChangeOut changes)

onConnectIn :: EffectFn1 JsConnection Unit -> OnConnect
onConnectIn f = \connection -> runEffectFn1 f (connectionOut connection)

defaultEdgeOptionsIn :: JsDefaultEdgeOptions -> DefaultEdgeOptions Foreign
defaultEdgeOptionsIn o =
  { animated: fromUndefinable o.animated
  , hidden: fromUndefinable o.hidden
  , deletable: fromUndefinable o.deletable
  , selectable: fromUndefinable o.selectable
  , focusable: fromUndefinable o.focusable
  , data: fromUndefinable o.data
  , zIndex: map Int.round (fromUndefinable o.zIndex)
  , ariaLabel: fromUndefinable o.ariaLabel
  , interactionWidth: fromUndefinable o.interactionWidth
  , reconnectable: fromUndefinable o.reconnectable >>= reconnectableIn
  }

-- | `boolean | HandleType`. `false` is "not reconnectable", which PureScript
-- | spells as the absence of the field rather than a third constructor.
reconnectableIn :: Foreign -> Maybe ReconnectHandleType
reconnectableIn raw = case asBoolean raw of
  Just true -> Just ReconnectAny
  Just false -> Nothing
  Nothing -> case asString raw of
    Just s -> Just (ReconnectOnly (handleTypeIn "defaultEdgeOptions.reconnectable" s))
    Nothing ->
      unsafeThrow $
        "ps-flow: `defaultEdgeOptions.reconnectable` must be a boolean, "
          <> "\"source\" or \"target\", got "
          <> typeName raw
          <> "."

proOptionsIn :: JsProOptions -> ProOptions
proOptionsIn o =
  { hideAttribution: o.hideAttribution
  , account: fromUndefinable o.account
  }

fitViewOptionsIn :: JsFitViewOptions -> FitViewOptions
fitViewOptionsIn o =
  { padding: map (paddingIn "fitViewOptions.padding") (fromUndefinable o.padding)
  , includeHiddenNodes: fromMaybe false (fromUndefinable o.includeHiddenNodes)
  , minZoom: fromUndefinable o.minZoom
  , maxZoom: fromUndefinable o.maxZoom
  , duration: map Int.round (fromUndefinable o.duration)
  , ease: fromUndefinable o.ease
  , interpolate:
      map (interpolateModeIn "fitViewOptions.interpolate") (fromUndefinable o.interpolate)
  , nodes: map (map \n -> { id: wrap n.id }) (fromUndefinable o.nodes)
  }

-- | Upstream's `Padding` is `` `${number}px` | `${number}%` | number `` or a
-- | record of those per side. A bare number is a **ratio** of the viewport,
-- | which is why upstream's default padding of `0.1` means ten percent.
paddingIn :: String -> Foreign -> Padding
paddingIn field raw = case paddingValueIn field raw of
  Just v -> UniformPadding v
  Nothing -> DirectionalPadding
    { top: side "top"
    , right: side "right"
    , bottom: side "bottom"
    , left: side "left"
    , x: side "x"
    , y: side "y"
    }
  where
  sides :: { top :: Undefinable Foreign
           , right :: Undefinable Foreign
           , bottom :: Undefinable Foreign
           , left :: Undefinable Foreign
           , x :: Undefinable Foreign
           , y :: Undefinable Foreign
           }
  sides = unsafeCoerce raw

  side :: String -> Maybe PaddingValue
  side name = fromUndefinable (readSide name) >>= \v ->
    case paddingValueIn (field <> "." <> name) v of
      Just pv -> Just pv
      Nothing ->
        unsafeThrow $
          "ps-flow: `" <> field <> "." <> name
            <> "` must be a number, \"<n>px\" or \"<n>%\"."

  readSide :: String -> Undefinable Foreign
  readSide = case _ of
    "top" -> sides.top
    "right" -> sides.right
    "bottom" -> sides.bottom
    "left" -> sides.left
    "x" -> sides.x
    _ -> sides.y

paddingValueIn :: String -> Foreign -> Maybe PaddingValue
paddingValueIn field raw = case asNumber raw of
  Just n -> Just (RatioPadding n)
  Nothing -> case asString raw of
    Just s -> Just (paddingStringIn field s)
    Nothing -> Nothing

paddingStringIn :: String -> String -> PaddingValue
paddingStringIn field s =
  case stripSuffix (Pattern "px") s of
    Just n -> PxPadding (readNumber n)
    Nothing -> case stripSuffix (Pattern "%") s of
      Just n -> PctPadding (readNumber n)
      Nothing -> badPadding field s
  where
  -- `fromMaybe'` and not `fromMaybe`: PureScript is strict, so a `where`
  -- binding that takes no argument is evaluated on entry, and a bare
  -- `bad = unsafeThrow …` would throw on every well-formed padding.
  readNumber n = fromMaybe' (\_ -> badPadding field s) (Number.fromString n)

badPadding :: forall a. String -> String -> a
badPadding field s =
  unsafeThrow $
    "ps-flow: `" <> field <> "` must be a number, \"<n>px\" or \"<n>%\", got "
      <> show s
      <> "."

-- | `boolean | number[]` — `true` pans on every button, an array names the
-- | mouse buttons that pan, and an empty array names none, which is `false`.
panOnDragIn :: Foreign -> PanOnDrag
panOnDragIn raw = case asBoolean raw of
  Just true -> PanAlways
  Just false -> NoPan
  Nothing -> case asArray raw of
    Just buttons ->
      case NEA.fromArray (map readButton buttons) of
        Just nea -> PanOnButtons nea
        Nothing -> NoPan
    Nothing ->
      unsafeThrow $
        "ps-flow: `panOnDrag` must be a boolean or an array of mouse-button "
          <> "numbers, got "
          <> typeName raw
          <> "."
  where
  readButton b = case asNumber b of
    Just n -> Int.round n
    Nothing ->
      unsafeThrow $
        "ps-flow: every entry of `panOnDrag` must be a mouse-button number, got "
          <> typeName b
          <> "."

ariaLabelConfigIn :: JsAriaLabelConfig -> AriaLabelConfigOverride
ariaLabelConfigIn c =
  { nodeA11yDescriptionDefault: fromUndefinable c."node.a11yDescription.default"
  , nodeA11yDescriptionKeyboardDisabled:
      fromUndefinable c."node.a11yDescription.keyboardDisabled"
  , nodeA11yDescriptionAriaLiveMessage:
      fromUndefinable c."node.a11yDescription.ariaLiveMessage"
  , edgeA11yDescriptionDefault: fromUndefinable c."edge.a11yDescription.default"
  , controlsAriaLabel: fromUndefinable c."controls.ariaLabel"
  , controlsZoomInAriaLabel: fromUndefinable c."controls.zoomIn.ariaLabel"
  , controlsZoomOutAriaLabel: fromUndefinable c."controls.zoomOut.ariaLabel"
  , controlsFitViewAriaLabel: fromUndefinable c."controls.fitView.ariaLabel"
  , controlsInteractiveAriaLabel: fromUndefinable c."controls.interactive.ariaLabel"
  , minimapAriaLabel: fromUndefinable c."minimap.ariaLabel"
  , handleAriaLabel: fromUndefinable c."handle.ariaLabel"
  }

-- ────────────────────────────────────────────────────────────────────────
-- The component
-- ────────────────────────────────────────────────────────────────────────

-- | What `index.js` exports as `ReactFlow`. A JavaScript consumer's props go
-- | in; the PureScript component built in `React.Container.ReactFlow` renders.
reactFlow :: ReactComponent JsFlowProps
reactFlow =
  unsafePerformEffect $ reactComponentWithChildren "ReactFlow"
    \(props :: JsFlowProps) -> pure (element PS.reactFlow (flowPropsIn props))
