-- | `System.XYPanZoom.EventHandler`'s "start"/"zoom"/"end" triad, driven the
-- | way a programmatic `zoom.transform()` call drives it — no active gesture,
-- | no real DOM event behind any of the three.
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
-- | matter what was passed. Only `createPanZoomEndHandler`'s end-of-gesture
-- | call bypassed it (a direct call, not through `callOnPanZoom`), which is
-- | why `onMoveEnd` fired while `onMoveStart` and `onMove` stayed silent: not
-- | a frame-count fluke, a categorical gap in one shared function.
-- |
-- | This runs in `spago test`, against handlers built directly from
-- | `System.XYPanZoom.EventHandler`'s constructors and fed a hand-built d3
-- | zoom event — no browser, no d3 instance, no vendored upstream.
module Test.System.XYPanZoom.EventHandler
  ( runEventHandlerTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_, makeAff, nonCanceler)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import System.FFI.D3Zoom (D3ZoomEvent)
import System.FFI.Timer (setTimeout)
import System.Types.PanZoom (PanOnDrag(..))
import System.XYPanZoom.EventHandler
  ( createPanZoomEndHandler
  , createPanZoomHandler
  , createPanZoomStartHandler
  , defaultZoomPanValues
  )
import Data.Either (Either(..))

-- | `{ transform: { x, y, k }, sourceEvent: null }` — a d3 zoom event with no
-- | real DOM event behind it, which is what a `.transform()` call raises
-- | outside an active gesture. `x`/`y`/`k` are arbitrary; only their identity
-- | across the three handlers is checked.
foreign import mkTransformOnlyZoomEvent :: Number -> Number -> Number -> D3ZoomEvent

assert :: String -> Boolean -> Aff Unit
assert label cond = liftEffect $
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | Resume once the `setTimeout 0` the end handler schedules has run.
settle :: Aff Unit
settle = makeAff \resume -> do
  _ <- setTimeout (resume (Right unit)) 0
  pure nonCanceler

runEventHandlerTests :: Effect Unit
runEventHandlerTests = launchAff_ do
  log "running XYPanZoom event handler tests..."

  zpv <- liftEffect defaultZoomPanValues
  startCount <- liftEffect (Ref.new 0)
  startEvents <- liftEffect (Ref.new [] :: Effect (Ref (Array Boolean)))
  moveCount <- liftEffect (Ref.new 0)
  endCount <- liftEffect (Ref.new 0)

  startH <- liftEffect $ createPanZoomStartHandler
    { zoomPanValues: zpv
    , onDraggingChange: \_ -> pure unit
    , onPanZoomStart: Just \mEvt _vp -> do
        Ref.modify_ (_ + 1) startCount
        let isNothingEvt = case mEvt of
              Nothing -> true
              Just _ -> false
        Ref.modify_ (_ <> [ isNothingEvt ]) startEvents
    }
  zoomH <- liftEffect $ createPanZoomHandler
    { zoomPanValues: zpv
    , panOnDrag: PanAlways
    , onPaneContextMenu: false
    , onTransformChange: \_ -> pure unit
    , onPanZoom: Just \_mEvt _vp -> Ref.modify_ (_ + 1) moveCount
    }
  endH <- liftEffect $ createPanZoomEndHandler
    { zoomPanValues: zpv
    , panOnDrag: PanAlways
    , panOnScroll: false
    , onDraggingChange: \_ -> pure unit
    , onPanZoomEnd: Just \_mEvt _vp -> Ref.modify_ (_ + 1) endCount
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
    (sEvts == [ true ])
