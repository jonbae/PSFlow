-- | Pure helpers used by `System.XYDrag`. Mirrors
-- | `xyflow/packages/system/src/xydrag/utils.ts`.
-- |
-- | `isParentSelected`, `getDragItems`, `getEventHandlerParams`, and
-- | `calculateSnapOffset` are pure functions over `NodeLookup`. `hasSelector`
-- | walks the live DOM and is `Effect`-typed.
module System.XYDrag.Utils
  ( isParentSelected
  , hasSelector
  , getDragItems
  , getEventHandlerParams
  , calculateSnapOffset
  ) where

import Prelude

import Data.Array (find, foldl, head, nub, snoc) as Array
import Data.Map (lookup) as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Set (Set)
import Data.Set (empty, insert, member) as Set
import Effect (Effect)
import Web.DOM.Element (Element)
import System.Types.Geometry (SnapGrid, XYPosition)
import System.Types.Ids (NodeId, ParentId, parentToNode, nodeToParent)
import System.Types.Node
  ( InternalNodeBase
  , NodeBase
  , NodeDragItem
  , NodeLookup
  )
import System.Utils.General (snapPosition)

-- | Walk the parent chain via `parentId`. Returns `true` as soon as any
-- | ancestor is `selected`. The visited-id `Set` short-circuits cycles —
-- | adoption code is supposed to enforce acyclicity, but `Map` does not,
-- | and a malformed lookup would otherwise spin forever here.
isParentSelected
  :: forall n a
   . { parentId :: Maybe ParentId | a }
  -> NodeLookup n
  -> Boolean
isParentSelected node lookup = go Set.empty node.parentId
  where
  go :: Set ParentId -> Maybe ParentId -> Boolean
  go _ Nothing = false
  go visited (Just pid)
    | Set.member pid visited = false
    | otherwise = case Map.lookup (parentToNode pid) lookup of
        Nothing -> false
        Just parent ->
          if parent.selected then true
          else go (Set.insert pid visited) parent.parentId

-- | DOM walk: starting at `target`, climb `parentElement` until either the
-- | element matches the CSS selector (return `true`) or we reach `domNode`
-- | (return `false`). Mirrors the TS `do-while` ascent. The implementation is
-- | delegated to JS because PS's `Web.DOM` lacks a portable `matches` binding
-- | that handles the early-return semantics.
foreign import hasSelectorImpl :: Element -> String -> Element -> Effect Boolean

hasSelector :: Element -> String -> Element -> Effect Boolean
hasSelector = hasSelectorImpl

-- | Build the drag items. The TS version filters by selection, parent
-- | selection, and draggable flag. The PS port matches that order — note that
-- | a `Nothing` `node.draggable` falls back to the `nodesDraggable` flag.
-- |
-- | TS returns a `Map` and iterates `nodeLookup` to build it, so the items
-- | come out in the lookup's insertion order, which is the order of the
-- | `nodes` array the lookup was adopted from. `Data.Map` iterates by key
-- | instead, so the caller passes that order as `order`, and the items come
-- | back as an array in it. Every reader of the items depends on the order:
-- | `calculateSnapOffset` snaps the first one, `getEventHandlerParams` reports
-- | the first one when no node was grabbed, and `updateNodePositions` emits
-- | its changes in it.
getDragItems
  :: forall n
   . Array NodeId
  -> NodeLookup n
  -> Boolean
  -> XYPosition
  -> Maybe NodeId
  -> Array NodeDragItem
