-- | Smoke-test app for ticket 049. Mounts a `<ReactFlow>` with two nodes,
-- | one edge, plus `<Background>`, `<Controls>`, and `<MiniMap>` overlays.
-- |
-- | The point of this file is **API-contract verification**: every
-- | component/type used here is imported only from the public-API barrel
-- | `React`. If `spago build` accepts this module, every symbol the
-- | example touches resolves through the public surface. That's all we
-- | claim for ticket 049 — actually executing the JS bundle in a browser
-- | (with react/react-dom installed) is the gate for ticket 053.
-- |
-- | Verbosity note: PS records have no defaults. The huge `Nothing`-everywhere
-- | construction below is *the* signal that the public types are
-- | well-formed end-to-end. If a field were missing or mistyped, this
-- | file would fail to compile.
module Example.Main where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import React.Basic (JSX, element)
import React.Basic.Hooks (reactChildrenFromArray)
import Web.DOM.Element (Element)
import Web.DOM.NonElementParentNode (getElementById)
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.Window (document)

import React
  ( Edge
  , Node
  , Position(..)
  , background
  , controls
  , miniMap
  , reactFlow
  , reactFlowProvider
  )
import React.Types.Component (ReactFlowProps, ReactFlowProviderProps, BackgroundProps, ControlsProps, MiniMapProps)

foreign import mountAppImpl :: Element -> JSX -> Effect Unit

-- | The example flow: two nodes 200×100 apart, one edge between them.
twoNodes :: Array (Node Unit)
twoNodes =
  [ mkNode "n1" 0.0 0.0
  , mkNode "n2" 250.0 100.0
  ]
  where
  mkNode nid x y =
    { id: nid
    , position: { x, y }
    , data: unit
    , sourcePosition: Just PosRight
    , targetPosition: Just PosLeft
    , hidden: false
    , selected: false
    , dragging: false
    , draggable: Nothing
    , selectable: Nothing
    , connectable: Nothing
    , deletable: Nothing
    , dragHandle: Nothing
    , width: Just 100.0
    , height: Just 40.0
    , initialWidth: Nothing
    , initialHeight: Nothing
    , parentId: Nothing
    , zIndex: Nothing
    , extent: Nothing
    , expandParent: false
    , ariaLabel: Nothing
    , origin: Nothing
    , handles: Nothing
    , measured: { width: Just 100.0, height: Just 40.0 }
    , nodeType: Nothing
    }

oneEdge :: Array (Edge Unit)
oneEdge =
  [ { id: "e1-2"
    , edgeType: Nothing
    , source: "n1"
    , target: "n2"
    , sourceHandle: Nothing
    , targetHandle: Nothing
    , animated: false
    , hidden: false
    , deletable: Nothing
    , selectable: Nothing
    , data: Nothing
    , selected: false
    , markerStart: Nothing
    , markerEnd: Nothing
    , zIndex: Nothing
    , ariaLabel: Nothing
    , interactionWidth: Nothing
    }
  ]

-- | Default `<Background />` props — `Nothing` everywhere, accept upstream defaults.
backgroundProps :: BackgroundProps
backgroundProps =
  { id: Nothing
  , color: Nothing
  , bgColor: Nothing
  , className: Nothing
  , patternClassName: Nothing
  , gap: Nothing
  , size: Nothing
  , offset: Nothing
  , lineWidth: Nothing
  , variant: Nothing
  , style: Nothing
  }

-- | Default `<Controls />` props — `Nothing` everywhere, no children.
controlsProps :: ControlsProps
controlsProps =
  { showZoom: Nothing
  , showFitView: Nothing
  , showInteractive: Nothing
  , fitViewOptions: Nothing
  , onZoomIn: Nothing
  , onZoomOut: Nothing
  , onFitView: Nothing
  , onInteractiveChange: Nothing
  , position: Nothing
  , children: reactChildrenFromArray []
  , style: Nothing
  , className: Nothing
  , "aria-label": Nothing
  , orientation: Nothing
  }

-- | Default `<MiniMap />` props — `Nothing` everywhere, no children.
miniMapProps :: MiniMapProps Unit
miniMapProps =
  { nodeColor: Nothing
  , nodeStrokeColor: Nothing
  , nodeClassName: Nothing
  , nodeBorderRadius: Nothing
  , nodeStrokeWidth: Nothing
  , nodeComponent: Nothing
  , bgColor: Nothing
  , maskColor: Nothing
  , maskStrokeColor: Nothing
  , maskStrokeWidth: Nothing
  , position: Nothing
  , onClick: Nothing
  , onNodeClick: Nothing
  , pannable: Nothing
  , zoomable: Nothing
  , "aria-label": Nothing
  , inversePan: Nothing
  , zoomStep: Nothing
  , offsetScale: Nothing
  , children: reactChildrenFromArray []
  , style: Nothing
  , className: Nothing
  }

