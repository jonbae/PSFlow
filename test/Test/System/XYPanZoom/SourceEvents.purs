-- | Local proxies for the d3 source-event arguments passed by pan-on-scroll
-- | pinch and controlled viewport synchronization.
module Test.System.XYPanZoom.SourceEvents
  ( runSourceEventTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Foreign (Foreign)
import Partial.Unsafe (unsafeCrashWith)
import System.FFI.D3Selection (D3Selection)
import System.FFI.D3Zoom (D3ZoomBehavior, D3ZoomEvent)
import System.Types.Connection (PanOnScrollMode(..))
import System.Types.PanZoom (PanOnDrag(..))
import System.XYPanZoom (syncViewportImpl)
import System.XYPanZoom.EventHandler
  ( createPanOnScrollHandler
  , createPanZoomHandler
  , defaultZoomPanValues
  )

foreign import mkPinchSpy :: Effect
  { behavior :: D3ZoomBehavior
  , selection :: D3Selection
  , event :: Foreign
  , sawExpectedCall :: Effect Boolean
  }

foreign import mkSyncSpy :: Effect
  { behavior :: D3ZoomBehavior
  , selection :: D3Selection
  , sawNoCalls :: Effect Boolean
  , sawExpectedCall :: Effect Boolean
  }

foreign import mkZoomEvent :: Boolean -> D3ZoomEvent

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

runSourceEventTests :: Effect Unit
runSourceEventTests = do
  log "running XYPanZoom source-event tests..."

  pinch <- mkPinchSpy
  zpv <- defaultZoomPanValues
  wheel <- createPanOnScrollHandler
    { zoomPanValues: zpv
    , noWheelClassName: "nowheel"
    , d3Selection: pinch.selection
    , d3Zoom: pinch.behavior
    , panOnScrollMode: Free
    , panOnScrollSpeed: 0.5
    , zoomOnPinch: true
    , onPanZoomStart: Nothing
    , onPanZoom: Nothing
    , onPanZoomEnd: Nothing
    }
  wheel pinch.event
  pinchPassed <- pinch.sawExpectedCall
  assert "pan-on-scroll pinch passes pointer-relative point and wheel event"
    pinchPassed

  sync <- mkSyncSpy
  syncViewportImpl sync.behavior sync.selection { x: 1.0, y: 2.0, zoom: 3.0 }
  unchangedSkipped <- sync.sawNoCalls
  assert "syncViewport skips an unchanged viewport" unchangedSkipped
  syncViewportImpl sync.behavior sync.selection { x: 4.0, y: 5.0, zoom: 2.0 }
  changedSynced <- sync.sawExpectedCall
  assert "syncViewport sends d3 a null point and sync source marker" changedSynced

  changed <- Ref.new 0
  zoom <- createPanZoomHandler
    { zoomPanValues: zpv
    , panOnDrag: PanAlways
    , onPaneContextMenu: false
    , onTransformChange: \_ -> Ref.modify_ (_ + 1) changed
    , onPanZoom: Nothing
    }
  zoom (mkZoomEvent true)
  suppressed <- Ref.read changed
  assert "the sync marker suppresses onTransformChange" (suppressed == 0)
  zoom (mkZoomEvent false)
  ordinary <- Ref.read changed
  assert "ordinary transforms still call onTransformChange" (ordinary == 1)