getDragItems order lookup nodesDraggable mousePos mNodeId =
  let
    isDraggable node = case node.draggable of
      Just b -> b
      Nothing -> nodesDraggable

    parentNotSelected node = case node.parentId of
      Nothing -> true
      Just _ -> not (isParentSelected node lookup)

    isTarget node =
      node.selected || (mNodeId == Just node.id)

    keep node =
      isTarget node
        && parentNotSelected node
        && isDraggable node

    toItem :: InternalNodeBase n -> NodeDragItem
    toItem node =
      { id: node.id
      , position: node.position
      , distance:
          { x: mousePos.x - node.internals.positionAbsolute.x
          , y: mousePos.y - node.internals.positionAbsolute.y
          }
      , extent: node.extent
      , parentId: node.parentId
      , origin: node.origin
      , expandParent: node.expandParent
      , internals: { positionAbsolute: node.internals.positionAbsolute }
      , measured:
          { width: fromMaybe 0.0 node.measured.width
          , height: fromMaybe 0.0 node.measured.height
          }
      , dragging: Nothing
      }

    -- A repeated id keeps its first position, as a second `set` on a JS
    -- `Map` does.
    step acc id = case Map.lookup id lookup of
      Just node | keep node -> Array.snoc acc (toItem node)
      _ -> acc
  in
    Array.foldl step [] (Array.nub order)

-- | Returns the `currentNode` (the node identified by `nodeId`, or the head of
-- | the drag-item list if `nodeId` is `Nothing`) plus the array of all
-- | drag-item nodes. The TS source returns a 2-tuple; the labelled record
-- | here makes call sites self-documenting.
-- |
-- | The TS `dragging` parameter defaults to `true`; PS callers must supply it.
-- | Both yielded forms (current and all) get their `position` and `dragging`
-- | rewritten to mirror the TS spread.
getEventHandlerParams
  :: forall n
   . Maybe NodeId
  -> Array NodeDragItem
  -> NodeLookup n
  -> Boolean
  -> { currentNode :: Maybe (NodeBase n), allNodes :: Array (NodeBase n) }
getEventHandlerParams mNodeId dragItems lookup dragging =
  let
    overlay :: InternalNodeBase n -> NodeDragItem -> NodeBase n
    overlay internal item =
      { id: internal.id
      , position: item.position
      , data: internal.data
      , sourcePosition: internal.sourcePosition
      , targetPosition: internal.targetPosition
      , hidden: internal.hidden
      , selected: internal.selected
      , dragging: Just dragging
      , draggable: internal.draggable
      , selectable: internal.selectable
      , connectable: internal.connectable
      , deletable: internal.deletable
      , dragHandle: internal.dragHandle
      , width: internal.width
      , height: internal.height
      , initialWidth: internal.initialWidth
      , initialHeight: internal.initialHeight
      , parentId: internal.parentId
      , zIndex: internal.zIndex
      , extent: internal.extent
      , expandParent: internal.expandParent
      , ariaLabel: internal.ariaLabel
      , origin: internal.origin
      , handles: internal.handles
      , measured: internal.measured
      , nodeType: internal.nodeType
      , className: internal.className
      , style: internal.style
      }

    allNodes :: Array (NodeBase n)
    allNodes = Array.foldl
      ( \acc item ->
          case Map.lookup item.id lookup of
            Just internal -> Array.snoc acc (overlay internal item)
            Nothing -> acc
      )
      []
      dragItems

    currentNode :: Maybe (NodeBase n)
    currentNode = case mNodeId of
      Nothing -> Array.head allNodes
      Just nid -> case Map.lookup nid lookup, Array.find (\i -> i.id == nid) dragItems of
        Just internal, Just item -> Just (overlay internal item)
        _, _ -> Array.head allNodes
  in
    { currentNode, allNodes }

-- | Snap-offset for a multi-selection drag: snap the *first* item's position
-- | and return the delta as the offset to apply to the rest. Returns
-- | `Nothing` when there are no drag items.
-- |
-- | The first item is TS's `dragItems.values().next().value`: the first
-- | dragged node in the `nodes` array, which `getDragItems` keeps. It is not
-- | the grabbed node, and it is not the node whose id sorts first.
calculateSnapOffset
  :: Array NodeDragItem
  -> SnapGrid
  -> Number
  -> Number
  -> Maybe XYPosition
calculateSnapOffset dragItems grid x y = case Array.head dragItems of
  Nothing -> Nothing
  Just refItem ->
    let
      refPos = { x: x - refItem.distance.x, y: y - refItem.distance.y }
      snapped = snapPosition refPos grid
    in
      Just { x: snapped.x - refPos.x, y: snapped.y - refPos.y }
