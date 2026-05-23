-- | Public component prop records. The big one is `ReactFlowProps`; the
-- | rest (`HandleProps`, `PanelProps`, etc.) are scaffolded with a
-- | minimal shape so downstream tickets can reference them without
-- | colliding. Each is filled in as its component implementation lands.
module React.Types.Component
  ( ReactFlowProps
  , HandleProps
  , PaneProps
  , PanelProps
  , EdgeLabelRendererProps
  , ViewportPortalProps
  , ViewportProps
  , ZoomPaneProps
  , ConnectionLineProps
  , NodesSelectionProps
  , UserSelectionProps
  , BackgroundProps
  , ControlsProps
  , ControlButtonProps
  , MiniMapProps
  , NodeToolbarProps
  , NodeResizerProps
  , EdgeToolbarProps
  , NodeRendererProps
  , EdgeRendererProps
  , MarkerDefinitionsProps
  , FlowRendererProps
  , GraphViewProps
  , A11yDescriptionsProps
  , AttributionProps
  , ReactFlowProviderProps
  , BatchProviderProps
  , SelectionListenerProps
  , StoreUpdaterProps
  ) where

import Prelude

import Data.Maybe (Maybe)
import Effect (Effect)
import React.Basic (JSX)
import React.Basic.Hooks (ReactChildren)
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
import System.Types.Geometry (CoordinateExtent, NodeOrigin, Position, SnapGrid)
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
    children :: ReactChildren JSX
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
-- |
-- | NB: the TS source allows `children` (the handle can wrap an icon).
-- | We omit it here for the initial port — `reactComponent` from
-- | `react-basic-hooks` requires `Lacks "children"` on the props row,
-- | and bridging through `reactComponentWithChildren` (which wraps
-- | children in `ReactChildren JSX`) would force every call site to
-- | construct a `ReactChildren` wrapper. Add back when a real use case
-- | for handle children appears.
type HandleProps =
  { handleType :: HandleType
  , position :: Position
  , id :: Maybe String
  , isConnectable :: Maybe Boolean
  , isConnectableStart :: Maybe Boolean
  , isConnectableEnd :: Maybe Boolean
  , onConnect :: Maybe OnConnect
  , isValidConnection :: Maybe (IsValidConnection Unit)
  , className :: Maybe String
  , style :: Maybe Style
  }

