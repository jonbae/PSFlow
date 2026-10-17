-- | What a node's `selected` holds when nothing has selected it.
-- |
-- | The local proxy for the node `selected` part of the map's "required
-- | Booleans where upstream's field is optional" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's `selected` is an optional field that only a selection change
-- | sets. A node the consumer wrote without it reads back without it, and so
-- | does its internal node. Its readers treat absent as `false`, and
-- | `getSelectionChanges` skips an item whose `selected` is `undefined` and
-- | isn't becoming selected. ps-flow held a required `Boolean`, so every node
-- | and internal node read back with `selected: false`.
module Test.Boundary.NodeSelected
  ( runNodeSelectedTests
  ) where

import Prelude

import Boundary.Elements (JsNode, internalNodeOut, nodeIn, nodeOut)
import Data.Array (length) as Array
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Set as Set
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign (Foreign)
import Partial.Unsafe (unsafeCrashWith)
import React.Store.Changes (getNodeSelectionChanges)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import System.Types.Ids (NodeId(..))

foreign import plainNode :: JsNode
foreign import nodeUnselected :: JsNode
foreign import hasOwnKey :: forall a. String -> a -> Boolean
foreign import isFalseAt :: forall a. String -> a -> Boolean

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

runNodeSelectedTests :: Effect Unit
runNodeSelectedTests = do
  log "\n=== Nodes: selected stays unset until a selection change sets it ==="

  let
    state = initialState
      ((defaultInitialStateOptions :: InitialStateOptions Foreign Foreign) { nodes = Just [ nodeIn plainNode ] })
    selectionChanges ids =
      Array.length (getNodeSelectionChanges state.nodeLookup (Set.fromFoldable (map NodeId ids)) false).changes

  assert "a node written without selected reads back without it"
    (not (hasOwnKey "selected" (nodeOut (nodeIn plainNode))))
  assert "a node written with selected: false reads back with it"
    (isFalseAt "selected" (nodeOut (nodeIn nodeUnselected)))
  assert "the internal node for a node without selected has none"
    (map (hasOwnKey "selected" <<< internalNodeOut) (Map.lookup (NodeId "a") state.nodeLookup) == Just false)
  assert "a node without selected that stays unselected makes no selection change, as upstream's guard has it"
    (selectionChanges [] == 0)
  assert "a node without selected that becomes selected makes one"
    (selectionChanges [ "a" ] == 1)
