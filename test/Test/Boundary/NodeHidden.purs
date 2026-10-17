-- | What a node's `hidden` holds when the consumer doesn't set it.
-- |
-- | The local proxy for the node `hidden` part of the map's "required
-- | Booleans where upstream's field is optional" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's `hidden` is an optional field that nothing fills in. A node
-- | the consumer wrote without it reads back without it, `adoptUserNodes`
-- | builds the internal node from `{ ...defaults, ...userNode }`, so the
-- | internal node has none either, and every reader treats absent as
-- | `false`. ps-flow held a required `Boolean`, so every node and internal
-- | node read back with `hidden: false`.
module Test.Boundary.NodeHidden
  ( runNodeHiddenTests
  ) where

import Prelude

import Boundary.Elements (JsNode, internalNodeOut, nodeIn, nodeOut)
import Data.Array (mapMaybe) as Array
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign (Foreign)
import Partial.Unsafe (unsafeCrashWith)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import System.Types.Geometry (Transform(..))
import System.Types.Ids (NodeId(..))
import System.Utils.Graph (getNodesInside)

foreign import plainNode :: JsNode
foreign import nodeShown :: JsNode
foreign import nodeHidden :: JsNode
foreign import hasOwnKey :: forall a. String -> a -> Boolean
foreign import isFalseAt :: forall a. String -> a -> Boolean

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

runNodeHiddenTests :: Effect Unit
runNodeHiddenTests = do
  log "\n=== Nodes: hidden stays unset until the consumer sets it ==="

  let
    state = initialState
      ( (defaultInitialStateOptions :: InitialStateOptions Foreign Foreign)
          { nodes = Just (map nodeIn [ plainNode, nodeShown, nodeHidden ]) }
      )
    internals = Array.mapMaybe (\id -> Map.lookup (NodeId id) state.nodeLookup) [ "a", "b", "c" ]
    inside = getNodesInside internals
      { x: 0.0, y: 0.0, width: 100.0, height: 100.0 }
      (Transform { tx: 0.0, ty: 0.0, scale: 1.0 })
      { partially: true, excludeNonSelectable: false }

  assert "a node written without hidden reads back without it"
    (not (hasOwnKey "hidden" (nodeOut (nodeIn plainNode))))
  assert "a node written with hidden: false reads back with it"
    (isFalseAt "hidden" (nodeOut (nodeIn nodeShown)))
  assert "the internal node for a node without hidden has none"
    (map (hasOwnKey "hidden" <<< internalNodeOut) (Map.lookup (NodeId "a") state.nodeLookup) == Just false)
  assert "getNodesInside keeps a node without hidden and one with hidden: false, and drops a hidden one"
    (map (unwrap <<< _.id) inside == [ "a", "b" ])
