-- | The big `ReactFlowState n e` record. Mirrors
-- | `xyflow/packages/react/src/types/store.ts ReactFlowStore` field by
-- | field. The TS `ReactFlowActions` half is *not* embedded here — the
-- | actions live as constructors of `React.Store.Action.Action`. Field
-- | names match the TS source exactly so a reviewer can compare the two
-- | side by side.
module React.Types.Store
  ( ReactFlowState
  , ReactFlowStore
  , MiddlewareKey
  , MiddlewareMap
  , FitViewResolver
  , ConnectionClickStartHandle
  ) where

import Prelude

import Data.Maybe (Maybe)
import React.Types.Edges (DefaultEdgeOptions, Edge)
import React.Types.Nodes (Node)
import React.Types.General
  ( IsValidConnection
  , OnBeforeDelete
  , OnDelete
  , OnEdgesChange
  , OnEdgesDelete
  , OnMove
  , OnMoveEnd
  , OnMoveStart
  , OnNodesChange
  , OnNodesDelete
  , OnSelectionChangeFunc
  , OnViewportChange
  , FitViewOptions
  )
import System.Constants (AriaLabelConfig)
import System.Types.Connection
  ( ConnectionLookup
  , ConnectionMode
  , ConnectionState
  , SelectionRect
  , ZIndexMode
  )
import System.Types.Edge (EdgeChange, EdgeLookup)
import System.Types.Geometry
  ( CoordinateExtent
  , NodeOrigin
  , SnapGrid
  , Transform
  )
import System.Types.Handle (HandleType)
import System.Types.Node
  ( InternalNodeBase
  , NodeChange
  , NodeLookup
  , OnError
  , ParentLookup
  )
import System.Types.PanZoom (PanZoomInstance)
import System.XYDrag (OnNodeDrag, OnSelectionDrag)
import System.XYHandle (OnConnect, OnConnectEnd, OnConnectStart)
import Web.HTML.HTMLDivElement (HTMLDivElement)

-- | The key of one middleware registration: a JavaScript `Symbol`, one per
-- | hook instance, as upstream's `useState(() => Symbol())` makes it.
foreign import data MiddlewareKey :: Type

-- | Upstream's `Map<symbol, (changes) => changes>`: one live, mutable `Map`
-- | per store, which the hooks write into in place and every state shares
-- | until `reset` makes a new one. `React.Store.Middleware` reads and
-- | writes it.
foreign import data MiddlewareMap :: Type -> Type

