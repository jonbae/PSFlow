-- | Pure reducer. Mirrors the action methods of
-- | `xyflow/packages/react/src/store/index.ts`. One handler per
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

import Data.Array (filter, foldl, mapMaybe, null, snoc) as Array
import Data.Foldable (foldl) as Foldable
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
import System.Types.Connection (ConnectionState(..), noConnection)
import System.Types.Edge (EdgeBase, EdgeChange(..))
import System.Types.Ids (NodeId)
import System.Types.Geometry (CoordinateExtent, Position(..))
import System.Types.Node (InternalNodeBase, NodeChange(..), NodeDragItem)
import System.Utils.Edges.Positions (getHandlePosition)
import System.Utils.Store
  ( adoptUserNodes
  , defaultUpdateNodesOptions
  , handleExpandParent
  , updateAbsolutePositions
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
  -- The limits live in two places: store state, which `panBy` and the
  -- viewport helpers read, and the d3 zoom behavior, which enforces them
  -- on a gesture. Writing only the first leaves a flow that changes any
  -- of the three after mount still bounded by the values it was created
  -- with. Each bound is read from the pre-update state, which is what
  -- upstream's `get()` before its `set()` gives it.
  SetMinZoom z ->
    { state: state { minZoom = z }
    , effects: [ RunSetScaleExtent z state.maxZoom ]
    }
  SetMaxZoom z ->
    { state: state { maxZoom = z }
    , effects: [ RunSetScaleExtent state.minZoom z ]
    }
  SetTranslateExtent ext ->
    { state: state { translateExtent = ext }
    , effects: [ RunSetTranslateExtent ext ]
    }
  SetNodeExtent ext -> reduceSetNodeExtent state ext
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
    s1 = adoptNodesInto state nodes
    fitViewNow = state.fitViewQueued && s1.nodesInitialized
  in
    { state: s1
        { fitViewQueued = if fitViewNow then false else state.fitViewQueued }
    , effects: if fitViewNow then [ ResolveFitView true ] else []
    }

-- | Re-adopt `nodes` into the lookups and write
-- | `nodes`/`nodeLookup`/`parentLookup`/`nodesInitialized` back onto the
-- | state. Shared by `reduceSetNodes` and the uncontrolled branch of
-- | `reduceTriggerNodeChanges`: a committed change has to re-adopt so the
-- | rendered nodes reflect it (`NodeWrapper` reads from `nodeLookup`, not
-- | the `nodes` array). `prev = state.nodeLookup` preserves the measured
-- | `handleBounds`/`bounds` of nodes that survive the change.
adoptNodesInto
  :: forall n e
   . ReactFlowState n e
  -> Array (Node n)
  -> ReactFlowState n e
adoptNodesInto state nodes =
  let
    r = adoptUserNodes nodes state.nodeLookup state.parentLookup
      ( defaultUpdateNodesOptions
          { nodeOrigin = state.nodeOrigin
          , nodeExtent = state.nodeExtent
          , elevateNodesOnSelect = state.elevateNodesOnSelect
          , zIndexMode = state.zIndexMode
          }
      )
  in
    state
      { nodes = nodes
      , nodeLookup = r.nodeLookup
      , parentLookup = r.parentLookup
      , nodesInitialized = r.nodesInitialized
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
reduceMergeNodeInternals state r
  -- TS `if (!updatedInternals) return;`: nothing was measured, so nothing
  -- is set, fitted, or reported.
  | not r.updatedInternals = { state, effects: [] }
  | otherwise =
      let
        -- TS `updateAbsolutePositions(nodeLookup, parentLookup, ...)`, now
        -- that the measured dimensions are in the lookup. TS doesn't touch
        -- `nodesInitialized` here; `setNodes` sets it when the measured
        -- nodes come back.
        positioned = updateAbsolutePositions r.nodeLookup r.parentLookup
          ( defaultUpdateNodesOptions
              { nodeOrigin = state.nodeOrigin
              , nodeExtent = state.nodeExtent
              , zIndexMode = state.zIndexMode
              }
          )
        s1 = state
          { nodeLookup = positioned.nodeLookup
          , parentLookup = positioned.parentLookup
          }
        -- TS resolves a queued fit, such as the initial `fitView`, before
        -- it triggers the node changes, so the viewport moves before
        -- `onNodesChange` fires. `r.triggerFitView` is ps-flow's: nothing
        -- sets it, and upstream's action takes no such parameter.
        fitNow = state.fitViewQueued || r.triggerFitView
        s2 = if fitNow then s1 { fitViewQueued = false } else s1
        fit = if fitNow then [ ResolveFitView true ] else []
        afterChanges =
          if Array.null r.changes then { state: s2, effects: [] }
          else reduceTriggerNodeChanges s2 r.changes
      in
        afterChanges { effects = fit <> afterChanges.effects }

-- UpdateNodePositions ---------------------------------------------------

reduceUpdateNodePositions
  :: forall n e
   . ReactFlowState n e
  -> Array NodeDragItem
  -> Boolean
  -> ReduceResult n e
reduceUpdateNodePositions state items dragging =
  let
    stepped = Array.foldl step { changes: [], parentExpandChildren: [], connection: state.connection } items

    -- TS reads the node from the lookup rather than the drag item, "to be
    -- sure to use the current expandParent and parentId value".
    step acc item =
      let
        mNode = Map.lookup item.id state.nodeLookup

        expandParentOf = case mNode of
          Just node | node.expandParent == Just true -> node.parentId
          _ -> Nothing

        change = NodePositionChange
          { id: item.id
          , position: Just case expandParentOf of
              Just _ -> { x: max 0.0 item.position.x, y: max 0.0 item.position.y }
              Nothing -> item.position
          , positionAbsolute: Nothing
          , dragging: Just dragging
          }

        -- The connection being drawn from a dragged node follows it, from
        -- the node as the lookup holds it before this change.
        connection = case mNode, acc.connection of
          Just node, ConnectionInProgress p
            | p.fromNode.id == node.id ->
                ConnectionInProgress p { from = getHandlePosition node (Just p.fromHandle) PosLeft true }
          _, c -> c

        expandChild = case expandParentOf of
          Just parentId ->
            [ { id: item.id
              , parentId
              , rect:
                  { x: item.internals.positionAbsolute.x
                  , y: item.internals.positionAbsolute.y
                  , width: item.measured.width
                  , height: item.measured.height
                  }
              }
            ]
          Nothing -> []
      in
        { changes: Array.snoc acc.changes change
        , parentExpandChildren: acc.parentExpandChildren <> expandChild
        , connection
        }

    expandChanges =
      if Array.null stepped.parentExpandChildren then []
      else handleExpandParent stepped.parentExpandChildren state.nodeLookup state.parentLookup state.nodeOrigin

    changes = Foldable.foldl (\cs middleware -> middleware cs)
      (stepped.changes <> expandChanges)
      (Map.values state.onNodesChangeMiddlewareMap)
  in
    reduceTriggerNodeChanges (state { connection = stepped.connection }) changes

-- TriggerNodeChanges ----------------------------------------------------

reduceTriggerNodeChanges
  :: forall n e
   . ReactFlowState n e
  -> Array (NodeChange n)
  -> ReduceResult n e
reduceTriggerNodeChanges state changes
  -- TS `triggerNodeChanges` does nothing at all for an empty list: no
  -- commit in uncontrolled mode and no `onNodesChange`. Every caller that
  -- found nothing to change, such as a pane click with nothing selected,
  -- reaches here with one.
  | Array.null changes = { state, effects: [] }
  | otherwise =
      let
        s1 =
          if state.hasDefaultNodes then
            -- Uncontrolled mode: commit the change *and* re-adopt so the lookup
            -- (what NodeWrapper renders from) reflects it — fixes uncontrolled
            -- drag and delete, which previously updated `nodes` but not the screen.
            adoptNodesInto state (applyNodeChanges changes state.nodes)
          else state
      in
        { state: s1, effects: [ FireOnNodesChange changes ] }

-- TriggerEdgeChanges ----------------------------------------------------

reduceTriggerEdgeChanges
  :: forall n e
   . ReactFlowState n e
  -> Array (EdgeChange e)
  -> ReduceResult n e
reduceTriggerEdgeChanges state changes
  -- TS `triggerEdgeChanges` guards the same way as `triggerNodeChanges`.
  | Array.null changes = { state, effects: [] }
  | otherwise =
      let
        s1 =
          if state.hasDefaultEdges then
            -- Uncontrolled mode: commit the change *and* rebuild `edgeLookup`
            -- (+ `connectionLookup`) so the rendered edges reflect it — EdgeWrapper
            -- reads `selected`/existence from `edgeLookup`, not the `edges` array.
            -- Mirrors `reduceSetEdges` and the node side's `reduceTriggerNodeChanges`
            -- re-adopt; without it uncontrolled edge select/delete never hit the DOM.
            let
              newEdges = applyEdgeChanges changes state.edges
              r = updateConnectionLookup newEdges
            in
              state
                { edges = newEdges
                , edgeLookup = r.edgeLookup
                , connectionLookup = r.connectionLookup
                }
          else state
      in
        { state: s1, effects: [ FireOnEdgesChange changes ] }

-- AddSelectedNodes ------------------------------------------------------

reduceAddSelectedNodes
  :: forall n e
   . ReactFlowState n e
  -> Array NodeId
  -> ReduceResult n e
reduceAddSelectedNodes state ids
  -- TS `addSelectedNodes`: while multi-selection is active, just mark these
  -- nodes selected — keep the existing node selection and leave edges untouched.
  | state.multiSelectionActive =
      let
        changes = map (\id -> NodeSelectionChange { id, selected: true }) ids
      in
        reduceTriggerNodeChanges state changes
  | otherwise =
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
reduceAddSelectedEdges state ids
  -- TS `addSelectedEdges`: while multi-selection is active, just mark these
  -- edges selected — keep the existing edge selection and leave nodes untouched.
  | state.multiSelectionActive =
      let
        changes = map (\id -> EdgeSelectionChange { id, selected: true }) ids
      in
        reduceTriggerEdgeChanges state changes
  | otherwise =
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

    nodesToUnselect = Array.filter (\n -> n.selected == Just true) targetNodes
    nodeChanges = map
      (\n -> NodeSelectionChange { id: n.id, selected: false })
      nodesToUnselect
    edgeChanges = map
      (\e -> EdgeSelectionChange { id: e.id, selected: false })
      (Array.filter (\e -> e.selected == Just true) targetEdges)

    -- TS unselects each internal node before it sends the change, "to
    -- prevent it to be selected while dragging the new node": a drag that
    -- starts by unselecting reads the lookup for its drag items.
    s1 = state
      { nodeLookup = Array.foldl
          (\lookup n -> Map.update (\internal -> Just internal { selected = Just false }) n.id lookup)
          state.nodeLookup
          nodesToUnselect
      }

    afterNodes = reduceTriggerNodeChanges s1 nodeChanges
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
reduceResetSelectedElements state
  -- TS `resetSelectedElements` returns before it reads a node or an edge
  -- when `elementsSelectable` is false. A selection the consumer passed in,
  -- such as a controlled node with `selected: true`, survives a pane click.
  | not state.elementsSelectable = { state, effects: [] }
  | otherwise =
      let
        nodePairs :: Array (Tuple NodeId (InternalNodeBase n))
        nodePairs = Map.toUnfoldable state.nodeLookup
        edgePairs :: Array (Tuple String (EdgeBase e))
        edgePairs = Map.toUnfoldable state.edgeLookup

        nodeChanges = Array.mapMaybe
          ( \(Tuple _ n) ->
              if n.selected == Just true then
                Just (NodeSelectionChange { id: n.id, selected: false })
              else Nothing
          )
          nodePairs
        edgeChanges = Array.mapMaybe
          ( \(Tuple _ e) ->
              if e.selected == Just true then
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
