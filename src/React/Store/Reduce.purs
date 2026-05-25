-- | Pure reducer. Mirrors the action methods of
-- | `xyflow-main/packages/react/src/store/index.ts`. One handler per
-- | `Action` constructor, returning the new state plus a list of
-- | `Effect_` descriptors for the shell to interpret.
-- |
-- | The reducer is total and pure: no `Effect`, no `Ref`, no `Aff`. All
-- | DOM- or async-touching work lives in the shell. The reducer's
-- | output is QuickCheck-testable directly.
module React.Store.Reduce
  ( reduce
  , ReduceResult
  ) where

import Prelude

import Data.Array (filter, mapMaybe, null, snoc) as Array
import Data.Map as Map
import Data.Maybe (Maybe(..), maybe)
import Data.Set as Set
import Data.Tuple (Tuple(..))
import React.Store.Action
  ( Action(..)
  , Effect_(..)
  , NodeInternalsResult
  )
import Unsafe.Reference (unsafeRefEq)
import React.Store.Changes
  ( applyEdgeChanges
  , applyNodeChanges
  , getEdgeSelectionChanges
  , getNodeSelectionChanges
  )
import React.Store.InitialState (defaultInitialStateOptions, initialState)
import React.Types.Edges (Edge)
import React.Types.General (OnViewportChange, UnselectNodesAndEdgesParams)
import React.Types.Nodes (Node)
import React.Types.Store (ReactFlowState)
import System.Types.Connection (noConnection)
import System.Types.Edge (EdgeBase, EdgeChange(..))
import System.Types.Ids (NodeId)
import System.Types.Geometry (CoordinateExtent)
import System.Types.Node (InternalNodeBase, NodeChange(..), NodeDragItem)
import System.Utils.Store
  ( adoptUserNodes
  , defaultUpdateNodesOptions
  , updateConnectionLookup
  )

type ReduceResult n e =
  { state :: ReactFlowState n e
  , effects :: Array (Effect_ n e)
  }

-- | The top-level dispatcher. One case per `Action` constructor.
reduce
  :: forall n e
   . ReactFlowState n e
  -> Action n e
  -> ReduceResult n e
reduce state = case _ of
  SetNodes ns -> reduceSetNodes state ns
  SetEdges es -> reduceSetEdges state es
  SetDefaultNodesAndEdges mNs mEs -> reduceSetDefaults state mNs mEs
  UpdateNodeInternals updates opts ->
    { state, effects: [ RunDomUpdateNodeInternals updates opts ] }
  MergeNodeInternalsResult r -> reduceMergeNodeInternals state r
  UpdateNodePositions items dragging ->
    reduceUpdateNodePositions state items dragging
  TriggerNodeChanges cs -> reduceTriggerNodeChanges state cs
  TriggerEdgeChanges cs -> reduceTriggerEdgeChanges state cs
  AddSelectedNodes ids -> reduceAddSelectedNodes state ids
  AddSelectedEdges ids -> reduceAddSelectedEdges state ids
  UnselectNodesAndEdges params -> reduceUnselectNodesAndEdges state params
  SetMinZoom z -> { state: state { minZoom = z }, effects: [] }
  SetMaxZoom z -> { state: state { maxZoom = z }, effects: [] }
  SetTranslateExtent ext -> { state: state { translateExtent = ext }, effects: [] }
  SetNodeExtent ext -> reduceSetNodeExtent state ext
  PanBy delta -> { state, effects: [ RunPanBy delta ] }
  SetCenter x y opts -> { state, effects: [ RunSetCenter x y opts ] }
  CancelConnection -> { state: state { connection = noConnection }, effects: [] }
  UpdateConnection c -> { state: state { connection = c }, effects: [] }
  ResetSelectedElements -> reduceResetSelectedElements state
  Reset -> { state: initialState defaultInitialStateOptions, effects: [] }
  InstallViewportListeners opts -> reduceInstallViewportListeners state opts
  UninstallViewportListeners opts -> reduceUninstallViewportListeners state opts
  AddSelectionChangeHandler cb ->
    { state: state
        { onSelectionChangeHandlers =
            Array.snoc state.onSelectionChangeHandlers cb
        }
    , effects: []
    }
  RemoveSelectionChangeHandler cb ->
    { state: state
        { onSelectionChangeHandlers =
            Array.filter (\h -> not (unsafeRefEq h cb))
              state.onSelectionChangeHandlers
        }
    , effects: []
    }
  AddOnNodesChangeMiddleware key fn ->
    { state: state
        { onNodesChangeMiddlewareMap =
            Map.insert key fn state.onNodesChangeMiddlewareMap
        }
    , effects: []
    }
  RemoveOnNodesChangeMiddleware key ->
    { state: state
        { onNodesChangeMiddlewareMap =
            Map.delete key state.onNodesChangeMiddlewareMap
        }
    , effects: []
    }
  AddOnEdgesChangeMiddleware key fn ->
    { state: state
        { onEdgesChangeMiddlewareMap =
            Map.insert key fn state.onEdgesChangeMiddlewareMap
        }
    , effects: []
    }
  RemoveOnEdgesChangeMiddleware key ->
    { state: state
        { onEdgesChangeMiddlewareMap =
            Map.delete key state.onEdgesChangeMiddlewareMap
        }
    , effects: []
    }
  PatchState f -> { state: f state, effects: [] }

