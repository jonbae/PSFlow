-- | `<ReactFlow />`, crossing.
-- |
-- | This is the indivisible part of the boundary. The flow props are one record
-- | of 125 fields, and a JavaScript consumer who sets seven of them still gets a
-- | props object whose other 118 keys are absent — so the conversion has to
-- | name all 125 whatever any one fixture needs. There is no vertical slice
-- | here to take.
-- |
-- | ## What a prop can be
-- |
-- | **Converted** — all 125: 75 of 75 non-callback fields, all 49 callback
-- | props, and `children`. All but one as of boundary stage 4; the one is
-- | `innerRef`, which #27 added along with the `forwardRef` that fills it.
-- | Three of the callbacks crossed in stage 1 with the component itself
-- | (`onNodesChange`, `onEdgesChange`, `onConnect`); 46 crossed in stage 2;
-- | and `onInit` crossed in stage 3, once `Boundary.Instance` existed to
-- | convert the one argument it is handed. Their converters live in
-- | `Boundary.Callbacks`.
-- |
-- | **Deferred, and therefore throwing at mount** — 0, as of stage 4. There
-- | were two: `edgeTypes` and `connectionLineComponent`, both deferred for the
-- | same reason — **their values had not crossed**. Each holds the consumer's
-- | own components, so crossing it means an outbound converter for the props
-- | those components receive; `nodeTypes` had one from stage 1
-- | (`Boundary.Elements.nodePropsOut`), and edge props and connection-line
-- | props are `Boundary.Edges`'.
-- |
-- | The `deferredProps` table that refused them is **gone**, and so is the
-- | `guardDeferred` that ran in front of `convertProps`. That is not the guard
-- | being dropped — it is the guard changing shape, because the failure it
-- | existed for has not gone anywhere. A prop that merely did nothing would be
-- | indistinguishable from a prop the consumer never set, which is the exact
-- | failure shape of the unrun `Effect` thunk that produced this whole effort:
-- | `setNodes(fn)` returned a thunk, nobody ran it, and every gate stayed
-- | green. The compiler does not help — a record forces you to write
-- | *something* per field and `Nothing` compiles perfectly. So
-- | `parity/boundary/mount.mjs` now reads `convertProps` and fails on any prop
-- | wired to a literal `Nothing`, which is the stronger claim: while props were
-- | being refused it could only ask whether each one was declared.
-- |
-- | ## The two components this module publishes
-- |
-- | `reactFlow`, and — since stage 4 — `reactFlowProvider`.
-- |
-- | There were three until #27. Stage 4 crossed `reactFlowWithRef`, ps-flow's
-- | own second export, so that a JavaScript consumer who needed the wrapper
-- | div's ref could reach it with upstream's props rather than through the
-- | PureScript nesting; `ReactFlow` itself was not a `forwardRef`, which stage
-- | 4 recorded as #27's and not its own. #27 made it one, and that is what
-- | removed the second component rather than merely deprecating it — the
-- | export existed to supply a capability `ReactFlow` now has.
-- |
-- | `reactFlowProvider` is here rather than in a module of its own because its
-- | thirteen initial values are flow props by another name, and they cross
-- | through the converters above.
module Boundary.Flow
  ( JsAriaLabelConfig
  , JsDefaultEdgeOptions
  , JsFlowProps
  , JsProOptions
  , JsReactFlowProviderProps
  , reactFlow
  , reactFlowProvider
  ) where

import Prelude

import Boundary.FitView (JsFitViewOptions, fitViewOptionsIn)
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
  , JsOnInit
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
  , onInitIn
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
import Boundary.Edges
  ( JsConnectionLineComponentProps
  , JsEdgeProps
  , connectionLineComponentIn
  , edgeTypesIn
  )
import Boundary.Enums
  ( colorModeIn
  , connectionLineTypeIn
  , connectionModeIn
  , handleTypeIn
  , panOnScrollModeIn
  , panelPositionIn
  , selectionModeIn
  , zIndexModeIn
  )
