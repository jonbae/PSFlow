-- | Pure helpers that apply `NodeChange` and `EdgeChange` values to
-- | arrays of nodes and edges. Ports
-- | `xyflow-main/packages/react/src/utils/changes.ts` 1:1, with TS
-- | mutable-update style replaced by record-update returning new values.
-- |
-- | All functions are pure — the React reducer calls them inline and
-- | tests them directly with QuickCheck.
module React.Store.Changes
  ( applyNodeChanges
  , applyEdgeChanges
  , createSelectionChangePayload
  , getNodeSelectionChanges
  , getEdgeSelectionChanges
  , getNodeElementsDiffChanges
  , getEdgeElementsDiffChanges
  , nodeToRemoveChange
  , edgeToRemoveChange
  , SelectionChangePayload
  ) where

import Prelude

import Data.Array (snoc) as Array
import Data.Foldable (foldl)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Set (Set)
import Data.Set as Set
import Data.Tuple (Tuple(..))
import React.Types.Edges (Edge)
import React.Types.Nodes (Node)
import System.Types.Edge (EdgeChange(..), EdgeLookup)
import System.Types.Node
  ( InternalNodeBase
  , NodeChange(..)
  , NodeLookup
  )

-- | Selection-change payload independent of node-vs-edge. The wrappers
-- | below promote it into a `NodeChange n` or `EdgeChange e`.
type SelectionChangePayload = { id :: String, selected :: Boolean }

createSelectionChangePayload :: String -> Boolean -> SelectionChangePayload
createSelectionChangePayload id selected = { id, selected }

-- | One bucket per change kind. `remove`/`replace` for an id wipes the
-- | per-id list (subsequent normal changes are pointless); `add` goes to
-- | its own bucket because adds happen *after* the existing-elements
-- | walk so indexed inserts land correctly.
type NodeChangeBuckets n =
  { byId :: Map String (Array (NodeChange n))
  , adds :: Array (NodeChange n)
  }

type EdgeChangeBuckets e =
  { byId :: Map String (Array (EdgeChange e))
  , adds :: Array (EdgeChange e)
  }

partitionNodeChanges :: forall n. Array (NodeChange n) -> NodeChangeBuckets n
partitionNodeChanges = foldl step { byId: Map.empty, adds: [] }
  where
  step acc c = case c of
    NodeAddChange _ -> acc { adds = Array.snoc acc.adds c }
    NodeRemoveChange { id } -> acc { byId = Map.insert id [ c ] acc.byId }
    NodeReplaceChange { id } -> acc { byId = Map.insert id [ c ] acc.byId }
    NodeDimensionChange { id } -> acc { byId = appendChange id c acc.byId }
    NodePositionChange { id } -> acc { byId = appendChange id c acc.byId }
    NodeSelectionChange { id } -> acc { byId = appendChange id c acc.byId }

  appendChange id c m = case Map.lookup id m of
    Nothing -> Map.insert id [ c ] m
    Just existing -> Map.insert id (Array.snoc existing c) m

partitionEdgeChanges :: forall e. Array (EdgeChange e) -> EdgeChangeBuckets e
partitionEdgeChanges = foldl step { byId: Map.empty, adds: [] }
  where
  step acc c = case c of
    EdgeAddChange _ -> acc { adds = Array.snoc acc.adds c }
    EdgeRemoveChange { id } -> acc { byId = Map.insert id [ c ] acc.byId }
    EdgeReplaceChange { id } -> acc { byId = Map.insert id [ c ] acc.byId }
    EdgeSelectionChange { id } -> acc { byId = appendChange id c acc.byId }

  appendChange id c m = case Map.lookup id m of
    Nothing -> Map.insert id [ c ] m
    Just existing -> Map.insert id (Array.snoc existing c) m

