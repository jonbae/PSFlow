-- | The **PureScript surface** of `ps-flow`. Mirrors
-- | `xyflow/packages/react/src/index.ts` one-for-one — every TS symbol
-- | the upstream package exports is re-surfaced here (modulo PS-idiom
-- | translations called out below).
-- |
-- | Two consumer audiences, and they no longer come through the same door:
-- |
-- |   * **PureScript users** import from this module. PS values must start
-- |     with a lowercase letter (grammar), so component names are
-- |     `reactFlow`, `miniMap`, `handle`, …; type names stay PascalCase.
-- |     Types and values are in separate namespaces, so the TS `Handle as
-- |     HandleBound` workaround is unnecessary.
-- |
-- |   * **JavaScript users** come through `index.js`, which is a bare
-- |     re-export of the **boundary module** (`Boundary`) rather than of
-- |     this one. That module re-exports everything below and crosses it
-- |     into JS-native shapes stage by stage. Nothing here knows it
-- |     exists, and nothing here changes to serve it.
-- |
-- | **Documented divergences from TS:**
-- |
-- |   1. Value-level identifiers are camelCase (PS grammar). `index.js`
-- |      restores TS-identical PascalCase names for JavaScript consumers.
-- |   2. `useConnection` is split into `useConnection` (no-arg) and
-- |      `useConnectionWith` (selector + Eq instance). The TS overload-set
-- |      maps cleanly onto two PS functions.
-- |   3. `useNodesState` / `useEdgesState` are thin wrappers over the
-- |      internal `useNodesEdgesState` hook (see
-- |      `React.Hook.NodesEdgesState`). Each returns the PS record shape
-- |      `{ nodes/edges, set…, on…Change }` — the TS 3-tuple translated.
-- |   4. `ConnectionInProgress` is exported as a type alias of
-- |      `ConnectionInProgressData` (the canonical PS name). `NoConnection`
-- |      is the nullary constructor of `ConnectionState`, not a standalone
-- |      type — there is no payload to alias, so an alias would be
-- |      misleading. Consumers pattern-match on `ConnectionState(..)` or
-- |      use the `noConnection` helper. This is intentional and final.
module React
  ( module ReExportComponents
  , module ReExportProvider
  , module ReExportHandle
  , module ReExportEdgeBase
  , module ReExportEdgeStraight
  , module ReExportEdgeBezier
  , module ReExportEdgeSimpleBezier
  , module ReExportEdgeStep
  , module ReExportEdgeSmoothStep
  , module ReExportEdgeText
  , module ReExportPanel
  , module ReExportEdgeLabelRenderer
  , module ReExportViewportPortal
  , module ReExportHookReactFlow
  , module ReExportHookStore
  , module ReExportHookSelectors
  , module ReExportHookNodesEdgesState
  , module ReExportHookKeyPress
  , module ReExportHookListeners
  , module ReExportHookMiddleware
  , module ReExportHookUpdateNodeInternals
  , module ReExportHookHandleConnections
  , module ReExportHookNodeConnections
  , module ReExportContextNodeId
  , module ReExportUtilGeneral
  , module ReExportStoreChanges
  , module ReExportAdditionalBackground
  , module ReExportAdditionalControls
  , module ReExportAdditionalControlsButton
  , module ReExportAdditionalMiniMap
  , module ReExportAdditionalNodeToolbar
  , module ReExportAdditionalNodeResizer
  , module ReExportAdditionalNodeResizerControl
  , module ReExportAdditionalEdgeToolbar
  , module ReExportReactTypes
  , module ReExportSystemGeometry
  , module ReExportSystemConnection
  , module ReExportSystemEdge
  , module ReExportSystemNode
  , module ReExportSystemHandle
  , module ReExportSystemConstants
  , module ReExportSystemXYDrag
  , module ReExportSystemXYHandle
  , module ReExportSystemXYResizer
  , module ReExportSystemUtilsGeneral
  , module ReExportSystemUtilsGraph
  , module ReExportSystemUtilsEdgesGeneral
  , module ReExportSystemUtilsEdgesBezier
  , module ReExportSystemUtilsEdgesStraight
  , module ReExportSystemUtilsEdgesSmoothStep
  , module ReExportSystemUtilsEdgesSimpleBezier
  , experimental_useOnNodesChangeMiddleware
  , experimental_useOnEdgesChangeMiddleware
  ) where

import Prelude

import React.Basic.Hooks (Hook)
import React.Hook.Middleware (UseMiddlewareHook, useOnNodesChangeMiddleware, useOnEdgesChangeMiddleware)
import System.Types.Edge (EdgeChange)
import System.Types.Node (NodeChange)

-- ────────────────────────────────────────────────────────────────────────
-- Components
-- ────────────────────────────────────────────────────────────────────────

import React.Container.ReactFlow (reactFlow, reactFlowWithRef) as ReExportComponents
import React.Provider (reactFlowProvider) as ReExportProvider
import React.Handle (handle) as ReExportHandle