-- | The big `<ReactFlow />` props record. All optional fields default to
-- | `Nothing`; the data inputs go through `nodes` / `edges` / `defaultViewport`.
reactFlowProps :: ReactFlowProps Unit Unit
reactFlowProps =
  { children: reactChildrenFromArray
      [ element background backgroundProps
      , element controls controlsProps
      , element miniMap miniMapProps
      ]
  , nodes: Just twoNodes
  , edges: Just oneEdge
  , defaultNodes: Nothing
  , defaultEdges: Nothing
  , defaultEdgeOptions: Nothing
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
  , onNodesChange: Nothing
  , onEdgesChange: Nothing
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
  , onConnect: Nothing
  , onConnectStart: Nothing
  , onConnectEnd: Nothing
  , onClickConnectStart: Nothing
  , onClickConnectEnd: Nothing
  , onInit: Nothing
  , onMove: Nothing
  , onMoveStart: Nothing
  , onMoveEnd: Nothing
  , onPaneScroll: Nothing
  , onPaneClick: Nothing
  , onPaneContextMenu: Nothing
  , onPaneMouseEnter: Nothing
  , onPaneMouseMove: Nothing
  , onPaneMouseLeave: Nothing
  , paneClickDistance: Nothing
  , nodeClickDistance: Nothing
  , onBeforeDelete: Nothing
  , isValidConnection: Nothing
  , onError: Nothing
  , nodeTypes: Nothing
  , edgeTypes: Nothing
  , connectionLineType: Nothing
  , connectionLineStyle: Nothing
  , connectionLineComponent: Nothing
  , connectionLineContainerStyle: Nothing
  , connectionMode: Nothing
  , deleteKeyCode: Nothing
  , selectionKeyCode: Nothing
  , selectionOnDrag: Nothing
  , selectionMode: Nothing
  , panActivationKeyCode: Nothing
  , multiSelectionKeyCode: Nothing
  , zoomActivationKeyCode: Nothing
  , snapToGrid: Nothing
  , snapGrid: Nothing
  , onlyRenderVisibleElements: Nothing
  , nodesDraggable: Nothing
  , nodesConnectable: Nothing
  , nodesFocusable: Nothing
  , nodeDragThreshold: Nothing
  , nodeOrigin: Nothing
  , nodeExtent: Nothing
  , autoPanOnNodeFocus: Nothing
  , autoPanOnNodeDrag: Nothing
  , noDragClassName: Nothing
  , edgesFocusable: Nothing
  , edgesReconnectable: Nothing
  , reconnectRadius: Nothing
  , connectionDragThreshold: Nothing
  , elementsSelectable: Nothing
  , selectNodesOnDrag: Nothing
  , elevateNodesOnSelect: Nothing
  , elevateEdgesOnSelect: Nothing
  , panOnDrag: Nothing
  , minZoom: Nothing
  , maxZoom: Nothing
  , translateExtent: Nothing
  , zoomOnScroll: Nothing
  , zoomOnPinch: Nothing
  , zoomOnDoubleClick: Nothing
  , panOnScroll: Nothing
  , panOnScrollSpeed: Nothing
  , panOnScrollMode: Nothing
  , preventScrolling: Nothing
  , viewport: Nothing
  , defaultViewport: Just { x: 0.0, y: 0.0, zoom: 1.0 }
  , onViewportChange: Nothing
  , fitView: Nothing
  , fitViewOptions: Nothing
  , defaultMarkerColor: Nothing
  , width: Nothing
  , height: Nothing
  , colorMode: Nothing
  , attributionPosition: Nothing
  , proOptions: Nothing
  , noWheelClassName: Nothing
  , noPanClassName: Nothing
  , disableKeyboardA11y: Nothing
  , ariaLabelConfig: Nothing
  , autoPanOnConnect: Nothing
  , autoPanSpeed: Nothing
  , autoPanOnSelection: Nothing
  , connectOnClick: Nothing
  , connectionRadius: Nothing
  , debug: Nothing
  , zIndexMode: Nothing
  }

-- | `<ReactFlowProvider />` props — the provider wraps `<ReactFlow />` so
-- | the example can use the public hooks (`useReactFlow`, etc.) from
-- | within future iterations. All fields `Nothing`/`Just []`.
providerProps :: ReactFlowProviderProps Unit Unit
providerProps =
  { initialNodes: Just twoNodes
  , initialEdges: Just oneEdge
  , defaultNodes: Nothing
  , defaultEdges: Nothing
  , initialWidth: Nothing
  , initialHeight: Nothing
  , fitView: Nothing
  , initialFitViewOptions: Nothing
  , initialMinZoom: Nothing
  , initialMaxZoom: Nothing
  , nodeOrigin: Nothing
  , nodeExtent: Nothing
  , zIndexMode: Nothing
  , children: reactChildrenFromArray
      [ element reactFlow reactFlowProps ]
  }

app :: JSX
app = element reactFlowProvider providerProps

main :: Effect Unit
main = do
  doc <- window >>= document <#> HTMLDocument.toNonElementParentNode
  mEl <- getElementById "app" doc
  case mEl of
    Just el -> mountAppImpl el app
    Nothing -> pure unit
