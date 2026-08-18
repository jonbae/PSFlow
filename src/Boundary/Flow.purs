-- | `<ReactFlow />`, crossing.
-- |
-- | This is the indivisible part of the boundary. The flow props are one record
-- | of 124 fields, and a JavaScript consumer who sets seven of them still gets a
-- | props object whose other 117 keys are absent — so the conversion has to
-- | name all 124 whatever any one fixture needs. There is no vertical slice
-- | here to take.
-- |
-- | ## What a prop can be
-- |
-- | **Converted** — 121: 72 of the 74 non-callback fields, plus all 49 callback
-- | props bar `onInit`. Three of the callbacks crossed in stage 1 with the
-- | component itself (`onNodesChange`, `onEdgesChange`, `onConnect`); the other
-- | 46 crossed in stage 2, and their converters live in `Boundary.Callbacks`.
-- |
-- | **Deferred, and therefore throwing at mount** — 3: `onInit`, `edgeTypes`
-- | and `connectionLineComponent`. A deferred prop that merely did nothing
-- | would be indistinguishable from a prop the consumer never set, which is the
-- | exact failure shape of the unrun `Effect` thunk that produced this whole
-- | effort: `setNodes(fn)` returned a thunk, nobody ran it, and every gate
-- | stayed green. The compiler does not help here — a record forces you to
-- | write *something* per field and `Nothing` compiles perfectly — so the guard
-- | is explicit, it is a table, and it runs before any conversion so the message
-- | names the offending prop rather than whatever happens to blow up first.
-- |
-- | The three are deferred for one shared reason: **their values have not
-- | crossed**. `edgeTypes` and `connectionLineComponent` hold the consumer's own
-- | components, so crossing them means an outbound converter for the props those
-- | components receive — `nodeTypes` has one
-- | (`Boundary.Elements.nodePropsOut`), edge props and connection-line props do
-- | not. `onInit` is handed the imperative `ReactFlowInstance`, which is
-- | boundary stage 3's whole subject.
module Boundary.Flow
  ( JsAriaLabelConfig
  , JsDefaultEdgeOptions
  , JsFitViewOptions
  , JsFlowProps
  , JsProOptions
  , fitViewOptionsIn
  , reactFlow
  ) where

import Prelude

import Boundary.Callbacks
  ( JsEdgeMouseHandler
  , JsIsValidConnection
  , JsMouseEventHandler
  , JsNodeMouseHandler
  , JsOnBeforeDelete
  , JsOnConnect
  , JsOnConnectEnd
  , JsOnConnectStart
  , JsOnDelete
  , JsOnEdgesChange
  , JsOnEdgesDelete
  , JsOnError
  , JsOnMove
  , JsOnNodeDrag
  , JsOnNodesChange
  , JsOnNodesDelete
  , JsOnPaneScroll
  , JsOnReconnect
  , JsOnReconnectEnd
  , JsOnReconnectStart
  , JsOnScroll
  , JsOnSelectionChange
  , JsOnViewportChange
  , JsSelectionDragHandler
  , edgeMouseHandlerIn
  , isValidConnectionIn
  , mouseEventHandlerIn
  , nodeMouseHandlerIn
  , onBeforeDeleteIn
  , onConnectEndIn
  , onConnectIn
  , onConnectStartIn
  , onDeleteIn
  , onEdgesChangeIn
  , onEdgesDeleteIn
  , onErrorIn
  , onMoveIn
  , onNodeDragIn
  , onNodesChangeIn
  , onNodesDeleteIn
  , onPaneScrollIn
  , onReconnectEndIn
  , onReconnectIn
  , onReconnectStartIn
  , onScrollIn
  , onSelectionChangeIn
  , onViewportChangeIn
  , selectionDragHandlerIn
  )