-- | Apply a single non-terminal change to a node. The outer driver
-- | handles `Remove` / `Replace` / `Add`. Note that the TS source's
-- | `resizing` flag has no representation on `NodeBase` (it lives on
-- | the React-layer `Node` extension in TS); we drop it here. If a
-- | future ticket adds a row-typed React `Node`, restore the
-- | resizing-update line.
applySingleNodeChange :: forall n. NodeChange n -> Node n -> Node n
applySingleNodeChange c node = case c of
  NodeSelectionChange { selected } -> node { selected = selected }
  NodePositionChange { position, dragging } ->
    let
      withPos = case position of
        Just p -> node { position = p }
        Nothing -> node
    in
      withPos { dragging = dragging }
  NodeDimensionChange { dimensions, setAttributes } ->
    case dimensions of
      Nothing -> node
      Just d ->
        let
          withMeasured =
            node { measured = { width: Just d.width, height: Just d.height } }
        in
          case setAttributes of
            Nothing -> withMeasured
            Just sa ->
              let
                n1 = if sa.width then withMeasured { width = Just d.width } else withMeasured
                n2 = if sa.height then n1 { height = Just d.height } else n1
              in
                n2
  -- Remove / Replace / Add are routed in the outer driver.
  NodeRemoveChange _ -> node
  NodeReplaceChange _ -> node
  NodeAddChange _ -> node

applySingleEdgeChange :: forall e. EdgeChange e -> Edge e -> Edge e
applySingleEdgeChange c edge = case c of
  EdgeSelectionChange { selected } -> edge { selected = selected }
  _ -> edge

-- | Apply all queued changes for one node id. Returns `Nothing` if the
-- | element should be dropped (remove change present).
applyChangesForNode
  :: forall n. Node n -> Array (NodeChange n) -> Maybe (Node n)
applyChangesForNode node changes = foldl step (Just node) changes
  where
  step acc c = case acc of
    Nothing -> Nothing -- a remove earlier in the list dominates
    Just curr -> case c of
      NodeRemoveChange _ -> Nothing
      NodeReplaceChange { item } -> Just item
      _ -> Just (applySingleNodeChange c curr)

applyChangesForEdge
  :: forall e. Edge e -> Array (EdgeChange e) -> Maybe (Edge e)
applyChangesForEdge edge changes = foldl step (Just edge) changes
  where
  step acc c = case acc of
    Nothing -> Nothing
    Just curr -> case c of
      EdgeRemoveChange _ -> Nothing
      EdgeReplaceChange { item } -> Just item
      _ -> Just (applySingleEdgeChange c curr)

-- | Public: apply an array of `NodeChange`s to an array of nodes.
applyNodeChanges
  :: forall n. Array (NodeChange n) -> Array (Node n) -> Array (Node n)
applyNodeChanges changes nodes =
  let
    buckets = partitionNodeChanges changes
    afterUpdates =
      foldl
        ( \acc node -> case Map.lookup node.id buckets.byId of
            Nothing -> Array.snoc acc node
            Just cs -> case applyChangesForNode node cs of
              Nothing -> acc
              Just updated -> Array.snoc acc updated
        )
        []
        nodes
  in
    foldl applyNodeAdd afterUpdates buckets.adds
  where
  applyNodeAdd acc c = case c of
    NodeAddChange { item } -> Array.snoc acc item
    _ -> acc

applyEdgeChanges
  :: forall e. Array (EdgeChange e) -> Array (Edge e) -> Array (Edge e)
applyEdgeChanges changes edges =
  let
    buckets = partitionEdgeChanges changes
    afterUpdates =
      foldl
        ( \acc edge -> case Map.lookup edge.id buckets.byId of
            Nothing -> Array.snoc acc edge
            Just cs -> case applyChangesForEdge edge cs of
              Nothing -> acc
              Just updated -> Array.snoc acc updated
        )
        []
        edges
  in
    foldl applyEdgeAdd afterUpdates buckets.adds
  where
  applyEdgeAdd acc c = case c of
    EdgeAddChange { item } -> Array.snoc acc item
    _ -> acc

-- | Selection-diff helper. Row-polymorphic so it works for both
-- | `NodeLookup` and `EdgeLookup`.
getSelectionChangesGeneric
  :: forall r
   . Map String { id :: String, selected :: Boolean | r }
  -> Set String
  -> Boolean
  -> { changes :: Array SelectionChangePayload
     , items :: Map String { id :: String, selected :: Boolean | r }
     }
