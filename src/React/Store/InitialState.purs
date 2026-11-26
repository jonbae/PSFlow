-- | Pure builder for the initial `ReactFlowState`. Mirrors
-- | `xyflow/packages/react/src/store/initialState.ts`. Public-API
-- | defaults match the TS source field-for-field.
-- |
-- | The seven that `<ReactFlow />` also resolves, and that `<StoreUpdater />`
-- | seeds its previous values with, are read from
-- | `React.Container.InitValues` rather than written here. That module says
-- | why the three copies upstream keeps have to be one here.
module React.Store.InitialState
  ( InitialStateOptions
  , defaultInitialStateOptions
  , defaultOnError
  , initialState
  , initialStateKeys
  , resetState
  ) where

import Prelude

import Control.Alt ((<|>))
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Number (isNaN)
import React.Container.InitValues
  ( defaultElementsSelectable
  , defaultMaxZoom
  , defaultMinZoom
  , defaultNoPanClassName
  , defaultNodeOrigin
  , defaultRfId
  )
import React.Types.Edges (Edge)
import React.Types.Nodes (Node)
import React.FFI.Env (isDevelopment)
import React.Store.Middleware (freshMiddlewareMap)
import React.Types.Store (ReactFlowState)
import React.Types.General (FitViewOptions)
import System.Constants (defaultAriaLabelConfig, infiniteExtent)
import System.Types.Connection
  ( ConnectionMode(..)
  , Padding(..)
  , PaddingValue(..)
  , ZIndexMode(..)
  , noConnection
  )
import System.Types.Geometry
  ( CoordinateExtent
  , NodeOrigin
  , Transform
  , mkSnapGrid
  , mkTransform
  )
import System.Types.Node (OnError)
import System.Utils.Graph (getInternalNodesBounds)
import System.Utils.General (devWarn, getViewportForBounds, identityTransform)
import System.Utils.Store (adoptUserNodes, defaultUpdateNodesOptions, updateConnectionLookup)

-- | Caller-controllable knobs. Everything else takes a hard-coded
-- | default matching the TS source.
type InitialStateOptions n e =
  { nodes :: Maybe (Array (Node n))
  , edges :: Maybe (Array (Edge e))
  , defaultNodes :: Maybe (Array (Node n))
  , defaultEdges :: Maybe (Array (Edge e))
  , width :: Maybe Number
  , height :: Maybe Number
  , fitView :: Maybe Boolean
  , fitViewOptions :: Maybe FitViewOptions
  , minZoom :: Maybe Number
  , maxZoom :: Maybe Number
  , nodeOrigin :: Maybe NodeOrigin
  , nodeExtent :: Maybe CoordinateExtent
  , zIndexMode :: Maybe ZIndexMode
  }

defaultInitialStateOptions :: forall n e. InitialStateOptions n e
defaultInitialStateOptions =
  { nodes: Nothing
  , edges: Nothing
  , defaultNodes: Nothing
  , defaultEdges: Nothing
  , width: Nothing
  , height: Nothing
  , fitView: Nothing
  , fitViewOptions: Nothing
  , minZoom: Nothing
  , maxZoom: Nothing
  , nodeOrigin: Nothing
  , nodeExtent: Nothing
  , zIndexMode: Nothing
  }

-- | A size JavaScript reads as true: present, not zero and not `NaN`.
truthy :: Maybe Number -> Boolean
truthy = case _ of
  Just n -> n /= 0.0 && not (isNaN n)
  Nothing -> false