-- SetNodes ---------------------------------------------------------------

reduceSetNodes
  :: forall n e
   . ReactFlowState n e
  -> Array (Node n)
  -> ReduceResult n e
reduceSetNodes state nodes =
  let
    r = adoptUserNodes nodes state.nodeLookup state.parentLookup
      ( defaultUpdateNodesOptions
          { nodeOrigin = state.nodeOrigin
          , nodeExtent = state.nodeExtent
          , elevateNodesOnSelect = state.elevateNodesOnSelect
          , zIndexMode = state.zIndexMode
          }
      )
    fitViewNow = state.fitViewQueued && r.nodesInitialized
  in
    { state: state
        { nodes = nodes
        , nodeLookup = r.nodeLookup
        , parentLookup = r.parentLookup
        , nodesInitialized = r.nodesInitialized
        , fitViewQueued = if fitViewNow then false else state.fitViewQueued
        }
    , effects: if fitViewNow then [ ResolveFitView true ] else []
    }

-- SetEdges ---------------------------------------------------------------

reduceSetEdges
  :: forall n e
   . ReactFlowState n e
  -> Array (Edge e)
  -> ReduceResult n e
reduceSetEdges state edges =
  let
    r = updateConnectionLookup edges
  in
    { state: state
        { edges = edges
        , edgeLookup = r.edgeLookup
        , connectionLookup = r.connectionLookup
        }
    , effects: []
    }

-- SetDefaultNodesAndEdges -----------------------------------------------

reduceSetDefaults
  :: forall n e
   . ReactFlowState n e
  -> Maybe (Array (Node n))
  -> Maybe (Array (Edge e))
  -> ReduceResult n e
reduceSetDefaults state mNs mEs =
  let
    afterNodes = case mNs of
      Just ns ->
        let
          res = reduceSetNodes state ns
        in
          { state: res.state { hasDefaultNodes = true }, effects: res.effects }
      Nothing -> { state, effects: [] }
    afterEdges = case mEs of
      Just es ->
        let
          res = reduceSetEdges afterNodes.state es
        in
          { state: res.state { hasDefaultEdges = true }
          , effects: afterNodes.effects <> res.effects
          }
      Nothing -> afterNodes
  in
    afterEdges

-- MergeNodeInternalsResult ----------------------------------------------

reduceMergeNodeInternals
  :: forall n e
   . ReactFlowState n e
  -> NodeInternalsResult n
  -> ReduceResult n e
reduceMergeNodeInternals state r =
  let
    s1 = state
      { nodeLookup = r.nodeLookup
      , parentLookup = r.parentLookup
      , nodesInitialized =
          if r.updatedInternals then true else state.nodesInitialized
      }
    afterChanges =
      if Array.null r.changes then { state: s1, effects: [] }
      else reduceTriggerNodeChanges s1 r.changes
    extra = if r.triggerFitView then [ ResolveFitView true ] else []
  in
    afterChanges { effects = afterChanges.effects <> extra }