import Boundary.Refusal (Refusal, refuseFirst)
import Boundary.Undefined (Undefinable, fromUndefinable, isDefined, orNullable)
import Boundary.Untagged (asArray, asBoolean, asNumber, asString, typeName)
import Data.Array.NonEmpty (fromArray) as NEA
import Data.Int (round) as Int
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Foreign.Object (Object)
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (ReactChildren, reactComponentWithChildren)
import React.Container.ReactFlow (reactFlow) as PS
import React.FFI.ForwardRef (forwardNullableRef)
import React.Provider (reactFlowProvider) as PS
import React.Types.Component (ReactFlowProps, ReactFlowProviderProps)
import React.Types.Edges (DefaultEdgeOptions, ReconnectHandleType(..))
import React.Types.General (ProOptions)
import System.Constants (AriaLabelConfigOverride)
import System.Types.PanZoom (PanOnDrag(..))

-- ────────────────────────────────────────────────────────────────────────
-- Sub-shapes
-- ────────────────────────────────────────────────────────────────────────

type JsProOptions =
  { hideAttribution :: Boolean
  , account :: Undefinable String
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
  , onInit :: Undefinable JsOnInit
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
  , edgeTypes :: Undefinable (Object (ReactComponent JsEdgeProps))
  , connectionLineType :: Undefinable String
  , connectionLineStyle :: Undefinable Foreign
  , connectionLineComponent :: Undefinable (ReactComponent JsConnectionLineComponentProps)
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
  -- | Upstream's name for what ps-flow spells `innerRef`, and the reason this
  -- | component is a `forwardRef`. `Boundary.Undefined.orNullable` says why it
  -- | is read from the props object as well as from the forwarded argument.
  -- | Last, because `ReactFlowProps.innerRef` is — the two records are kept in
  -- | one order so they read side by side, and `PanelProps` pairs the same two
  -- | spellings in the same place.
  , ref :: Undefinable Foreign
  }

-- ────────────────────────────────────────────────────────────────────────
-- The conversion
--
-- There was a `deferredProps` table here, and a `guardDeferred` in front of
-- this function, from stage 1 until stage 4. It held every prop that resolved
-- on the JS surface and had no converter, and it threw on the first one a
-- consumer supplied. Stage 2 emptied 46 of its entries, stage 3 the 47th, and
-- stage 4 the last two — so it is gone, along with the entry kind it was the
-- last user of (`Boundary.Refusal`).
--
-- What replaces it is not a smaller guard but a differently-shaped check:
-- `parity/boundary/mount.mjs` reads this function and fails if *any* prop is
-- wired to `Nothing`. While props were being refused that check asked whether
-- each one was declared; with nothing refused it asks whether anything is
-- dropped, which is the stronger of the two and the one worth keeping.
--
-- The `flowPropsIn` that stood in front of this went with the guard. It existed
-- to make the guard unskippable — `convert <<< guard` has no way to reach a
-- converted field without going through the guard first — and with nothing to
-- guard it was a name for `convertProps` and nothing else. `Boundary.Chrome`
-- lost its `miniMapPropsIn` in the same commit and for the same reason.
-- ────────────────────────────────────────────────────────────────────────

convertProps :: JsFlowProps -> Nullable Foreign -> ReactFlowProps Foreign Foreign
convertProps p forwarded =
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
  , onInit: map onInitIn (fromUndefinable p.onInit)
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
  , edgeTypes: map edgeTypesIn (fromUndefinable p.edgeTypes)
  , connectionLineType:
      map (connectionLineTypeIn "connectionLineType")
        (fromUndefinable p.connectionLineType)
  , connectionLineStyle: map asCssStyle (fromUndefinable p.connectionLineStyle)
  , connectionLineComponent:
      map connectionLineComponentIn (fromUndefinable p.connectionLineComponent)
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
  , innerRef: orNullable p.ref forwarded
  }

