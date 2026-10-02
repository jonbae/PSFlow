-- | The MiniMap's store slice, against a pane measured after the MiniMap
-- | rendered.
-- |
-- | The local proxy for "Draw the MiniMap's viewport rectangle at the
-- | pane's size from mount, not 0×0 until the viewport moves" (#131). The
-- | pane's size reaches the store in `<ZoomPane />`'s mount effect, through
-- | `useResizeHandler`. `<MiniMap />` is a later sibling of `<GraphView />`
-- | under `<ReactFlow />`, so it rendered against a width and height of 0
-- | and subscribed only after the measurement had been written. Its
-- | `useStore` kept the 0×0 slice until something else moved it, which is
-- | why a pan used to fix the rectangle and a flow that never panned drew
-- | `M0,0h0v0h0z`.
-- |
-- | The cause was `useStore`, fixed under #128 and proved in general by
-- | `Test.React.Hook.Store`. This runs the MiniMap's own selector through
-- | the same subscription, so the symptom this ticket names has a check of
-- | its own. A `subscribeSlice` that only subscribes, which is what
-- | `useStore` did before #128, fails it.
module Test.React.Additional.MiniMap
  ( runMiniMapSliceTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Additional.MiniMap (MMSlice(..), selector)
import React.Hook.Store (subscribeSlice)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (createStore)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

runMiniMapSliceTests :: Effect Unit
runMiniMapSliceTests = do
  log "\n=== MiniMap: the viewport rectangle has the pane's size from mount (#131) ==="

  store <- createStore (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
  -- The MiniMap's render, before the pane is measured.
  rendered <- selector <$> store.getState
  let MMSlice before = rendered
  assert "the MiniMap renders before the pane is measured, at 0 × 0"
    (before.viewBB.width == 0.0 && before.viewBB.height == 0.0)

  -- `<ZoomPane />`'s mount effect, which runs before the MiniMap's.
  store.dispatch (PatchState _ { width = 1280.0, height = 720.0 })

  -- The MiniMap's mount effect: its subscription.
  latest <- Ref.new Nothing
  _ <- subscribeSlice store selector rendered \slice -> Ref.write (Just slice) latest
  handed <- Ref.read latest
  assert "the MiniMap's viewport rectangle takes the pane's measured size"
    ( case handed of
        Just (MMSlice s) -> s.viewBB.width == 1280.0 && s.viewBB.height == 720.0
        Nothing -> false
    )
