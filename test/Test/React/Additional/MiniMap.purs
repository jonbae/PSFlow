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
-- | `useStore` is React's `useSyncExternalStore` (#133), which reads
-- | `getSnapshot` again once it has subscribed and re-renders if the result
-- | is a different object. This renders the MiniMap's own selector through
-- | `useStore` against `Test.React.Hook.Store`'s fake dispatcher, moves the
-- | pane's size the way `<ZoomPane />` does, and reads the snapshot React
-- | would read.
module Test.React.Additional.MiniMap
  ( runMiniMapSliceTests
  ) where

import Prelude

import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Additional.MiniMap (MMSlice(..), selector)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (createStore)
import Test.React.Hook.Store (rendererFor, sameReference)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

runMiniMapSliceTests :: Effect Unit
runMiniMapSliceTests = do
  log "\n=== MiniMap: the viewport rectangle has the pane's size from mount (#131) ==="

  store <- createStore (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
  -- The MiniMap's render, before the pane is measured.
  miniMap <- rendererFor store selector
  MMSlice before <- miniMap.render
  assert "the MiniMap renders before the pane is measured, at 0 × 0"
    (before.viewBB.width == 0.0 && before.viewBB.height == 0.0)

  -- `<ZoomPane />`'s mount effect, which runs before the MiniMap's.
  store.dispatch (PatchState _ { width = 1280.0, height = 720.0 })

  -- What React reads once the MiniMap has subscribed.
  after <- miniMap.fake.snapshot
  let MMSlice s = after
  assert "the MiniMap's snapshot moves to the pane's measured size, so React re-renders it"
    ( not (sameReference (MMSlice before) after)
        && s.viewBB.width == 1280.0
        && s.viewBB.height == 720.0
    )
