-- | Public component prop records. The big one is `ReactFlowProps`; the
-- | rest (`HandleProps`, `PanelProps`, etc.) are scaffolded with a
-- | minimal shape so downstream tickets can reference them without
-- | colliding. Each is filled in as its component implementation lands.
module React.Types.Component
  ( ReactFlowProps
  , HandleProps
  , PanelProps
  , EdgeLabelRendererProps
  , ViewportPortalProps
  , ConnectionLineProps
  , BackgroundProps
  , ControlsProps
  , ControlButtonProps
  , MiniMapProps
  , NodeToolbarProps
  , NodeResizerProps
  , EdgeToolbarProps
  ) where

import Prelude

import Data.Maybe (Maybe)
import Effect (Effect)
import React.Basic (JSX)
import React.Types.Edges
  ( ConnectionLineComponentProps
  , DefaultEdgeOptions
  , Edge
  , EdgeMouseHandler
  , EdgeTypesMap
  , OnReconnect
  , Style
  )
import React.Types.Nodes (Node, NodeMouseHandler, NodeTypesMap, OnNodeDrag, SelectionDragHandler)
import React.Types.General
  ( FitViewOptions
  , IsValidConnection
  , OnBeforeDelete
  , OnDelete
  , OnEdgesChange
  , OnEdgesDelete
  , OnInit
  , OnMove
  , OnMoveEnd
  , OnMoveStart
  , OnNodesChange
  , OnNodesDelete
  , OnSelectionChangeFunc
  , OnViewportChange
  , ProOptions
  )
import React.Types.Instance (ReactFlowInstance)
import System.Constants (AriaLabelConfigOverride)
import System.Types.Connection
  ( ColorMode
  , ConnectionMode
  , FinalConnectionState
  , KeyCode
  , PanOnScrollMode
  , PanelPosition
  , SelectionMode
  , Viewport
  , ZIndexMode
  )
import System.Types.Edge (ConnectionLineType)
import System.Types.Geometry (CoordinateExtent, NodeOrigin, SnapGrid)
import System.Types.Handle (HandleType)
import System.Types.Node (InternalNodeBase, OnError)
import System.Types.PanZoom (PanOnDrag)
import System.XYHandle (OnConnect, OnConnectEnd, OnConnectStart)
import Web.UIEvent.MouseEvent (MouseEvent)
import Web.UIEvent.WheelEvent (WheelEvent)

