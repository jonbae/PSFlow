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
  , reduceWith
  , Setup
  , ReduceResult
  ) where

import Prelude

import System.Utils.AsWritten (isHeld, iterated, member, orIfUndefined, reduced) as AsWritten

import System.Utils.Lookup as Lookup
import System.Utils.Number as JsNumber

import Data.Array (filter, foldl, null, snoc) as Array
import Data.Maybe (Maybe(..))
import Data.Set (Set)
import Data.Set as Set
import React.Store.Action
  ( Action(..)
  , Effect_(..)
  , FitInputs
  , NodeInternalsResult
  )
import React.Store.InPlace (inPlace, inPlaceThen)
import React.Store.Middleware (hasMiddleware)
import Foreign (unsafeToForeign)
import Unsafe.Reference (unsafeRefEq)
import React.Store.Changes
  ( applyEdgeChanges
  , applyNodeChanges
  , getEdgeSelectionChanges
  , getNodeSelectionChanges
  )
import React.Store.InitialState (initialStateKeys, resetState)
import React.Store.Partial (applyPartial)
import React.Types.Edges (Edge)
import React.Types.General (UnselectNodesAndEdgesParams)
import React.Types.Nodes (Node)
import React.Types.Store (ReactFlowState)
import System.Types.Connection (ConnectionLookup, ConnectionState(..), isInProgress, noConnection)
import System.Types.Edge (EdgeChange(..), EdgeLookup)
import System.Types.Ids (NodeId)
import System.Constants (infiniteExtent)
import System.Types.Geometry (CoordinateExtent(..), Position(..))
import System.Types.Node (NodeChange(..), NodeDragItem, NodeLookup)
import System.Utils.Edges.Positions (getHandlePosition)
import System.Utils.Store
  ( adoptUserNodes
  , defaultUpdateNodesOptions
  , handleExpandParent
  , updateAbsolutePositions
  , updateConnectionLookup
  )

-- | `writes` names the members upstream's `set` calls for the same action
-- | name, in the order they name them, whether or not their values change.
-- | A member a `setState(next, true)` left out comes back at the first one
-- | that names it. `PatchState`'s JavaScript caller keeps its own record, and
-- | `MutateState` hands the state back.
type ReduceResult n e =
  { state :: ReactFlowState n e
  , effects :: Array (Effect_ n e)
  , writes :: Array String
  }

-- | The top-level dispatcher, for a store created with an infinite
-- | `nodeExtent`. One case per `Action` constructor.
reduce
  :: forall n e
   . ReactFlowState n e
  -> Action n e
  -> ReduceResult n e
reduce = reduceWith { nodeExtent: infiniteExtent }

-- | What upstream's store closes over when `createStore` builds it. Its
-- | `setNodes` adopts with the `nodeExtent` the store was created with, a
-- | closure variable, whatever the store's own `nodeExtent` has become since;
-- | `setNodeExtent`, the drag and `updateNodeInternals` read the store's.
type Setup = { nodeExtent :: CoordinateExtent }

-- | `reduce`, for a store created with `setup`.
reduceWith
  :: forall n e
   . Setup
  -> ReactFlowState n e
  -> Action n e
  -> ReduceResult n e
