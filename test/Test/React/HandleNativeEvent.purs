-- | The event a handle hands on when a connection starts.
-- |
-- | The local proxy for the report's connect scenarios, which
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name. Upstream's `<Handle />` runs
-- |
-- |     const isMouseTriggered = isMouseEvent(event.nativeEvent);
-- |     if (isConnectableStart && ((isMouseTriggered && event.button === 0) || !isMouseTriggered)) {
-- |       XYHandle.onPointerDown(event.nativeEvent, { … onConnectStart … });
-- |
-- | and its click handler calls `onClickConnectStart(event.nativeEvent, …)`.
-- | ps-flow's handed on React's synthetic event, so `onConnectStart` and
-- | `onClickConnectStart` got a `SyntheticBaseEvent` where upstream's get a
-- | `MouseEvent` or `PointerEvent`. Its guard read `button` on every
-- | event, and a touch has none, so a touch never started a connection.
-- |
-- | The test checks `nativePointerEvent` and `startsConnection`, the two
-- | pieces the handlers are built from. That the handlers use them is the
-- | net's to check: `spago test` has no DOM to press a handle in.
module Test.React.HandleNativeEvent
  ( runHandleNativeEventTests
  ) where

import Prelude

import Data.Either (either)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic.Events (SyntheticEvent)
import React.Handle (nativePointerEvent, startsConnection)

foreign import mouseDown :: SyntheticEvent
foreign import secondaryMouseDown :: SyntheticEvent
foreign import touchStart :: SyntheticEvent
foreign import isNativeOf :: forall a. SyntheticEvent -> a -> Boolean

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

runHandleNativeEventTests :: Effect Unit
runHandleNativeEventTests = do
  log "\n=== A handle hands on the native event, and a touch starts a connection ==="

  assert "a mouse down hands on its native event, as a mouse event"
    (either (isNativeOf mouseDown) (const false) (nativePointerEvent mouseDown))
  assert "a touch start hands on its native event, as a touch event"
    (either (const false) (isNativeOf touchStart) (nativePointerEvent touchStart))

  assert "the main mouse button starts a connection"
    (startsConnection true (nativePointerEvent mouseDown))
  assert "another mouse button doesn't"
    (not (startsConnection true (nativePointerEvent secondaryMouseDown)))
  assert "a touch starts a connection"
    (startsConnection true (nativePointerEvent touchStart))
  assert "nothing starts one on a handle that can't start a connection"
    ( not (startsConnection false (nativePointerEvent mouseDown))
        && not (startsConnection false (nativePointerEvent touchStart))
    )