-- UpdateNodePositions ---------------------------------------------------

reduceUpdateNodePositions
  :: forall n e
   . ReactFlowState n e
  -> Array NodeDragItem
  -> Boolean
  -> ReduceResult n e
reduceUpdateNodePositions state items dragging =
  let
    changes =
      map
        ( \item ->
            NodePositionChange
              { id: item.id
              , position: Just item.position
              , positionAbsolute: Just item.internals.positionAbsolute
              , dragging
              }
        )
        items
  in
    reduceTriggerNodeChanges state changes

-- TriggerNodeChanges ----------------------------------------------------

reduceTriggerNodeChanges
  :: forall n e
   . ReactFlowState n e
  -> Array (NodeChange n)
  -> ReduceResult n e
reduceTriggerNodeChanges state changes =
  let
    s1 =
      if state.hasDefaultNodes then
        state { nodes = applyNodeChanges changes state.nodes }
      else state
  in
    { state: s1, effects: [ FireOnNodesChange changes ] }

-- TriggerEdgeChanges ----------------------------------------------------

reduceTriggerEdgeChanges
  :: forall n e
   . ReactFlowState n e
  -> Array (EdgeChange e)
  -> ReduceResult n e
reduceTriggerEdgeChanges state changes =
  let
    s1 =
      if state.hasDefaultEdges then
        state { edges = applyEdgeChanges changes state.edges }
      else state
  in
    { state: s1, effects: [ FireOnEdgesChange changes ] }

-- AddSelectedNodes ------------------------------------------------------

reduceAddSelectedNodes
  :: forall n e
   . ReactFlowState n e
  -> Array NodeId
  -> ReduceResult n e
reduceAddSelectedNodes state ids =
  let
    selectedSet = Set.fromFoldable ids
    nodeRes = getNodeSelectionChanges state.nodeLookup selectedSet true
    -- TS behaviour: when selecting any nodes, deselect all edges.
    edgeRes =
      if Array.null ids then { changes: [] }
      else getEdgeSelectionChanges state.edgeLookup Set.empty
    s1 = state { nodeLookup = nodeRes.items }
    afterNodes = reduceTriggerNodeChanges s1 nodeRes.changes
    afterEdges = reduceTriggerEdgeChanges afterNodes.state edgeRes.changes
  in
    { state: afterEdges.state
    , effects: afterNodes.effects <> afterEdges.effects
    }

-- AddSelectedEdges ------------------------------------------------------

reduceAddSelectedEdges
  :: forall n e
   . ReactFlowState n e
  -> Array String
  -> ReduceResult n e
reduceAddSelectedEdges state ids =
  let
    selectedSet = Set.fromFoldable ids
    edgeRes = getEdgeSelectionChanges state.edgeLookup selectedSet
    nodeRes =
      if Array.null ids then { changes: [], items: state.nodeLookup }
      else getNodeSelectionChanges state.nodeLookup Set.empty true
    s1 = state { nodeLookup = nodeRes.items }
    afterEdges = reduceTriggerEdgeChanges s1 edgeRes.changes
    afterNodes = reduceTriggerNodeChanges afterEdges.state nodeRes.changes
  in
    { state: afterNodes.state
    , effects: afterEdges.effects <> afterNodes.effects
    }

-- UnselectNodesAndEdges -------------------------------------------------

reduceUnselectNodesAndEdges
  :: forall n e
   . ReactFlowState n e
  -> UnselectNodesAndEdgesParams n e
  -> ReduceResult n e
reduceUnselectNodesAndEdges state params =
  let
    targetNodes = case params.nodes of
      Just ns -> ns
      Nothing -> state.nodes
    targetEdges = case params.edges of
      Just es -> es
      Nothing -> state.edges

    nodeChanges = map
      (\n -> NodeSelectionChange { id: n.id, selected: false })
      (Array.filter _.selected targetNodes)
    edgeChanges = map
      (\e -> EdgeSelectionChange { id: e.id, selected: false })
      (Array.filter _.selected targetEdges)

    afterNodes = reduceTriggerNodeChanges state nodeChanges
    afterEdges = reduceTriggerEdgeChanges afterNodes.state edgeChanges
  in
    { state: afterEdges.state
    , effects: afterNodes.effects <> afterEdges.effects
    }

