-- | All-`Nothing` base records for the generic-test harness. Fixtures build a
-- | concrete flow by record-updating these (`defaultReactFlowProps { … }`), so a
-- | fixture only spells out the handful of fields it cares about instead of the
-- | full ~130-field `ReactFlowProps`. Mirrors the role of xyflow's `Flow.tsx`
-- | spreading `{...flowConfig.flowProps}` over a `<ReactFlow>`.
module Generic.Defaults
  ( defaultReactFlowProps
  , defaultProviderProps
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import React.Basic.Hooks (reactChildrenFromArray)
import React.Types.Component (ReactFlowProps, ReactFlowProviderProps)

defaultReactFlowProps :: ReactFlowProps Unit Unit
defaultReactFlowProps =
  { children: reactChildrenFromArray []
  , nodes: Nothing
  , edges: Nothing
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
  , onScroll: Nothing
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
  , defaultViewport: Nothing
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

defaultProviderProps :: ReactFlowProviderProps Unit Unit
defaultProviderProps =
  { initialNodes: Nothing
  , initialEdges: Nothing
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
  , children: reactChildrenFromArray []
  }
