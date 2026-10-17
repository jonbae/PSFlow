-- | What a node's `expandParent` holds when the consumer doesn't set it.
-- |
-- | The local proxy for the `expandParent` part of the map's "required
-- | Booleans where upstream's field is optional" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's `expandParent` is an optional field that nothing fills in. A
-- | node the consumer wrote without it reads back without it, and
-- | `adoptUserNodes` builds the internal node from `{ ...defaults, ...userNode }`,
-- | so the internal node has none either. ps-flow held a required `Boolean`,
-- | so every node and internal node read back with `expandParent: false`.
module Test.Boundary.NodeExpandParent
  ( runNodeExpandParentTests
  ) where

import Prelude

import Boundary.Elements (JsNode, internalNodeOut, nodeIn, nodeOut)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign (Foreign)
import Partial.Unsafe (unsafeCrashWith)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import System.Types.Ids (NodeId(..))

foreign import plainNode :: JsNode
foreign import nodeNotExpanding :: JsNode
foreign import hasOwnKey :: forall a. String -> a -> Boolean
foreign import isFalseAt :: forall a. String -> a -> Boolean

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | The internal node a flow holding only `node` keeps for it, read back.
internalOf :: JsNode -> Maybe Boolean
internalOf node =
  let
    state = initialState
      ((defaultInitialStateOptions :: InitialStateOptions Foreign Foreign) { nodes = Just [ nodeIn node ] })
  in
    map (hasOwnKey "expandParent" <<< internalNodeOut) (Map.lookup (NodeId "a") state.nodeLookup)

runNodeExpandParentTests :: Effect Unit
runNodeExpandParentTests = do
  log "\n=== Nodes: expandParent stays unset until the consumer sets it ==="

  assert "a node written without expandParent reads back without it"
    (not (hasOwnKey "expandParent" (nodeOut (nodeIn plainNode))))
  assert "a node written with expandParent: false reads back with it"
    (isFalseAt "expandParent" (nodeOut (nodeIn nodeNotExpanding)))
  assert "the internal node for a node without expandParent has none"
    (internalOf plainNode == Just false)
  assert "the internal node for a node with expandParent: false keeps it"
    (internalOf nodeNotExpanding == Just true)
