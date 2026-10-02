-- | One run of `useViewportSync`'s effect, against upstream's.
-- |
-- | The local proxy for "Wire controlled viewport changes to
-- | panZoom.syncViewport and drive them in the net" (#128). Upstream's
-- | effect calls `panZoom?.syncViewport(viewport)` and then writes the
-- | store (`xyflow-main/packages/react/src/hooks/useViewportSync.ts`).
-- | ps-flow wrote the store and nothing else, so d3 kept the transform it
-- | already had and the next gesture started from there.
-- |
-- | Like `Test.React.Hook.Drag`, this runs without rendering: `spago test`
-- | has no DOM. `runViewportSync` is the effect's whole body, handed a
-- | recording `syncViewport` and `dispatch`. A `runViewportSync` that
-- | ignores `syncViewport` is what the hook amounted to before the fix, and
-- | it fails the first two checks.
module Test.React.Hook.ViewportSync
  ( runViewportSyncTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Hook.ViewportSync (runViewportSync)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import React.Types.Store (ReactFlowState)
import System.Types.Connection (Viewport)
import System.Types.Geometry (Transform(..))

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | One step of the effect, as the instance or the store saw it.
data Step
  = Synced Viewport
  | Wrote { x :: Number, y :: Number, zoom :: Number }

derive instance eqStep :: Eq Step

start :: ReactFlowState Unit Unit
start = initialState (defaultInitialStateOptions :: InitialStateOptions Unit Unit)

-- | Run the effect once and list what reached the instance and the store,
-- | in the order it reached them. A store write is read back as the
-- | transform it leaves on a fresh state.
run :: Boolean -> Maybe Viewport -> Effect (Array Step)
run hasInstance mViewport = do
  steps <- Ref.new []
  let
    record step = Ref.modify_ (_ <> [ step ]) steps
  runViewportSync
    { syncViewport:
        if hasInstance then Just \vp -> record (Synced vp)
        else Nothing
    , dispatch: case _ of
        PatchState f -> do
          let Transform t = (f start).transform
          record (Wrote { x: t.tx, y: t.ty, zoom: t.scale })
        _ -> unsafeCrashWith "useViewportSync dispatched something other than PatchState"
    }
    mViewport
  Ref.read steps

runViewportSyncTests :: Effect Unit
runViewportSyncTests = do
  log "\n=== useViewportSync: a controlled viewport reaches the pan-zoom instance (#128) ==="

  let vp = { x: -200.0, y: 80.0, zoom: 1.5 }

  withInstance <- run true (Just vp)
  assert "a controlled viewport reaches the pan-zoom instance"
    (withInstance /= [ Wrote vp ])
  assert "the instance hears first and the store second, as upstream's effect runs"
    (withInstance == [ Synced vp, Wrote vp ])

  beforeInstance <- run false (Just vp)
  assert "before the instance exists, the store is written alone"
    (beforeInstance == [ Wrote vp ])

  uncontrolled <- run true Nothing
  assert "with no viewport prop, nothing is synced or written"
    (uncontrolled == [])
