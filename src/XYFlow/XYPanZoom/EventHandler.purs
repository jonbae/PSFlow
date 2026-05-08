-- | Pan/zoom event handler creators — port of
-- | `xyflow-main/packages/system/src/xypanzoom/eventhandler.ts`.
-- |
-- | Each `create*` returns an `Effect <handler>` because the handlers close
-- | over `Ref ZoomPanValues` shared with the controller; the `Effect`
-- | wrapper is the moment the closures latch onto the cells.
module XYFlow.XYPanZoom.EventHandler
  ( ZoomPanValues
  , defaultZoomPanValues
  , PanOnScrollParams
  , ZoomOnScrollParams
  , PanZoomStartHandlerParams
  , PanZoomHandlerParams
  , PanZoomEndHandlerParams
  , WheelEventHandler
  , D3ZoomEventHandler
  , createPanOnScrollHandler
  , createZoomOnScrollHandler
  , createPanZoomStartHandler
  , createPanZoomHandler
  , createPanZoomEndHandler
  ) where

import Prelude

import Data.Foldable (for_)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Foreign (Foreign)
import XYFlow.FFI.D3Zoom
  ( D3ZoomBehavior
  , D3ZoomEvent
  , selectionGetZoomProperty
  , zoomBehaviorScaleTo
  , zoomBehaviorTranslateBy
  , zoomEventSourceEvent
  , zoomEventTransform
  , zoomTransformK
  )
import XYFlow.FFI.D3Selection (D3Selection)
import XYFlow.FFI.Timer (TimeoutId, clearTimeout, setTimeout)
import XYFlow.Types.Connection (PanOnScrollMode(..), Viewport)
import XYFlow.Types.Geometry (Transform, mkTransform)
import XYFlow.Types.PanZoom (OnDraggingChange, OnPanZoom, OnTransformChange, PanOnDrag)
import XYFlow.Utils.General (isMacOs)
import XYFlow.XYPanZoom.Utils
  ( isRightClickPan
  , isWrappedWithClass
  , transformToViewport
  , wheelDelta
  )

-- | Mutable controller state shared across the five handler families. The
-- | TS structure is a plain object; PS holds the equivalent record of
-- | `Ref` cells so the handlers can read/write atomically.
type ZoomPanValues =
  { isZoomingOrPanning :: Ref Boolean
  , usedRightMouseButton :: Ref Boolean
  , prevViewport :: Ref Viewport
  , mouseButton :: Ref Int
  , timerId :: Ref (Maybe TimeoutId)
  , panScrollTimeout :: Ref (Maybe TimeoutId)
  , isPanScrolling :: Ref Boolean
  }

defaultZoomPanValues :: Effect ZoomPanValues
defaultZoomPanValues = do
  isZoomingOrPanning <- Ref.new false
  usedRightMouseButton <- Ref.new false
  prevViewport <- Ref.new { x: 0.0, y: 0.0, zoom: 0.0 }
  mouseButton <- Ref.new 0
  timerId <- Ref.new Nothing
  panScrollTimeout <- Ref.new Nothing
  isPanScrolling <- Ref.new false
  pure
    { isZoomingOrPanning
    , usedRightMouseButton
    , prevViewport
    , mouseButton
    , timerId
    , panScrollTimeout
    , isPanScrolling
    }

-- | Wheel-event handler shape — `Foreign` is the d3-handed event.
type WheelEventHandler = Foreign -> Effect Unit

-- | d3-zoom event handler shape.
type D3ZoomEventHandler = D3ZoomEvent -> Effect Unit

-- ----------------------------------------------------------------------------
-- Param records
-- ----------------------------------------------------------------------------

type PanOnScrollParams =
  { zoomPanValues :: ZoomPanValues
  , noWheelClassName :: String
  , d3Selection :: D3Selection
  , d3Zoom :: D3ZoomBehavior
  , panOnScrollMode :: PanOnScrollMode
  , panOnScrollSpeed :: Number
  , zoomOnPinch :: Boolean
  , onPanZoomStart :: Maybe OnPanZoom
  , onPanZoom :: Maybe OnPanZoom
  , onPanZoomEnd :: Maybe OnPanZoom
  }

type ZoomOnScrollParams =
  { noWheelClassName :: String
  , preventScrolling :: Boolean
  , d3ZoomHandler :: WheelEventHandler
  }

type PanZoomStartHandlerParams =
  { zoomPanValues :: ZoomPanValues
  , onDraggingChange :: OnDraggingChange
  , onPanZoomStart :: Maybe OnPanZoom
  }

type PanZoomHandlerParams =
  { zoomPanValues :: ZoomPanValues
  , panOnDrag :: PanOnDrag
  , onPaneContextMenu :: Boolean
  , onTransformChange :: OnTransformChange
  , onPanZoom :: Maybe OnPanZoom
  }