-- | Build the initial `ReactFlowState`. Pure — every helper called here
-- | (`adoptUserNodes`, `updateConnectionLookup`, `getInternalNodesBounds`,
-- | `getViewportForBounds`) is pure after ticket 022a.
initialState :: forall n e. InitialStateOptions n e -> ReactFlowState n e
initialState opts =
  let
    -- Pick controlled-or-default nodes/edges, matching TS:
    --   nodes: defaultNodes ?? nodes ?? []
    nodes = fromMaybe [] (opts.defaultNodes <|> opts.nodes)
    edges = fromMaybe [] (opts.defaultEdges <|> opts.edges)

    nodeOrigin = fromMaybe defaultNodeOrigin opts.nodeOrigin
    nodeExtent = fromMaybe infiniteExtent opts.nodeExtent
    minZoom = fromMaybe defaultMinZoom opts.minZoom
    maxZoom = fromMaybe defaultMaxZoom opts.maxZoom
    zIndexMode = fromMaybe ZBasic opts.zIndexMode
    width = fromMaybe 0.0 opts.width
    height = fromMaybe 0.0 opts.height

    connRes = updateConnectionLookup edges

    adoptOpts = defaultUpdateNodesOptions
      { nodeOrigin = nodeOrigin
      , nodeExtent = nodeExtent
      , zIndexMode = zIndexMode
      }
    adopted = adoptUserNodes nodes Map.empty Map.empty adoptOpts

    -- Upstream's `fitView && width && height`, which reads a negative
    -- size as true and a `NaN` one as false.
    fitViewRequested = fromMaybe false opts.fitView && truthy opts.width && truthy opts.height

    defaultFitViewPaddingLocal = UniformPadding (RatioPadding 0.1)

    transform :: Transform
    transform =
      if fitViewRequested then
        let
          -- Upstream fits only the nodes whose own sizes are truthy. A
          -- `measured` size doesn't count.
          bounds = getInternalNodesBounds adopted.nodeLookup
            ( Just \n ->
                (truthy n.width || truthy n.initialWidth)
                  && (truthy n.height || truthy n.initialHeight)
            )
          padding = case opts.fitViewOptions of
            Just fvo -> fromMaybe defaultFitViewPaddingLocal fvo.padding
            Nothing -> defaultFitViewPaddingLocal
          mz = case opts.fitViewOptions of
            Just fvo -> fromMaybe minZoom fvo.minZoom
            Nothing -> minZoom
          xz = case opts.fitViewOptions of
            Just fvo -> fromMaybe maxZoom fvo.maxZoom
            Nothing -> maxZoom
          viewport = getViewportForBounds bounds width height mz xz padding
        in
          mkTransform viewport.x viewport.y viewport.zoom
      else identityTransform
  in
    { rfId: defaultRfId
    , width
    , height
    , transform
    , nodes
    , nodesInitialized: adopted.nodesInitialized
    , nodeLookup: adopted.nodeLookup
    , parentLookup: adopted.parentLookup
    , edges
    , edgeLookup: connRes.edgeLookup
    , connectionLookup: connRes.connectionLookup
    , onNodesChange: Nothing
    , onEdgesChange: Nothing
    , hasDefaultNodes: case opts.defaultNodes of
        Just _ -> true
        Nothing -> false
    , hasDefaultEdges: case opts.defaultEdges of
        Just _ -> true
        Nothing -> false
    , domNode: Nothing
    , paneDragging: false
    , noPanClassName: defaultNoPanClassName
    , panZoom: Nothing
    , minZoom
    , maxZoom
    , translateExtent: infiniteExtent
    , nodeExtent
    , nodeOrigin
    , nodeDragThreshold: 1.0
    , connectionDragThreshold: 1.0
    , nodesSelectionActive: false
    , userSelectionActive: false
    , userSelectionRect: Nothing
    , connection: noConnection
    , connectionMode: Strict
    , connectionClickStartHandle: Nothing
    , snapToGrid: false
    , snapGrid: mkSnapGrid 15.0 15.0
    , nodesDraggable: true
    , autoPanOnNodeFocus: true
    , nodesConnectable: true
    , nodesFocusable: true
    , edgesFocusable: true
    , edgesReconnectable: true
    , elementsSelectable: defaultElementsSelectable
    , elevateNodesOnSelect: true
    -- Upstream's initial state holds `true`, and `<ReactFlow />`'s own
    -- default of `false` reaches the store through `StoreUpdater` on mount.
    , elevateEdgesOnSelect: true
    , selectNodesOnDrag: true
    , multiSelectionActive: false
    , onNodeDragStart: Nothing
    , onNodeDrag: Nothing
    , onNodeDragStop: Nothing
    , onSelectionDragStart: Nothing
    , onSelectionDrag: Nothing
    , onSelectionDragStop: Nothing
    , onMoveStart: Nothing
    , onMove: Nothing
    , onMoveEnd: Nothing
    , onConnect: Nothing
    , onConnectStart: Nothing
    , onConnectEnd: Nothing
    , onClickConnectStart: Nothing
    , onClickConnectEnd: Nothing
    , connectOnClick: true
    , defaultEdgeOptions: Nothing
    , fitViewQueued: fromMaybe false opts.fitView
    , fitViewOptions: opts.fitViewOptions
    , fitViewResolver: Nothing
    , onNodesDelete: Nothing
    , onEdgesDelete: Nothing
    , onDelete: Nothing
    , onError: Just defaultOnError
    , onViewportChangeStart: Nothing
    , onViewportChange: Nothing
    , onViewportChangeEnd: Nothing
    , onBeforeDelete: Nothing
    , onSelectionChangeHandlers: []
    , ariaLiveMessage: ""
    , autoPanOnConnect: true
    , autoPanOnNodeDrag: true
    , autoPanSpeed: 15.0
    , connectionRadius: 20.0
    , isValidConnection: Nothing
    , lib: "react"
    , debug: false
    , ariaLabelConfig: defaultAriaLabelConfig
    , zIndexMode
    , onNodesChangeMiddlewareMap: freshMiddlewareMap unit
    , onEdgesChangeMiddlewareMap: freshMiddlewareMap unit
    }

