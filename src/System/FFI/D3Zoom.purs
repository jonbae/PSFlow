-- | Thin FFI wrapper around `d3-zoom` and `d3-interpolate`. Used by
-- | `XYFlow.XYPanZoom` and `XYFlow.XYMinimap`. Functions are exposed as
-- | one-shot `Effect` actions; callers chain them in `do`-blocks.
module System.FFI.D3Zoom
  ( ZoomTransform(..)
  , D3ZoomBehavior
  , D3ZoomEvent
  , D3Interpolate
  , zoomTransformX
  , zoomTransformY
  , zoomTransformK
  , zoomIdentity
  , zoomTranslate
  , zoomScale
  , zoomCreate
  , setScaleExtent
  , setTranslateExtent
  , setWheelDelta
  , setClickDistance
  , setZoomOn
  , setZoomFilter
  , setInterpolate
  , zoomBehaviorTransform
  , zoomBehaviorScaleTo
  , zoomBehaviorScaleBy
  , zoomBehaviorTranslateBy
  , zoomBehaviorConstrain
  , currentZoomTransform
  , selectionGetZoomProperty
  , selectionSetWheelHandler
  , selectionGetZoomHandler
  , selectionCallZoom
  , selectionSetDblClickHandler
  , selectionSetDblClickNull
  , linearInterpolate
  , smoothZoomInterpolate
  , zoomEventTransform
  , zoomEventSourceEvent
  ) where

import Prelude

import Effect (Effect)
import Foreign (Foreign)
import System.FFI.D3Selection (D3Selection)

-- | Opaque `d3.ZoomTransform` value carrying `(x, y, k)` triples. Existing
-- | dependents (`XYFlow.Types.PanZoom`) re-export the constructor from this
-- | module, so we keep the newtype shape stable.
newtype ZoomTransform = ZoomTransform Foreign

foreign import data D3ZoomBehavior :: Type
foreign import data D3ZoomEvent :: Type
foreign import data D3Interpolate :: Type

-- | Component accessors on `ZoomTransform`. Pure: `d3.ZoomTransform` is an
-- | immutable triple of `(x, y, k)`. The PS phantom around `Foreign` is
-- | discarded by the JS accessors.
foreign import zoomTransformX :: ZoomTransform -> Number
foreign import zoomTransformY :: ZoomTransform -> Number
foreign import zoomTransformK :: ZoomTransform -> Number

-- | `d3.zoomIdentity` — the (0, 0, 1) zoom transform, used as the seed for
-- | translate/scale chains.
foreign import zoomIdentity :: ZoomTransform

-- | `transform.translate(x, y)`. Pure because `d3.ZoomTransform` is
-- | immutable.
foreign import zoomTranslate :: ZoomTransform -> Number -> Number -> ZoomTransform

-- | `transform.scale(k)`. Pure.
foreign import zoomScale :: ZoomTransform -> Number -> ZoomTransform

-- | `d3.zoom()` — fresh zoom behavior.
foreign import zoomCreate :: Effect D3ZoomBehavior

-- | `behavior.scaleExtent([min, max])`.
foreign import setScaleExtent
  :: Number -> Number -> D3ZoomBehavior -> Effect D3ZoomBehavior

-- | `behavior.translateExtent([[minX, minY], [maxX, maxY]])`.
foreign import setTranslateExtent
  :: Number
  -> Number
  -> Number
  -> Number
  -> D3ZoomBehavior
  -> Effect D3ZoomBehavior

-- | `behavior.wheelDelta(fn)` — install a wheel-event delta calculator.
foreign import setWheelDelta
  :: (Foreign -> Effect Number) -> D3ZoomBehavior -> Effect D3ZoomBehavior

-- | `behavior.clickDistance(n)`.
foreign import setClickDistance
  :: Number -> D3ZoomBehavior -> Effect D3ZoomBehavior

