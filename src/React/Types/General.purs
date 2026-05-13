-- | Callback aliases, options records, and supporting types used by
-- | `React.Types.Component` and `React.Types.Instance`. Most entries are
-- | thin type synonyms over the System layer.
module React.Types.General
  ( OnNodesChange
  , OnEdgesChange
  , OnNodesDelete
  , OnEdgesDelete
  , OnDelete
  , OnInit
  , OnSelectionChangeParams
  , OnSelectionChangeFunc
  , UnselectNodesAndEdgesParams
  , FlowExportObject
  , OnBeforeDelete
  , OnBeforeDeleteResult
  , IsValidConnection
  , OnMove
  , OnMoveStart
  , OnMoveEnd
  , OnViewportChange
  , ProOptions
  , FitView
  , module ReexportFitView
  ) where

import Prelude

import Data.Maybe (Maybe)
import Effect (Effect)
import Effect.Aff (Aff)
import React.Types.Edges (Edge)
import React.Types.Nodes (Node)
import System.Types.Connection (Viewport)
import System.Types.Edge (EdgeChange)
import System.Types.Node (NodeChange)
import System.Utils.Graph (FitViewOptions) as ReexportFitView
import System.Utils.Graph (FitViewOptions)
import Web.UIEvent.MouseEvent (MouseEvent)

-- Public callback aliases mirroring `xyflow-main/packages/react/src/types/general.ts`.

type OnNodesChange n = Array (NodeChange n) -> Effect Unit

type OnEdgesChange e = Array (EdgeChange e) -> Effect Unit

type OnNodesDelete n = Array (Node n) -> Effect Unit

type OnEdgesDelete e = Array (Edge e) -> Effect Unit

type OnDelete n e =
  { nodes :: Array (Node n), edges :: Array (Edge e) } -> Effect Unit

type OnSelectionChangeParams n e =
  { nodes :: Array (Node n), edges :: Array (Edge e) }

type OnSelectionChangeFunc n e =
  OnSelectionChangeParams n e -> Effect Unit

type UnselectNodesAndEdgesParams n e =
  { nodes :: Maybe (Array (Node n))
  , edges :: Maybe (Array (Edge e))
  }

type FlowExportObject n e =
  { nodes :: Array (Node n)
  , edges :: Array (Edge e)
  , viewport :: Viewport
  }

-- | `OnBeforeDelete` may veto the delete by returning `false` or filter the
-- | set of nodes/edges to delete. The TS source returns
-- | `Promise<boolean | { nodes, edges }>` — port to `Aff` returning a
-- | tagged record.
type OnBeforeDeleteResult n e =
  { allow :: Boolean
  , nodes :: Maybe (Array (Node n))
  , edges :: Maybe (Array (Edge e))
  }

type OnBeforeDelete n e =
  { nodes :: Array (Node n), edges :: Array (Edge e) }
    -> Aff (OnBeforeDeleteResult n e)

-- | Predicate used to validate a candidate connection. The TS signature is
-- | `(edgeOrConnection) => boolean`; we pass the edge (when available) and
-- | the raw connection candidate.
type IsValidConnection e =
  { source :: String
  , target :: String
  , sourceHandle :: Maybe String
  , targetHandle :: Maybe String
  , edge :: Maybe (Edge e)
  } -> Boolean

-- Move callbacks ---------------------------------------------------------

type OnMove = Maybe MouseEvent -> Viewport -> Effect Unit

type OnMoveStart = OnMove

type OnMoveEnd = OnMove

type OnViewportChange = Viewport -> Effect Unit

-- Misc ------------------------------------------------------------------

type OnInit instance_ = instance_ -> Effect Unit

-- | TS `ProOptions { hideAttribution: boolean; account?: string }`.
type ProOptions =
  { hideAttribution :: Boolean
  , account :: Maybe String
  }

-- | `FitView` is the public-API method on `ReactFlowInstance`. Defined
-- | here so both `ReactFlowProps` (the optional `fitView` flag) and
-- | `ReactFlowInstance` (the method) can reference the same shape.
type FitView = Maybe FitViewOptions -> Aff Boolean