-- | Upstream's `withResolvers<boolean>()` result, `{ promise, resolve,
-- | reject }`, which a queued `fitView` waits on. Foreign because a consumer
-- | can write its own through `setState`, and the store then calls that
-- | object's `resolve`. `React.Store.FitViewResolver` reads and writes it.
foreign import data FitViewResolver :: Type

-- | TS `Pick<Handle, 'nodeId' | 'id'> & Required<Pick<Handle, 'type'>>`.
-- | Recorded when the user clicks (not drags) a source handle and we are
-- | waiting for the matching click on the target side.
type ConnectionClickStartHandle =
  { nodeId :: String
  , id :: Maybe String
  , handleType :: HandleType
  }

-- | Immutable React-Flow state, polymorphic in the user node data row `n`
-- | and edge data row `e`. The shell owns a single `Ref (ReactFlowState n e)`.
type ReactFlowState n e =
  { rfId :: String
  , width :: Number
  , height :: Number
  , transform :: Transform
  , nodes :: Array (Node n)
  , nodesInitialized :: Boolean
  , nodeLookup :: NodeLookup n
  , parentLookup :: ParentLookup n
  , edges :: Array (Edge e)
  , edgeLookup :: EdgeLookup e
  , connectionLookup :: ConnectionLookup
  , onNodesChange :: Maybe (OnNodesChange n)
  , onEdgesChange :: Maybe (OnEdgesChange e)
  , hasDefaultNodes :: Boolean
  , hasDefaultEdges :: Boolean
  , domNode :: Maybe HTMLDivElement
  , paneDragging :: Boolean
  , noPanClassName :: String
  , panZoom :: Maybe PanZoomInstance
  , minZoom :: Number
  , maxZoom :: Number
  , translateExtent :: CoordinateExtent
  , nodeExtent :: CoordinateExtent
  , nodeOrigin :: NodeOrigin
  , nodeDragThreshold :: Number
  , connectionDragThreshold :: Number
  , nodesSelectionActive :: Boolean
  , userSelectionActive :: Boolean
  , userSelectionRect :: Maybe SelectionRect
  , connection :: ConnectionState (InternalNodeBase n)
  , connectionMode :: ConnectionMode
  , connectionClickStartHandle :: Maybe ConnectionClickStartHandle
  , snapToGrid :: Boolean
  , snapGrid :: SnapGrid
  , nodesDraggable :: Boolean
  , autoPanOnNodeFocus :: Boolean
  , nodesConnectable :: Boolean
  , nodesFocusable :: Boolean
  , edgesFocusable :: Boolean
  , edgesReconnectable :: Boolean
  , elementsSelectable :: Boolean
  , elevateNodesOnSelect :: Boolean
  , elevateEdgesOnSelect :: Boolean
  , selectNodesOnDrag :: Boolean
  , multiSelectionActive :: Boolean
  , onNodeDragStart :: Maybe (OnNodeDrag n)
  , onNodeDrag :: Maybe (OnNodeDrag n)
  , onNodeDragStop :: Maybe (OnNodeDrag n)
  , onSelectionDragStart :: Maybe (OnSelectionDrag n)
  , onSelectionDrag :: Maybe (OnSelectionDrag n)
  , onSelectionDragStop :: Maybe (OnSelectionDrag n)
  , onMoveStart :: Maybe OnMoveStart
  , onMove :: Maybe OnMove
  , onMoveEnd :: Maybe OnMoveEnd
  , onConnect :: Maybe OnConnect
  , onConnectStart :: Maybe OnConnectStart
  , onConnectEnd :: Maybe (OnConnectEnd n)
  , onClickConnectStart :: Maybe OnConnectStart
  , onClickConnectEnd :: Maybe (OnConnectEnd n)
  , connectOnClick :: Boolean
  , defaultEdgeOptions :: Maybe (DefaultEdgeOptions e)
  , fitViewQueued :: Boolean
  , fitViewOptions :: Maybe FitViewOptions
  , fitViewResolver :: Maybe FitViewResolver
  , onNodesDelete :: Maybe (OnNodesDelete n)
  , onEdgesDelete :: Maybe (OnEdgesDelete e)
  , onDelete :: Maybe (OnDelete n e)
  , onError :: Maybe OnError
  , onViewportChangeStart :: Maybe OnViewportChange
  , onViewportChange :: Maybe OnViewportChange
  , onViewportChangeEnd :: Maybe OnViewportChange
  , onBeforeDelete :: Maybe (OnBeforeDelete n e)
  , onSelectionChangeHandlers :: Array (OnSelectionChangeFunc n e)
  , ariaLiveMessage :: String
  , autoPanOnConnect :: Boolean
  , autoPanOnNodeDrag :: Boolean
  , autoPanSpeed :: Number
  , connectionRadius :: Number
  , isValidConnection :: Maybe (IsValidConnection e)
  , lib :: String
  , debug :: Boolean
  , ariaLabelConfig :: AriaLabelConfig
  , zIndexMode :: ZIndexMode
  , onNodesChangeMiddlewareMap :: MiddlewareMap (NodeChange n)
  , onEdgesChangeMiddlewareMap :: MiddlewareMap (EdgeChange e)
  }

-- | TS-name alias for `ReactFlowState`. Upstream splits the store in two —
-- | `ReactFlowStore` (the state) and `ReactFlowActions` (the methods) — and
-- | defines `ReactFlowState = ReactFlowStore & ReactFlowActions`. PS models
-- | the actions half as constructors of `React.Store.Action.Action` rather
-- | than as record fields, so the record above is upstream's `ReactFlowStore`
-- | exactly, and the two upstream names denote the same PS type here.
type ReactFlowStore n e = ReactFlowState n e