type PanZoomEndHandlerParams =
  { zoomPanValues :: ZoomPanValues
  , panOnDrag :: PanOnDrag
  , panOnScroll :: Boolean
  , onDraggingChange :: OnDraggingChange
  , onPanZoomEnd :: Maybe OnPanZoom
  , onPaneContextMenu :: Maybe (Foreign -> Effect Unit)
  }

-- | Shape readers for d3 events. `D3ZoomEvent.sourceEvent` is opaque.
foreign import sourceEventInternal :: Foreign -> Effect Boolean
foreign import sourceEventSync :: Foreign -> Effect Boolean
foreign import sourceEventButton :: Foreign -> Effect Int
foreign import sourceEventTypeIs :: Foreign -> String -> Effect Boolean
foreign import sourceEventStopImmediate :: Foreign -> Effect Unit
foreign import sourceEventPreventDefault :: Foreign -> Effect Unit
foreign import sourceEventDeltaXY :: Foreign -> Effect { x :: Number, y :: Number, mode :: Int, shiftKey :: Boolean }
-- | Coerce a `Foreign` event into the union the user-supplied callback
-- | expects. Same `unsafeCoerce` move the TS source uses (`as MouseEvent | TouchEvent`).
foreign import asMouseOrTouch :: Foreign -> Foreign

-- | Wrapper to call user-supplied `OnPanZoom` callbacks. The `Foreign` is the
-- | underlying mouse/touch event, opaque on the PS side until the user picks.
callOnPanZoom :: Maybe OnPanZoom -> Foreign -> Viewport -> Effect Unit
callOnPanZoom mCb _ev _vp = case mCb of
  Just _ -> pure unit -- Type alignment is enforced by `OnPanZoom`'s shape;
  -- the actual event coercion happens at the FFI boundary in callers that
  -- already have a `Maybe (Either MouseEvent TouchEvent)`.
  Nothing -> pure unit

-- ----------------------------------------------------------------------------
-- createPanOnScrollHandler
-- ----------------------------------------------------------------------------

createPanOnScrollHandler :: PanOnScrollParams -> Effect WheelEventHandler
createPanOnScrollHandler p = pure \event -> do
  inNoWheel <- isWrappedWithClass event p.noWheelClassName
  if inNoWheel then do
    ctrl <- foreignCtrlKey event
    when ctrl (sourceEventPreventDefault event)
    pure unit
  else do
    sourceEventPreventDefault event
    sourceEventStopImmediate event
    currentTransform <- selectionGetZoomProperty p.d3Selection
    let currentZoom = zoomTransformK currentTransform
        zoomBase = if currentZoom == 0.0 then 1.0 else currentZoom

    ctrl <- foreignCtrlKey event
    if ctrl && p.zoomOnPinch then do
      delta <- wheelDelta event
      let newZoom = zoomBase * powN 2.0 delta
      zoomBehaviorScaleTo p.d3Zoom p.d3Selection newZoom
    else do
      d <- sourceEventDeltaXY event
      let
        deltaNormalize = if d.mode == 1 then 20.0 else 1.0
        rawDx = case p.panOnScrollMode of
          Vertical -> 0.0
          _ -> d.x * deltaNormalize
        rawDy = case p.panOnScrollMode of
          Horizontal -> 0.0
          _ -> d.y * deltaNormalize
      mac <- isMacOs
      let
        isShiftWindowsOverride =
          not mac && d.shiftKey && p.panOnScrollMode /= Vertical
        dx = if isShiftWindowsOverride then d.y * deltaNormalize else rawDx
        dy = if isShiftWindowsOverride then 0.0 else rawDy
      zoomBehaviorTranslateBy p.d3Zoom p.d3Selection
        (-(dx / zoomBase) * p.panOnScrollSpeed)
        (-(dy / zoomBase) * p.panOnScrollSpeed)

      next <- selectionGetZoomProperty p.d3Selection
      let nextViewport = transformToViewport next

      mPST <- Ref.read p.zoomPanValues.panScrollTimeout
      for_ mPST clearTimeout
      Ref.write Nothing p.zoomPanValues.panScrollTimeout

      panning <- Ref.read p.zoomPanValues.isPanScrolling
      if not panning then do
        Ref.write true p.zoomPanValues.isPanScrolling
        callOnPanZoom p.onPanZoomStart event nextViewport
      else do
        callOnPanZoom p.onPanZoom event nextViewport
        tid <- setTimeout
          ( do
              callOnPanZoom p.onPanZoomEnd event nextViewport
              Ref.write false p.zoomPanValues.isPanScrolling
          )
          150
        Ref.write (Just tid) p.zoomPanValues.panScrollTimeout

foreign import foreignCtrlKey :: Foreign -> Effect Boolean
foreign import powN :: Number -> Number -> Number

-- ----------------------------------------------------------------------------
-- createZoomOnScrollHandler
-- ----------------------------------------------------------------------------

