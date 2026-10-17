-- | The six edge-path helpers, called the way a JavaScript caller calls
-- | them, against upstream's answers.
-- |
-- | The local proxy for `Boundary.EdgePaths` on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93),
-- | which `custom-edge-baseedge-path` and `mount-baseline--edges-base-edge-path`
-- | showed throwing "Failed pattern match at System.Utils.Edges.SmoothStep" on
-- | the position strings a custom edge is handed. The expected arrays are the
-- | vendored upstream's own answers to the calls surface parity makes, so a
-- | converter that drops a default, reorders the array, or ignores a string
-- | fails here.
module Test.Boundary.EdgePaths
  ( runEdgePathsTests
  ) where

import Prelude

import Boundary.EdgePaths
  ( JsBezierEdgeCenterParams
  , JsBezierPathParams
  , JsEdgePoints
  , JsSimpleBezierPathParams
  , JsSmoothStepPathParams
  , getBezierEdgeCenter
  , getBezierPath
  , getEdgeCenter
  , getSimpleBezierPath
  , getSmoothStepPath
  , getStraightPath
  )
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import Unsafe.Coerce (unsafeCoerce)

foreign import points :: JsEdgePoints
foreign import bezierControl :: JsBezierEdgeCenterParams
foreign import bezierRightLeft :: JsBezierPathParams
foreign import bezierDefaults :: JsBezierPathParams
foreign import backwards :: JsEdgePoints
foreign import backwardsDefaults :: JsBezierPathParams
foreign import smoothStepRightLeft :: JsSmoothStepPathParams
foreign import smoothStepDefaults :: JsSmoothStepPathParams
foreign import json :: forall a. a -> String

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | The bare points, read as a parameter object with every option left out.
bare :: forall r. JsEdgePoints -> Record r
bare = unsafeCoerce

runEdgePathsTests :: Effect Unit
runEdgePathsTests = do
  log "\n=== The edge-path helpers, as JavaScript calls them ==="

  assert "getBezierPath takes the position strings and returns upstream's array"
    (json (getBezierPath bezierRightLeft) == """["M0,20 C75,20 75,100 150,100",75,60,75,40]""")
  assert "getBezierPath defaults the positions to bottom and top"
    (json (getBezierPath (bare points)) == json (getBezierPath bezierDefaults))
  assert "getBezierPath's default curvature is upstream's, where the curvature applies"
    (json (getBezierPath (bare backwards)) == json (getBezierPath backwardsDefaults))

  assert "getSmoothStepPath takes the position strings and returns upstream's array"
    ( json (getSmoothStepPath smoothStepRightLeft)
        == """["M0 20L20 20L 70,20Q 75,20 75,25L 75,95Q 75,100 80,100L130 100L150 100",75,60,75,40]"""
    )
  assert "getSmoothStepPath defaults the positions, the radius, the offset, and the step position"
    (json (getSmoothStepPath (bare points)) == json (getSmoothStepPath smoothStepDefaults))

  assert "getSimpleBezierPath defaults the positions and returns upstream's array"
    (json (getSimpleBezierPath (bare points :: JsSimpleBezierPathParams)) == """["M0,20 C0,60 150,60 150,100",75,60,75,40]""")

  assert "getStraightPath returns upstream's array"
    (json (getStraightPath points) == """["M 0,20L 150,100",75,60,75,40]""")

  assert "getEdgeCenter returns upstream's array"
    (json (getEdgeCenter points) == "[75,60,75,40]")

  assert "getBezierEdgeCenter returns upstream's array"
    (json (getBezierEdgeCenter bezierControl) == "[75,60,75,40]")