reduceWith setup state = case _ of
  SetNodes ns -> reduceSetNodes setup state ns
  SetEdges es -> reduceSetEdges state es
  SetDefaultNodesAndEdges mNs mEs -> reduceSetDefaults setup state mNs mEs
  UpdateNodeInternals updates opts ->
    { state, effects: [ RunDomUpdateNodeInternals updates opts ], writes: [] }
  MergeNodeInternalsResult r -> reduceMergeNodeInternals state r
  UpdateNodePositions items dragging ->
    reduceUpdateNodePositions setup state items dragging
  TriggerNodeChanges cs -> reduceTriggerNodeChanges setup state cs
  TriggerEdgeChanges cs -> reduceTriggerEdgeChanges state cs
  AddSelectedNodes ids -> reduceAddSelectedNodes setup state ids
  AddSelectedEdges ids -> reduceAddSelectedEdges state ids
  ReplaceNodeSelection ids -> reduceReplaceNodeSelection setup state ids
  ReplaceEdgeSelection ids -> reduceReplaceEdgeSelection state ids
  UnselectNodesAndEdges params -> reduceUnselectNodesAndEdges setup state params
  -- The limits live in two places: store state, which `panBy` and the
  -- viewport helpers read, and the d3 zoom behavior, which enforces them
  -- on a gesture. Writing only the first leaves a flow that changes any
  -- of the three after mount still bounded by the values it was created
  -- with. Each bound is read from the pre-update state, which is what
  -- upstream's `get()` before its `set()` gives it.
  SetMinZoom z ->
    { state: state { minZoom = z }
    , effects: [ RunSetScaleExtent state.panZoom z state.maxZoom ]
    , writes: [ "minZoom" ]
    }
  SetMaxZoom z ->
    { state: state { maxZoom = z }
    , effects: [ RunSetScaleExtent state.panZoom state.minZoom z ]
    , writes: [ "maxZoom" ]
    }
  SetTranslateExtent ext ->
    { state: state { translateExtent = ext }
    , effects: [ RunSetTranslateExtent state.panZoom ext ]
    , writes: [ "translateExtent" ]
    }
  SetNodeExtent ext -> reduceSetNodeExtent state ext
  SetCenter x y opts -> { state, effects: [ RunSetCenter x y opts ], writes: [] }
  CancelConnection ->
    { state: state { connection = noConnection }, effects: [], writes: [ "connection" ] }
  UpdateConnection c ->
    { state: state { connection = c }, effects: [], writes: [ "connection" ] }
  ResetSelectedElements -> reduceResetSelectedElements setup state
  Reset -> { state: resetState state, effects: [], writes: initialStateKeys }
  -- `useOnViewportChange` writes all three on mount, `undefined` included.
  SetViewportChangeStartHandler callback ->
    { state: state { onViewportChangeStart = callback }
    , effects: []
    , writes: [ "onViewportChangeStart" ]
    }
  SetViewportChangeHandler callback ->
    { state: state { onViewportChange = callback }, effects: [], writes: [ "onViewportChange" ] }
  SetViewportChangeEndHandler callback ->
    { state: state { onViewportChangeEnd = callback }
    , effects: []
    , writes: [ "onViewportChangeEnd" ]
    }
  AddSelectionChangeHandler cb ->
    { state: state
        { onSelectionChangeHandlers =
            Array.snoc state.onSelectionChangeHandlers cb
        }
    , effects: []
    , writes: [ "onSelectionChangeHandlers" ]
    }
  RemoveSelectionChangeHandler cb ->
    { state: state
        { onSelectionChangeHandlers =
            Array.filter (\h -> not (unsafeRefEq h cb))
              state.onSelectionChangeHandlers
        }
    , effects: []
    , writes: [ "onSelectionChangeHandlers" ]
    }
  Assign p -> case applyPartial p state of
    Just r -> { state: r.state, effects: [], writes: r.written }
    Nothing -> { state, effects: [], writes: [] }
  PatchState f -> { state: f state, effects: [], writes: [] }
  MutateState f -> { state: inPlace f state, effects: [], writes: [] }

-- SetNodes ---------------------------------------------------------------

reduceSetNodes
  :: forall n e
   . Setup
  -> ReactFlowState n e
  -> Array (Node n)
  -> ReduceResult n e
reduceSetNodes setup state nodes =
  let
    s1 = adoptNodesInto setup state nodes
    fitViewNow = state.fitViewQueued && s1.nodesInitialized
  in
    { state:
        if fitViewNow then s1 { fitViewQueued = false, fitViewOptions = Nothing }
        else s1
    , effects: if fitViewNow then [ ResolveFitView (fitInputs state s1.nodeLookup) ] else []
    , writes: setNodesWrites fitViewNow
    }

-- | What upstream's `resolveFitView` reads with `get()`: `state` is the
-- | state the update started from, and `nodes` the lookup it adopted.
fitInputs :: forall n e. ReactFlowState n e -> NodeLookup n -> FitInputs n
fitInputs state nodes =
  { nodes
  , width: state.width
  , height: state.height
  , panZoom: state.panZoom
  , minZoom: state.minZoom
  , maxZoom: state.maxZoom
  , options: state.fitViewOptions
  , resolver: state.fitViewResolver
  }