-- | Public top-level props for the `<ReactFlow />` component. Mirrors
-- | `xyflow-main/packages/react/src/types/component-props.ts ReactFlowProps`
-- | field for field. Every TS optional becomes `Maybe`; every callback
-- | becomes `Maybe (... -> Effect Unit)`. `children` is included for the
-- | underlying div.
type ReactFlowProps n e =
  { -- Children / data inputs
    children :: Maybe JSX
  , nodes :: Maybe (Array (Node n))
  , edges :: Maybe (Array (Edge e))
  , defaultNodes :: Maybe (Array (Node n))
  , defaultEdges :: Maybe (Array (Edge e))
  , defaultEdgeOptions :: Maybe (DefaultEdgeOptions e)
  -- Node mouse events
  , onNodeClick :: Maybe (NodeMouseHandler n)
  , onNodeDoubleClick :: Maybe (NodeMouseHandler n)
  , onNodeMouseEnter :: Maybe (NodeMouseHandler n)
  , onNodeMouseMove :: Maybe (NodeMouseHandler n)
  , onNodeMouseLeave :: Maybe (NodeMouseHandler n)
  , onNodeContextMenu :: Maybe (NodeMouseHandler n)
  , onNodeDragStart :: Maybe (OnNodeDrag n)
  , onNodeDrag :: Maybe (OnNodeDrag n)
  , onNodeDragStop :: Maybe (OnNodeDrag n)
  -- Edge mouse events
  , onEdgeClick :: Maybe (EdgeMouseHandler e)
  , onEdgeContextMenu :: Maybe (EdgeMouseHandler e)
  , onEdgeMouseEnter :: Maybe (EdgeMouseHandler e)
  , onEdgeMouseMove :: Maybe (EdgeMouseHandler e)
  , onEdgeMouseLeave :: Maybe (EdgeMouseHandler e)
  , onEdgeDoubleClick :: Maybe (EdgeMouseHandler e)
  , onReconnect :: Maybe (OnReconnect e)
  , onReconnectStart :: Maybe (MouseEvent -> Edge e -> HandleType -> Effect Unit)
  , onReconnectEnd ::
      Maybe (MouseEvent -> Edge e -> HandleType -> FinalConnectionState (InternalNodeBase n) -> Effect Unit)
  -- State change callbacks
  , onNodesChange :: Maybe (OnNodesChange n)
  , onEdgesChange :: Maybe (OnEdgesChange e)
  , onNodesDelete :: Maybe (OnNodesDelete n)
  , onEdgesDelete :: Maybe (OnEdgesDelete e)
  , onDelete :: Maybe (OnDelete n e)
  -- Selection callbacks
  , onSelectionDragStart :: Maybe (SelectionDragHandler n)
  , onSelectionDrag :: Maybe (SelectionDragHandler n)
  , onSelectionDragStop :: Maybe (SelectionDragHandler n)
  , onSelectionStart :: Maybe (MouseEvent -> Effect Unit)
  , onSelectionEnd :: Maybe (MouseEvent -> Effect Unit)
  , onSelectionContextMenu :: Maybe (MouseEvent -> Array (Node n) -> Effect Unit)
  , onSelectionChange :: Maybe (OnSelectionChangeFunc n e)
  -- Connection callbacks
  , onConnect :: Maybe OnConnect
  , onConnectStart :: Maybe OnConnectStart
  , onConnectEnd :: Maybe (OnConnectEnd n)
  , onClickConnectStart :: Maybe OnConnectStart
  , onClickConnectEnd :: Maybe (OnConnectEnd n)
  -- Init / move
  , onInit :: Maybe (OnInit (ReactFlowInstance n e))
  , onMove :: Maybe OnMove
  , onMoveStart :: Maybe OnMoveStart
  , onMoveEnd :: Maybe OnMoveEnd
  -- Pane handlers
  , onPaneScroll :: Maybe (Maybe WheelEvent -> Effect Unit)
  , onPaneClick :: Maybe (MouseEvent -> Effect Unit)
  , onPaneContextMenu :: Maybe (MouseEvent -> Effect Unit)
  , onPaneMouseEnter :: Maybe (MouseEvent -> Effect Unit)
  , onPaneMouseMove :: Maybe (MouseEvent -> Effect Unit)
  , onPaneMouseLeave :: Maybe (MouseEvent -> Effect Unit)
  , paneClickDistance :: Maybe Number
  , nodeClickDistance :: Maybe Number
  -- Deletion & validation
  , onBeforeDelete :: Maybe (OnBeforeDelete n e)
  , isValidConnection :: Maybe (IsValidConnection e)
  , onError :: Maybe OnError
  -- Node / edge configuration
  , nodeTypes :: Maybe NodeTypesMap
  , edgeTypes :: Maybe EdgeTypesMap
  , connectionLineType :: Maybe ConnectionLineType
  , connectionLineStyle :: Maybe Style
  , connectionLineComponent :: Maybe (ConnectionLineComponentProps n -> JSX)
  , connectionLineContainerStyle :: Maybe Style
  -- Interaction settings
  , connectionMode :: Maybe ConnectionMode
  , deleteKeyCode :: Maybe KeyCode
  , selectionKeyCode :: Maybe KeyCode
  , selectionOnDrag :: Maybe Boolean
  , selectionMode :: Maybe SelectionMode
  , panActivationKeyCode :: Maybe KeyCode
  , multiSelectionKeyCode :: Maybe KeyCode
  , zoomActivationKeyCode :: Maybe KeyCode
  -- Grid / snapping
  , snapToGrid :: Maybe Boolean
  , snapGrid :: Maybe SnapGrid
  -- Performance
  , onlyRenderVisibleElements :: Maybe Boolean
  -- Node interaction
  , nodesDraggable :: Maybe Boolean
  , nodesConnectable :: Maybe Boolean
  , nodesFocusable :: Maybe Boolean
  , nodeDragThreshold :: Maybe Number
  , nodeOrigin :: Maybe NodeOrigin
  , nodeExtent :: Maybe CoordinateExtent
  , autoPanOnNodeFocus :: Maybe Boolean
  , autoPanOnNodeDrag :: Maybe Boolean
  , noDragClassName :: Maybe String
  -- Edge interaction
  , edgesFocusable :: Maybe Boolean
  , edgesReconnectable :: Maybe Boolean
  , reconnectRadius :: Maybe Number
  , connectionDragThreshold :: Maybe Number
  -- Selection
  , elementsSelectable :: Maybe Boolean
  , selectNodesOnDrag :: Maybe Boolean
  -- Elevation
  , elevateNodesOnSelect :: Maybe Boolean
  , elevateEdgesOnSelect :: Maybe Boolean
  -- Pan / zoom
  , panOnDrag :: Maybe PanOnDrag
  , minZoom :: Maybe Number
  , maxZoom :: Maybe Number
  , translateExtent :: Maybe CoordinateExtent
  , zoomOnScroll :: Maybe Boolean
  , zoomOnPinch :: Maybe Boolean
  , zoomOnDoubleClick :: Maybe Boolean
  , panOnScroll :: Maybe Boolean
  , panOnScrollSpeed :: Maybe Number
  , panOnScrollMode :: Maybe PanOnScrollMode
  , preventScrolling :: Maybe Boolean
  -- Viewport
  , viewport :: Maybe Viewport
  , defaultViewport :: Maybe Viewport
  , onViewportChange :: Maybe OnViewportChange
  , fitView :: Maybe Boolean
  , fitViewOptions :: Maybe FitViewOptions
  -- UI
  , defaultMarkerColor :: Maybe String
  , width :: Maybe Number
  , height :: Maybe Number
  , colorMode :: Maybe ColorMode
  , attributionPosition :: Maybe PanelPosition
  , proOptions :: Maybe ProOptions
  , noWheelClassName :: Maybe String
  , noPanClassName :: Maybe String
  -- Accessibility
  , disableKeyboardA11y :: Maybe Boolean
  , ariaLabelConfig :: Maybe AriaLabelConfigOverride
  -- Auto-pan / connect
  , autoPanOnConnect :: Maybe Boolean
  , autoPanSpeed :: Maybe Number
  , autoPanOnSelection :: Maybe Boolean
  , connectOnClick :: Maybe Boolean
  , connectionRadius :: Maybe Number
  -- Debug / z-indexing
  , debug :: Maybe Boolean
  , zIndexMode :: Maybe ZIndexMode
  }