getSelectionChangesGeneric items selectedIds mutate =
  let
    pairs :: Array (Tuple String { id :: String, selected :: Boolean | r })
    pairs = Map.toUnfoldable items
    step acc (Tuple id item) =
      let
        willBeSelected = Set.member id selectedIds
      in
        if item.selected /= willBeSelected then
          let
            change = { id: item.id, selected: willBeSelected }
            newItems =
              if mutate then
                Map.insert id (item { selected = willBeSelected }) acc.items
              else acc.items
          in
            acc { changes = Array.snoc acc.changes change, items = newItems }
        else acc
  in
    foldl step { changes: [], items } pairs

getNodeSelectionChanges
  :: forall n
   . NodeLookup n
  -> Set String
  -> Boolean
  -> { changes :: Array (NodeChange n)
     , items :: NodeLookup n
     }
getNodeSelectionChanges lookup selectedIds mutate =
  let
    r = getSelectionChangesGeneric lookup selectedIds mutate
    changes = map (\p -> NodeSelectionChange { id: p.id, selected: p.selected }) r.changes
  in
    { changes, items: r.items }

getEdgeSelectionChanges
  :: forall e
   . EdgeLookup e
  -> Set String
  -> { changes :: Array (EdgeChange e)
     }
getEdgeSelectionChanges lookup selectedIds =
  let
    r = getSelectionChangesGeneric lookup selectedIds false
    changes = map (\p -> EdgeSelectionChange { id: p.id, selected: p.selected }) r.changes
  in
    { changes }

-- | Diff between a fresh user-supplied node array and the store's
-- | current lookup. Produces `add` / `remove` / `replace` changes.
getNodeElementsDiffChanges
  :: forall n
   . Maybe (Array (Node n))
  -> NodeLookup n
  -> Array (NodeChange n)
getNodeElementsDiffChanges mItems lookup =
  let
    items = case mItems of
      Just xs -> xs
      Nothing -> []
    itemsLookup :: Map String (Node n)
    itemsLookup = Map.fromFoldable (map (\n -> Tuple n.id n) items)
    forwardPass = foldl forwardStep { changes: [], index: 0 } items
    forwardStep acc item =
      let
        storeItem :: Maybe (InternalNodeBase n)
        storeItem = Map.lookup item.id lookup
        change = case storeItem of
          Just _ -> NodeReplaceChange { id: item.id, item }
          Nothing -> NodeAddChange { item, index: Just acc.index }
      in
        { changes: Array.snoc acc.changes change, index: acc.index + 1 }
    removes =
      foldl
        ( \acc (Tuple id _) ->
            if Map.member id itemsLookup then acc
            else Array.snoc acc (NodeRemoveChange { id })
        )
        []
        (Map.toUnfoldable lookup :: Array (Tuple String (InternalNodeBase n)))
  in
    forwardPass.changes <> removes

getEdgeElementsDiffChanges
  :: forall e
   . Maybe (Array (Edge e))
  -> EdgeLookup e
  -> Array (EdgeChange e)
getEdgeElementsDiffChanges mItems lookup =
  let
    items = case mItems of
      Just xs -> xs
      Nothing -> []
    itemsLookup :: Map String (Edge e)
    itemsLookup = Map.fromFoldable (map (\e -> Tuple e.id e) items)
    forwardPass = foldl forwardStep { changes: [], index: 0 } items
    forwardStep acc item =
      let
        change = case Map.lookup item.id lookup of
          Just _ -> EdgeReplaceChange { id: item.id, item }
          Nothing -> EdgeAddChange { item, index: Just acc.index }
      in
        { changes: Array.snoc acc.changes change, index: acc.index + 1 }
    removes =
      foldl
        ( \acc (Tuple id _) ->
            if Map.member id itemsLookup then acc
            else Array.snoc acc (EdgeRemoveChange { id })
        )
        []
        (Map.toUnfoldable lookup :: Array (Tuple String (Edge e)))
  in
    forwardPass.changes <> removes

nodeToRemoveChange :: forall n. Node n -> NodeChange n
nodeToRemoveChange n = NodeRemoveChange { id: n.id }

edgeToRemoveChange :: forall e. Edge e -> EdgeChange e
edgeToRemoveChange e = EdgeRemoveChange { id: e.id }
