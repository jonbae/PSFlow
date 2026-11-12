-- | `System.XYPanZoom.EventHandler`'s "start"/"zoom"/"end" dispatch, with the
-- | event shapes d3 supplies for programmatic and real-event transforms.
-- |
-- | The local proxy for "Fire onMoveStart and onMove from auto-pan, which
-- | currently fires only onMoveEnd" (#121). Auto-pan moves the viewport
-- | through `panBy` → `setViewportConstrained` → `zoomBehaviorTransform`,
-- | which is d3's `zoom.transform(selection, t)`; outside an active gesture
-- | d3 raises "start", "zoom" and "end" synchronously in that order, each
-- | with `sourceEvent: null` since no real pointer event drove the call.
-- |
-- | `callOnPanZoom`, the function all three handlers route the user's
-- | `onPanZoomStart` / `onPanZoom` / `onPanZoomEnd` callbacks through, used to
-- | discard the callback outright — `case mCb of Just _ -> pure unit` — no
-- | matter what was passed. That left `onMoveStart` and `onMove` silent while
-- | the end path still fired: not a frame-count fluke, a categorical dispatch
-- | gap.
-- |
-- | This is a handler-level proxy: it proves dispatch and coercion once those
-- | handlers receive a d3 event. The system-parity scenarios prove that
-- | auto-pan's `panBy` path reaches them.
module Test.System.XYPanZoom.EventHandler
  ( runEventHandlerTests
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_, makeAff, nonCanceler)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import System.FFI.D3Selection (D3Selection)
import System.FFI.D3Zoom
  ( D3ZoomBehavior
  , D3ZoomEvent
  , zoomBehaviorTranslateByInternal
  )
import System.FFI.Timer (setTimeout)
import System.Types.PanZoom (PanOnDrag(..))
import System.XYPanZoom.EventHandler
  ( createPanZoomEndHandler
  , createPanZoomHandler
  , createPanZoomStartHandler
  , defaultZoomPanValues
  )
import Web.TouchEvent.TouchEvent (TouchEvent)
import Web.UIEvent.MouseEvent (MouseEvent)

-- | `{ transform: { x, y, k }, sourceEvent: null }` — a d3 zoom event with no
-- | real DOM event behind it, which is what a `.transform()` call raises
-- | outside an active gesture. `x`/`y`/`k` are arbitrary; only their identity
-- | across the three handlers is checked.
foreign import mkTransformOnlyZoomEvent :: Number -> Number -> Number -> D3ZoomEvent
foreign import mkMouseSourcedZoomEvent :: Number -> Number -> Number -> D3ZoomEvent
foreign import mkTouchSourcedZoomEvent :: Number -> Number -> Number -> D3ZoomEvent
foreign import mkTranslateBySpy
  :: Effect
       { behavior :: D3ZoomBehavior
       , selection :: D3Selection
       , sawExpectedCall :: Effect Boolean
       }

eventKind :: Maybe (Either MouseEvent TouchEvent) -> String
eventKind = case _ of
  Nothing -> "none"
  Just (Left _) -> "mouse"
  Just (Right _) -> "touch"

assert :: String -> Boolean -> Aff Unit
assert label cond = liftEffect $
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | Yield once so a mistakenly deferred/debounced callback has a chance to
-- | expose itself to the count assertions below.
settle :: Aff Unit
settle = makeAff \resume -> do
  _ <- setTimeout (resume (Right unit)) 0
  pure nonCanceler