-- | Ticket 038 — `<Pane />`. The pan/select interaction surface that
-- | hosts nodes, edges, and the user-selection lasso. Widened beyond
-- | the ticket's scaffold to include `selectionKeyPressed`,
-- | `paneClickDistance`, `autoPanOnSelection`, and `selectionOnDrag` so
-- | the rAF auto-pan loop and first-move click-distance threshold can
-- | be driven from the parent (matches upstream TS).
-- |
-- | The component is built via `reactComponentWithChildren`, so
-- | `children` here is `ReactChildren JSX` rather than `Array JSX` —
-- | call sites wrap an array via `reactChildrenFromArray`.
type PaneProps =
  { children :: ReactChildren JSX
  , isSelecting :: Boolean
  , selectionKeyPressed :: Boolean
  , selectionMode :: SelectionMode
  , panOnDrag :: PanOnDrag
  , selectionOnDrag :: Boolean
  , autoPanOnSelection :: Boolean
  , paneClickDistance :: Number
  , onSelectionStart :: Maybe (MouseEvent -> Effect Unit)
  , onSelectionEnd :: Maybe (MouseEvent -> Effect Unit)
  , onPaneClick :: Maybe (MouseEvent -> Effect Unit)
  , onPaneContextMenu :: Maybe (MouseEvent -> Effect Unit)
  , onPaneScroll :: Maybe (WheelEvent -> Effect Unit)
  , onPaneMouseEnter :: Maybe (MouseEvent -> Effect Unit)
  , onPaneMouseMove :: Maybe (MouseEvent -> Effect Unit)
  , onPaneMouseLeave :: Maybe (MouseEvent -> Effect Unit)
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

-- | Ticket 039 — `<Viewport />`. Thin transform container that applies
-- | `state.transform` (`translate(x,y) scale(z)`) so children render in
-- | flow coordinates. Built via `reactComponentWithChildren`, hence
-- | `children :: ReactChildren JSX` (callers wrap an array via
-- | `reactChildrenFromArray`).
type ViewportProps =
  { children :: ReactChildren JSX }

-- | Ticket 039 — `<ZoomPane />`. Wraps the viewport in a pan/zoom
-- | surface backed by `System.XYPanZoom`. The `onMove`/`onMoveStart`/
-- | `onMoveEnd` fields are part of the external contract but read from
-- | the store at fire time (upstream TS lines 79, 84, 89) — the parent
-- | `<ReactFlow />` puts them into the store. `selectionOnDrag` is
-- | added because `PanZoomUpdateOptions.selectionOnDrag` requires a
-- | value at update time.
type ZoomPaneProps =
  { children :: ReactChildren JSX
  , onPaneContextMenu :: Maybe (MouseEvent -> Effect Unit)
  , zoomOnScroll :: Boolean
  , zoomOnPinch :: Boolean
  , zoomOnDoubleClick :: Boolean
  , panOnScroll :: Boolean
  , panOnScrollSpeed :: Number
  , panOnScrollMode :: PanOnScrollMode
  , panOnDrag :: PanOnDrag
  , defaultViewport :: Viewport
  , translateExtent :: CoordinateExtent
  , minZoom :: Number
  , maxZoom :: Number
  , zoomActivationKeyCode :: Maybe KeyCode
  , preventScrolling :: Boolean
  , noWheelClassName :: String
  , noPanClassName :: String
  , onMove :: Maybe OnMove
  , onMoveStart :: Maybe OnMoveStart
  , onMoveEnd :: Maybe OnMoveEnd
  , onViewportChange :: Maybe OnViewportChange
  , isControlledViewport :: Boolean
  , paneClickDistance :: Number
  , selectionOnDrag :: Boolean
  }

-- Ticket 036 — internal connection-line component props.
type ConnectionLineProps n =
  { connectionLineComponent :: Maybe (ConnectionLineComponentProps n -> JSX)
  , connectionLineStyle :: Maybe Style
  , connectionLineType :: Maybe ConnectionLineType
  , connectionLineContainerStyle :: Maybe Style
  }

-- Ticket 037 — `<NodesSelection />` (bounding box around selected nodes,
-- draggable as a group). Mirrors
-- `xyflow-main/packages/react/src/components/NodesSelection/index.tsx
-- NodesSelectionProps`.
type NodesSelectionProps n =
  { onSelectionContextMenu :: Maybe (MouseEvent -> Array (Node n) -> Effect Unit)
  , noPanClassName :: Maybe String
  , disableKeyboardA11y :: Boolean
  }

-- Ticket 037 — `<UserSelection />` (the drag-lasso rectangle). The TS
-- source takes no props; we keep a sentinel field so `reactComponent`'s
-- row-kind constraints have something to chew on without forcing
-- callers through a no-arg type.
type UserSelectionProps =
  { ignored :: Maybe Unit
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

-- | Ticket 040 — `<NodeRenderer />`. Mirrors
-- | `xyflow-main/packages/react/src/container/NodeRenderer/index.tsx
-- | NodeRendererProps`. The shared `ResizeObserver` is allocated inside
-- | the renderer (not threaded in via props) — there is no `resizeObserver`
-- | field on this record, matching TS.
type NodeRendererProps n =
  { onlyRenderVisibleElements :: Boolean
  , noPanClassName :: String
  , noDragClassName :: String
  , rfId :: String
  , disableKeyboardA11y :: Boolean
  , nodeExtent :: Maybe CoordinateExtent
  , nodeTypes :: Maybe NodeTypesMap
  , nodeClickDistance :: Maybe Number
  , onNodeClick :: Maybe (NodeMouseHandler n)
  , onNodeDoubleClick :: Maybe (NodeMouseHandler n)
  , onNodeMouseEnter :: Maybe (NodeMouseHandler n)
  , onNodeMouseMove :: Maybe (NodeMouseHandler n)
  , onNodeMouseLeave :: Maybe (NodeMouseHandler n)
  , onNodeContextMenu :: Maybe (NodeMouseHandler n)
  }

-- | Ticket 040 — `<EdgeRenderer />`. Mirrors
-- | `xyflow-main/packages/react/src/container/EdgeRenderer/index.tsx
-- | EdgeRendererProps`. TS allows an optional `children` slot; PS omits
-- | it for now (no in-tree caller needs it — add back when one appears).
type EdgeRendererProps n e =
  { onlyRenderVisibleElements :: Boolean
  , defaultMarkerColor :: Maybe String
  , rfId :: String
  , noPanClassName :: String
  , disableKeyboardA11y :: Boolean
  , reconnectRadius :: Maybe Number
  , edgeTypes :: Maybe EdgeTypesMap
  , onEdgeClick :: Maybe (EdgeMouseHandler e)
  , onEdgeDoubleClick :: Maybe (EdgeMouseHandler e)
  , onEdgeContextMenu :: Maybe (EdgeMouseHandler e)
  , onEdgeMouseEnter :: Maybe (EdgeMouseHandler e)
  , onEdgeMouseMove :: Maybe (EdgeMouseHandler e)
  , onEdgeMouseLeave :: Maybe (EdgeMouseHandler e)
  , onReconnect :: Maybe (OnReconnect e)
  , onReconnectStart ::
      Maybe (MouseEvent -> Edge e -> HandleType -> Effect Unit)
  , onReconnectEnd ::
      Maybe
        ( MouseEvent
        -> Edge e
        -> HandleType
        -> FinalConnectionState (InternalNodeBase n)
        -> Effect Unit
        )
  }

-- | Ticket 040 — `<MarkerDefinitions />`. Mirrors
-- | `xyflow-main/packages/react/src/container/EdgeRenderer/MarkerDefinitions.tsx`.
type MarkerDefinitionsProps =
  { defaultColor :: Maybe String
  , rfId :: Maybe String
  }

-- | Ticket 040 — `<FlowRenderer />`. Mirrors
-- | `xyflow-main/packages/react/src/container/FlowRenderer/index.tsx
-- | FlowRendererProps`. Structural shell: hosts `ZoomPane` → `Pane` →
-- | user children + `NodesSelection` overlay. Built via
-- | `reactComponentWithChildren`, so `children :: ReactChildren JSX`.
type FlowRendererProps n =
  { children :: ReactChildren JSX
  , isControlledViewport :: Boolean
  -- Pane mouse / scroll
  , onPaneClick :: Maybe (MouseEvent -> Effect Unit)
  , onPaneMouseEnter :: Maybe (MouseEvent -> Effect Unit)
  , onPaneMouseMove :: Maybe (MouseEvent -> Effect Unit)
  , onPaneMouseLeave :: Maybe (MouseEvent -> Effect Unit)
  , onPaneContextMenu :: Maybe (MouseEvent -> Effect Unit)
  , onPaneScroll :: Maybe (WheelEvent -> Effect Unit)
  , paneClickDistance :: Number
  -- Selection
  , deleteKeyCode :: Maybe KeyCode
  , selectionKeyCode :: Maybe KeyCode
  , selectionOnDrag :: Boolean
  , selectionMode :: SelectionMode
  , onSelectionStart :: Maybe (MouseEvent -> Effect Unit)
  , onSelectionEnd :: Maybe (MouseEvent -> Effect Unit)
  , onSelectionContextMenu :: Maybe (MouseEvent -> Array (Node n) -> Effect Unit)
  , multiSelectionKeyCode :: Maybe KeyCode
  , panActivationKeyCode :: Maybe KeyCode
  , zoomActivationKeyCode :: Maybe KeyCode
  , elementsSelectable :: Boolean
  -- Zoom / pan
  , zoomOnScroll :: Boolean
  , zoomOnPinch :: Boolean
  , panOnScroll :: Boolean
  , panOnScrollSpeed :: Number
  , panOnScrollMode :: PanOnScrollMode
  , zoomOnDoubleClick :: Boolean
  , panOnDrag :: PanOnDrag
  , autoPanOnSelection :: Boolean
  -- Viewport
  , defaultViewport :: Viewport
  , translateExtent :: CoordinateExtent
  , minZoom :: Number
  , maxZoom :: Number
  , preventScrolling :: Boolean
  , noWheelClassName :: String
  , noPanClassName :: String
  , disableKeyboardA11y :: Boolean
  , onViewportChange :: Maybe OnViewportChange
  }

-- | Ticket 041 — `<GraphView />`. Pass-through orchestrator that lives
-- | between `<ReactFlow />` and the rendering layer. Mirrors
-- | `xyflow-main/packages/react/src/container/GraphView/index.tsx
-- | GraphViewProps`. The fields that the upstream TS marks `Required<Pick
-- | <…>>` are upgraded from `Maybe X` to `X` here (the parent `<ReactFlow
-- | />` always supplies a default at the seam, see ticket 042).
type GraphViewProps n e =
  { rfId :: String
  -- Required-with-defaults (upgraded from Maybe at the ReactFlow seam):
  , connectionLineType :: ConnectionLineType
  , onlyRenderVisibleElements :: Boolean
  , translateExtent :: CoordinateExtent
  , minZoom :: Number
  , maxZoom :: Number
  , defaultMarkerColor :: String
  , noDragClassName :: String
  , noWheelClassName :: String
  , noPanClassName :: String
  , defaultViewport :: Viewport
  , disableKeyboardA11y :: Boolean
  , paneClickDistance :: Number
  , nodeClickDistance :: Number
  , selectionMode :: SelectionMode
  , selectionOnDrag :: Boolean
  , panOnDrag :: PanOnDrag
  , panOnScroll :: Boolean
  , panOnScrollSpeed :: Number
  , panOnScrollMode :: PanOnScrollMode
  , zoomOnScroll :: Boolean
  , zoomOnPinch :: Boolean
  , zoomOnDoubleClick :: Boolean
  , preventScrolling :: Boolean
  , elementsSelectable :: Boolean
  , autoPanOnSelection :: Boolean
  -- Key codes (Maybe is intentional — null disables the key)
  , selectionKeyCode :: Maybe KeyCode
  , deleteKeyCode :: Maybe KeyCode
  , multiSelectionKeyCode :: Maybe KeyCode
  , panActivationKeyCode :: Maybe KeyCode
  , zoomActivationKeyCode :: Maybe KeyCode
  -- Pass-through fields keep Maybe-ness verbatim
  , onInit :: Maybe (OnInit (ReactFlowInstance n e))
  , viewport :: Maybe Viewport
  , onViewportChange :: Maybe OnViewportChange
  , nodeTypes :: Maybe NodeTypesMap
  , edgeTypes :: Maybe EdgeTypesMap
  , nodeExtent :: Maybe CoordinateExtent
  , connectionLineStyle :: Maybe Style
  , connectionLineComponent :: Maybe (ConnectionLineComponentProps n -> JSX)
  , connectionLineContainerStyle :: Maybe Style
  -- Node mouse events
  , onNodeClick :: Maybe (NodeMouseHandler n)
  , onNodeDoubleClick :: Maybe (NodeMouseHandler n)
  , onNodeMouseEnter :: Maybe (NodeMouseHandler n)
  , onNodeMouseMove :: Maybe (NodeMouseHandler n)
  , onNodeMouseLeave :: Maybe (NodeMouseHandler n)
  , onNodeContextMenu :: Maybe (NodeMouseHandler n)
  -- Edge mouse events
  , onEdgeClick :: Maybe (EdgeMouseHandler e)
  , onEdgeDoubleClick :: Maybe (EdgeMouseHandler e)
  , onEdgeContextMenu :: Maybe (EdgeMouseHandler e)
  , onEdgeMouseEnter :: Maybe (EdgeMouseHandler e)
  , onEdgeMouseMove :: Maybe (EdgeMouseHandler e)
  , onEdgeMouseLeave :: Maybe (EdgeMouseHandler e)
  -- Reconnect
  , onReconnect :: Maybe (OnReconnect e)
  , onReconnectStart :: Maybe (MouseEvent -> Edge e -> HandleType -> Effect Unit)
  , onReconnectEnd ::
      Maybe (MouseEvent -> Edge e -> HandleType -> FinalConnectionState (InternalNodeBase n) -> Effect Unit)
  , reconnectRadius :: Maybe Number
  -- Selection
  , onSelectionContextMenu :: Maybe (MouseEvent -> Array (Node n) -> Effect Unit)
  , onSelectionStart :: Maybe (MouseEvent -> Effect Unit)
  , onSelectionEnd :: Maybe (MouseEvent -> Effect Unit)
  -- Pane events
  , onPaneClick :: Maybe (MouseEvent -> Effect Unit)
  , onPaneMouseEnter :: Maybe (MouseEvent -> Effect Unit)
  , onPaneMouseMove :: Maybe (MouseEvent -> Effect Unit)
  , onPaneMouseLeave :: Maybe (MouseEvent -> Effect Unit)
  , onPaneContextMenu :: Maybe (MouseEvent -> Effect Unit)
  , onPaneScroll :: Maybe (Maybe WheelEvent -> Effect Unit)
  }

-- | Ticket 042 — `<A11yDescriptions />`. Mirrors
-- | `xyflow-main/packages/react/src/components/A11yDescriptions/index.tsx`.
type A11yDescriptionsProps =
  { rfId :: String
  , disableKeyboardA11y :: Boolean
  }

-- | Ticket 042 — `<Attribution />`. Mirrors
-- | `xyflow-main/packages/react/src/components/Attribution/index.tsx`.
type AttributionProps =
  { proOptions :: Maybe ProOptions
  , position :: Maybe PanelPosition
  }

-- | Ticket 043 — `<ReactFlowProvider />`. Mirrors
-- | `xyflow-main/packages/react/src/components/ReactFlowProvider/index.tsx
-- | ReactFlowProviderProps`. Same shape as the consumer-facing prop bundle
-- | upstream: every field is `Maybe`, the provider falls back to the
-- | initial-state defaults. `children` is a `ReactChildren JSX` because the
-- | component is built via `reactComponentWithChildren`.
type ReactFlowProviderProps n e =
  { initialNodes :: Maybe (Array (Node n))
  , initialEdges :: Maybe (Array (Edge e))
  , defaultNodes :: Maybe (Array (Node n))
  , defaultEdges :: Maybe (Array (Edge e))
  , initialWidth :: Maybe Number
  , initialHeight :: Maybe Number
  , fitView :: Maybe Boolean
  , initialFitViewOptions :: Maybe FitViewOptions
  , initialMinZoom :: Maybe Number
  , initialMaxZoom :: Maybe Number
  , nodeOrigin :: Maybe NodeOrigin
  , nodeExtent :: Maybe CoordinateExtent
  , zIndexMode :: Maybe ZIndexMode
  , children :: ReactChildren JSX
  }

-- | Ticket 043 — `<BatchProvider />`. No own props beyond `children`.
type BatchProviderProps =
  { children :: ReactChildren JSX
  }

-- | Ticket 043 — `<SelectionListener />`. Receives the user-supplied
-- | callback; the component also reads `state.onSelectionChangeHandlers`
-- | (set by the `useOnSelectionChange` hook from ticket 029) at fire time.
type SelectionListenerProps n e =
  { onSelectionChange :: Maybe (OnSelectionChangeFunc n e)
  }

-- | Ticket 043 — `<StoreUpdater />`. Mirrors the TS `reactFlowFieldsToTrack`
-- | list at `xyflow-main/packages/react/src/components/StoreUpdater/index.tsx`
-- | (lines 15-74) plus `rfId`. Each field is `Maybe X` because every
-- | `ReactFlowProps` field on the upstream consumer side is optional, and
-- | the StoreUpdater dispatches only when the prop is `Just`.
type StoreUpdaterProps n e =
  { rfId :: String
  , nodes :: Maybe (Array (Node n))
  , edges :: Maybe (Array (Edge e))
  , defaultNodes :: Maybe (Array (Node n))
  , defaultEdges :: Maybe (Array (Edge e))
  , onConnect :: Maybe OnConnect
  , onConnectStart :: Maybe OnConnectStart
  , onConnectEnd :: Maybe (OnConnectEnd n)
  , onClickConnectStart :: Maybe OnConnectStart
  , onClickConnectEnd :: Maybe (OnConnectEnd n)
  , nodesDraggable :: Maybe Boolean
  , autoPanOnNodeFocus :: Maybe Boolean
  , nodesConnectable :: Maybe Boolean
  , nodesFocusable :: Maybe Boolean
  , edgesFocusable :: Maybe Boolean
  , edgesReconnectable :: Maybe Boolean
  , elevateNodesOnSelect :: Maybe Boolean
  , elevateEdgesOnSelect :: Maybe Boolean
  , minZoom :: Maybe Number
  , maxZoom :: Maybe Number
  , nodeExtent :: Maybe CoordinateExtent
  , onNodesChange :: Maybe (OnNodesChange n)
  , onEdgesChange :: Maybe (OnEdgesChange e)
  , elementsSelectable :: Maybe Boolean
  , connectionMode :: Maybe ConnectionMode
  , snapGrid :: Maybe SnapGrid
  , snapToGrid :: Maybe Boolean
  , translateExtent :: Maybe CoordinateExtent
  , connectOnClick :: Maybe Boolean
  , defaultEdgeOptions :: Maybe (DefaultEdgeOptions e)
  , fitView :: Maybe Boolean
  , fitViewOptions :: Maybe FitViewOptions
  , onNodesDelete :: Maybe (OnNodesDelete n)
  , onEdgesDelete :: Maybe (OnEdgesDelete e)
  , onDelete :: Maybe (OnDelete n e)
  , onNodeDrag :: Maybe (OnNodeDrag n)
  , onNodeDragStart :: Maybe (OnNodeDrag n)
  , onNodeDragStop :: Maybe (OnNodeDrag n)
  , onSelectionDrag :: Maybe (SelectionDragHandler n)
  , onSelectionDragStart :: Maybe (SelectionDragHandler n)
  , onSelectionDragStop :: Maybe (SelectionDragHandler n)
  , onMoveStart :: Maybe OnMoveStart
  , onMove :: Maybe OnMove
  , onMoveEnd :: Maybe OnMoveEnd
  , noPanClassName :: Maybe String
  , nodeOrigin :: Maybe NodeOrigin
  , autoPanOnConnect :: Maybe Boolean
  , autoPanOnNodeDrag :: Maybe Boolean
  , onError :: Maybe OnError
  , connectionRadius :: Maybe Number
  , isValidConnection :: Maybe (IsValidConnection e)
  , selectNodesOnDrag :: Maybe Boolean
  , nodeDragThreshold :: Maybe Number
  , connectionDragThreshold :: Maybe Number
  , onBeforeDelete :: Maybe (OnBeforeDelete n e)
  , debug :: Maybe Boolean
  , autoPanSpeed :: Maybe Number
  , ariaLabelConfig :: Maybe AriaLabelConfigOverride
  , zIndexMode :: Maybe ZIndexMode
  }