-- | `setNodes`' `set`: with the queued fit's two members when it fits.
setNodesWrites :: Boolean -> Array String
setNodesWrites fits =
  if fits then [ "nodes", "nodesInitialized", "fitViewQueued", "fitViewOptions", "nodesSelectionActive" ]
  else [ "nodes", "nodesInitialized", "nodesSelectionActive" ]

-- | Re-adopt `nodes` into the lookups and write
-- | `nodes`/`nodeLookup`/`parentLookup`/`nodesInitialized` back onto the
-- | state, for `reduceSetNodes`. `NodeWrapper` renders from `nodeLookup`, not
-- | the `nodes` array, so every new `nodes` has to re-adopt. `prev =
-- | state.nodeLookup` preserves the measured `handleBounds`/`bounds` of
-- | nodes that survive the change.
adoptNodesInto
  :: forall n e
   . Setup
  -> ReactFlowState n e
  -> Array (Node n)
  -> ReactFlowState n e
adoptNodesInto setup state nodes =
  let
    r = adoptUserNodes nodes state.nodeLookup state.parentLookup
      ( defaultUpdateNodesOptions
          -- TS `mergeObjects(defaultOptions, options)` puts the default in
          -- place of an `undefined` option.
          { nodeOrigin = AsWritten.orIfUndefined defaultUpdateNodesOptions.nodeOrigin state.nodeOrigin
          , nodeExtent = setup.nodeExtent
          , elevateNodesOnSelect = state.elevateNodesOnSelect
          , zIndexMode = state.zIndexMode
          -- TS fills the store's own lookups in place, and a node that
          -- throws leaves them holding the nodes before it, set by nobody.
          , keepProgress = \progress ->
              inPlaceThen (_ { nodeLookup = progress.nodeLookup, parentLookup = progress.parentLookup }) state unit
          }
      )
  in
    state
      { nodes = nodes
      , nodeLookup = r.nodeLookup
      , parentLookup = r.parentLookup
      , nodesInitialized = r.nodesInitialized
      , nodesSelectionActive = state.nodesSelectionActive && r.hasSelectedNodes
      }

-- SetEdges ---------------------------------------------------------------

reduceSetEdges
  :: forall n e
   . ReactFlowState n e
  -> Array (Edge e)
  -> ReduceResult n e
reduceSetEdges state edges =
  let
    r = updateConnectionLookup (keepLookups state) state.connectionLookup state.edgeLookup edges
  in
    { state: state
        { edges = edges
        , edgeLookup = r.edgeLookup
        , connectionLookup = r.connectionLookup
        }
    , effects: []
    , writes: [ "edges" ]
    }

-- SetDefaultNodesAndEdges -----------------------------------------------

reduceSetDefaults
  :: forall n e
   . Setup
  -> ReactFlowState n e
  -> Maybe (Array (Node n))
  -> Maybe (Array (Edge e))
  -> ReduceResult n e