-- | The members `getInitialState` names, in the order it names them, which
-- | is the order upstream's `createStore` lays them out and `reset` writes
-- | them.
initialStateKeys :: Array String
initialStateKeys =
  [ "rfId", "width", "height", "transform", "nodes", "nodesInitialized", "nodeLookup"
  , "parentLookup", "edges", "edgeLookup", "connectionLookup", "onNodesChange"
  , "onEdgesChange", "hasDefaultNodes", "hasDefaultEdges", "panZoom", "minZoom"
  , "maxZoom", "translateExtent", "nodeExtent", "nodesSelectionActive"
  , "userSelectionActive", "userSelectionRect", "connectionMode", "domNode"
  , "paneDragging", "noPanClassName", "nodeOrigin", "nodeDragThreshold"
  , "connectionDragThreshold", "snapGrid", "snapToGrid", "nodesDraggable"
  , "nodesConnectable", "nodesFocusable", "edgesFocusable", "edgesReconnectable"
  , "elementsSelectable", "elevateNodesOnSelect", "elevateEdgesOnSelect"
  , "selectNodesOnDrag", "multiSelectionActive", "fitViewQueued", "fitViewOptions"
  , "fitViewResolver", "connection", "connectionClickStartHandle", "connectOnClick"
  , "ariaLiveMessage", "autoPanOnConnect", "autoPanOnNodeDrag", "autoPanOnNodeFocus"
  , "autoPanSpeed", "connectionRadius", "onError", "isValidConnection"
  , "onSelectionChangeHandlers", "lib", "debug", "ariaLabelConfig", "zIndexMode"
  , "onNodesChangeMiddlewareMap", "onEdgesChangeMiddlewareMap"
  ]

-- | Upstream's `reset`, `set({ ...getInitialState() })`. The `set` merges, so
-- | every member the initial state names goes back to its initial value and
-- | the 22 it does not name, the callbacks `StoreUpdater` adds beside it and
-- | `defaultEdgeOptions`, keep theirs.
resetState :: forall n e. ReactFlowState n e -> ReactFlowState n e
resetState s = (initialState defaultInitialStateOptions)
  { onNodeDragStart = s.onNodeDragStart
  , onNodeDrag = s.onNodeDrag
  , onNodeDragStop = s.onNodeDragStop
  , onSelectionDragStart = s.onSelectionDragStart
  , onSelectionDrag = s.onSelectionDrag
  , onSelectionDragStop = s.onSelectionDragStop
  , onMoveStart = s.onMoveStart
  , onMove = s.onMove
  , onMoveEnd = s.onMoveEnd
  , onConnect = s.onConnect
  , onConnectStart = s.onConnectStart
  , onConnectEnd = s.onConnectEnd
  , onClickConnectStart = s.onClickConnectStart
  , onClickConnectEnd = s.onClickConnectEnd
  , defaultEdgeOptions = s.defaultEdgeOptions
  , onNodesDelete = s.onNodesDelete
  , onEdgesDelete = s.onEdgesDelete
  , onDelete = s.onDelete
  , onViewportChangeStart = s.onViewportChangeStart
  , onViewportChange = s.onViewportChange
  , onViewportChangeEnd = s.onViewportChangeEnd
  , onBeforeDelete = s.onBeforeDelete
  }

-- | Upstream's initial `onError`, `devWarn`: in development it writes
-- | `[React Flow]: <message> Help: https://reactflow.dev/error#<id>` with
-- | `console.warn`, so an error a consumer handles nowhere still shows. One
-- | value, so that the store's JavaScript view can recognise it and hand out
-- | upstream's function in its place.
defaultOnError :: OnError
defaultOnError = devWarn isDevelopment
