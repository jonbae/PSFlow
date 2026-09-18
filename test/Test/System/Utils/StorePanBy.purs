-- | `System.Utils.Store.panBy` at a `translateExtent` boundary.
-- |
-- | The local proxy for "Report from panBy whether the viewport moved, so
-- | auto-pan stops moving nodes at a translateExtent" (#99). The Boolean this
-- | function returns is the only thing an auto-pan frame has to tell a pan
-- | that landed from one the viewport refused, and it used to answer `true`
-- | for any transform d3 handed back. At a boundary `constrain` hands back the
-- | transform the viewport is already at, so every frame read a refusal as
-- | movement and moved the dragged node by the distance it had asked to pan.
-- | Upstream's `transformChanged` compares the constrained transform with the
-- | current one, component by component
-- | (`xyflow/packages/system/src/utils/store.ts`, `panBy`).
-- |
-- | Each case gives the stand-in instance the answer d3 would give and checks
-- | what `panBy` reads off it. Whether d3 clamps where the case says it does
-- | is the browser's question, and the net's; the `atBoundary` answer is a
-- | clamp so that one case reads as the boundary rather than as a canned
-- | reply.
-- |
-- | The auto-pan loop's own proxy in `Test.System.XYDrag` covers the other
-- | half: that a frame whose pan answered `false` moves nothing.
module Test.System.Utils.StorePanBy
  ( runStorePanByTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import System.Constants (infiniteExtent)
import System.Types.Connection (Viewport)
import System.Types.Geometry (CoordinateExtent, Transform, mkCoordinateExtent, mkTransform)
import System.Types.PanZoom (PanZoomInstance)
import System.Utils.Store (panBy)
import System.XYPanZoom.Utils (viewportToTransform)

assert :: String -> Boolean -> Aff Unit
assert label cond = liftEffect $
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | What the instance answered with, and what it was asked for on the way.
type Instance =
  { instance :: PanZoomInstance
  , asked :: Ref (Array Viewport)
  }

-- | A `PanZoomInstance` whose `setViewportConstrained` runs `answer` on the
-- | requested viewport and hands back the result as a d3 transform.
-- | `Nothing` is the real instance's answer when its d3 selection has gone.
-- |
-- | Every other method is inert: `panBy` calls exactly one of them, and if it
-- | starts calling a second, `spago test` says so rather than a browser.
withAnswer :: (Viewport -> Maybe Viewport) -> Effect Instance
withAnswer answer = do
  asked <- Ref.new []
  pure
    { asked
    , instance:
        { update: \_ -> pure unit
        , destroy: pure unit
        , getViewport: pure { x: 0.0, y: 0.0, zoom: 1.0 }
        , setViewport: \_ _ -> pure Nothing
        , setViewportConstrained: \v _ _ -> do
            liftEffect (Ref.modify_ (_ <> [ v ]) asked)
            pure (map viewportToTransform (answer v))
        , setScaleExtent: \_ _ -> pure unit
        , setTranslateExtent: \_ -> pure unit
        , scaleTo: \_ _ -> pure false
        , scaleBy: \_ _ -> pure false
        , syncViewport: \_ -> pure unit
        , setClickDistance: \_ -> pure unit
        }
    }

-- | The pan the auto-pan loop asks for: 11.25px right, which is the default
-- | speed at 10px from an 800 × 600 container's left edge.
nudge :: { x :: Number, y :: Number }
nudge = { x: 11.25, y: 0.0 }

-- | The viewport every case starts from.
origin :: Transform
origin = mkTransform 0.0 0.0 1.0

extent :: CoordinateExtent
extent = mkCoordinateExtent (-2000.0) (-2000.0) 2000.0 2000.0

-- | `panBy` against the stand-in, from `origin`.
panFrom :: Instance -> { x :: Number, y :: Number } -> Aff Boolean
panFrom inst delta =
  panBy delta (Just inst.instance) origin extent 800.0 600.0

-- | d3's `constrain` at a boundary: a translate that takes `x` no further
-- | than 0, which is where the viewport already is.
atBoundary :: Viewport -> Maybe Viewport
atBoundary v = Just (v { x = min 0.0 v.x })

runStorePanByTests :: Effect Unit
runStorePanByTests = launchAff_ do
  log "running store panBy tests..."

  -- Away from the boundary `constrain` translates by nothing, so the answer
  -- is the viewport as asked for and the pan landed.
  accepted <- liftEffect (withAnswer Just)
  moved <- panFrom accepted nudge
  assert "a pan the viewport accepted reports true" moved

  -- At the boundary the answer is the position the viewport is already at.
  -- This is the regression: the old reading saw a transform and called it
  -- movement, so the auto-pan frame moved its node by 11.25px a frame while
  -- the viewport held still.
  refusing <- liftEffect (withAnswer atBoundary)
  refused <- panFrom refusing nudge
  assert "a pan constrained back to the current viewport reports false"
    (not refused)

  -- The instance still ran, so that `false` is the comparison's answer and
  -- not an early return that skipped the constraint.
  askedAtEdge <- liftEffect (Ref.read refusing.asked)
  assert "a refused pan still asked the instance to constrain it"
    (askedAtEdge == [ { x: 11.25, y: 0.0, zoom: 1.0 } ])

  -- Partway into the boundary: the answer gives back some of the pan but not
  -- all of it, which is movement.
  shortened <- liftEffect (withAnswer \v -> Just (v { x = v.x / 2.0 }))
  some <- panFrom shortened nudge
  assert "a pan the viewport shortened but did not refuse reports true" some

  -- Each component on its own, because upstream compares all three and a
  -- comparison that dropped one would pass every case before this.
  onlyY <- liftEffect (withAnswer \v -> Just (v { x = 0.0, y = 40.0 }))
  yMoved <- panFrom onlyY nudge
  assert "a constrained viewport differing only in y reports true" yMoved

  onlyZoom <- liftEffect (withAnswer \v -> Just (v { x = 0.0, zoom = 2.0 }))
  zoomMoved <- panFrom onlyZoom nudge
  assert "a constrained viewport differing only in zoom reports true"
    zoomMoved

  -- A zero delta is upstream's `!delta.x && !delta.y`: no pan to judge, so
  -- no constraint either.
  untouched <- liftEffect (withAnswer Just)
  still <- panFrom untouched { x: 0.0, y: 0.0 }
  assert "a zero delta reports false" (not still)
  askedNothing <- liftEffect (Ref.read untouched.asked)
  assert "a zero delta does not touch the instance" (askedNothing == [])

  -- No instance is the pane not mounted yet. Upstream's `!panZoom` returns
  -- `false` there, and so the loop's `when ok` moves nothing.
  bare <- panBy nudge Nothing origin infiniteExtent 800.0 600.0
  assert "with no pan-zoom instance the pan reports false" (not bare)

  -- An instance whose d3 selection has gone answers with no transform, which
  -- is not movement.
  gone <- liftEffect (withAnswer (const Nothing))
  none <- panFrom gone nudge
  assert "an instance that answers with no transform reports false" (not none)