-- The remaining records are scaffolded with the fields the upstream
-- component definitions list. Implementation tickets will validate them.

-- Ticket 034 — `<Handle />` component.
type HandleProps =
  { handleType :: HandleType
  , position :: { x :: Number, y :: Number }
  , id :: Maybe String
  , isConnectable :: Maybe Boolean
  , onConnect :: Maybe OnConnect
  , isValidConnection :: Maybe (IsValidConnection Unit)
  , children :: Maybe JSX
  }

-- Ticket 042 — `<Panel />` (overlay panel positioned relative to viewport).
type PanelProps =
  { position :: PanelPosition
  , children :: Maybe JSX
  }

-- Ticket 044 — `<EdgeLabelRenderer />` portal target.
type EdgeLabelRendererProps =
  { children :: Maybe JSX
  }

-- Ticket 044 — `<ViewportPortal />` portal target.
type ViewportPortalProps =
  { children :: Maybe JSX
  }

-- Ticket 036 — internal connection-line component props.
type ConnectionLineProps n =
  { connectionLineComponent :: Maybe (ConnectionLineComponentProps n -> JSX)
  , connectionLineStyle :: Maybe Style
  , connectionLineType :: Maybe ConnectionLineType
  , connectionLineContainerStyle :: Maybe Style
  }

