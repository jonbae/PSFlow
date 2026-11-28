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
  ( module Boundary.FlowMembers
  , JsFlowProps
  , JsProOptions
  , JsReactFlowProviderProps
  , reactFlow
  , reactFlowProvider
  ) where

import Prelude

import Boundary.FitView (JsFitViewOptions, fitViewOptionsIn)
import Boundary.Callbacks
  ( edgeChangeIdentityOut
  , nodeChangeIdentityOut
  , JsEdgeMouseHandler
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
  ( JsDefaultEdgeOptions
  , JsEdge
  , defaultEdgeOptionsIn
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
import Boundary.Original (remembering, stably)
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
  , panOnScrollModeIn
  , panelPositionIn
  , selectionModeIn
  , zIndexModeIn
  )
import Boundary.FlowMembers (JsAriaLabelConfig, ariaLabelConfigIn, panOnDragIn)
import Boundary.Rest (restOf)
import Boundary.Store (JsStoreView, storeViewOf)
import Boundary.Undefined (Undefinable, fromUndefinable, isNull, orNullable)
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign, unsafeFromForeign, unsafeToForeign)
import Foreign.Object (Object)
import React.Basic (JSX, ReactComponent, element, keyed)
import React.Basic.Hooks (ReactChildren, reactChildrenFromArray, reactChildrenToArray, reactComponent, reactComponentWithChildren)
import React.Basic.Hooks as React
import React.Hook.Store (useStoreApi)
import React.Store.Shell (Store)
import React.Container.ReactFlow (reactFlow) as PS
import React.FFI.ForwardRef (forwardNullableRef)
import React.Context.ChangeLog (ChangeLog, changeLogProvider)
import System.Types.Edge (EdgeChange)
import System.Types.Node (NodeChange)
import React.Provider (reactFlowProvider) as PS
import React.Types.Component (ReactFlowProps, ReactFlowProviderProps)
import React.Types.General (ProOptions)

-- ────────────────────────────────────────────────────────────────────────
-- Sub-shapes
-- ────────────────────────────────────────────────────────────────────────