-- SetNodeExtent ---------------------------------------------------------

reduceSetNodeExtent
  :: forall n e
   . ReactFlowState n e
  -> CoordinateExtent
  -> ReduceResult n e
reduceSetNodeExtent state ext =
  let
    r = adoptUserNodes state.nodes state.nodeLookup state.parentLookup
      ( defaultUpdateNodesOptions
          { nodeOrigin = state.nodeOrigin
          , nodeExtent = ext
          , elevateNodesOnSelect = state.elevateNodesOnSelect
          , zIndexMode = state.zIndexMode
          }
      )
  in
    { state: state
        { nodeExtent = ext
        , nodeLookup = r.nodeLookup
        , parentLookup = r.parentLookup
        }
    , effects: []
    }

-- InstallViewportListeners / UninstallViewportListeners ----------------
--
-- Atomic 3-slot patching. `Just cb` overwrites the slot; `Nothing`
-- leaves it untouched. Uninstall additionally guards the clear with a
-- reference-equality check against the installed callback, so a
-- second hook that has since installed a different callback into the
-- same slot is not disturbed. This was previously expressed inline in
-- `React.Hook.Listeners` via `PatchState`.

type ViewportSlots =
  { onStart :: Maybe OnViewportChange
  , onChange :: Maybe OnViewportChange
  , onEnd :: Maybe OnViewportChange
  }

reduceInstallViewportListeners
  :: forall n e
   . ReactFlowState n e
  -> ViewportSlots
  -> ReduceResult n e
reduceInstallViewportListeners state opts =
  { state: state
      { onViewportChangeStart =
          maybe state.onViewportChangeStart Just opts.onStart
      , onViewportChange =
          maybe state.onViewportChange Just opts.onChange
      , onViewportChangeEnd =
          maybe state.onViewportChangeEnd Just opts.onEnd
      }
  , effects: []
  }

-- | If `installed` matches `current` by reference, clear the slot;
-- | otherwise leave `current` alone. `Nothing` for `installed` means
-- | "we did not set this slot, leave it untouched".
clearIf
  :: Maybe OnViewportChange
  -> Maybe OnViewportChange
  -> Maybe OnViewportChange
clearIf installed current = case installed, current of
  Just inst, Just curr ->
    if unsafeRefEq inst curr then Nothing else current
  _, _ -> current

reduceUninstallViewportListeners
  :: forall n e
   . ReactFlowState n e
  -> ViewportSlots
  -> ReduceResult n e
reduceUninstallViewportListeners state opts =
  { state: state
      { onViewportChangeStart =
          clearIf opts.onStart state.onViewportChangeStart
      , onViewportChange =
          clearIf opts.onChange state.onViewportChange
      , onViewportChangeEnd =
          clearIf opts.onEnd state.onViewportChangeEnd
      }
  , effects: []
  }

-- ResetSelectedElements -------------------------------------------------

reduceResetSelectedElements
  :: forall n e
   . ReactFlowState n e
  -> ReduceResult n e
reduceResetSelectedElements state =
  let
    nodePairs :: Array (Tuple NodeId (InternalNodeBase n))
    nodePairs = Map.toUnfoldable state.nodeLookup
    edgePairs :: Array (Tuple String (EdgeBase e))
    edgePairs = Map.toUnfoldable state.edgeLookup

    nodeChanges = Array.mapMaybe
      ( \(Tuple _ n) ->
          if n.selected then
            Just (NodeSelectionChange { id: n.id, selected: false })
          else Nothing
      )
      nodePairs
    edgeChanges = Array.mapMaybe
      ( \(Tuple _ e) ->
          if e.selected then
            Just (EdgeSelectionChange { id: e.id, selected: false })
          else Nothing
      )
      edgePairs

    afterNodes = reduceTriggerNodeChanges state nodeChanges
    afterEdges = reduceTriggerEdgeChanges afterNodes.state edgeChanges
  in
    { state: afterEdges.state
    , effects: afterNodes.effects <> afterEdges.effects
    }
