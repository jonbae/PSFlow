-- | What a dimension change's `resizing` holds when no resize built it.
-- |
-- | The local proxy, with `Test.System.Utils.MeasuredDimensions`, for the
-- | dimension change's `resizing` on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93),
-- | the field the `setAttributes` entry left emitted unconditionally.
-- | Upstream's `resizing` is optional on a dimension change: only
-- | `NodeResizeControl` sets it, and the changes `updateNodeInternals` and
-- | `handleExpandParent` build don't carry it. ps-flow held a required
-- | `Boolean`, so every dimension change crossed with `resizing: false`.
module Test.Boundary.DimensionResizing
  ( runDimensionResizingTests
  ) where

import Prelude

import Boundary.Elements (JsNodeChange, nodeChangeIn, nodeChangeOut)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)

foreign import measureChange :: JsNodeChange
foreign import resizeStep :: JsNodeChange
foreign import resizeEnd :: JsNodeChange
foreign import hasOwnKey :: forall a. String -> a -> Boolean
foreign import valueAt :: forall a. String -> Boolean -> a -> Boolean

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

runDimensionResizingTests :: Effect Unit
runDimensionResizingTests = do
  log "\n=== Dimension changes: resizing stays unset unless a resize sets it ==="

  let roundTrip = nodeChangeOut <<< nodeChangeIn

  assert "a dimension change written without resizing reads back without it"
    (not (hasOwnKey "resizing" (roundTrip measureChange)))
  assert "a dimension change written with resizing: true reads back with it"
    (valueAt "resizing" true (roundTrip resizeStep))
  assert "a dimension change written with resizing: false reads back with it"
    (valueAt "resizing" false (roundTrip resizeEnd))
