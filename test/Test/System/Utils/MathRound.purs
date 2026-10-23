-- | `roundHalfUp` is JavaScript's `Math.round`, down to the sign of a zero.
-- |
-- | The local proxy for the report's `wheel-zooms-to-changed-limits`
-- | scenario, which
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name. Upstream's `snapPosition` rounds with `Math.round`,
-- | which gives `-0` for a value from -0.5 up to 0. In that scenario, the
-- | flow snaps to a 15 by 15 grid under a viewport at (40, -588), zoomed to
-- | 8, so `screenToFlowPosition({ x: 0, y: 0 })` snaps x = -5 / 15 = -0.33,
-- | and upstream answers `-0`. ps-flow's hand-written `roundHalfUp`
-- | floored, and answered `0`.
-- |
-- | `screenToFlowPosition` reads the container's bounds, which `spago test`
-- | has no DOM for. The test runs the part after them,
-- | `pointToRendererPoint`, at the container's origin.
module Test.System.Utils.MathRound
  ( runMathRoundTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import System.Types.Geometry (mkSnapGrid, mkTransform)
import System.Utils.General (pointToRendererPoint, roundHalfUp, snapPosition)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | `-0`: zero, with a negative sign, which `==` can't tell from `0`.
negativeZero :: Number -> Boolean
negativeZero n = n == 0.0 && 1.0 / n < 0.0

-- | `0`, with a positive sign.
positiveZero :: Number -> Boolean
positiveZero n = n == 0.0 && 1.0 / n > 0.0

runMathRoundTests :: Effect Unit
runMathRoundTests = do
  log "\n=== roundHalfUp is Math.round, down to the sign of a zero ==="

  assert "a value just below 0 rounds to -0, as Math.round's does"
    (negativeZero (roundHalfUp (-0.3)))
  assert "-0.5 rounds to -0, as Math.round's does"
    (negativeZero (roundHalfUp (-0.5)))
  assert "-0 rounds to -0"
    (negativeZero (roundHalfUp (-0.0)))
  assert "a value just above 0 rounds to 0"
    (positiveZero (roundHalfUp 0.3))
  assert "halves round toward +infinity"
    (roundHalfUp (-1.5) == -1.0 && roundHalfUp 1.5 == 2.0 && roundHalfUp 2.5 == 3.0)
  assert "the largest double below one half rounds to 0"
    (positiveZero (roundHalfUp 0.49999999999999994))

  let snapped = snapPosition { x: -5.0, y: 73.5 } (mkSnapGrid 15.0 15.0)
  assert "snapping a point just left of a grid line's half gives -0"
    (negativeZero snapped.x && snapped.y == 75.0)

  let atOrigin = pointToRendererPoint { x: 0.0, y: 0.0 } (mkTransform 40.0 (-588.0) 8.0) (Just (mkSnapGrid 15.0 15.0))
  assert "the container's origin, under wheel-zooms-to-changed-limits' viewport and grid, is (-0, 75), as upstream's screenToFlowPosition answers"
    (negativeZero atOrigin.x && atOrigin.y == 75.0)