-- | The thirteen `defaultEdgeOptions` members ps-flow's own record has no room
-- | for. The last refusal table on this surface, and the one the deferred
-- | props were never quite the same as: these are refused because the
-- | internals do not model them, not because a converter is pending, so no
-- | stage retires them. The guard has to name them because nothing about
-- | writing the conversion would.
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
-- |
-- | A `forwardRef`, which is upstream's shape and — since #27 — the PureScript
-- | component's capability. It was a plain component beside a second export,
-- | `ReactFlowWithRef`, and the pair is gone: a `ref` handed to this one was
-- | silently dropped, and the one that took a ref nested every prop under a
-- | `props` field and read `children` from inside it, so neither was the
-- | element upstream's documentation writes.
-- |
-- | The ref does not need `elementWithNullableRef` here the way `Panel` and
-- | `Handle` do not: it travels as `innerRef` on the props record, a field
-- | React does not reserve, and `React.Container.ReactFlow` puts it on the
-- | wrapper `<div>`.
reactFlow :: ReactComponent JsFlowProps
reactFlow =
  forwardNullableRef "ReactFlow" \(props :: JsFlowProps) forwarded ->
    element PS.reactFlow (convertProps props forwarded)

-- ────────────────────────────────────────────────────────────────────────
-- ReactFlowProvider
--
-- The context provider a consumer wraps their own tree in when they want the
-- hooks outside `<ReactFlow />`. Thirteen initial values and `children`, all
-- optional, and every one of them a shape some flow prop already crosses — so
-- this record shares `nodeIn`, `edgeIn`, `fitViewOptionsIn`, `nodeOriginIn`,
-- `coordinateExtentIn` and `zIndexModeIn` with the props record above rather
-- than restating them.
-- ────────────────────────────────────────────────────────────────────────

type JsReactFlowProviderProps =
  { initialNodes :: Undefinable (Array JsNode)
  , initialEdges :: Undefinable (Array JsEdge)
  , defaultNodes :: Undefinable (Array JsNode)
  , defaultEdges :: Undefinable (Array JsEdge)
  , initialWidth :: Undefinable Number
  , initialHeight :: Undefinable Number
  , fitView :: Undefinable Boolean
  , initialFitViewOptions :: Undefinable JsFitViewOptions
  , initialMinZoom :: Undefinable Number
  , initialMaxZoom :: Undefinable Number
  , nodeOrigin :: Undefinable (Array Number)
  , nodeExtent :: Undefinable (Array (Array Number))
  , zIndexMode :: Undefinable String
  , children :: ReactChildren JSX
  }

convertProvider :: JsReactFlowProviderProps -> ReactFlowProviderProps Foreign Foreign
convertProvider p =
  { initialNodes: map (map nodeIn) (fromUndefinable p.initialNodes)
  , initialEdges: map (map edgeIn) (fromUndefinable p.initialEdges)
  , defaultNodes: map (map nodeIn) (fromUndefinable p.defaultNodes)
  , defaultEdges: map (map edgeIn) (fromUndefinable p.defaultEdges)
  , initialWidth: fromUndefinable p.initialWidth
  , initialHeight: fromUndefinable p.initialHeight
  , fitView: fromUndefinable p.fitView
  , initialFitViewOptions: map fitViewOptionsIn (fromUndefinable p.initialFitViewOptions)
  , initialMinZoom: fromUndefinable p.initialMinZoom
  , initialMaxZoom: fromUndefinable p.initialMaxZoom
  , nodeOrigin:
      map (nodeOriginIn "ReactFlowProvider.nodeOrigin") (fromUndefinable p.nodeOrigin)
  , nodeExtent:
      map (coordinateExtentIn "ReactFlowProvider.nodeExtent") (fromUndefinable p.nodeExtent)
  , zIndexMode:
      map (zIndexModeIn "ReactFlowProvider.zIndexMode") (fromUndefinable p.zIndexMode)
  , children: p.children
  }

reactFlowProvider :: ReactComponent JsReactFlowProviderProps
reactFlowProvider =
  unsafePerformEffect $ reactComponentWithChildren "ReactFlowProvider"
    \(props :: JsReactFlowProviderProps) ->
      pure (element PS.reactFlowProvider (convertProvider props))
