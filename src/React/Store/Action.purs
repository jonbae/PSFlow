-- | Action ADT and `Effect_` (effect-descriptor) ADT for the Redux-style
-- | React store. Mirrors `xyflow/packages/react/src/store/index.ts`'s
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
  , FitInputs
  , NodeInternalsResult
  ) where


import Data.Maybe (Maybe)
import Data.Set (Set)
import React.Store.Partial (StatePartial)
import React.Types.Edges (Edge)
import React.Types.General
  ( FitViewOptions
  , OnSelectionChangeFunc
  , OnSelectionChangeParams
  , OnViewportChange
  , UnselectNodesAndEdgesParams
  )
import React.Types.Nodes (InternalNode, Node)
import React.Types.Store (FitViewResolver, ReactFlowState)
import System.Constants (ErrorCode)
import System.Types.Connection
  ( Connection
  , ConnectionState
  , FinalConnectionState
  , SetCenterOptions
  )
import System.Types.Edge (EdgeChange)
import System.Types.Geometry (CoordinateExtent)
import System.Types.Ids (NodeId)
import System.Types.Node
  ( InternalNodeBase
  , InternalNodeUpdate
  , NodeChange
  , NodeDragItem
  , NodeLookup
  , ParentLookup
  )
import System.Types.PanZoom (PanZoomInstance)
import System.XYHandle (OnConnectStartParams)

-- | What a queued fit fits with.
type FitInputs n =
  { nodes :: NodeLookup n
  , width :: Number
  , height :: Number
  , panZoom :: Maybe PanZoomInstance
  , minZoom :: Number
  , maxZoom :: Number
  , options :: Maybe FitViewOptions
  , resolver :: Maybe FitViewResolver
  }

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
-- |   * The listener-registration constructors
-- |     (`SetViewportChangeHandler`, `AddSelectionChangeHandler`, …) used
-- |     by `React.Hook.Listeners`. Their state updates live in
-- |     `React.Store.Reduce`. The middleware hooks write into the live
-- |     middleware map in place, as upstream's do, so they need none.
-- |   * `Assign` — upstream's `store.setState(partial)` from a component or
-- |     hook. The partial names the members it writes; see
-- |     `React.Store.Partial`.
-- |   * `PatchState` — escape hatch for `useStoreApi().setState(fn)`, whose
-- |     JavaScript caller keeps its own record of the keys it wrote.
-- |   * `MutateState` — upstream's in-place writes into the state, which
-- |     notify nobody. See `React.Store.InPlace`.
data Action n e
  = SetNodes (Array (Node n))
  | SetEdges (Array (Edge e))
  | SetDefaultNodesAndEdges (Maybe (Array (Node n))) (Maybe (Array (Edge e)))
  -- In insertion order, as upstream's `Map<string, InternalNodeUpdate>`
  -- iterates: the order the observer reported the nodes, or the ids a
  -- `useUpdateNodeInternals` caller passed. `System.Utils.Store.setUpdate`
  -- builds one.
  | UpdateNodeInternals (Array InternalNodeUpdate) { triggerFitView :: Boolean }
  | MergeNodeInternalsResult (NodeInternalsResult n)
  | UpdateNodePositions (Array NodeDragItem) Boolean
  | TriggerNodeChanges (Array (NodeChange n))
  | TriggerEdgeChanges (Array (EdgeChange e))
  | AddSelectedNodes (Array NodeId)
  | AddSelectedEdges (Array String)
  -- TS `triggerNodeChanges(getSelectionChanges(nodeLookup, new Set(ids), true))`
  -- and `triggerEdgeChanges(getSelectionChanges(edgeLookup, new Set(ids)))`:
  -- the selection becomes exactly `ids`. Each is one statement of
  -- `addSelectedNodes` and `addSelectedEdges` outside multi-selection.
  | ReplaceNodeSelection (Set NodeId)
  | ReplaceEdgeSelection (Set String)
  | UnselectNodesAndEdges (UnselectNodesAndEdgesParams n e)
  | SetMinZoom Number
  | SetMaxZoom Number
  | SetTranslateExtent CoordinateExtent
  | SetNodeExtent CoordinateExtent
  | SetCenter Number Number SetCenterOptions
  | CancelConnection
  | UpdateConnection (ConnectionState (InternalNodeBase n))
  | ResetSelectedElements
  | Reset
  -- Each source effect updates one slot, including absence.
  | SetViewportChangeStartHandler (Maybe OnViewportChange)
  | SetViewportChangeHandler (Maybe OnViewportChange)
  | SetViewportChangeEndHandler (Maybe OnViewportChange)
  | AddSelectionChangeHandler (OnSelectionChangeFunc n e)
  | RemoveSelectionChangeHandler (OnSelectionChangeFunc n e)
  | Assign (StatePartial (ReactFlowState n e))
  | PatchState (ReactFlowState n e -> ReactFlowState n e)
  | MutateState (ReactFlowState n e -> ReactFlowState n e)

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
      (Array InternalNodeUpdate)
      { triggerFitView :: Boolean }
  -- Measurement publishes its internals before triggering the user-node
  -- changes. Keep that second store update observable to subscribers.
  | RunTriggerNodeChanges (Array (NodeChange n))
  -- The second statement of `addSelectedNodes` or `addSelectedEdges`, which
  -- TS runs once the first one's `set` and change callback are done, reading
  -- the lookups as they are then.
  | RunReplaceNodeSelection (Set NodeId)
  | RunReplaceEdgeSelection (Set String)
  -- TS `if (debug) console.log('React Flow: trigger node changes', changes)`,
  -- and its edge counterpart. The reducer emits them when the state it
  -- reduced has `debug` set, which is when upstream's `get()` reads it.
  | LogNodeChanges (Array (NodeChange n))
  | LogEdgeChanges (Array (EdgeChange e))
  -- A drag's position changes, to run through the node-change middleware
  -- and then trigger. Middleware is consumer code, so it runs in the shell,
  -- after the reducer's state is written, and a store write it makes is
  -- kept. Upstream runs it inside `updateNodePositions`, before
  -- `triggerNodeChanges` reads the store.
  | RunNodesChangeMiddleware (Array (NodeChange n))
  | RunSetCenter Number Number SetCenterOptions
  -- Zoom and pan limits, pushed onto the pan-zoom instance. The reducer
  -- carries the values rather than leaving the shell to read them back,
  -- so the descriptor says what it asks for — and so it matches
  -- upstream's explicit `setScaleExtent([minZoom, maxZoom])`, which passes
  -- the changed bound beside the one already in state. The instance is the
  -- one upstream's `get()` reads before its `set`.
  | RunSetScaleExtent (Maybe PanZoomInstance) Number Number
  | RunSetTranslateExtent (Maybe PanZoomInstance) CoordinateExtent
  -- Resolution of the queued fit, with everything upstream's
  -- `resolveFitView` reads from `get()` before its caller's `set`: the
  -- options before the reducer cleared them, and the node lookup the
  -- update adopted, which upstream changes in place first.
  | ResolveFitView (FitInputs n)
  -- Error logging — swallowed if `state.onError` is `Nothing`.
  | LogError ErrorCode