-- Built-in edges
import React.Edge.Base (baseEdge) as ReExportEdgeBase
import React.Edge.Straight (straightEdge) as ReExportEdgeStraight
import React.Edge.Bezier (bezierEdge) as ReExportEdgeBezier
import React.Edge.SimpleBezier (simpleBezierEdge) as ReExportEdgeSimpleBezier
import React.Edge.Step (stepEdge) as ReExportEdgeStep
import React.Edge.SmoothStep (smoothStepEdge) as ReExportEdgeSmoothStep
import React.Edge.Text (edgeText) as ReExportEdgeText

-- Portals
import React.Portal.Panel (panel) as ReExportPanel
import React.Portal.EdgeLabelRenderer (edgeLabelRenderer) as ReExportEdgeLabelRenderer
import React.Portal.ViewportPortal (viewportPortal) as ReExportViewportPortal

-- ────────────────────────────────────────────────────────────────────────
-- Hooks
-- ────────────────────────────────────────────────────────────────────────

import React.Hook.ReactFlow (useReactFlow) as ReExportHookReactFlow
import React.Hook.Store (useStore, useStoreApi) as ReExportHookStore
import React.Hook.Selectors
  ( UseNodesInitializedOptions
  , useNodes
  , useEdges
  , useViewport
  , useConnection
  , useConnectionWith
  , useNodesData
  , useInternalNode
  , useNodesInitialized
  ) as ReExportHookSelectors
import React.Hook.NodesEdgesState
  ( NodesEdgesState
  , NodesStateBundle
  , EdgesStateBundle
  , useNodesEdgesState
  , useNodesState
  , useEdgesState
  ) as ReExportHookNodesEdgesState
import React.Hook.KeyPress (UseKeyPressOptions, KeyMatcher, useKeyPress) as ReExportHookKeyPress
import React.Hook.Listeners
  ( UseOnViewportChangeOptions
  , UseOnSelectionChangeOptions
  , useOnViewportChange
  , useOnSelectionChange
  ) as ReExportHookListeners
import React.Hook.Middleware (useOnNodesChangeMiddleware, useOnEdgesChangeMiddleware) as ReExportHookMiddleware
import React.Hook.UpdateNodeInternals (useUpdateNodeInternals) as ReExportHookUpdateNodeInternals
import React.Hook.HandleConnections (useHandleConnections) as ReExportHookHandleConnections
import React.Hook.NodeConnections (useNodeConnections) as ReExportHookNodeConnections
import React.Context.NodeId (useNodeId) as ReExportContextNodeId

-- ────────────────────────────────────────────────────────────────────────
-- Utilities
-- ────────────────────────────────────────────────────────────────────────

import React.Util.General (isNode, isEdge) as ReExportUtilGeneral
import React.Store.Changes (applyNodeChanges, applyEdgeChanges) as ReExportStoreChanges

-- ────────────────────────────────────────────────────────────────────────
-- Additional components
-- ────────────────────────────────────────────────────────────────────────

import React.Additional.Background (background) as ReExportAdditionalBackground
import React.Additional.Controls (controls) as ReExportAdditionalControls
import React.Additional.Controls.Button (controlButton) as ReExportAdditionalControlsButton
import React.Additional.MiniMap (miniMap) as ReExportAdditionalMiniMap
import React.Additional.NodeToolbar (nodeToolbar) as ReExportAdditionalNodeToolbar
import React.Additional.NodeResizer (nodeResizer) as ReExportAdditionalNodeResizer
import React.Additional.NodeResizer.Control (nodeResizeControl) as ReExportAdditionalNodeResizerControl
import React.Additional.EdgeToolbar (edgeToolbar) as ReExportAdditionalEdgeToolbar

-- ────────────────────────────────────────────────────────────────────────
-- React-layer types (covers `export * from './types'`)
-- ────────────────────────────────────────────────────────────────────────

import React.Types
  ( BackgroundProps
  , ConnectionLineProps
  , ControlButtonProps
  , ControlsProps
  , EdgeLabelRendererProps
  , EdgeToolbarProps
  , HandleProps
  , MiniMapProps
  , NodeResizerProps
  , NodeToolbarProps
  , PanelProps
  , ReactFlowProps
  , ViewportPortalProps
  , BaseEdgeProps
  , BezierEdgeProps
  , ConnectionLineComponentProps
  , ConnectionStatus(..)
  , DefaultEdgeOptions
  , Edge
  , EdgeComponentProps
  , EdgeLabelOptions
  , EdgeMouseHandler
  , EdgeProps
  , EdgeTextProps
  , EdgeTypesMap
  , EdgeWrapperProps
  , OnReconnect
  , ReconnectHandleType(..)
  , SimpleBezierEdgeProps
  , SmoothStepEdgeProps
  , StepEdgeProps
  , StraightEdgeProps
  , Style
  , FitView
  , FitViewOptions
  , FlowExportObject
  , IsValidConnection
  , OnBeforeDelete
  , OnBeforeDeleteResult
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
  , OnSelectionChangeParams
  , OnViewportChange
  , ProOptions
  , UnselectNodesAndEdgesParams
  , DeleteElementsOptions
  , NodeOrIdOrRect(..)
  , NodeRefForBounds(..)
  , ReactFlowInstance
  , ReactFlowJsonObject
  , ScreenToFlowOptions
  , UpdateOptions
  , ViewportHelperFunctions
  , ZoomOptions
  , SetCenter
  , SetViewport
  , FitBounds
  , InternalNode
  , Node
  , NodeMouseHandler
  , NodeTypesMap
  , NodeWrapperProps
  , OnNodeDrag
  , ResizeObserver
  , SelectionDragHandler
  , ConnectionClickStartHandle
  , MiddlewareKey(..)
  , ReactFlowState
  ) as ReExportReactTypes

