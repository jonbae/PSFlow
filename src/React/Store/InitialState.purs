-- | Pure builder for the initial `ReactFlowState`. Mirrors
-- | `xyflow-main/packages/react/src/store/initialState.ts`. Public-API
-- | defaults match the TS source field-for-field.
module React.Store.InitialState
  ( InitialStateOptions
  , defaultInitialStateOptions
  , initialState
  ) where

import Prelude

import Control.Alt ((<|>))
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import React.Types.Edges (Edge)
import React.Types.Nodes (Node)
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
  , mkNodeOrigin
  , mkSnapGrid
  , mkTransform
  )
import System.Utils.Graph (getInternalNodesBounds)
import System.Utils.General (getViewportForBounds, identityTransform)
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

    nodeOrigin = fromMaybe (mkNodeOrigin 0.0 0.0) opts.nodeOrigin
    nodeExtent = fromMaybe infiniteExtent opts.nodeExtent
    minZoom = fromMaybe 0.5 opts.minZoom
    maxZoom = fromMaybe 2.0 opts.maxZoom
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

    fitViewRequested = fromMaybe false opts.fitView && width > 0.0 && height > 0.0

    defaultFitViewPaddingLocal = UniformPadding (RatioPadding 0.1)

    transform :: Transform
    transform =
      if fitViewRequested then
        let
          bounds = getInternalNodesBounds adopted.nodeLookup Nothing
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
    { rfId: "1"
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
    , noPanClassName: "nopan"
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
    , elementsSelectable: true
    , elevateNodesOnSelect: true
    , elevateEdgesOnSelect: false
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
    , onError: Nothing
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
    , onNodesChangeMiddlewareMap: Map.empty
    , onEdgesChangeMiddlewareMap: Map.empty
    }
