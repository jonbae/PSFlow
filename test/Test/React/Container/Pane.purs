-- | The lasso auto-pan loop in `React.Container.Pane`, one frame at a time.
-- |
-- | The local proxy for "Commit the lasso selection rect only when the pan
-- | landed, as upstream's autoPan does" (#109). Upstream's `autoPan`
-- | (`xyflow/packages/react/src/container/Pane/index.tsx`) awaits `panBy` and
-- | commits the selection rect only when the viewport moved *and* the gesture
-- | is still in progress; either way it then asks for the next frame.
-- |
-- | ps-flow dispatched the fire-and-forget `PanBy` action, which has no
-- | answer to read, so every frame committed: a lasso held against a
-- | `translateExtent` boundary grew its rect by the distance the viewport had
-- | refused to pan and selected nodes the pointer never reached. Each half of
-- | the restored guard fails a check here, as does putting the next-frame
-- | request beside the pan rather than inside its continuation.
-- |
-- | The net cannot see this class: no scenario sets a `translateExtent` and
-- | then drags a selection box into it. So the proof is here, in `spago test`
-- | — the same shape as `Test.System.XYDrag`, which is the node drag's
-- | equivalent loop. The frame clock is the `scheduleFrame` the loop is
-- | handed rather than a stand-in for `window`, so each frame is run by the
-- | check that wants one and two suites cannot clobber each other's globals.
module Test.React.Container.Pane
  ( runPaneAutoPanTests
  ) where

import Prelude

import Data.Array (length, head) as Array
import Data.Either (Either(..))
import Data.Foldable (for_)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_, makeAff, nonCanceler)
import Effect.Aff.AVar as AVar
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Container.Pane.Internal (AutoPanEnv, autoPanLoop)
import System.FFI.Timer (setTimeout)
import System.Types.Geometry (XYPosition)
import System.Utils.Dom (DOMRect)

assert :: String -> Boolean -> Aff Unit
assert label cond = liftEffect $
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | Resume once every microtask queued so far has run.
settle :: Aff Unit
settle = makeAff \resume -> do
  _ <- setTimeout (resume (Right unit)) 0
  pure nonCanceler

-- | The pane the lasso is drawn on.
paneBounds :: DOMRect
paneBounds = { left: 0.0, top: 0.0, width: 800.0, height: 600.0 }

-- | 40px from an edge is where auto-pan starts, so the middle of an 800 × 600
-- | pane pans by nothing.
awayFromEdges :: XYPosition
awayFromEdges = { x: 400.0, y: 300.0 }

-- | 10px from the left edge: velocity (40 − 10) / 40 at the default speed of
-- | 15, so each frame asks to pan 11.25px right.
nearLeftEdge :: XYPosition
nearLeftEdge = { x: 10.0, y: 300.0 }

leftEdgeDelta :: XYPosition
leftEdgeDelta = { x: 11.25, y: 0.0 }

type Setup =
  { mouse :: XYPosition
  , selectionInProgress :: Boolean
  , autoPanOnSelection :: Boolean
  , bounds :: Maybe DOMRect
  }

-- | A lasso already under way, with the pointer at `mouse`.
lassoUnderWay :: XYPosition -> Setup
lassoUnderWay mouse =
  { mouse
  , selectionInProgress: true
  , autoPanOnSelection: true
  , bounds: Just paneBounds
  }

-- | What the frame asked for, in the order it asked. `frames` holds the
-- | frames it scheduled, unrun, so a check can see how many are outstanding
-- | and run one to carry the loop forward.
type Recorded =
  { pans :: Ref (Array XYPosition)
  , commits :: Ref (Array XYPosition)
  , frames :: Ref (Array (Effect Unit))
  , position :: Ref XYPosition
  }

envWith :: Setup -> Recorded -> (XYPosition -> Aff Boolean) -> AutoPanEnv
envWith setup rec panBy =
  { autoPanOnSelection: setup.autoPanOnSelection
  , autoPanSpeed: 15.0
  , containerBounds: pure setup.bounds
  , position: Ref.read rec.position
  , selectionInProgress: pure setup.selectionInProgress
  , panBy: \delta ->
      liftEffect (Ref.modify_ (_ <> [ delta ]) rec.pans) *> panBy delta
  , commitUserSelectionRect: \x y ->
      Ref.modify_ (_ <> [ { x, y } ]) rec.commits
  , scheduleFrame: \frame -> Ref.modify_ (_ <> [ frame ]) rec.frames
  }

scheduled :: Recorded -> Aff Int
scheduled rec = liftEffect (Array.length <$> Ref.read rec.frames)

-- | Run one frame, then hand the recording to `check`. `check` starts before
-- | any microtask has run, so it can see what the frame did on its caller's
-- | stack and what it left until after.
withFrame
  :: Setup
  -> (XYPosition -> Aff Boolean)
  -> (Recorded -> Aff Unit)
  -> Aff Unit
withFrame setup panBy check = do
  rec <- liftEffect do
    pans <- Ref.new []
    commits <- Ref.new []
    frames <- Ref.new []
    position <- Ref.new setup.mouse
    pure { pans, commits, frames, position }
  liftEffect $ autoPanLoop (envWith setup rec panBy)
  check rec