reduceSetDefaults setup state mNs mEs =
  let
    afterNodes = case mNs of
      Just ns ->
        let
          res = reduceSetNodes setup state ns
        in
          { state: res.state { hasDefaultNodes = true }
          , effects: res.effects
          , writes: res.writes <> [ "hasDefaultNodes" ]
          }
      Nothing -> { state, effects: [], writes: [] }
    afterEdges = case mEs of
      Just es ->
        let
          res = reduceSetEdges afterNodes.state es
        in
          { state: res.state { hasDefaultEdges = true }
          , effects: afterNodes.effects <> res.effects
          , writes: afterNodes.writes <> res.writes <> [ "hasDefaultEdges" ]
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
  | not r.updatedInternals = { state, effects: [], writes: [] }
  | otherwise =
      let
        -- TS `updateAbsolutePositions(nodeLookup, parentLookup, ...)`, now
        -- that the measured dimensions are in the lookup. TS doesn't touch
        -- `nodesInitialized` here; `setNodes` sets it when the measured
        -- nodes come back.
        positioned = updateAbsolutePositions r.nodeLookup r.parentLookup
          ( defaultUpdateNodesOptions
              { nodeOrigin = AsWritten.orIfUndefined defaultUpdateNodesOptions.nodeOrigin state.nodeOrigin
              , nodeExtent = AsWritten.orIfUndefined defaultUpdateNodesOptions.nodeExtent state.nodeExtent
              -- TS has already written the measured internals into the
              -- store's lookup, and placed the nodes before one that throws.
              , keepProgress = \progress ->
                  inPlaceThen (_ { nodeLookup = progress.nodeLookup, parentLookup = progress.parentLookup }) state unit
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
        s2 = if fitNow then s1 { fitViewQueued = false, fitViewOptions = Nothing } else s1
        fit = if fitNow then [ ResolveFitView (fitInputs state s1.nodeLookup) ] else []
        -- Upstream first calls set({}) to notify about the measured
        -- internals, then triggerNodeChanges may call setNodes. Combining
        -- those writes loses a selector evaluation and its observable errors.
        changes = if Array.null r.changes then [] else [ RunTriggerNodeChanges r.changes ]
      in
        { state: s2
        , effects: fit <> changes
        , writes: if fitNow then [ "fitViewQueued", "fitViewOptions" ] else []
        }

-- UpdateNodePositions ---------------------------------------------------

reduceUpdateNodePositions
  :: forall n e
   . Setup
  -> ReactFlowState n e
  -> Array NodeDragItem
  -> Boolean
  -> ReduceResult n e
reduceUpdateNodePositions setup state items dragging =
  let
    stepped = Array.foldl step { changes: [], parentExpandChildren: [], connection: state.connection } items

    -- TS reads the node from the lookup rather than the drag item, "to be
    -- sure to use the current expandParent and parentId value".
    step acc item =
      let
        mNode = Lookup.get item.id state.nodeLookup

        expandParentOf = case mNode of
          Just node | node.expandParent == Just true -> node.parentId
          _ -> Nothing

        change = NodePositionChange
          { id: item.id
          , position: Just case expandParentOf of
              Just _ ->
                { x: JsNumber.max 0.0 item.position.x
                , y: JsNumber.max 0.0 item.position.y
                }
              Nothing -> item.position
          , positionAbsolute: Nothing
          , dragging: Just dragging
          }

        -- The connection being drawn from a dragged node follows it, from
        -- the node as the lookup holds it before this change.
        connection = case mNode, acc.connection of
          -- TS `connection.inProgress && connection.fromNode.id === node.id`,
          -- of a connection a consumer wrote with a value of another shape,
          -- which only reads it.
          Just node, c
            | AsWritten.isHeld c
                && isInProgress c
                && unsafeRefEq (AsWritten.member "id" (AsWritten.member "fromNode" c)) (unsafeToForeign node.id) -> c
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

    changes = stepped.changes <> expandChanges
    -- Upstream only sets connection state when dragging its source node.
    -- In a controlled flow, reporting position changes otherwise performs
    -- no store write; a redundant write wakes subscribers upstream leaves idle.
    nextState = if unsafeRefEq state.connection stepped.connection then state
      else state { connection = stepped.connection }
    -- Upstream's `updateConnection` sets `connection`.
    connectionWrites = if unsafeRefEq state.connection stepped.connection then [] else [ "connection" ]
  in
    -- With middleware registered, the changes run through it in the shell,
    -- where a store write the consumer's middleware makes survives. With
    -- none, there is nothing to run and the trigger stays in this update.
    if hasMiddleware state.onNodesChangeMiddlewareMap then
      { state: nextState, effects: [ RunNodesChangeMiddleware changes ], writes: connectionWrites }
    else
      let
        triggered = reduceTriggerNodeChanges setup nextState changes
      in
        triggered { writes = connectionWrites <> triggered.writes }

-- TriggerNodeChanges ----------------------------------------------------

reduceTriggerNodeChanges
  :: forall n e
   . Setup
  -> ReactFlowState n e
  -> Array (NodeChange n)
  -> ReduceResult n e
reduceTriggerNodeChanges setup state changes
  -- TS `triggerNodeChanges` does nothing at all for an empty list: no
  -- commit in uncontrolled mode and no `onNodesChange`. Every caller that
  -- found nothing to change, such as a pane click with nothing selected,
  -- reaches here with one.
  | Array.null changes = { state, effects: [], writes: [] }
  -- Uncontrolled mode: TS applies the changes and calls `setNodes`, which
  -- re-adopts them into the lookup `NodeWrapper` renders from and fits a
  -- queued view once the nodes are initialized.
  | state.hasDefaultNodes =
      let
        r = reduceSetNodes setup state (applyNodeChanges changes state.nodes)
      in
        r { effects = r.effects <> [ FireOnNodesChange changes ] }
  | otherwise = { state, effects: [ FireOnNodesChange changes ], writes: [] }

-- TriggerEdgeChanges ----------------------------------------------------

reduceTriggerEdgeChanges
  :: forall n e
   . ReactFlowState n e
  -> Array (EdgeChange e)
  -> ReduceResult n e
reduceTriggerEdgeChanges state changes
  -- TS `triggerEdgeChanges` guards the same way as `triggerNodeChanges`.
  | Array.null changes = { state, effects: [], writes: [] }
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
              r = updateConnectionLookup (keepLookups state) state.connectionLookup state.edgeLookup newEdges
            in
              state
                { edges = newEdges
                , edgeLookup = r.edgeLookup
                , connectionLookup = r.connectionLookup
                }
          else state
      in
        { state: s1
        , effects: [ FireOnEdgesChange changes ]
        , writes: if state.hasDefaultEdges then [ "edges" ] else []
        }

-- AddSelectedNodes ------------------------------------------------------

reduceAddSelectedNodes
  :: forall n e
   . Setup
  -> ReactFlowState n e
  -> Array NodeId
  -> ReduceResult n e
reduceAddSelectedNodes setup state ids
  -- TS `addSelectedNodes`: while multi-selection is active, just mark these
  -- nodes selected — keep the existing node selection and leave edges untouched.
  | state.multiSelectionActive =
      let
        changes = map (\id -> NodeSelectionChange { id, selected: true }) ids
      in
        reduceTriggerNodeChanges setup state changes
  -- Otherwise TS selects exactly these nodes, then unselects every edge, an
  -- empty list included. The edge statement runs once the node one's `set`
  -- and `onNodesChange` are done.
  | otherwise =
      let
        nodes = reduceReplaceNodeSelection setup state (Set.fromFoldable ids)
      in
        nodes { effects = nodes.effects <> [ RunReplaceEdgeSelection Set.empty ] }

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
  -- Otherwise TS selects exactly these edges, then unselects every node, an
  -- empty list included. The node statement runs once the edge one's `set`
  -- and `onEdgesChange` are done, so the internal nodes are unselected
  -- after `onEdgesChange`.
  | otherwise =
      let
        edges = reduceReplaceEdgeSelection state (Set.fromFoldable ids)
      in
        edges { effects = edges.effects <> [ RunReplaceNodeSelection Set.empty ] }

-- ReplaceNodeSelection, ReplaceEdgeSelection -----------------------------

-- | TS `triggerNodeChanges(getSelectionChanges(nodeLookup, ids, true))`.
reduceReplaceNodeSelection
  :: forall n e
   . Setup
  -> ReactFlowState n e
  -> Set NodeId
  -> ReduceResult n e
reduceReplaceNodeSelection setup state ids =
  let
    r = getNodeSelectionChanges state.nodes state.nodeLookup ids true
    -- TS's `getSelectionChanges(..., true)` selects the internal nodes in
    -- place, so a controlled flow's store notifies nobody until the
    -- consumer's nodes come back.
    s1 = inPlace (_ { nodeLookup = r.items }) state
  in
    reduceTriggerNodeChanges setup s1 r.changes

-- | TS `triggerEdgeChanges(getSelectionChanges(edgeLookup, ids))`.
reduceReplaceEdgeSelection
  :: forall n e
   . ReactFlowState n e
  -> Set String
  -> ReduceResult n e
reduceReplaceEdgeSelection state ids =
  reduceTriggerEdgeChanges state (getEdgeSelectionChanges state.edges state.edgeLookup ids).changes

-- UnselectNodesAndEdges -------------------------------------------------

reduceUnselectNodesAndEdges
  :: forall n e
   . Setup
  -> ReactFlowState n e
  -> UnselectNodesAndEdgesParams n e
  -> ReduceResult n e
reduceUnselectNodesAndEdges setup state params =
  let
    -- TS walks each with `for…of`.
    targetNodes = AsWritten.iterated case params.nodes of
      Just ns -> ns
      Nothing -> state.nodes
    targetEdges = AsWritten.iterated case params.edges of
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
    -- starts by unselecting reads the lookup for its drag items. It does so
    -- in place, so the store notifies nobody of it.
    s1 = inPlace
      ( _
          { nodeLookup = Array.foldl
              ( \lookup n -> case Lookup.get n.id lookup of
                  Nothing -> lookup
                  Just internal -> inPlaceThen (_ { selected = Just false }) internal lookup
              )
              state.nodeLookup
              nodesToUnselect
          }
      )
      state

    afterNodes = reduceTriggerNodeChanges setup s1 nodeChanges
    afterEdges = reduceTriggerEdgeChanges afterNodes.state edgeChanges
  in
    { state: afterEdges.state
    , effects: afterNodes.effects <> afterEdges.effects
    , writes: afterNodes.writes <> afterEdges.writes
    }

-- SetNodeExtent ---------------------------------------------------------

reduceSetNodeExtent
  :: forall n e
   . ReactFlowState n e
  -> CoordinateExtent
  -> ReduceResult n e
reduceSetNodeExtent state ext
  -- TS compares the four numbers with `===` and returns before its `set`.
  | sameExtent ext state.nodeExtent = { state, effects: [], writes: [] }
  | otherwise =
      let
        -- TS re-adopts with `checkEquality: false`, so a node whose user
        -- object is unchanged is still rebuilt and clamped to the new extent.
        r = adoptUserNodes state.nodes state.nodeLookup state.parentLookup
          ( defaultUpdateNodesOptions
              { nodeOrigin = state.nodeOrigin
              , nodeExtent = ext
              , elevateNodesOnSelect = state.elevateNodesOnSelect
              , zIndexMode = state.zIndexMode
              , checkEquality = false
              }
          )
      in
        { state: state
            { nodeExtent = ext
            , nodeLookup = r.nodeLookup
            , parentLookup = r.parentLookup
            }
        , effects: []
        , writes: [ "nodeExtent" ]
        }

-- | TS's four `===` comparisons, in its order: `[0][0]`, `[0][1]`, `[1][0]`,
-- | `[1][1]`, stopping at the first that differs.
sameExtent :: CoordinateExtent -> CoordinateExtent -> Boolean
sameExtent (CoordinateExtent a) (CoordinateExtent b) =
  a.minX == b.minX
    && a.minY == b.minY
    && a.maxX == b.maxX
    && a.maxY == b.maxY

-- | Where upstream's `updateConnectionLookup` throws partway, the store's
-- | own lookups, which it clears and fills in place, stay as far as it got,
-- | set by nobody.
keepLookups
  :: forall n e
   . ReactFlowState n e
  -> { connectionLookup :: ConnectionLookup, edgeLookup :: EdgeLookup e }
  -> Unit
keepLookups state progress =
  inPlaceThen (_ { connectionLookup = progress.connectionLookup, edgeLookup = progress.edgeLookup }) state unit

-- ResetSelectedElements -------------------------------------------------

reduceResetSelectedElements
  :: forall n e
   . Setup
  -> ReactFlowState n e
  -> ReduceResult n e
reduceResetSelectedElements setup state
  -- TS `resetSelectedElements` returns before it reads a node or an edge
  -- when `elementsSelectable` is false. A selection the consumer passed in,
  -- such as a controlled node with `selected: true`, survives a pane click.
  | not state.elementsSelectable = { state, effects: [], writes: [] }
  | otherwise =
      let
        -- TS `nodes.reduce(…)` and `edges.reduce(…)` over the consumer's
        -- nodes and edges, not the lookups: a node selected in place, by a
        -- selection box in a flow that ignores the change, is not reset.
        nodeChanges = AsWritten.reduced
          ( \res n ->
              if n.selected == Just true then Array.snoc res (NodeSelectionChange { id: n.id, selected: false })
              else res
          )
          []
          state.nodes
        edgeChanges = AsWritten.reduced
          ( \res e ->
              if e.selected == Just true then Array.snoc res (EdgeSelectionChange { id: e.id, selected: false })
              else res
          )
          []
          state.edges

        afterNodes = reduceTriggerNodeChanges setup state nodeChanges
        afterEdges = reduceTriggerEdgeChanges afterNodes.state edgeChanges
      in
        { state: afterEdges.state
        , effects: afterNodes.effects <> afterEdges.effects
        , writes: afterNodes.writes <> afterEdges.writes
        }
