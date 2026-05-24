-- | Action ADT and `Effect_` (effect-descriptor) ADT for the Redux-style
-- | React store. Mirrors `xyflow-main/packages/react/src/store/index.ts`'s
-- | 20 named action methods plus the `PatchState` escape hatch for
-- | upstream's `useStoreApi().setState(fn)` pattern.
-- |
-- | `Effect_` constructors are *descriptions* of side effects. The shell
-- | (`React.Store.Shell`) is the one place that interprets them as real
-- | `Effect Unit` / `Aff` work. This keeps `React.Store.Reduce` pure and
-- | QuickCheck-testable.
module React.Store.Action
  ( Action(..)
  , Effect_(..)
  , NodeInternalsResult
  ) where


import Data.Map (Map)
import Data.Maybe (Maybe)
import React.Types.Edges (Edge)
import React.Types.General
  ( OnSelectionChangeFunc
  , OnSelectionChangeParams
  , OnViewportChange
  , UnselectNodesAndEdgesParams
  )
import React.Types.Nodes (InternalNode, Node)
import React.Types.Store (MiddlewareKey, ReactFlowState)
import System.Constants (ErrorCode)
import System.Types.Connection
  ( Connection
  , ConnectionState
  , FinalConnectionState
  , SetCenterOptions
  )
import System.Types.Edge (EdgeChange)
import System.Types.Geometry (CoordinateExtent, XYPosition)
import System.Types.Node
  ( InternalNodeBase
  , InternalNodeUpdate
  , NodeChange
  , NodeDragItem
  , NodeLookup
  , ParentLookup
  )
import System.XYHandle (OnConnectStartParams)

-- | The payload returned by `System.Utils.Store.updateNodeInternals`.
-- | Carried back into the reducer via `MergeNodeInternalsResult` so the
-- | DOM-read result lands in state through the normal dispatch path.
type NodeInternalsResult n =
  { nodeLookup :: NodeLookup n
  , parentLookup :: ParentLookup n
  , changes :: Array (NodeChange n)
  , updatedInternals :: Boolean
  , triggerFitView :: Boolean
  }

-- | Action ADT. Each constructor corresponds to one named TS action
-- | method on the upstream Zustand store, with the addition of:
-- |   * `MergeNodeInternalsResult` — the follow-up the shell dispatches
-- |     after running the DOM-driven `updateNodeInternals` system helper.
-- |   * The listener/middleware-registration constructors
-- |     (`InstallViewportListeners`, `AddSelectionChangeHandler`,
-- |     `AddOnNodesChangeMiddleware`, …) used by `React.Hook.Listeners`
-- |     and `React.Hook.Middleware`. The atomicity and ref-equality
-- |     clear logic for these lives in `React.Store.Reduce`.
-- |   * `PatchState` — escape hatch for `useStoreApi().setState(fn)`.
data Action n e
  = SetNodes (Array (Node n))
  | SetEdges (Array (Edge e))
  | SetDefaultNodesAndEdges (Maybe (Array (Node n))) (Maybe (Array (Edge e)))
  | UpdateNodeInternals (Map String InternalNodeUpdate) { triggerFitView :: Boolean }
  | MergeNodeInternalsResult (NodeInternalsResult n)
  | UpdateNodePositions (Array NodeDragItem) Boolean
  | TriggerNodeChanges (Array (NodeChange n))
  | TriggerEdgeChanges (Array (EdgeChange e))
  | AddSelectedNodes (Array String)
  | AddSelectedEdges (Array String)
  | UnselectNodesAndEdges (UnselectNodesAndEdgesParams n e)
  | SetMinZoom Number
  | SetMaxZoom Number
  | SetTranslateExtent CoordinateExtent
  | SetNodeExtent CoordinateExtent
  | PanBy XYPosition
  | SetCenter Number Number SetCenterOptions
  | CancelConnection
  | UpdateConnection (ConnectionState (InternalNodeBase n))
  | ResetSelectedElements
  | Reset
  -- Atomic 3-slot install. A `Just` overwrites the slot; a `Nothing`
  -- leaves it untouched. Mirrors the `maybe s.slot Just opts.slot`
  -- pattern the hook used to apply via `PatchState`.
  | InstallViewportListeners
      { onStart :: Maybe OnViewportChange
      , onChange :: Maybe OnViewportChange
      , onEnd :: Maybe OnViewportChange
      }
  -- Atomic 3-slot uninstall. Each `Just cb` clears the corresponding
  -- slot only when the currently-stored callback is reference-equal
  -- to `cb`. A `Nothing` leaves the slot alone.
  | UninstallViewportListeners
      { onStart :: Maybe OnViewportChange
      , onChange :: Maybe OnViewportChange
      , onEnd :: Maybe OnViewportChange
      }
  | AddSelectionChangeHandler (OnSelectionChangeFunc n e)
  | RemoveSelectionChangeHandler (OnSelectionChangeFunc n e)
  | AddOnNodesChangeMiddleware MiddlewareKey (Array (NodeChange n) -> Array (NodeChange n))
  | RemoveOnNodesChangeMiddleware MiddlewareKey
  | AddOnEdgesChangeMiddleware MiddlewareKey (Array (EdgeChange e) -> Array (EdgeChange e))
  | RemoveOnEdgesChangeMiddleware MiddlewareKey
  | PatchState (ReactFlowState n e -> ReactFlowState n e)

-- | Effect descriptors. The reducer emits these as data; the shell
-- | interprets them when it interprets each dispatch.
data Effect_ n e
  -- User-callback fires (consumer-facing).
  = FireOnNodesChange (Array (NodeChange n))
  | FireOnEdgesChange (Array (EdgeChange e))
  | FireOnSelectionChange (OnSelectionChangeParams n e)
  | FireOnConnect Connection
  | FireOnConnectStart OnConnectStartParams
  | FireOnConnectEnd (FinalConnectionState (InternalNode n))
  -- Side-effecting system calls the shell must perform.
  | RunDomUpdateNodeInternals
      (Map String InternalNodeUpdate)
      { triggerFitView :: Boolean }
  | RunPanBy XYPosition
  | RunSetCenter Number Number SetCenterOptions
  -- Resolution of the queued fitView promise.
  | ResolveFitView Boolean
  -- Error logging — swallowed if `state.onError` is `Nothing`.
  | LogError ErrorCode