runPaneAutoPanTests :: Effect Unit
runPaneAutoPanTests = launchAff_ do
  log "running lasso auto-pan loop tests..."

  -- The lasso loop pans every frame, unlike the node drag's, which
  -- short-circuits on a zero delta. `panBy` is what answers `false` for one,
  -- and that answer is what keeps the rect where the pointer left it.
  withFrame (lassoUnderWay awayFromEdges) (\_ -> pure false) \rec -> do
    settle
    pans <- liftEffect (Ref.read rec.pans)
    commits <- liftEffect (Ref.read rec.commits)
    frames <- scheduled rec
    assert "a frame away from the edges still asks its pan"
      (pans == [ { x: 0.0, y: 0.0 } ])
    assert "a frame away from the edges commits nothing" (commits == [])
    assert "a frame away from the edges asks for the next one" (frames == 1)

  -- A pan the viewport refused: the boundary case this ticket exists for.
  withFrame (lassoUnderWay nearLeftEdge) (\_ -> pure false) \rec -> do
    settle
    pans <- liftEffect (Ref.read rec.pans)
    commits <- liftEffect (Ref.read rec.commits)
    frames <- scheduled rec
    assert "a frame near an edge asks to pan by the auto-pan velocity"
      (pans == [ leftEdgeDelta ])
    assert "a frame whose pan was refused commits nothing" (commits == [])
    assert "a frame whose pan was refused still asks for the next one"
      (frames == 1)

  -- A pan that landed. ps-flow's own `panBy` completes synchronously, which
  -- is the case that decides whether the commit runs inside the frame's
  -- caller — for the first frame, the `onPointerMove` that started the loop,
  -- which commits the rect itself once it returns.
  withFrame (lassoUnderWay nearLeftEdge) (\_ -> pure true) \rec -> do
    inside <- liftEffect (Ref.read rec.commits)
    asked <- scheduled rec
    assert "a frame whose pan completed synchronously commits nothing inside its caller"
      (inside == [])
    assert "a frame whose pan completed synchronously asks for no frame inside its caller"
      (asked == 0)
    settle
    commits <- liftEffect (Ref.read rec.commits)
    frames <- scheduled rec
    assert "a frame whose pan landed commits the rect at the pointer"
      (commits == [ nearLeftEdge ])
    assert "a frame whose pan landed asks for exactly one next frame" (frames == 1)
    -- And what it scheduled is another frame of the same loop, so the pointer
    -- held at the edge keeps panning.
    liftEffect do
      queued <- Ref.read rec.frames
      for_ (Array.head queued) identity
    settle
    pans <- liftEffect (Ref.read rec.pans)
    assert "the frame it asked for is another turn of the loop"
      (pans == [ leftEdgeDelta, leftEdgeDelta ])

  -- Held open on an AVar to show that nothing is asked for in the meantime.
  gate <- AVar.empty
  withFrame (lassoUnderWay nearLeftEdge) (\_ -> AVar.take gate) \rec -> do
    held <- scheduled rec
    inflight <- liftEffect (Ref.read rec.commits)
    assert "a frame asks for no frame while its pan is in flight" (held == 0)
    assert "a frame commits nothing while its pan is in flight" (inflight == [])
    AVar.put true gate
    settle
    landed <- scheduled rec
    commits <- liftEffect (Ref.read rec.commits)
    assert "a frame asks for the next one once its pan has landed" (landed == 1)
    assert "a frame commits once its pan has landed" (commits == [ nearLeftEdge ])

  -- The other half of upstream's guard: the gesture ended while the pan was
  -- in flight, so there is no rect left to grow.
  withFrame (lassoUnderWay nearLeftEdge) { selectionInProgress = false }
    (\_ -> pure true)
    \rec -> do
      settle
      commits <- liftEffect (Ref.read rec.commits)
      frames <- scheduled rec
      assert "a frame whose gesture has ended commits nothing" (commits == [])
      assert "a frame whose gesture has ended still asks for the next one"
        (frames == 1)

  -- The pointer moves on while the pan is in flight, and the rect follows it
  -- there. TS reads `position.current` again inside its `.then`.
  withFrame (lassoUnderWay nearLeftEdge) (\_ -> pure true) \rec -> do
    liftEffect (Ref.write { x: 12.0, y: 305.0 } rec.position)
    settle
    commits <- liftEffect (Ref.read rec.commits)
    assert "a frame commits at the pointer as of the pan landing, not as of the pan starting"
      (commits == [ { x: 12.0, y: 305.0 } ])

  -- Both ways a frame returns without asking for another, which is how the
  -- loop stops.
  withFrame (lassoUnderWay nearLeftEdge) { autoPanOnSelection = false }
    (\_ -> pure true)
    \rec -> do
      settle
      pans <- liftEffect (Ref.read rec.pans)
      frames <- scheduled rec
      assert "a frame with autoPanOnSelection off pans nothing" (pans == [])
      assert "a frame with autoPanOnSelection off ends the loop" (frames == 0)

  withFrame (lassoUnderWay nearLeftEdge) { bounds = Nothing }
    (\_ -> pure true)
    \rec -> do
      settle
      pans <- liftEffect (Ref.read rec.pans)
      frames <- scheduled rec
      assert "a frame with no container bounds pans nothing" (pans == [])
      assert "a frame with no container bounds ends the loop" (frames == 0)
