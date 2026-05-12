-- | Pure helpers used by `System.XYDrag`. Mirrors
-- | `xyflow-main/packages/system/src/xydrag/utils.ts`.
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

import Data.Array (foldl, head, snoc) as Array
import Data.Map (Map)
import Data.Map (empty, insert, lookup, toUnfoldable) as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Set (Set)
import Data.Set (empty, insert, member) as Set
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Web.DOM.Element (Element)
import System.Types.Geometry (SnapGrid, XYPosition)
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
   . { parentId :: Maybe String | a }
  -> NodeLookup n
  -> Boolean
isParentSelected node lookup = go Set.empty node.parentId
  where
  go :: Set String -> Maybe String -> Boolean
  go _ Nothing = false
  go visited (Just pid)
    | Set.member pid visited = false
    | otherwise = case Map.lookup pid lookup of
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

-- | Build the drag-items map. The TS version filters by selection, parent
-- | selection, and draggable flag. The PS port matches that order — note that
-- | a `Nothing` `node.draggable` falls back to the `nodesDraggable` flag.
getDragItems
  :: forall n
   . NodeLookup n
  -> Boolean
  -> XYPosition
  -> Maybe String
  -> Map String NodeDragItem
getDragItems lookup nodesDraggable mousePos mNodeId =
  let
    entries :: Array (Tuple String (InternalNodeBase n))
    entries = Map.toUnfoldable lookup

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
      , dragging: false
      }

    step acc (Tuple id node) =
      if keep node then Map.insert id (toItem node) acc
      else acc
  in
    Array.foldl step Map.empty entries

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
   . Maybe String
  -> Map String NodeDragItem
  -> NodeLookup n
  -> Boolean
  -> { currentNode :: Maybe (NodeBase n), allNodes :: Array (NodeBase n) }
getEventHandlerParams mNodeId dragItems lookup dragging =
  let
    items :: Array (Tuple String NodeDragItem)
    items = Map.toUnfoldable dragItems

    overlay :: InternalNodeBase n -> NodeDragItem -> NodeBase n
    overlay internal item =
      { id: internal.id
      , position: item.position
      , data: internal.data
      , sourcePosition: internal.sourcePosition
      , targetPosition: internal.targetPosition
      , hidden: internal.hidden
      , selected: internal.selected
      , dragging
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
      }

    allNodes :: Array (NodeBase n)
    allNodes = Array.foldl
      ( \acc (Tuple id item) ->
          case Map.lookup id lookup of
            Just internal -> Array.snoc acc (overlay internal item)
            Nothing -> acc
      )
      []
      items

    currentNode :: Maybe (NodeBase n)
    currentNode = case mNodeId of
      Nothing -> Array.head allNodes
      Just nid -> case Map.lookup nid lookup, Map.lookup nid dragItems of
        Just internal, Just item -> Just (overlay internal item)
        _, _ -> Array.head allNodes
  in
    { currentNode, allNodes }

-- | Snap-offset for a multi-selection drag: snap the *first* item's position
-- | and return the delta as the offset to apply to the rest. Returns
-- | `Nothing` when the drag-items map is empty.
-- |
-- | Divergence note: TS picks the user-clicked item as the reference (via
-- | insertion order in the JS Map). PS picks the lowest-key item, because
-- | `Map.toUnfoldable` orders by key. The visible difference is which item
-- | snaps exactly to the grid in a multi-drag — others move by the delta
-- | regardless. To restore TS parity, thread the click-target id through
-- | the call chain and look it up here instead of taking the head.
calculateSnapOffset
  :: Map String NodeDragItem
  -> SnapGrid
  -> Number
  -> Number
  -> Maybe XYPosition
calculateSnapOffset dragItems grid x y =
  let
    items :: Array (Tuple String NodeDragItem)
    items = Map.toUnfoldable dragItems
  in
    case Array.head items of
      Nothing -> Nothing
      Just (Tuple _ refItem) ->
        let
          refPos = { x: x - refItem.distance.x, y: y - refItem.distance.y }
          snapped = snapPosition refPos grid
        in
          Just { x: snapped.x - refPos.x, y: snapped.y - refPos.y }