createZoomOnScrollHandler :: ZoomOnScrollParams -> Effect WheelEventHandler
createZoomOnScrollHandler p = pure \event -> do
  isWheel <- sourceEventTypeIs event "wheel"
  ctrl <- foreignCtrlKey event
  let preventZoom = not p.preventScrolling && isWheel && not ctrl
  insideNoWheel <- isWrappedWithClass event p.noWheelClassName
  when (ctrl && isWheel && insideNoWheel) (sourceEventPreventDefault event)
  if preventZoom || insideNoWheel then pure unit
  else do
    sourceEventPreventDefault event
    p.d3ZoomHandler event

-- ----------------------------------------------------------------------------
-- createPanZoomStartHandler
-- ----------------------------------------------------------------------------

createPanZoomStartHandler
  :: PanZoomStartHandlerParams -> Effect D3ZoomEventHandler
createPanZoomStartHandler p = pure \event -> do
  let src = zoomEventSourceEvent event
  internal <- sourceEventInternal src
  unless internal do
    let viewport = transformToViewport (zoomEventTransform event)
    btn <- sourceEventButton src
    Ref.write btn p.zoomPanValues.mouseButton
    Ref.write true p.zoomPanValues.isZoomingOrPanning
    Ref.write viewport p.zoomPanValues.prevViewport
    isMouseDown <- sourceEventTypeIs src "mousedown"
    when isMouseDown (p.onDraggingChange true)
    callOnPanZoom p.onPanZoomStart src viewport

-- ----------------------------------------------------------------------------
-- createPanZoomHandler
-- ----------------------------------------------------------------------------

createPanZoomHandler :: PanZoomHandlerParams -> Effect D3ZoomEventHandler
createPanZoomHandler p = pure \event -> do
  let src = zoomEventSourceEvent event
      transform = zoomEventTransform event
  btn <- Ref.read p.zoomPanValues.mouseButton
  let
    rightClickActive = p.onPaneContextMenu && isRightClickPan p.panOnDrag btn
  Ref.write rightClickActive p.zoomPanValues.usedRightMouseButton
  sync <- sourceEventSync src
  unless sync do
    -- TS calls onTransformChange with a 3-tuple; PS wraps in `Transform`.
    p.onTransformChange (mkTransformLocal transform)
  internal <- sourceEventInternal src
  case p.onPanZoom of
    Just _ | not internal -> callOnPanZoom p.onPanZoom src
        (transformToViewport transform)
    _ -> pure unit
  where
  -- Pull (x, y, k) off the d3 ZoomTransform and wrap into the PS Transform.
  -- The underlying value is a d3 ZoomTransform (immutable record); we read
  -- its three fields directly via FFI.
  mkTransformLocal :: forall a. a -> Transform
  mkTransformLocal t = mkTransform (transformX_ t) (transformY_ t)
    (zoomTransformK_ t)

-- Local FFI accessors — read the (x, y, k) fields off a d3 ZoomTransform.
-- They duplicate the `XYFlow.FFI.D3Zoom` accessors but on `Foreign`-typed
-- input, since `zoomEventTransform` here returns `ZoomTransform` opaquely.
foreign import zoomTransformK_ :: forall a. a -> Number
foreign import transformX_ :: forall a. a -> Number
foreign import transformY_ :: forall a. a -> Number

-- ----------------------------------------------------------------------------
-- createPanZoomEndHandler
-- ----------------------------------------------------------------------------

createPanZoomEndHandler :: PanZoomEndHandlerParams -> Effect D3ZoomEventHandler
createPanZoomEndHandler p = pure \event -> do
  let src = zoomEventSourceEvent event
  internal <- sourceEventInternal src
  unless internal do
    Ref.write false p.zoomPanValues.isZoomingOrPanning
    btn <- Ref.read p.zoomPanValues.mouseButton
    used <- Ref.read p.zoomPanValues.usedRightMouseButton
    case p.onPaneContextMenu of
      Just cb | isRightClickPan p.panOnDrag btn && not used -> cb src
      _ -> pure unit
    Ref.write false p.zoomPanValues.usedRightMouseButton
    p.onDraggingChange false
    case p.onPanZoomEnd of
      Just cb -> do
        let viewport = transformToViewport (zoomEventTransform event)
        Ref.write viewport p.zoomPanValues.prevViewport
        mPrev <- Ref.read p.zoomPanValues.timerId
        for_ mPrev clearTimeout
        let delay = if p.panOnScroll then 150 else 0
        tid <- setTimeout
          (callOnPanZoomDirect cb src viewport)
          delay
        Ref.write (Just tid) p.zoomPanValues.timerId
      Nothing -> pure unit
  where
  -- `cb` is `OnPanZoom = Maybe (Either MouseEvent TouchEvent) -> Viewport -> Effect Unit`.
  -- We pass `Nothing` for the event because we don't have a typed mouse/
  -- touch event at this layer — the d3 source event is `Foreign`.
  callOnPanZoomDirect cb _src vp = cb Nothing vp
