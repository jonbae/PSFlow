-- | Exact numeric parity at the exported geometry/resize helper seams.
-- | The specimen is the pinned vendored source, not a reimplementation.
module Test.System.Utils.NumericParity (runNumericParityTests) where

import Prelude

import Boundary.Undefined (Undefinable, fromUndefinable)
import Data.Function.Uncurried (Fn1, Fn2, Fn3, mkFn1, mkFn2, mkFn3)
import Effect (Effect)
import Effect.Uncurried (EffectFn1, runEffectFn1)
import System.Types.Connection (Padding(..), PaddingValue(..), Viewport)
import System.Utils.General as General
import System.Types.Geometry (Box, CoordinateExtent(..), NodeOrigin(..), Rect, XYPosition)
import System.XYResizer.Types (ResizeBoundaries, ResizeParams)
import System.XYResizer.Utils (ControlDirection, PointerPosition, ResizeStartValues, getDimensionsAfterResize)

foreign import checkClamp :: EffectFn1 (Fn3 Number Number Number Number) Unit
foreign import checkBounds :: EffectFn1 (Fn2 Box Box Box) Unit
foreign import checkResize :: EffectFn1 (Fn1 ResizeInput ResizeParams) Unit
foreign import checkGeometry
  :: EffectFn1
       { rectangles :: Fn2 Rect Rect Rect
       , overlap :: Fn2 Rect Rect Number
       , position :: Fn3 XYPosition Extent Dimensions XYPosition
       , viewport :: Fn1 ViewportInput Viewport
       }
       Unit

type Extent = { minX :: Number, minY :: Number, maxX :: Number, maxY :: Number }
type Dimensions = { width :: Undefinable Number, height :: Undefinable Number }
type ViewportInput =
  { bounds :: Rect, width :: Number, height :: Number
  , minZoom :: Number, maxZoom :: Number, padding :: Number
  }
type ResizeInput =
  { start :: ResizeStartValues, direction :: ControlDirection, pointer :: PointerPosition
  , boundaries :: ResizeBoundaries, keepAspectRatio :: Boolean
  , origin :: { ox :: Number, oy :: Number }
  , extent :: Undefinable Extent, childExtent :: Undefinable Extent
  }

runNumericParityTests :: Effect Unit
runNumericParityTests = do
  runEffectFn1 checkClamp (mkFn3 General.clamp)
  runEffectFn1 checkBounds (mkFn2 General.getBoundsOfBoxes)
  runEffectFn1 checkGeometry
    { rectangles: mkFn2 General.getBoundsOfRects
    , overlap: mkFn2 General.getOverlappingArea
    , position: mkFn3 \position extent dimensions ->
        General.clampPosition position (CoordinateExtent extent)
          { width: fromUndefinable dimensions.width, height: fromUndefinable dimensions.height }
    , viewport: mkFn1 \p -> General.getViewportForBounds p.bounds p.width p.height
        p.minZoom p.maxZoom (UniformPadding (RatioPadding p.padding))
    }
  runEffectFn1 checkResize (mkFn1 \p -> getDimensionsAfterResize p.start p.direction p.pointer
    p.boundaries p.keepAspectRatio (NodeOrigin p.origin)
    (map CoordinateExtent (fromUndefinable p.extent))
    (map CoordinateExtent (fromUndefinable p.childExtent)))
