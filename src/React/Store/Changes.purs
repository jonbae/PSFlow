-- | Pure helpers that apply `NodeChange` and `EdgeChange` values to
-- | arrays of nodes and edges. Ports
-- | `xyflow/packages/react/src/utils/changes.ts` 1:1, with TS
-- | mutable-update style replaced by record-update returning new values.
-- |
-- | Applying changes is pure. Selection discovery's `mutate` branch writes
-- | into the existing internal nodes, as upstream's getSelectionChanges does.
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

import System.Utils.AsWritten (iterated, mapped, orIfUndefined) as AsWritten

import System.Utils.Lookup as Lookup

import Data.Array (insertAt, length, snoc, uncons) as Array
import Data.Foldable (foldl)
import Data.Function.Uncurried (runFn3)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Set (Set)
import Data.Set as Set
import Data.Tuple (Tuple(..))
import React.Types.Edges (Edge)
import React.Types.Nodes (Node)
import React.Store.InPlace (inPlaceThen)
import System.Types.Edge (EdgeChange(..), EdgeLookup)
import System.Types.Ids (NodeId)
import Unsafe.Reference (unsafeRefEq)
import System.Types.Node
  ( NodeChange(..)
  , NodeLookup
  , copyNodeRecord
  , rememberNodeUpdate
  , userNodeIdentity
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
  { byId :: Map NodeId (Array (NodeChange n))
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
-- | handles `Remove` / `Replace` / `Add`.
applySingleNodeChange :: forall n. NodeChange n -> Node n -> Node n
applySingleNodeChange c node = case c of
  NodeSelectionChange { selected } ->
    runFn3 rememberNodeUpdate node (node { selected = Just selected }) { selected }
  NodePositionChange { position, dragging } ->
    let
      withPos = case position of
        Just p -> runFn3 rememberNodeUpdate node (node { position = p }) { position: p }
        Nothing -> node
    in
      -- TS `if (typeof change.dragging !== 'undefined')`.
      case dragging of
        Just value ->
          runFn3 rememberNodeUpdate withPos (withPos { dragging = dragging }) { dragging: value }
        Nothing -> withPos
  NodeDimensionChange { dimensions, setAttributes, resizing } ->
    let
      measured = case dimensions of
        Nothing -> node
        Just d ->
          let
            withMeasured = runFn3 rememberNodeUpdate node
              (node { measured = { width: Just d.width, height: Just d.height } })
              { measured: copyNodeRecord d }
          in
            case setAttributes of
              Nothing -> withMeasured
              Just sa ->
                let
                  n1 =
                    if sa.width then
                      runFn3 rememberNodeUpdate withMeasured
                        (withMeasured { width = Just d.width }) { width: d.width }
                    else withMeasured
                  n2 =
                    if sa.height then
                      runFn3 rememberNodeUpdate n1
                        (n1 { height = Just d.height }) { height: d.height }
                    else n1
                in
                  n2
    in case resizing of
      Nothing -> measured
      Just value ->
        runFn3 rememberNodeUpdate measured (measured { resizing = resizing }) { resizing: value }
  -- Remove / Replace / Add are routed in the outer driver.
  NodeRemoveChange _ -> node
  NodeReplaceChange _ -> node
  NodeAddChange _ -> node

applySingleEdgeChange :: forall e. EdgeChange e -> Edge e -> Edge e
applySingleEdgeChange c edge = case c of
  EdgeSelectionChange { selected } -> edge { selected = Just selected }
  _ -> edge

-- | Apply all queued changes for one node id. Returns `Nothing` if the
-- | element should be dropped (remove change present).
-- |
-- | TS inspects `changes[0]` alone for `remove` and `replace` and then
-- | `continue`s the element loop, so anything queued *behind* either one is
-- | dropped — a replace hands over a whole new element, and a partial update
-- | computed against the old one has nothing left to say. Both can only ever
-- | be the head: bucketing a remove or a replace overwrites the id's list
-- | rather than appending to it.
-- | Copy affected nodes before updating, keeping their consumer fields beside
-- | each typed record so later adoption and callbacks see the updated object.
applyChangesForNode
  :: forall n. Node n -> Array (NodeChange n) -> Maybe (Node n)
applyChangesForNode node changes = case Array.uncons changes of
  Nothing -> Just node
  Just { head } -> case head of
    NodeRemoveChange _ -> Nothing
    NodeReplaceChange { item } -> Just (copyNodeRecord item)
    _ -> Just (foldl (\curr c -> applySingleNodeChange c curr) (copyNodeRecord node) changes)

applyChangesForEdge
  :: forall e. Edge e -> Array (EdgeChange e) -> Maybe (Edge e)
applyChangesForEdge edge changes = case Array.uncons changes of
  Nothing -> Just edge
  Just { head } -> case head of
    EdgeRemoveChange _ -> Nothing
    EdgeReplaceChange { item } -> Just item
    _ -> Just (foldl (\curr c -> applySingleEdgeChange c curr) edge changes)

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
        -- TS `for (const element of elements)`.
        (AsWritten.iterated nodes)
  in
    foldl applyNodeAdd afterUpdates buckets.adds
  where
  applyNodeAdd acc c = case c of
    NodeAddChange { item, index } -> insertItemAt index (copyNodeRecord item) acc
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
        (AsWritten.iterated edges)
  in
    foldl applyEdgeAdd afterUpdates buckets.adds
  where
  applyEdgeAdd acc c = case c of
    EdgeAddChange { item, index } -> insertItemAt index item acc
    _ -> acc

-- | Place an `add` change's item. TS runs the adds after the existing-elements
-- | walk so an index lands against the final array, then
-- | `updatedElements.splice(change.index, 0, item)` — and `splice` *clamps*
-- | its start rather than refusing: past the end appends, and a negative
-- | counts back from the end, bottoming out at 0. `Array.insertAt` rejects
-- | both, so the clamp is spelled out here.
insertItemAt :: forall a. Maybe Int -> a -> Array a -> Array a
insertItemAt mIndex item arr = case mIndex of
  Nothing -> Array.snoc arr item
  Just i ->
    let
      len = Array.length arr
      at = if i < 0 then max 0 (len + i) else min i len
    in
      fromMaybe (Array.snoc arr item) (Array.insertAt at item arr)

-- | Selection-diff helper. Polymorphic in the key type so it works
-- | for both `NodeLookup` (keyed by `NodeId`) and `EdgeLookup`
-- | (keyed by `String`), and in how the item holds `selected`: a node's is a
-- | `Boolean`, and an edge's is a `Maybe Boolean`, read as `false` when it's
-- | unset. That reading is upstream's
-- | `!(item.selected === undefined && !willBeSelected) && item.selected !== willBeSelected`.
-- |
-- | TS walks the lookup with `for…of`, in the order it was filled from
-- | `filledFrom`, so the changes come in that order.
getSelectionChangesGeneric
  :: forall k s r q
   . Ord k
  => (s -> Boolean)
  -> (Boolean -> s)
  -> Array { id :: k | q }
  -> Map k { id :: k, selected :: s | r }
  -> Set k
  -> Boolean
  -> { changes :: Array { id :: k, selected :: Boolean }
     , items :: Map k { id :: k, selected :: s | r }
     }
getSelectionChangesGeneric isSelected toSelected filledFrom items selectedIds mutate =
  let
    step acc (Tuple id item) =
      let
        willBeSelected = Set.member id selectedIds
      in
        if isSelected item.selected /= willBeSelected then
          let
            change = { id: item.id, selected: willBeSelected }
            result = acc { changes = Array.snoc acc.changes change }
          in
            if mutate then
              inPlaceThen (_ { selected = toSelected willBeSelected }) item result
            else result
        else acc
  in
    foldl step { changes: [], items } (Lookup.fillOrderEntries filledFrom items)

-- | TS `getSelectionChanges(nodeLookup, selectedIds, mutate)`, for a lookup
-- | filled from `nodes`.
getNodeSelectionChanges
  :: forall n q
   . Array { id :: NodeId | q }
  -> NodeLookup n
  -> Set NodeId
  -> Boolean
  -> { changes :: Array (NodeChange n)
     , items :: NodeLookup n
     }
getNodeSelectionChanges nodes lookup selectedIds mutate =
  let
    r = getSelectionChangesGeneric (_ == Just true) Just nodes lookup selectedIds mutate
    changes = map (\p -> NodeSelectionChange { id: p.id, selected: p.selected }) r.changes
  in
    { changes, items: r.items }

-- | TS `getSelectionChanges(edgeLookup, selectedIds)`, for a lookup filled
-- | from `edges`.
getEdgeSelectionChanges
  :: forall e q
   . Array { id :: String | q }
  -> EdgeLookup e
  -> Set String
  -> { changes :: Array (EdgeChange e)
     }
getEdgeSelectionChanges edges lookup selectedIds =
  let
    r = getSelectionChangesGeneric (_ == Just true) Just edges lookup selectedIds false
    changes = map (\p -> EdgeSelectionChange { id: p.id, selected: p.selected }) r.changes
  in
    { changes }

-- | Diff between a fresh user-supplied node array and the store's
-- | current lookup. Produces `add` / `remove` / `replace` changes.
-- |
-- | TS `getElementsDiffChanges`: `items = []` for `undefined`, then
-- | `items.map(…)`, `lookup.get(item.id)` for each item, and
-- | `for (const [id] of lookup)`. An item is replaced only when it isn't the
-- | object the store holds, the lookup's `internals.userNode`: the consumer's
-- | object behind each, as `adoptUserNodes` compares them, because ps-flow can
-- | hold two records decoded from one object.
getNodeElementsDiffChanges
  :: forall n
   . Maybe (Array (Node n))
  -> NodeLookup n
  -> Array (NodeChange n)
getNodeElementsDiffChanges mItems lookup =
  let
    items = AsWritten.orIfUndefined [] case mItems of
      Just xs -> xs
      Nothing -> []
    itemsLookup :: Map NodeId (Node n)
    itemsLookup = Map.fromFoldable (AsWritten.mapped (\n -> Tuple n.id n) items)
    forwardPass = foldl forwardStep { changes: [], index: 0 } items
    forwardStep acc item =
      let
        change = case Lookup.get item.id lookup of
          Just stored
            | unsafeRefEq (userNodeIdentity stored.internals.userNode) (userNodeIdentity item) -> []
            | otherwise -> [ NodeReplaceChange { id: item.id, item } ]
          Nothing -> [ NodeAddChange { item, index: Just acc.index } ]
      in
        { changes: acc.changes <> change, index: acc.index + 1 }
    removes =
      foldl
        ( \acc id ->
            if Map.member id itemsLookup then acc
            else Array.snoc acc (NodeRemoveChange { id })
        )
        []
        (Lookup.entryKeys lookup)
  in
    forwardPass.changes <> removes

getEdgeElementsDiffChanges
  :: forall e
   . Maybe (Array (Edge e))
  -> EdgeLookup e
  -> Array (EdgeChange e)
getEdgeElementsDiffChanges mItems lookup =
  let
    items = AsWritten.orIfUndefined [] case mItems of
      Just xs -> xs
      Nothing -> []
    itemsLookup :: Map String (Edge e)
    itemsLookup = Map.fromFoldable (AsWritten.mapped (\e -> Tuple e.id e) items)
    forwardPass = foldl forwardStep { changes: [], index: 0 } items
    -- TS replaces an item only when it isn't the object the lookup holds.
    forwardStep acc item =
      let
        change = case Lookup.get item.id lookup of
          Just stored
            | unsafeRefEq stored item -> []
            | otherwise -> [ EdgeReplaceChange { id: item.id, item } ]
          Nothing -> [ EdgeAddChange { item, index: Just acc.index } ]
      in
        { changes: acc.changes <> change, index: acc.index + 1 }
    removes =
      foldl
        ( \acc id ->
            if Map.member id itemsLookup then acc
            else Array.snoc acc (EdgeRemoveChange { id })
        )
        []
        (Lookup.entryKeys lookup)
  in
    forwardPass.changes <> removes

nodeToRemoveChange :: forall n. Node n -> NodeChange n
nodeToRemoveChange n = NodeRemoveChange { id: n.id }

edgeToRemoveChange :: forall e. Edge e -> EdgeChange e
edgeToRemoveChange e = EdgeRemoveChange { id: e.id }
