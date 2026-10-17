-- | What a node's `dragging` holds before a drag sets it.
-- |
-- | The local proxy for the node `dragging` part of the map's "required
-- | Booleans where upstream's field is optional" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's `dragging` is optional on a node and on a position change. A
-- | node the consumer wrote without it reads back without it, and so does its
-- | internal node. `applyChange` copies a change's `dragging` only
-- | `if (typeof change.dragging !== 'undefined')`, and the position changes
-- | `NodeResizeControl` and `handleExpandParent` build don't carry it. ps-flow
-- | held a required `Boolean` on both, so every node read back with
-- | `dragging: false`, and every position change set it.
module Test.Boundary.NodeDragging
  ( runNodeDraggingTests
  ) where

import Prelude

import Boundary.Elements (JsNode, JsNodeChange, internalNodeOut, nodeIn, nodeOut)
import Boundary.Utils (applyNodeChanges)
import Data.Function.Uncurried (runFn2)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign (Foreign)
import Partial.Unsafe (unsafeCrashWith)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import System.Types.Ids (NodeId(..))

foreign import plainNode :: JsNode
foreign import nodeAtRest :: JsNode
foreign import moveWithoutDragging :: JsNodeChange
foreign import moveWhileDragging :: JsNodeChange
foreign import hasOwnKey :: forall a. String -> a -> Boolean
foreign import valueAt :: forall a. String -> Boolean -> a -> Boolean

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

runNodeDraggingTests :: Effect Unit
runNodeDraggingTests = do
  log "\n=== Nodes: dragging stays unset until a change sets it ==="

  let
    state = initialState
      ((defaultInitialStateOptions :: InitialStateOptions Foreign Foreign) { nodes = Just [ nodeIn plainNode ] })
    applied change = runFn2 applyNodeChanges [ change ] [ plainNode ]

  assert "a node written without dragging reads back without it"
    (not (hasOwnKey "dragging" (nodeOut (nodeIn plainNode))))
  assert "a node written with dragging: false reads back with it"
    (valueAt "dragging" false (nodeOut (nodeIn nodeAtRest)))
  assert "the internal node for a node without dragging has none"
    (map (hasOwnKey "dragging" <<< internalNodeOut) (Map.lookup (NodeId "a") state.nodeLookup) == Just false)
  assert "a position change without dragging leaves the node's dragging unset"
    (map (hasOwnKey "dragging") (applied moveWithoutDragging) == [ false ])
  assert "a position change with dragging sets it"
    (map (valueAt "dragging" true) (applied moveWhileDragging) == [ true ])
