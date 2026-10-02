-- | The first move of a connection drag, and the auto-pan frame it starts.
-- |
-- | The local proxy for "Stop ps-flow panning the viewport during a
-- | connection drag that upstream does not pan" (#126). TS `onPointerMove`
-- | writes `position` and then calls `autoPan()`, which reads it. ps-flow
-- | wrote the position inside a `runOnRef` and started the loop through a
-- | second, nested `runOnRef`, which is not re-entrant: the first frame read
-- | the state from before the move. `connect-drag-holding-source` presses at
-- | y = 20 and moves to y = 40, the edge of the 40px band, so upstream pans
-- | by nothing and ps-flow panned by the velocity at y = 20: 15 × 20 / 40 =
-- | 7.5px. The caller's write-back then discarded the frame's handle, so a
-- | pointer-up before that frame ran cancelled nothing.
-- |
-- | Running the first frame through `runOnRef` again, which is what the
-- | handler did before the fix, fails the first two checks. Like
-- | `Test.System.XYDrag`, this runs against a frame clock that counts
-- | requests and runs none of them.
module Test.System.XYHandle
  ( runXYHandleTests
  ) where

import Prelude

import Data.Foldable (for_)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import System.FFI.AnimationFrame (cancelAnimationFrame)
import System.Types.Geometry (XYPosition)
import System.XYHandle (AutoPanEnv, initialDragState, runOnRef, trackPointer)
import Test.System.XYDrag (installFrameClock)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

type Run =
  { pans :: Array XYPosition
  , requests :: Int
  -- | The frames a pointer-up cancels, read off the state as `onPointerUp`
  -- | reads it.
  , cancelledOnUp :: Array Int
  }

-- | Press at `down`, move to each of `moves` in a 1280 × 720 container, as
-- | the net's chrome-defaults route is, then release.
drive :: Boolean -> XYPosition -> Array XYPosition -> Effect Run
drive autoPanOnConnect down moves = do
  clock <- installFrameClock
  pans <- Ref.new []
  stateRef <- Ref.new (initialDragState down)
  let
    env :: AutoPanEnv
    env =
      { autoPanOnConnect
      , autoPanSpeed: Nothing
      , bounds: { width: 1280.0, height: 720.0 }
      , panBy: \delta -> do
          liftEffect (Ref.modify_ (_ <> [ delta ]) pans)
          pure true
      }
  for_ moves \pos -> runOnRef stateRef (trackPointer env stateRef pos Nothing)
  s <- Ref.read stateRef
  for_ s.autoPanId cancelAnimationFrame
  run <- { pans: _, requests: _, cancelledOnUp: _ }
    <$> Ref.read pans
    <*> clock.requests
    <*> clock.cancelled
  clock.restore
  pure run

runXYHandleTests :: Effect Unit
runXYHandleTests = do
  log "\n=== XYHandle: the first auto-pan frame reads the move that started it (#126) ==="

  let
    down = { x: 99.0, y: 20.0 }
    first = { x: 139.0, y: 40.0 }
    second = { x: 179.0, y: 60.0 }

  held <- drive true down [ first, second ]
  assert "a move to the edge of the band pans by nothing, as upstream computes"
    (held.pans == [ { x: 0.0, y: 0.0 } ])
  assert "a pointer-up cancels the frame the first move asked for"
    (held.cancelledOnUp == [ 1 ])
  assert "only the first move starts the loop"
    (held.requests == 1)

  inBand <- drive true down [ { x: 139.0, y: 20.0 } ]
  assert "a move inside the band pans by the velocity there"
    (inBand.pans == [ { x: 0.0, y: 7.5 } ])

  off <- drive false down [ first, second ]
  assert "with autoPanOnConnect off, nothing pans and no frame is asked for"
    (off.pans == [] && off.requests == 0)
