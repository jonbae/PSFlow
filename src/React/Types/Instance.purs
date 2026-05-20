-- | `ReactFlowInstance` — the rich object the hook `useReactFlow` returns
-- | and that `onInit` callbacks receive. A record of `Effect`/`Aff`-typed
-- | methods plus viewport helpers.
-- |
-- | **Return-type discipline.** Methods that animate (zoom/pan/fit) return
-- | `Aff Boolean` — they resolve `true` when the animation completes, or
-- | `false` when the underlying `panZoom` instance isn't available yet
-- | (matches upstream's `Promise<boolean>`). Methods that simply read or
-- | mutate state return `Effect _`. The split mirrors
-- | `xyflow-main/packages/react/src/hooks/useViewportHelper.ts`.
module React.Types.Instance
  ( ReactFlowInstance
  , ReactFlowJsonObject
  , DeleteElementsOptions
  , ViewportHelperFunctions
  , NodeOrIdOrRect(..)
  , NodeRefForBounds(..)
  , UpdateOptions
  , ZoomOptions
  , FitBoundsOptions
  , ScreenToFlowOptions
  ) where

import Prelude

import Data.Either (Either)
import Data.Maybe (Maybe)
import Effect (Effect)
import Effect.Aff (Aff)
import React.Types.Edges (Edge)
import React.Types.General (FitView)
import React.Types.Nodes (InternalNode, Node)
import System.Types.Connection
  ( HandleConnection
  , InterpolateMode
  , NodeConnection
  , SetCenterOptions
  , Viewport
  )
import System.Types.Geometry (Rect, XYPosition)
import System.Types.Handle (HandleType)

type ReactFlowJsonObject n e =
  { nodes :: Array (Node n)
  , edges :: Array (Edge e)
  , viewport :: Viewport
  }

-- | TS `(Node | { id: string })[]`. We accept either a full node or a
-- | bare id to delete by reference.
type DeleteElementsOptions n e =
  { nodes :: Maybe (Array (Either String (Node n)))
  , edges :: Maybe (Array (Either String (Edge e)))
  }

-- | Argument shape for `getIntersectingNodes` / `isNodeIntersecting`. TS
-- | uses `NodeType | { id: string } | Rect`; we tag explicitly.
data NodeOrIdOrRect n
  = NodeArg (Node n)
  | IdArg String
  | RectArg Rect

-- | For `getNodesBounds`. TS `(NodeType | InternalNode | string)[]`.
data NodeRefForBounds n
  = BoundsNode (Node n)
  | BoundsInternal (InternalNode n)
  | BoundsId String

type UpdateOptions = { replace :: Boolean }

-- | Animation options accepted by every animated viewport helper
-- | (`zoomIn`/`zoomOut`/`zoomTo`/`setViewport`). Mirrors upstream's
-- | `ViewportHelperFunctionOptions` and matches `PanZoomTransformOptions`
-- | shape field-for-field so the helpers can forward straight into
-- | `panZoom.scaleBy` / `panZoom.setViewport`.
type ZoomOptions =
  { duration :: Maybe Int
  , ease :: Maybe (Number -> Number)
  , interpolate :: Maybe InterpolateMode
  }

-- | Options for `fitBounds`. TS `FitBoundsOptions = ViewportHelperFunctionOptions & { padding? }`.
type FitBoundsOptions =
  { padding :: Maybe Number
  , duration :: Maybe Int
  , ease :: Maybe (Number -> Number)
  , interpolate :: Maybe InterpolateMode
  }

-- | TS `(clientPosition, options?: { snapToGrid?: boolean; snapGrid?: SnapGrid })`.
-- | Flattened to a record.
type ScreenToFlowOptions =
  { snapToGrid :: Maybe Boolean
  , snapGrid :: Maybe { gx :: Number, gy :: Number }
  }

-- | The viewport-manipulation half of `ReactFlowInstance`. Mirrors
-- | `xyflow-main/packages/react/src/types/general.ts ViewportHelperFunctions`.
-- |
-- | Every animated method returns `Aff Boolean` — `true` once the d3
-- | transition resolves, `false` when there is no `panZoom` instance to
-- | drive the animation. The non-animated readers (`getZoom`,
-- | `getViewport`, `screenToFlowPosition`, `flowToScreenPosition`) stay
-- | `Effect`.
type ViewportHelperFunctions =
  { zoomIn :: ZoomOptions -> Aff Boolean
  , zoomOut :: ZoomOptions -> Aff Boolean
  , zoomTo :: Number -> ZoomOptions -> Aff Boolean
  , getZoom :: Effect Number
  , setViewport :: Viewport -> ZoomOptions -> Aff Boolean
  , getViewport :: Effect Viewport
  , setCenter :: Number -> Number -> SetCenterOptions -> Aff Boolean
  , fitBounds :: Rect -> FitBoundsOptions -> Aff Boolean
  , screenToFlowPosition :: XYPosition -> ScreenToFlowOptions -> Effect XYPosition
  , flowToScreenPosition :: XYPosition -> Effect XYPosition
  }

-- | The full `ReactFlowInstance n e` — TS `GeneralHelpers & ViewportHelperFunctions & { viewportInitialized }`.
-- | A record of `Effect`/`Aff`-typed methods.
type ReactFlowInstance n e =
  { -- General helpers
    getNodes :: Effect (Array (Node n))
  , setNodes :: (Array (Node n) -> Array (Node n)) -> Effect Unit
  , addNodes :: Array (Node n) -> Effect Unit
  , getNode :: String -> Effect (Maybe (Node n))
  , getInternalNode :: String -> Effect (Maybe (InternalNode n))
  , getEdges :: Effect (Array (Edge e))
  , setEdges :: (Array (Edge e) -> Array (Edge e)) -> Effect Unit
  , addEdges :: Array (Edge e) -> Effect Unit
  , getEdge :: String -> Effect (Maybe (Edge e))
  , toObject :: Effect (ReactFlowJsonObject n e)
  , deleteElements ::
      DeleteElementsOptions n e
      -> Aff { deletedNodes :: Array (Node n), deletedEdges :: Array (Edge e) }
  , getIntersectingNodes ::
      NodeOrIdOrRect n
      -> Maybe Boolean
      -> Maybe (Array (Node n))
      -> Effect (Array (Node n))
  , isNodeIntersecting :: NodeOrIdOrRect n -> Rect -> Maybe Boolean -> Effect Boolean
  , updateNode :: String -> (Node n -> Node n) -> UpdateOptions -> Effect Unit
  , updateNodeData :: String -> (Node n -> Node n) -> UpdateOptions -> Effect Unit
  , updateEdge :: String -> (Edge e -> Edge e) -> UpdateOptions -> Effect Unit
  , updateEdgeData :: String -> (Edge e -> Edge e) -> UpdateOptions -> Effect Unit
  , getNodesBounds :: Array (NodeRefForBounds n) -> Effect Rect
  , getHandleConnections ::
      { handleType :: HandleType, nodeId :: String, id :: Maybe String }
      -> Effect (Array HandleConnection)
  , getNodeConnections ::
      { handleType :: Maybe HandleType, nodeId :: String, handleId :: Maybe String }
      -> Effect (Array NodeConnection)
  , fitView :: FitView
  -- Viewport helpers (flattened into the same record per the TS intersection)
  , zoomIn :: ZoomOptions -> Aff Boolean
  , zoomOut :: ZoomOptions -> Aff Boolean
  , zoomTo :: Number -> ZoomOptions -> Aff Boolean
  , getZoom :: Effect Number
  , setViewport :: Viewport -> ZoomOptions -> Aff Boolean
  , getViewport :: Effect Viewport
  , setCenter :: Number -> Number -> SetCenterOptions -> Aff Boolean
  , fitBounds :: Rect -> FitBoundsOptions -> Aff Boolean
  , screenToFlowPosition :: XYPosition -> ScreenToFlowOptions -> Effect XYPosition
  , flowToScreenPosition :: XYPosition -> Effect XYPosition
  , viewportInitialized :: Boolean
  }
