-- | Pure helpers used by `System.XYPanZoom`. Mirrors
-- | `xyflow-main/packages/system/src/xypanzoom/utils.ts`.
-- |
-- | `transformToViewport` and `viewportToTransform` are pure conversions
-- | between d3's `ZoomTransform` and our `Viewport`. `isRightClickPan` is a
-- | total Boolean check. `isWrappedWithClass` and `wheelDelta` touch the DOM
-- | and are `Effect`-typed.
module System.XYPanZoom.Utils
  ( transformToViewport
  , viewportToTransform
  , isRightClickPan
  , isWrappedWithClass
  , wheelDelta
  , defaultEase
  ) where

import Prelude

import Data.Array (elem) as Array
import Effect (Effect)
import Foreign (Foreign)
import System.FFI.D3Zoom
  ( ZoomTransform
  , zoomIdentity
  , zoomScale
  , zoomTransformK
  , zoomTransformX
  , zoomTransformY
  , zoomTranslate
  )
import System.Types.Connection (Viewport)
import System.Types.PanZoom (PanOnDrag(..))
import System.Utils.General (isMacOs)

-- | Project a d3 `ZoomTransform` into a `Viewport`. Pure: the `Foreign`
-- | wrapper is read-only at this layer.
transformToViewport :: ZoomTransform -> Viewport
transformToViewport t =
  { x: zoomTransformX t
  , y: zoomTransformY t
  , zoom: zoomTransformK t
  }

-- | Build a `ZoomTransform` from a `Viewport` via `zoomIdentity.translate.scale`.
-- | Pure (modulo d3's immutable `ZoomTransform`).
viewportToTransform :: Viewport -> ZoomTransform
viewportToTransform v = zoomScale (zoomTranslate zoomIdentity v.x v.y) v.zoom

-- | TS: `usedButton === 2 && Array.isArray(panOnDrag) && panOnDrag.includes(2)`.
-- | The PS `PanOnDrag` ADT collapses the array case to `PanOnButtons buttons`;
-- | only `PanOnButtons` containing `2` qualifies.
isRightClickPan :: PanOnDrag -> Int -> Boolean
isRightClickPan panOnDrag usedButton =
  usedButton == 2 && case panOnDrag of
    PanOnButtons buttons -> Array.elem 2 (asArray buttons)
    _ -> false
  where
  -- Promote NonEmptyArray to Array for `elem`. Avoid pulling
  -- `Data.Array.NonEmpty` into the import set; coerce via `foldr`.
  asArray = foreignToArray

foreign import foreignToArray :: forall a. a -> Array Int

-- | TS: `event.target.closest('.<className>')` — climbs the DOM looking for
-- | an ancestor whose class list contains `className`. PS treats it as
-- | `Effect Boolean`.
foreign import isWrappedWithClassImpl :: Foreign -> String -> Effect Boolean

isWrappedWithClass :: Foreign -> String -> Effect Boolean
isWrappedWithClass = isWrappedWithClassImpl

-- | TS: `wheelDelta(event)` — converts a wheel/scroll event into a normalised
-- | pinch/zoom delta. The factor of 10 on macOS pinch is preserved.
wheelDelta :: Foreign -> Effect Number
wheelDelta event = do
  ctrlKey <- foreignCtrlKey event
  mac <- isMacOs
  let factor = if ctrlKey && mac then 10.0 else 1.0
  delta <- foreignDeltaY event
  mode <- foreignDeltaMode event
  let
    mult
      | mode == 1 = 0.05
      | mode /= 0 = 1.0
      | otherwise = 0.002
  pure ((-delta) * mult * factor)

-- | Default cubic ease — taken verbatim from d3-ease.
defaultEase :: Number -> Number
defaultEase t0 =
  let
    t = t0 * 2.0
  in
    if t <= 1.0 then t * t * t / 2.0
    else
      let t' = t - 2.0
      in (t' * t' * t' + 2.0) / 2.0

foreign import foreignCtrlKey :: Foreign -> Effect Boolean
foreign import foreignDeltaY :: Foreign -> Effect Number
foreign import foreignDeltaMode :: Foreign -> Effect Int
