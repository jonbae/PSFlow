-- | How a connection a consumer reads writes a missing handle.
-- |
-- | The local proxy for a finding of the net re-run on
-- | [PR #156](https://github.com/jonbae/PSFlow/pull/156), under
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's `updateConnectionLookup` reads each edge with
-- | `sourceHandle = null` and `targetHandle = null` defaults, and builds
-- | `{ edgeId, source, target, sourceHandle, targetHandle }`, so
-- | `getNodeConnections`, `getHandleConnections`, and both connection hooks
-- | hand a consumer `null` for a missing handle, as `Connection` types it.
-- | ps-flow handed `undefined`.
module Test.Boundary.ConnectionNullHandle
  ( runConnectionNullHandleTests
  ) where

import Prelude

import Boundary.Instance (handleConnectionOut)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import System.Types.Ids (NodeId(..))

foreign import isNullAt :: forall a. String -> a -> Boolean
foreign import keysOf :: forall a. a -> Array String
foreign import valueIs :: forall a. String -> String -> a -> Boolean

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

runConnectionNullHandleTests :: Effect Unit
runConnectionNullHandleTests = do
  log "\n=== Connections: a missing handle is null, as upstream writes it ==="

  let
    noHandles = handleConnectionOut
      { source: NodeId "a", target: NodeId "b", sourceHandle: Nothing, targetHandle: Nothing, edgeId: "ab" }
    withHandles = handleConnectionOut
      { source: NodeId "a", target: NodeId "b", sourceHandle: Just "s", targetHandle: Just "t", edgeId: "ab" }

  assert "a connection with no handles writes both as null"
    (isNullAt "sourceHandle" noHandles && isNullAt "targetHandle" noHandles)
  assert "a connection with handles writes their ids"
    (valueIs "sourceHandle" "s" withHandles && valueIs "targetHandle" "t" withHandles)
  assert "a connection has upstream's keys, in upstream's order"
    (keysOf noHandles == [ "edgeId", "source", "target", "sourceHandle", "targetHandle" ])