runEventHandlerTests :: Effect Unit
runEventHandlerTests = launchAff_ do
  log "running XYPanZoom event handler tests..."

  translateSpy <- liftEffect mkTranslateBySpy
  liftEffect $ zoomBehaviorTranslateByInternal
    translateSpy.behavior translateSpy.selection 3.0 4.0
  sawInternal <- liftEffect translateSpy.sawExpectedCall
  assert "pan-on-scroll's translateBy carries the internal source marker"
    sawInternal

  zpv <- liftEffect defaultZoomPanValues
  startCount <- liftEffect (Ref.new 0)
  startEvents <- liftEffect (Ref.new [] :: Effect (Ref (Array String)))
  moveCount <- liftEffect (Ref.new 0)
  moveEvents <- liftEffect (Ref.new [] :: Effect (Ref (Array String)))
  endCount <- liftEffect (Ref.new 0)
  endEvents <- liftEffect (Ref.new [] :: Effect (Ref (Array String)))

  startH <- liftEffect $ createPanZoomStartHandler
    { zoomPanValues: zpv
    , onDraggingChange: \_ -> pure unit
    , onPanZoomStart: Just \mEvt _vp -> do
        Ref.modify_ (_ + 1) startCount
        Ref.modify_ (_ <> [ eventKind mEvt ]) startEvents
    }
  zoomH <- liftEffect $ createPanZoomHandler
    { zoomPanValues: zpv
    , panOnDrag: PanAlways
    , onPaneContextMenu: false
    , onTransformChange: \_ -> pure unit
    , onPanZoom: Just \mEvt _vp -> do
        Ref.modify_ (_ + 1) moveCount
        Ref.modify_ (_ <> [ eventKind mEvt ]) moveEvents
    }
  endH <- liftEffect $ createPanZoomEndHandler
    { zoomPanValues: zpv
    , panOnDrag: PanAlways
    , panOnScroll: false
    , onDraggingChange: \_ -> pure unit
    , onPanZoomEnd: Just \mEvt _vp -> do
        Ref.modify_ (_ + 1) endCount
        Ref.modify_ (_ <> [ eventKind mEvt ]) endEvents
    , onPaneContextMenu: Nothing
    }

  -- One auto-pan frame: d3's synthesized gesture calls start, zoom, then end
  -- in sequence, each against the same sourceEvent-less event.
  let event = mkTransformOnlyZoomEvent 10.0 20.0 1.0
  liftEffect (startH event)
  liftEffect (zoomH event)
  liftEffect (endH event)
  settle

  s <- liftEffect (Ref.read startCount)
  m <- liftEffect (Ref.read moveCount)
  e <- liftEffect (Ref.read endCount)
  assert "a programmatic transform fires onMoveStart once" (s == 1)
  assert "a programmatic transform fires onMove once" (m == 1)
  assert "a programmatic transform fires onMoveEnd once, not unpaired" (e == 1)

  sEvts <- liftEffect (Ref.read startEvents)
  assert "onMoveStart sees no source event, matching auto-pan's own call"
    (sEvts == [ "none" ])
  eEvts <- liftEffect (Ref.read endEvents)
  assert "onMoveEnd sees no source event for the same programmatic transform"
    (eEvts == [ "none" ])

  -- The Just branches are consumer-visible too. Feed the handlers the two
  -- shapes `foreignAsMouseOrTouch` distinguishes, back-to-back: regular ends
  -- must not cancel each other through the scroll-only debounce timer.
  let mouseEvent = mkMouseSourcedZoomEvent 11.0 21.0 1.1
      touchEvent = mkTouchSourcedZoomEvent 12.0 22.0 1.2
  liftEffect (startH mouseEvent)
  liftEffect (zoomH mouseEvent)
  liftEffect (endH mouseEvent)
  liftEffect (startH touchEvent)
  liftEffect (zoomH touchEvent)
  liftEffect (endH touchEvent)
  settle

  sAll <- liftEffect (Ref.read startCount)
  mAll <- liftEffect (Ref.read moveCount)
  eAll <- liftEffect (Ref.read endCount)
  assert "three transforms keep three balanced callback triads"
    (sAll == 3 && mAll == 3 && eAll == 3)

  sKinds <- liftEffect (Ref.read startEvents)
  mKinds <- liftEffect (Ref.read moveEvents)
  eKinds <- liftEffect (Ref.read endEvents)
  let expectedKinds = [ "none", "mouse", "touch" ]
  assert "onMoveStart preserves null, mouse/wheel, and touch source shapes"
    (sKinds == expectedKinds)
  assert "onMove preserves null, mouse/wheel, and touch source shapes"
    (mKinds == expectedKinds)
  assert "onMoveEnd preserves null, mouse/wheel, and touch source shapes"
    (eKinds == expectedKinds)