-- ────────────────────────────────────────────────────────────────────────
-- System re-exports (mirroring TS lines 43-143 of index.ts)
-- ────────────────────────────────────────────────────────────────────────

import System.Types.Geometry
  ( XYPosition
  , XYZPosition
  , Dimensions
  , Rect
  , Box
  , Transform(..)
  , CoordinateExtent(..)
  , NodeOrigin(..)
  , SnapGrid(..)
  , Position(..)
  ) as ReExportSystemGeometry

import System.Types.Connection
  ( Connection
  , HandleConnection
  , NodeConnection
  , Viewport
  , SelectionRect
  , ConnectionMode(..)
  , PanOnScrollMode(..)
  , SelectionMode(..)
  , PanelPosition(..)
  , ColorModeClass(..)
  , ColorMode(..)
  , ZIndexMode(..)
  , KeyCode(..)
  , ViewportHelperFunctionOptions
  , SetCenterOptions
  , FitBoundsOptions
  , ConnectionState(..)
  , ConnectionInProgressData
  , ConnectionInProgress
  , FinalConnectionState
  ) as ReExportSystemConnection

import System.Types.Edge
  ( ConnectionLineType(..)
  , MarkerType(..)
  , EdgeMarker
  , EdgeMarkerType(..)
  , SmoothStepPathOptions
  , BezierPathOptions
  , EdgeChange(..)
  ) as ReExportSystemEdge

import System.Types.Node
  ( Align(..)
  , NodeChange(..)
  , OnError
  ) as ReExportSystemNode

import System.Types.Handle (HandleType(..), Handle) as ReExportSystemHandle

import System.Constants (AriaLabelConfig) as ReExportSystemConstants

import System.XYDrag (OnSelectionDrag) as ReExportSystemXYDrag

import System.XYHandle
  ( OnConnect
  , OnConnectStart
  , OnConnectStartParams
  , OnConnectEnd
  , OnReconnectEnd
  ) as ReExportSystemXYHandle

import System.XYResizer
  ( ControlPosition(..)
  , ControlLinePosition(..)
  , ResizeControlVariant(..)
  , ResizeParams
  , ResizeParamsWithDirection
  , ResizeDragEvent(..)
  , ShouldResize
  , OnResize
  , OnResizeStart
  , OnResizeEnd
  ) as ReExportSystemXYResizer

import System.Utils.General (getViewportForBounds) as ReExportSystemUtilsGeneral

import System.Utils.Graph
  ( getNodesBounds
  , getIncomers
  , getOutgoers
  , getConnectedEdges
  ) as ReExportSystemUtilsGraph

import System.Utils.Edges.General
  ( getEdgeCenter
  , addEdge
  , reconnectEdge
  ) as ReExportSystemUtilsEdgesGeneral

import System.Utils.Edges.Bezier
  ( getBezierEdgeCenter
  , getBezierPath
  ) as ReExportSystemUtilsEdgesBezier

import System.Utils.Edges.Straight (getStraightPath) as ReExportSystemUtilsEdgesStraight

import System.Utils.Edges.SmoothStep (getSmoothStepPath) as ReExportSystemUtilsEdgesSmoothStep

import System.Utils.Edges.SimpleBezier (getSimpleBezierPath) as ReExportSystemUtilsEdgesSimpleBezier

-- ────────────────────────────────────────────────────────────────────────
-- TS-name-compat aliases
--
-- TS exports `experimental_useOnNodesChangeMiddleware`; PS dropped the
-- prefix when porting. These two aliases keep the TS name reachable from
-- the public surface so the API contract is satisfied byte-for-byte.
-- ────────────────────────────────────────────────────────────────────────

experimental_useOnNodesChangeMiddleware
  :: forall n
   . (Array (NodeChange n) -> Array (NodeChange n))
  -> Hook
       (UseMiddlewareHook (Array (NodeChange n) -> Array (NodeChange n)))
       Unit
experimental_useOnNodesChangeMiddleware = useOnNodesChangeMiddleware

experimental_useOnEdgesChangeMiddleware
  :: forall e
   . (Array (EdgeChange e) -> Array (EdgeChange e))
  -> Hook
       (UseMiddlewareHook (Array (EdgeChange e) -> Array (EdgeChange e)))
       Unit
experimental_useOnEdgesChangeMiddleware = useOnEdgesChangeMiddleware