type JsProOptions =
  { hideAttribution :: Boolean
  , account :: Undefinable String
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
  , className :: Undefinable String
  , style :: Undefinable Foreign
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
-- last user of. The refusal module itself went in Step 3 G, with its last
-- table: `defaultEdgeOptions`' thirteen members, which now convert.
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

-- | Every member that converts an object, an array or a function goes through
-- | `stably`, so a consumer who passes the same value again gets the same
-- | conversion back. `<StoreUpdater />` and every `memo` boundary below then
-- | see an unchanged prop, as upstream's `!==` checks do, rather than a new
-- | one on each render of `<ReactFlow />`.
convertProps :: JsFlowProps -> Nullable Foreign -> ReactFlowProps Foreign Foreign
convertProps p forwarded =
  { children: p.children
  , nodes: map (stably "nodes" (remembering (map nodeIn))) (fromUndefinable p.nodes)
  , edges: map (stably "edges" (remembering (map edgeIn))) (fromUndefinable p.edges)
  , defaultNodes: map (stably "defaultNodes" (remembering (map nodeIn))) (fromUndefinable p.defaultNodes)
  , defaultEdges: map (stably "defaultEdges" (remembering (map edgeIn))) (fromUndefinable p.defaultEdges)
  , defaultEdgeOptions: map (stably "defaultEdgeOptions" defaultEdgeOptionsIn) (fromUndefinable p.defaultEdgeOptions)
  , onNodeClick: map (stably "onNodeClick" nodeMouseHandlerIn) (fromUndefinable p.onNodeClick)
  , onNodeDoubleClick: map (stably "onNodeDoubleClick" nodeMouseHandlerIn) (fromUndefinable p.onNodeDoubleClick)
  , onNodeMouseEnter: map (stably "onNodeMouseEnter" nodeMouseHandlerIn) (fromUndefinable p.onNodeMouseEnter)
  , onNodeMouseMove: map (stably "onNodeMouseMove" nodeMouseHandlerIn) (fromUndefinable p.onNodeMouseMove)
  , onNodeMouseLeave: map (stably "onNodeMouseLeave" nodeMouseHandlerIn) (fromUndefinable p.onNodeMouseLeave)
  , onNodeContextMenu: map (stably "onNodeContextMenu" nodeMouseHandlerIn) (fromUndefinable p.onNodeContextMenu)
  , onNodeDragStart: map (stably "onNodeDragStart" (remembering onNodeDragIn)) (fromUndefinable p.onNodeDragStart)
  , onNodeDrag: map (stably "onNodeDrag" (remembering onNodeDragIn)) (fromUndefinable p.onNodeDrag)
  , onNodeDragStop: map (stably "onNodeDragStop" (remembering onNodeDragIn)) (fromUndefinable p.onNodeDragStop)
  , onEdgeClick: map (stably "onEdgeClick" edgeMouseHandlerIn) (fromUndefinable p.onEdgeClick)
  , onEdgeContextMenu: map (stably "onEdgeContextMenu" edgeMouseHandlerIn) (fromUndefinable p.onEdgeContextMenu)
  , onEdgeMouseEnter: map (stably "onEdgeMouseEnter" edgeMouseHandlerIn) (fromUndefinable p.onEdgeMouseEnter)
  , onEdgeMouseMove: map (stably "onEdgeMouseMove" edgeMouseHandlerIn) (fromUndefinable p.onEdgeMouseMove)
  , onEdgeMouseLeave: map (stably "onEdgeMouseLeave" edgeMouseHandlerIn) (fromUndefinable p.onEdgeMouseLeave)
  , onEdgeDoubleClick: map (stably "onEdgeDoubleClick" edgeMouseHandlerIn) (fromUndefinable p.onEdgeDoubleClick)
  , onReconnect: map (stably "onReconnect" onReconnectIn) (fromUndefinable p.onReconnect)
  , onReconnectStart: map (stably "onReconnectStart" onReconnectStartIn) (fromUndefinable p.onReconnectStart)
  , onReconnectEnd: map (stably "onReconnectEnd" onReconnectEndIn) (fromUndefinable p.onReconnectEnd)
  , onNodesChange: map (stably "onNodesChange" (remembering onNodesChangeIn)) (fromUndefinable p.onNodesChange)
  , onEdgesChange: map (stably "onEdgesChange" (remembering onEdgesChangeIn)) (fromUndefinable p.onEdgesChange)
  , onNodesDelete: map (stably "onNodesDelete" (remembering onNodesDeleteIn)) (fromUndefinable p.onNodesDelete)
  , onEdgesDelete: map (stably "onEdgesDelete" (remembering onEdgesDeleteIn)) (fromUndefinable p.onEdgesDelete)
  , onDelete: map (stably "onDelete" (remembering onDeleteIn)) (fromUndefinable p.onDelete)
  , onSelectionDragStart: map (stably "onSelectionDragStart" (remembering selectionDragHandlerIn)) (fromUndefinable p.onSelectionDragStart)
  , onSelectionDrag: map (stably "onSelectionDrag" (remembering selectionDragHandlerIn)) (fromUndefinable p.onSelectionDrag)
  , onSelectionDragStop: map (stably "onSelectionDragStop" (remembering selectionDragHandlerIn)) (fromUndefinable p.onSelectionDragStop)
  , onSelectionStart: map (stably "onSelectionStart" mouseEventHandlerIn) (fromUndefinable p.onSelectionStart)
  , onSelectionEnd: map (stably "onSelectionEnd" mouseEventHandlerIn) (fromUndefinable p.onSelectionEnd)
  , onSelectionContextMenu: map (stably "onSelectionContextMenu" selectionDragHandlerIn) (fromUndefinable p.onSelectionContextMenu)
  , onSelectionChange: map (stably "onSelectionChange" onSelectionChangeIn) (fromUndefinable p.onSelectionChange)
  , onConnect: map (stably "onConnect" (remembering onConnectIn)) (fromUndefinable p.onConnect)
  , onConnectStart: map (stably "onConnectStart" (remembering onConnectStartIn)) (fromUndefinable p.onConnectStart)
  , onConnectEnd: map (stably "onConnectEnd" (remembering onConnectEndIn)) (fromUndefinable p.onConnectEnd)
  , onClickConnectStart: map (stably "onClickConnectStart" (remembering onConnectStartIn)) (fromUndefinable p.onClickConnectStart)
  , onClickConnectEnd: map (stably "onClickConnectEnd" (remembering onConnectEndIn)) (fromUndefinable p.onClickConnectEnd)
  , onInit: map (stably "onInit" onInitIn) (fromUndefinable p.onInit)
  , onMove: map (stably "onMove" (remembering onMoveIn)) (fromUndefinable p.onMove)
  , onMoveStart: map (stably "onMoveStart" (remembering onMoveIn)) (fromUndefinable p.onMoveStart)
  , onMoveEnd: map (stably "onMoveEnd" (remembering onMoveIn)) (fromUndefinable p.onMoveEnd)
  , className: fromUndefinable p.className
  , style: map (stably "style" asCssStyle) (fromUndefinable p.style)
  , onScroll: map (stably "onScroll" onScrollIn) (fromUndefinable p.onScroll)
  , onPaneScroll: map (stably "onPaneScroll" onPaneScrollIn) (fromUndefinable p.onPaneScroll)
  , onPaneClick: map (stably "onPaneClick" mouseEventHandlerIn) (fromUndefinable p.onPaneClick)
  , onPaneContextMenu: map (stably "onPaneContextMenu" mouseEventHandlerIn) (fromUndefinable p.onPaneContextMenu)
  , onPaneMouseEnter: map (stably "onPaneMouseEnter" mouseEventHandlerIn) (fromUndefinable p.onPaneMouseEnter)
  , onPaneMouseMove: map (stably "onPaneMouseMove" mouseEventHandlerIn) (fromUndefinable p.onPaneMouseMove)
  , onPaneMouseLeave: map (stably "onPaneMouseLeave" mouseEventHandlerIn) (fromUndefinable p.onPaneMouseLeave)
  , paneClickDistance: fromUndefinable p.paneClickDistance
  , nodeClickDistance: fromUndefinable p.nodeClickDistance
  , onBeforeDelete: map (stably "onBeforeDelete" (remembering onBeforeDeleteIn)) (fromUndefinable p.onBeforeDelete)
  , isValidConnection: map (stably "isValidConnection" (remembering isValidConnectionIn)) (fromUndefinable p.isValidConnection)
  , onError: map (stably "onError" (remembering onErrorIn)) (fromUndefinable p.onError)
  , nodeTypes: map (stably "nodeTypes" nodeTypesIn) (fromUndefinable p.nodeTypes)
  , edgeTypes: map (stably "edgeTypes" edgeTypesIn) (fromUndefinable p.edgeTypes)
  , connectionLineType:
      map (stably "connectionLineType" (connectionLineTypeIn "connectionLineType"))
        (fromUndefinable p.connectionLineType)
  , connectionLineStyle: map (stably "connectionLineStyle" asCssStyle) (fromUndefinable p.connectionLineStyle)
  , connectionLineComponent:
      map (stably "connectionLineComponent" connectionLineComponentIn) (fromUndefinable p.connectionLineComponent)
  , connectionLineContainerStyle:
      map (stably "connectionLineContainerStyle" asCssStyle) (fromUndefinable p.connectionLineContainerStyle)
  , connectionMode: map (stably "connectionMode" (connectionModeIn "connectionMode")) (fromUndefinable p.connectionMode)
  , deleteKeyCode: keyCodeIn "deleteKeyCode" p.deleteKeyCode
  , selectionKeyCode: keyCodeIn "selectionKeyCode" p.selectionKeyCode
  , selectionOnDrag: fromUndefinable p.selectionOnDrag
  , selectionMode: map (stably "selectionMode" (selectionModeIn "selectionMode")) (fromUndefinable p.selectionMode)
  , panActivationKeyCode: keyCodeIn "panActivationKeyCode" p.panActivationKeyCode
  , multiSelectionKeyCode: keyCodeIn "multiSelectionKeyCode" p.multiSelectionKeyCode
  , zoomActivationKeyCode: keyCodeIn "zoomActivationKeyCode" p.zoomActivationKeyCode
  , snapToGrid: fromUndefinable p.snapToGrid
  , snapGrid: map (stably "snapGrid" (snapGridIn "snapGrid")) (fromUndefinable p.snapGrid)
  , onlyRenderVisibleElements: fromUndefinable p.onlyRenderVisibleElements
  , nodesDraggable: fromUndefinable p.nodesDraggable
  , nodesConnectable: fromUndefinable p.nodesConnectable
  , nodesFocusable: fromUndefinable p.nodesFocusable
  , nodeDragThreshold: fromUndefinable p.nodeDragThreshold
  , nodeOrigin: map (stably "nodeOrigin" (nodeOriginIn "nodeOrigin")) (fromUndefinable p.nodeOrigin)
  , nodeExtent: map (stably "nodeExtent" (coordinateExtentIn "nodeExtent")) (fromUndefinable p.nodeExtent)
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
  , panOnDrag: map (stably "panOnDrag" panOnDragIn) (fromUndefinable p.panOnDrag)
  , minZoom: fromUndefinable p.minZoom
  , maxZoom: fromUndefinable p.maxZoom
  , translateExtent:
      map (stably "translateExtent" (coordinateExtentIn "translateExtent")) (fromUndefinable p.translateExtent)
  , zoomOnScroll: fromUndefinable p.zoomOnScroll
  , zoomOnPinch: fromUndefinable p.zoomOnPinch
  , zoomOnDoubleClick: fromUndefinable p.zoomOnDoubleClick
  , panOnScroll: fromUndefinable p.panOnScroll
  , panOnScrollSpeed: fromUndefinable p.panOnScrollSpeed
  , panOnScrollMode:
      map (stably "panOnScrollMode" (panOnScrollModeIn "panOnScrollMode")) (fromUndefinable p.panOnScrollMode)
  , preventScrolling: fromUndefinable p.preventScrolling
  , viewport: map (stably "viewport" viewportIn) (fromUndefinable p.viewport)
  , defaultViewport: map (stably "defaultViewport" viewportIn) (fromUndefinable p.defaultViewport)
  , onViewportChange: map (stably "onViewportChange" (remembering onViewportChangeIn)) (fromUndefinable p.onViewportChange)
  , fitView: fromUndefinable p.fitView
  , fitViewOptions: map (stably "fitViewOptions" (remembering fitViewOptionsIn)) (fromUndefinable p.fitViewOptions)
  -- `string | null`, and `null` is not absence: upstream's default
  -- `'#b1b1b7'` applies only to `undefined`, and a null colour draws each
  -- default marker with no stroke, as `''` does, since the symbols write
  -- `color && { stroke: color }`. So `null` crosses as `''`.
  , defaultMarkerColor:
      if isNull p.defaultMarkerColor then Just "" else fromUndefinable p.defaultMarkerColor
  , width: fromUndefinable p.width
  , height: fromUndefinable p.height
  , colorMode: map (stably "colorMode" (colorModeIn "colorMode")) (fromUndefinable p.colorMode)
  , attributionPosition:
      map (stably "attributionPosition" (panelPositionIn "attributionPosition")) (fromUndefinable p.attributionPosition)
  , proOptions: map (stably "proOptions" proOptionsIn) (fromUndefinable p.proOptions)
  , noWheelClassName: fromUndefinable p.noWheelClassName
  , noPanClassName: fromUndefinable p.noPanClassName
  , disableKeyboardA11y: fromUndefinable p.disableKeyboardA11y
  , ariaLabelConfig: map (stably "ariaLabelConfig" ariaLabelConfigIn) (fromUndefinable p.ariaLabelConfig)
  , autoPanOnConnect: fromUndefinable p.autoPanOnConnect
  , autoPanSpeed: fromUndefinable p.autoPanSpeed
  , autoPanOnSelection: fromUndefinable p.autoPanOnSelection
  , connectOnClick: fromUndefinable p.connectOnClick
  , connectionRadius: fromUndefinable p.connectionRadius
  , debug: fromUndefinable p.debug
  , zIndexMode: map (stably "zIndexMode" (zIndexModeIn "zIndexMode")) (fromUndefinable p.zIndexMode)
  , innerRef: orNullable p.ref forwarded
  -- Upstream's `...rest`, which its wrapper `<div>` spreads. `JsFlowProps`
  -- names every member upstream destructures bar `id`, which upstream sets on
  -- the div after the rest, so it rides here with the value it would have had.
  , wrapperAttributes: restOf p
  }

proOptionsIn :: JsProOptions -> ProOptions
proOptionsIn o =
  { hideAttribution: o.hideAttribution
  , account: fromUndefinable o.account
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
    changeLogProvider jsChangeLog
      [ element PS.reactFlow
          ( (convertProps props forwarded)
              { children = reactChildrenFromArray
                  ( [ keyed "ps-flow-store-defaults"
                        (element storeDefaults { defaultNodes: props.defaultNodes, defaultEdges: props.defaultEdges })
                    ]
                      <> reactChildrenToArray props.children
                  )
              }
          )
      ]

-- | The changes a `debug` log shows, as the JS surface's `onNodesChange` and
-- | `onEdgesChange` receive them. The store reads it when it is created, so
-- | `<ReactFlow />` and `<ReactFlowProvider />` both provide it.
jsChangeLog :: ChangeLog
jsChangeLog =
  { nodeChanges: \changes ->
      unsafeToForeign (map nodeChangeIdentityOut (unsafeFromForeign changes :: Array (NodeChange Foreign)))
  , edgeChanges: \changes ->
      unsafeToForeign (map edgeChangeIdentityOut (unsafeFromForeign changes :: Array (EdgeChange Foreign)))
  }

-- | `defaultNodes` and `defaultEdges` as upstream's `<StoreUpdater />` leaves
-- | them: two keys of the store's state that `ReactFlowState` does not
-- | declare, holding the consumer's own arrays. It renders first among the
-- | flow's children, so its effect writes them before any child of the
-- | consumer's reads the state at mount, as upstream's runs before theirs.
storeDefaults
  :: ReactComponent
       { defaultNodes :: Undefinable (Array JsNode)
       , defaultEdges :: Undefinable (Array JsEdge)
       }
storeDefaults =
  unsafePerformEffect $ reactComponent "StoreDefaults" \p -> React.do
    store <- useStoreApi
    pure $ element storeDefaultsWriter
      { view: storeViewOf (store :: Store Foreign Foreign)
      , defaultNodes: p.defaultNodes
      , defaultEdges: p.defaultEdges
      }

foreign import storeDefaultsWriter
  :: ReactComponent
       { view :: JsStoreView
       , defaultNodes :: Undefinable (Array JsNode)
       , defaultEdges :: Undefinable (Array JsEdge)
       }

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
  { initialNodes: map (remembering (map nodeIn)) (fromUndefinable p.initialNodes)
  , initialEdges: map (remembering (map edgeIn)) (fromUndefinable p.initialEdges)
  , defaultNodes: map (remembering (map nodeIn)) (fromUndefinable p.defaultNodes)
  , defaultEdges: map (remembering (map edgeIn)) (fromUndefinable p.defaultEdges)
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
      pure (changeLogProvider jsChangeLog [ element PS.reactFlowProvider (convertProvider props) ])