-- Ticket 045 — `<Background />`.
type BackgroundProps =
  { id :: Maybe String
  , color :: Maybe String
  , bgColor :: Maybe String
  , patternClassName :: Maybe String
  , gap :: Maybe Number
  , size :: Maybe Number
  , offset :: Maybe Number
  , lineWidth :: Maybe Number
  , variant :: Maybe String
  , children :: Maybe JSX
  }

-- Ticket 046 — `<Controls />`.
type ControlsProps =
  { showZoom :: Maybe Boolean
  , showFitView :: Maybe Boolean
  , showInteractive :: Maybe Boolean
  , fitViewOptions :: Maybe FitViewOptions
  , onZoomIn :: Maybe (Effect Unit)
  , onZoomOut :: Maybe (Effect Unit)
  , onFitView :: Maybe (Effect Unit)
  , onInteractiveChange :: Maybe (Boolean -> Effect Unit)
  , position :: Maybe PanelPosition
  , children :: Maybe JSX
  , orientation :: Maybe String
  }

type ControlButtonProps =
  { onClick :: Maybe (Effect Unit)
  , disabled :: Maybe Boolean
  , children :: Maybe JSX
  }

-- Ticket 047 — `<MiniMap />`.
type MiniMapProps n =
  { nodeColor :: Maybe (Node n -> String)
  , nodeStrokeColor :: Maybe (Node n -> String)
  , nodeClassName :: Maybe (Node n -> String)
  , nodeBorderRadius :: Maybe Number
  , nodeStrokeWidth :: Maybe Number
  , maskColor :: Maybe String
  , maskStrokeColor :: Maybe String
  , maskStrokeWidth :: Maybe Number
  , position :: Maybe PanelPosition
  , onClick :: Maybe (MouseEvent -> { x :: Number, y :: Number } -> Effect Unit)
  , onNodeClick :: Maybe (NodeMouseHandler n)
  , pannable :: Maybe Boolean
  , zoomable :: Maybe Boolean
  , ariaLabel :: Maybe String
  , inversePan :: Maybe Boolean
  , zoomStep :: Maybe Number
  , offsetScale :: Maybe Number
  }

-- Ticket 048 — `<NodeToolbar />`.
type NodeToolbarProps =
  { nodeId :: Maybe String
  , isVisible :: Maybe Boolean
  , position :: Maybe { x :: Number, y :: Number }
  , offset :: Maybe Number
  , align :: Maybe String
  , children :: Maybe JSX
  }

-- Ticket 048 — `<NodeResizer />`.
type NodeResizerProps =
  { nodeId :: Maybe String
  , isVisible :: Maybe Boolean
  , color :: Maybe String
  , handleClassName :: Maybe String
  , handleStyle :: Maybe Style
  , lineClassName :: Maybe String
  , lineStyle :: Maybe Style
  , minWidth :: Maybe Number
  , minHeight :: Maybe Number
  , maxWidth :: Maybe Number
  , maxHeight :: Maybe Number
  , keepAspectRatio :: Maybe Boolean
  , shouldResize :: Maybe ({ width :: Number, height :: Number } -> Boolean)
  }

-- Ticket 048 — `<EdgeToolbar />`.
type EdgeToolbarProps =
  { edgeId :: Maybe String
  , isVisible :: Maybe Boolean
  , offset :: Maybe Number
  , children :: Maybe JSX
  }