import Boundary.Elements
  ( JsEdge
  , JsNode
  , JsNodeProps
  , JsViewport
  , asCssStyle
  , coordinateExtentIn
  , edgeIn
  , keyCodeIn
  , nodeIn
  , nodeOriginIn
  , nodeTypesIn
  , snapGridIn
  , viewportIn
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
import Boundary.Refusal (Refusal, componentProp, deferredMessage, instanceProp, refuseFirst)
import Boundary.Undefined (Undefinable, fromUndefinable, isDefined)
import Boundary.Untagged (asArray, asBoolean, asNumber, asString, typeName)
import Data.Array.NonEmpty (fromArray) as NEA
import Data.Int (round) as Int
import Data.Maybe (Maybe(..), fromMaybe, fromMaybe')
import Data.Newtype (wrap)
import Data.Number (fromString) as Number
import Data.String (Pattern(..), stripSuffix)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Foreign.Object (Object)
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (ReactChildren, reactComponentWithChildren)
import React.Container.ReactFlow (reactFlow) as PS
import React.Types.Component (ReactFlowProps)
import React.Types.Edges (DefaultEdgeOptions, ReconnectHandleType(..))
import React.Types.General (FitViewOptions, ProOptions)
import System.Constants (AriaLabelConfigOverride)
import System.Types.Connection (Padding(..), PaddingValue(..))
import System.Types.PanZoom (PanOnDrag(..))
import Unsafe.Coerce (unsafeCoerce)

-- ────────────────────────────────────────────────────────────────────────
-- Sub-shapes
-- ────────────────────────────────────────────────────────────────────────

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

-- | Upstream's `DefaultEdgeOptions` is `Edge` minus its identity fields — 23
-- | of them. `React.Types.Edges.DefaultEdgeOptions` carries ten. The other
-- | thirteen are named here anyway, and **refused**, because dropping them is
-- | the same silence the deferred props exist to prevent: a consumer writing
-- | `defaultEdgeOptions={{ type: 'smoothstep' }}` would get straight edges and
-- | no indication why.
-- |
-- | The thirteen split two ways, and the message says which:
-- |
-- |   * `type`, `markerStart`, `markerEnd`, `style`, `className` and `label`
-- |     are fields `Edge` itself has — so the value has somewhere to go, just
-- |     not through this record, and setting it per edge works today.
-- |   * the five remaining label options, `ariaRole` and `domAttributes` are fields
-- |     ps-flow does not model anywhere yet. Those are census rows.
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
  -- Refused. Present so they can be seen and rejected, never read.
  , type :: Undefinable Foreign
  , markerStart :: Undefinable Foreign
  , markerEnd :: Undefinable Foreign
  , style :: Undefinable Foreign
  , className :: Undefinable Foreign
  , label :: Undefinable Foreign
  , labelStyle :: Undefinable Foreign
  , labelShowBg :: Undefinable Foreign
  , labelBgStyle :: Undefinable Foreign
  , labelBgPadding :: Undefinable Foreign
  , labelBgBorderRadius :: Undefinable Foreign
  , ariaRole :: Undefinable Foreign
  , domAttributes :: Undefinable Foreign
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
  , onNodeClick :: Undefinable JsNodeMouseHandler
  , onNodeDoubleClick :: Undefinable JsNodeMouseHandler
  , onNodeMouseEnter :: Undefinable JsNodeMouseHandler
  , onNodeMouseMove :: Undefinable JsNodeMouseHandler
  , onNodeMouseLeave :: Undefinable JsNodeMouseHandler
  , onNodeContextMenu :: Undefinable JsNodeMouseHandler
  , onNodeDragStart :: Undefinable JsOnNodeDrag
  , onNodeDrag :: Undefinable JsOnNodeDrag
  , onNodeDragStop :: Undefinable JsOnNodeDrag
  , onEdgeClick :: Undefinable JsEdgeMouseHandler
  , onEdgeContextMenu :: Undefinable JsEdgeMouseHandler
  , onEdgeMouseEnter :: Undefinable JsEdgeMouseHandler
  , onEdgeMouseMove :: Undefinable JsEdgeMouseHandler
  , onEdgeMouseLeave :: Undefinable JsEdgeMouseHandler
  , onEdgeDoubleClick :: Undefinable JsEdgeMouseHandler
  , onReconnect :: Undefinable JsOnReconnect
  , onReconnectStart :: Undefinable JsOnReconnectStart
  , onReconnectEnd :: Undefinable JsOnReconnectEnd
  , onNodesChange :: Undefinable JsOnNodesChange
  , onEdgesChange :: Undefinable JsOnEdgesChange
  , onNodesDelete :: Undefinable JsOnNodesDelete
  , onEdgesDelete :: Undefinable JsOnEdgesDelete
  , onDelete :: Undefinable JsOnDelete
  , onSelectionDragStart :: Undefinable JsSelectionDragHandler
  , onSelectionDrag :: Undefinable JsSelectionDragHandler
  , onSelectionDragStop :: Undefinable JsSelectionDragHandler
  , onSelectionStart :: Undefinable JsMouseEventHandler
  , onSelectionEnd :: Undefinable JsMouseEventHandler
  , onSelectionContextMenu :: Undefinable JsSelectionDragHandler
  , onSelectionChange :: Undefinable JsOnSelectionChange
  , onConnect :: Undefinable JsOnConnect
  , onConnectStart :: Undefinable JsOnConnectStart
  , onConnectEnd :: Undefinable JsOnConnectEnd
  , onClickConnectStart :: Undefinable JsOnConnectStart
  , onClickConnectEnd :: Undefinable JsOnConnectEnd
  , onInit :: Undefinable Foreign
  , onMove :: Undefinable JsOnMove
  , onMoveStart :: Undefinable JsOnMove
  , onMoveEnd :: Undefinable JsOnMove
  , onScroll :: Undefinable JsOnScroll
  , onPaneScroll :: Undefinable JsOnPaneScroll
  , onPaneClick :: Undefinable JsMouseEventHandler
  , onPaneContextMenu :: Undefinable JsMouseEventHandler
  , onPaneMouseEnter :: Undefinable JsMouseEventHandler
  , onPaneMouseMove :: Undefinable JsMouseEventHandler
  , onPaneMouseLeave :: Undefinable JsMouseEventHandler
  , paneClickDistance :: Undefinable Number
  , nodeClickDistance :: Undefinable Number
  , onBeforeDelete :: Undefinable JsOnBeforeDelete
  , isValidConnection :: Undefinable JsIsValidConnection
  , onError :: Undefinable JsOnError
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
  , onViewportChange :: Undefinable JsOnViewportChange
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

-- | Every prop that resolves on the JS surface but does not yet cross. Named
-- | rather than counted, because the count is the thing that drifts.
-- |
-- | Stage 2 took 46 entries out of this table. The three left are the props
-- | whose *values* have not crossed: `onInit` is handed the imperative
-- | instance, and the other two are handed the props a consumer's own component
-- | receives. None of the three is waiting on a conversion this module could
-- | write.
deferredProps :: Array (Refusal JsFlowProps)
deferredProps =
  [ instanceProp "onInit" _.onInit
  , componentProp "edgeTypes" _.edgeTypes
  , componentProp "connectionLineComponent" _.connectionLineComponent
  ]

-- | Throws on the first deferred prop the consumer supplied, and otherwise
-- | hands the props straight back.
guardDeferred :: JsFlowProps -> JsFlowProps
guardDeferred = refuseFirst deferredMessage deferredProps

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
  , onNodeClick: map nodeMouseHandlerIn (fromUndefinable p.onNodeClick)
  , onNodeDoubleClick: map nodeMouseHandlerIn (fromUndefinable p.onNodeDoubleClick)
  , onNodeMouseEnter: map nodeMouseHandlerIn (fromUndefinable p.onNodeMouseEnter)
  , onNodeMouseMove: map nodeMouseHandlerIn (fromUndefinable p.onNodeMouseMove)
  , onNodeMouseLeave: map nodeMouseHandlerIn (fromUndefinable p.onNodeMouseLeave)
  , onNodeContextMenu: map nodeMouseHandlerIn (fromUndefinable p.onNodeContextMenu)
  , onNodeDragStart: map onNodeDragIn (fromUndefinable p.onNodeDragStart)
  , onNodeDrag: map onNodeDragIn (fromUndefinable p.onNodeDrag)
  , onNodeDragStop: map onNodeDragIn (fromUndefinable p.onNodeDragStop)
  , onEdgeClick: map edgeMouseHandlerIn (fromUndefinable p.onEdgeClick)
  , onEdgeContextMenu: map edgeMouseHandlerIn (fromUndefinable p.onEdgeContextMenu)
  , onEdgeMouseEnter: map edgeMouseHandlerIn (fromUndefinable p.onEdgeMouseEnter)
  , onEdgeMouseMove: map edgeMouseHandlerIn (fromUndefinable p.onEdgeMouseMove)
  , onEdgeMouseLeave: map edgeMouseHandlerIn (fromUndefinable p.onEdgeMouseLeave)
  , onEdgeDoubleClick: map edgeMouseHandlerIn (fromUndefinable p.onEdgeDoubleClick)
  , onReconnect: map onReconnectIn (fromUndefinable p.onReconnect)
  , onReconnectStart: map onReconnectStartIn (fromUndefinable p.onReconnectStart)
  , onReconnectEnd: map onReconnectEndIn (fromUndefinable p.onReconnectEnd)
  , onNodesChange: map onNodesChangeIn (fromUndefinable p.onNodesChange)
  , onEdgesChange: map onEdgesChangeIn (fromUndefinable p.onEdgesChange)
  , onNodesDelete: map onNodesDeleteIn (fromUndefinable p.onNodesDelete)
  , onEdgesDelete: map onEdgesDeleteIn (fromUndefinable p.onEdgesDelete)
  , onDelete: map onDeleteIn (fromUndefinable p.onDelete)
  , onSelectionDragStart: map selectionDragHandlerIn (fromUndefinable p.onSelectionDragStart)
  , onSelectionDrag: map selectionDragHandlerIn (fromUndefinable p.onSelectionDrag)
  , onSelectionDragStop: map selectionDragHandlerIn (fromUndefinable p.onSelectionDragStop)
  , onSelectionStart: map mouseEventHandlerIn (fromUndefinable p.onSelectionStart)
  , onSelectionEnd: map mouseEventHandlerIn (fromUndefinable p.onSelectionEnd)
  , onSelectionContextMenu: map selectionDragHandlerIn (fromUndefinable p.onSelectionContextMenu)
  , onSelectionChange: map onSelectionChangeIn (fromUndefinable p.onSelectionChange)
  , onConnect: map onConnectIn (fromUndefinable p.onConnect)
  , onConnectStart: map onConnectStartIn (fromUndefinable p.onConnectStart)
  , onConnectEnd: map onConnectEndIn (fromUndefinable p.onConnectEnd)
  , onClickConnectStart: map onConnectStartIn (fromUndefinable p.onClickConnectStart)
  , onClickConnectEnd: map onConnectEndIn (fromUndefinable p.onClickConnectEnd)
  , onInit: Nothing
  , onMove: map onMoveIn (fromUndefinable p.onMove)
  , onMoveStart: map onMoveIn (fromUndefinable p.onMoveStart)
  , onMoveEnd: map onMoveIn (fromUndefinable p.onMoveEnd)
  , onScroll: map onScrollIn (fromUndefinable p.onScroll)
  , onPaneScroll: map onPaneScrollIn (fromUndefinable p.onPaneScroll)
  , onPaneClick: map mouseEventHandlerIn (fromUndefinable p.onPaneClick)
  , onPaneContextMenu: map mouseEventHandlerIn (fromUndefinable p.onPaneContextMenu)
  , onPaneMouseEnter: map mouseEventHandlerIn (fromUndefinable p.onPaneMouseEnter)
  , onPaneMouseMove: map mouseEventHandlerIn (fromUndefinable p.onPaneMouseMove)
  , onPaneMouseLeave: map mouseEventHandlerIn (fromUndefinable p.onPaneMouseLeave)
  , paneClickDistance: fromUndefinable p.paneClickDistance
  , nodeClickDistance: fromUndefinable p.nodeClickDistance
  , onBeforeDelete: map onBeforeDeleteIn (fromUndefinable p.onBeforeDelete)
  , isValidConnection: map isValidConnectionIn (fromUndefinable p.isValidConnection)
  , onError: map onErrorIn (fromUndefinable p.onError)
  , nodeTypes: map nodeTypesIn (fromUndefinable p.nodeTypes)
  , edgeTypes: Nothing
  , connectionLineType:
      map (connectionLineTypeIn "connectionLineType")
        (fromUndefinable p.connectionLineType)
  , connectionLineStyle: map asCssStyle (fromUndefinable p.connectionLineStyle)
  , connectionLineComponent: Nothing
  , connectionLineContainerStyle:
      map asCssStyle (fromUndefinable p.connectionLineContainerStyle)
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
  , viewport: map viewportIn (fromUndefinable p.viewport)
  , defaultViewport: map viewportIn (fromUndefinable p.defaultViewport)
  , onViewportChange: map onViewportChangeIn (fromUndefinable p.onViewportChange)
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

-- | The thirteen `defaultEdgeOptions` members ps-flow's own record has no room
-- | for. Same shape as `deferredProps` and for the same reason — the guard has
-- | to name them, because nothing about writing the conversion would.
refusedEdgeOptions :: Array (Refusal JsDefaultEdgeOptions)
refusedEdgeOptions =
  [ droppedOption "type" _.type
  , droppedOption "markerStart" _.markerStart
  , droppedOption "markerEnd" _.markerEnd
  , droppedOption "style" _.style
  , droppedOption "className" _.className
  , droppedOption "label" _.label
  , unmodelledOption "labelStyle" _.labelStyle
  , unmodelledOption "labelShowBg" _.labelShowBg
  , unmodelledOption "labelBgStyle" _.labelBgStyle
  , unmodelledOption "labelBgPadding" _.labelBgPadding
  , unmodelledOption "labelBgBorderRadius" _.labelBgBorderRadius
  , unmodelledOption "ariaRole" _.ariaRole
  , unmodelledOption "domAttributes" _.domAttributes
  ]

droppedOption :: forall a. String -> (JsDefaultEdgeOptions -> Undefinable a) -> Refusal JsDefaultEdgeOptions
droppedOption name get =
  { name
  , stage: 1
  , note:
      "ps-flow's `DefaultEdgeOptions` has no such member, though `Edge` does — \
      \set it on each edge instead"
  , supplied: \p -> isDefined (get p)
  }

unmodelledOption :: forall a. String -> (JsDefaultEdgeOptions -> Undefinable a) -> Refusal JsDefaultEdgeOptions
unmodelledOption name get =
  { name
  , stage: 1
  , note: "ps-flow does not model this edge field yet, on any record"
  , supplied: \p -> isDefined (get p)
  }

guardEdgeOptions :: JsDefaultEdgeOptions -> JsDefaultEdgeOptions
guardEdgeOptions = refuseFirst message refusedEdgeOptions
  where
  message d =
    "ps-flow: `defaultEdgeOptions." <> d.name
      <> "` is refused rather than ignored — "
      <> d.note
      <> ". Dropping it silently would look exactly like never having set it."

defaultEdgeOptionsIn :: JsDefaultEdgeOptions -> DefaultEdgeOptions Foreign
defaultEdgeOptionsIn = convertEdgeOptions <<< guardEdgeOptions

convertEdgeOptions :: JsDefaultEdgeOptions -> DefaultEdgeOptions Foreign
convertEdgeOptions o =
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

-- | Exported because `<Controls />` takes the same options bag, and a second
-- | copy of a nine-field conversion is a second thing to drift.
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
    { top: side "top" sides.top
    , right: side "right" sides.right
    , bottom: side "bottom" sides.bottom
    , left: side "left" sides.left
    , x: side "x" sides.x
    , y: side "y" sides.y
    }
  where
  sides
    :: { top :: Undefinable Foreign
       , right :: Undefinable Foreign
       , bottom :: Undefinable Foreign
       , left :: Undefinable Foreign
       , x :: Undefinable Foreign
       , y :: Undefinable Foreign
       }
  sides = unsafeCoerce raw

  -- The side is passed in, not looked up by name: a name-keyed lookup needs a
  -- fallback branch, and the fallback would answer a misspelled side with some
  -- other side's value rather than failing.
  side :: String -> Undefinable Foreign -> Maybe PaddingValue
  side name value = fromUndefinable value >>= \v ->
    case paddingValueIn (field <> "." <> name) v of
      Just pv -> Just pv
      Nothing -> badPadding (field <> "." <> name) (typeName v)

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
