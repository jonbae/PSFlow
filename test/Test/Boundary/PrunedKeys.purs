-- | Which keys the element converters hand a consumer.
-- |
-- | The local proxy for the map's "prune `undefined` keys in the element
-- | converters" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93),
-- | settled as decision 6. Upstream hands back nodes, edges, and their
-- | markers as the consumer wrote them, and builds each change with only the
-- | keys it sets, so none of them carries a key whose value is `undefined`.
-- | ps-flow's converters wrote every field of the record, as `undefined`
-- | where the port holds `Nothing`.
-- |
-- | A user node has no `measured` until it's measured. An internal node always
-- | has `measured` with both keys, and `internals.handleBounds` set or not,
-- | because upstream builds them that way. Its `internals.rootParentIndex`
-- | and `internals.bounds` are written only when they hold a value.
module Test.Boundary.PrunedKeys
  ( runPrunedKeysTests
  ) where

import Prelude

import Boundary.Elements (edgeChangeOut, edgeOut, internalNodeOut, nodeChangeOut, nodeOut)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign (Foreign, unsafeToForeign)
import Partial.Unsafe (unsafeCrashWith)
import System.Types.Edge (EdgeAriaLabel(..), EdgeBase, EdgeChange(..), EdgeMarkerType(..), MarkerType(..))
import System.Types.Ids (NodeId(..))
import System.Types.Node (InternalNodeBase, NodeBase, NodeChange(..))

foreign import undefinedKeys :: forall a. a -> Array String
foreign import sortedKeys :: forall a. a -> Array String
foreign import hasOwnKey :: forall a. String -> a -> Boolean
foreign import isNullAt :: forall a. String -> a -> Boolean
foreign import markerOf :: forall a. String -> a -> Foreign

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | A node the consumer wrote with an id, a position, and a width.
node :: NodeBase Foreign
node =
  { id: NodeId "a"
  , position: { x: 0.0, y: 0.0 }
  , data: unsafeToForeign {}
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: false
  , selected: false
  , dragging: false
  , draggable: Nothing
  , selectable: Nothing
  , connectable: Nothing
  , deletable: Nothing
  , dragHandle: Nothing
  , width: Just 120.0
  , height: Nothing
  , initialWidth: Nothing
  , initialHeight: Nothing
  , parentId: Nothing
  , zIndex: Nothing
  , extent: Nothing
  , expandParent: false
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Nothing, height: Nothing }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

internalNode :: InternalNodeBase Foreign
internalNode =
  { id: node.id
  , position: node.position
  , data: node.data
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: false
  , selected: false
  , dragging: false
  , draggable: Nothing
  , selectable: Nothing
  , connectable: Nothing
  , deletable: Nothing
  , dragHandle: Nothing
  , width: Nothing
  , height: Nothing
  , initialWidth: Nothing
  , initialHeight: Nothing
  , parentId: Nothing
  , zIndex: Nothing
  , extent: Nothing
  , expandParent: false
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Nothing, height: Nothing }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  , internals:
      { positionAbsolute: { x: 0.0, y: 0.0 }
      , z: 0.0
      , rootParentIndex: Nothing
      , handleBounds: Nothing
      , bounds: Nothing
      }
  }

-- | An edge with a custom marker that sets only its type, and an aria label
-- | turned off with `null`.
edge :: EdgeBase Foreign
edge =
  { id: "ab"
  , edgeType: Nothing
  , source: NodeId "a"
  , target: NodeId "b"
  , sourceHandle: Nothing
  , targetHandle: Nothing
  , animated: Nothing
  , hidden: false
  , deletable: Nothing
  , selectable: Nothing
  , data: Nothing
  , selected: false
  , markerStart: Nothing
  , markerEnd: Just
      ( CustomMarker
          { markerType: ArrowClosed
          , color: Nothing
          , width: Nothing
          , height: Nothing
          , markerUnits: Nothing
          , orient: Nothing
          , strokeWidth: Nothing
          }
      )
  , zIndex: Nothing
  , label: Nothing
  , ariaLabel: Just AriaLabelOff
  , interactionWidth: Nothing
  , className: Nothing
  , style: Nothing
  }

runPrunedKeysTests :: Effect Unit
runPrunedKeysTests = do
  log "\n=== Element converters: no key holds undefined ==="

  let jsNode = nodeOut node
  assert "a node has no key that holds undefined"
    (undefinedKeys jsNode == [])
  assert "a node keeps the keys that hold a value"
    (hasOwnKey "width" jsNode && not (hasOwnKey "height" jsNode))
  assert "a node that hasn't been measured has no measured key"
    (not (hasOwnKey "measured" jsNode))
  assert "a measured node has measured with both keys"
    (sortedKeys (markerOf "measured" (nodeOut node { measured = { width: Just 50.0, height: Just 25.0 } })) == [ "height", "width" ])

  let jsEdge = edgeOut edge
  assert "an edge has no key that holds undefined"
    (undefinedKeys jsEdge == [])
  assert "an edge keeps an aria label turned off with null"
    (isNullAt "ariaLabel" jsEdge)
  assert "an edge's custom marker has only the keys that hold a value"
    (sortedKeys (markerOf "markerEnd" jsEdge) == [ "type" ])

  assert "a node selection change has only upstream's keys"
    (sortedKeys (nodeChangeOut (NodeSelectionChange { id: NodeId "a", selected: true })) == [ "id", "selected", "type" ])
  assert "an edge removal has only upstream's keys"
    (sortedKeys (edgeChangeOut (EdgeRemoveChange { id: "ab" })) == [ "id", "type" ])

  let jsInternal = internalNodeOut internalNode
  assert "an internal node has no top-level key that holds undefined"
    (undefinedKeys jsInternal == [])
  assert "an internal node keeps measured's keys before measurement, as upstream does"
    (sortedKeys (markerOf "measured" jsInternal) == [ "height", "width" ])
  assert "an internal node's internals keep handleBounds before measurement, and nothing else unset"
    (sortedKeys (markerOf "internals" jsInternal) == [ "handleBounds", "positionAbsolute", "z" ])