-- | `behavior.on(typename, handler)` — `start`, `zoom`, `end`. Passing the
-- | empty handler tear-down is achieved by the JS side using `null`.
foreign import setZoomOn
  :: String
  -> (D3ZoomEvent -> Effect Unit)
  -> D3ZoomBehavior
  -> Effect D3ZoomBehavior

-- | `behavior.filter(predicate)`.
foreign import setZoomFilter
  :: (Foreign -> Effect Boolean)
  -> D3ZoomBehavior
  -> Effect D3ZoomBehavior

-- | `behavior.interpolate(fn)`. The `D3Interpolate` value is one of the two
-- | exported sentinels (`linearInterpolate` or `smoothZoomInterpolate`).
foreign import setInterpolate
  :: D3Interpolate -> D3ZoomBehavior -> Effect D3ZoomBehavior

-- | `behavior.transform(selection, transform)` — programmatic transform set.
foreign import zoomBehaviorTransform
  :: D3ZoomBehavior -> D3Selection -> ZoomTransform -> Effect Unit

foreign import zoomBehaviorScaleTo
  :: D3ZoomBehavior -> D3Selection -> Number -> Effect Unit

foreign import zoomBehaviorScaleBy
  :: D3ZoomBehavior -> D3Selection -> Number -> Effect Unit

foreign import zoomBehaviorTranslateBy
  :: D3ZoomBehavior -> D3Selection -> Number -> Number -> Effect Unit

-- | `behavior.constrain()(transform, [[x1,y1],[x2,y2]], [[mx1,my1],[mx2,my2]])`.
-- | The two extents are the visible bbox and the translate extent.
foreign import zoomBehaviorConstrain
  :: D3ZoomBehavior
  -> ZoomTransform
  -> Number -> Number -> Number -> Number
  -> Number -> Number -> Number -> Number
  -> ZoomTransform

-- | `d3.zoomTransform(domNode)` — read the current transform off a node.
foreign import currentZoomTransform :: forall a. a -> Effect ZoomTransform

-- | `selection.property('__zoom')` — read the live zoom transform off a
-- | selection without going through `d3.zoomTransform`.
foreign import selectionGetZoomProperty :: D3Selection -> Effect ZoomTransform

-- | `selection.on('wheel.zoom', handler, { passive: false })`.
foreign import selectionSetWheelHandler
  :: D3Selection -> (Foreign -> Effect Unit) -> Effect Unit

-- | `selection.on(typename)` — read the currently bound handler. Returns a
-- | callable JS function — opaque on the PS side.
foreign import selectionGetZoomHandler
  :: D3Selection -> String -> Effect (Foreign -> Effect Unit)

-- | `selection.call(behavior)` — install the zoom behavior on a selection.
foreign import selectionCallZoom :: D3Selection -> D3ZoomBehavior -> Effect Unit

-- | `selection.on('dblclick.zoom', handler)` / `selection.on('dblclick.zoom', null)`.
foreign import selectionSetDblClickHandler
  :: D3Selection -> (Foreign -> Effect Unit) -> Effect Unit

foreign import selectionSetDblClickNull :: D3Selection -> Effect Unit

-- | `d3.interpolate` — straight-line interpolator. Sentinel value the JS
-- | layer hands back unchanged.
foreign import linearInterpolate :: D3Interpolate

-- | `d3.interpolateZoom` — semantic-zoom interpolator from
-- | "Smooth and efficient zooming and panning" (van Wijk & Nuij, 2003).
foreign import smoothZoomInterpolate :: D3Interpolate

-- | `event.transform` accessor.
foreign import zoomEventTransform :: D3ZoomEvent -> ZoomTransform

-- | `event.sourceEvent` accessor — the underlying mouse/wheel/touch event,
-- | or `undefined` for synthetic events. Returns `Foreign` because the
-- | concrete event type varies.
foreign import zoomEventSourceEvent :: D3ZoomEvent -> Foreign
