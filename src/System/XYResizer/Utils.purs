-- | Pure helpers used by `System.XYResizer`. Mirrors
-- | `xyflow-main/packages/system/src/xyresizer/utils.ts`.
-- |
-- | All three functions are pure. `getDimensionsAfterResize` is a 280-line
-- | constraint solver (min/max + extent + child-extent + aspect ratio); the
-- | PS port is a structural translation, with comments anchoring each
-- | section to its TS counterpart.
module System.XYResizer.Utils
  ( ControlDirection
  , ResizeStartValues
  , PointerPosition
  , getResizeDirection
  , getControlDirection
  , getDimensionsAfterResize
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Number (floor) as Number
import System.Types.Geometry (CoordinateExtent(..), NodeOrigin(..))
import System.XYResizer
  ( ControlLinePosition(..)
  , ControlPosition(..)
  , CornerPosition(..)
  , ResizeBoundaries
  , ResizeParams
  )

-- | Result of `getControlDirection` — bools for axis activity and which
-- | edges (x or y) the resize affects.
type ControlDirection =
  { isHorizontal :: Boolean
  , isVertical :: Boolean
  , affectsX :: Boolean
  , affectsY :: Boolean
  }

-- | Snapshot of the values at drag start. Mirrors TS `StartValues`.
type ResizeStartValues =
  { x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  , pointerX :: Number
  , pointerY :: Number
  , aspectRatio :: Number
  }

-- | Pointer position with snapped axes — the shape produced by
-- | `System.Utils.Dom.getPointerPosition`.
type PointerPosition =
  { x :: Number, y :: Number, xSnapped :: Number, ySnapped :: Number }

-- | TS returns `number[]` of length 2; PS uses a labelled record. Each
-- | field is in `{-1, 0, 1}` — `1` = enlarge, `-1` = shrink, `0` = no change.
getResizeDirection
  :: { width :: Number
     , prevWidth :: Number
     , height :: Number
     , prevHeight :: Number
     , affectsX :: Boolean
     , affectsY :: Boolean
     }
  -> { dx :: Int, dy :: Int }
getResizeDirection p =
  let
    deltaWidth = p.width - p.prevWidth
    deltaHeight = p.height - p.prevHeight
    base x =
      if x > 0.0 then 1
      else if x < 0.0 then -1
      else 0
    rawDx = base deltaWidth
    rawDy = base deltaHeight
    dx =
      if deltaWidth /= 0.0 && p.affectsX then rawDx * (-1)
      else rawDx
    dy =
      if deltaHeight /= 0.0 && p.affectsY then rawDy * (-1)
      else rawDy
  in
    { dx, dy }

-- | Decompose a `ControlPosition` into `(isHorizontal, isVertical,
-- | affectsX, affectsY)`. The TS version uses string `.includes`; the PS
-- | port pattern-matches the nested ADT.
getControlDirection :: ControlPosition -> ControlDirection
getControlDirection cp = case cp of
  ControlLine LineLeft ->
    { isHorizontal: true, isVertical: false, affectsX: true, affectsY: false }
  ControlLine LineRight ->
    { isHorizontal: true, isVertical: false, affectsX: false, affectsY: false }
  ControlLine LineTop ->
    { isHorizontal: false, isVertical: true, affectsX: false, affectsY: true }
  ControlLine LineBottom ->
    { isHorizontal: false, isVertical: true, affectsX: false, affectsY: false }
  ControlCorner CornerTopLeft ->
    { isHorizontal: true, isVertical: true, affectsX: true, affectsY: true }
  ControlCorner CornerTopRight ->
    { isHorizontal: true, isVertical: true, affectsX: false, affectsY: true }
  ControlCorner CornerBottomLeft ->
    { isHorizontal: true, isVertical: true, affectsX: true, affectsY: false }
  ControlCorner CornerBottomRight ->
    { isHorizontal: true, isVertical: true, affectsX: false, affectsY: false }

-- ----------------------------------------------------------------------------
-- getDimensionsAfterResize — the big one.
-- ----------------------------------------------------------------------------

-- Local helpers, names match TS exactly.
getLowerExtentClamp :: Number -> Number -> Number
getLowerExtentClamp lowerExtent lowerBound =
  max 0.0 (lowerBound - lowerExtent)

getUpperExtentClamp :: Number -> Number -> Number
getUpperExtentClamp upperExtent upperBound =
  max 0.0 (upperExtent - upperBound)

getSizeClamp :: Number -> Number -> Number -> Number
getSizeClamp size minSize maxSize =
  max 0.0 (max (minSize - size) (size - maxSize))

xor_ :: Boolean -> Boolean -> Boolean
xor_ a b = if a then not b else b

-- | The full constraint solver. The body mirrors `utils.ts:114–280`
-- | line-for-line. Section headers (`-- 1.`, `-- 2.`, …) align with the
-- | numbered comments in the TS source for easier auditing.
getDimensionsAfterResize
  :: ResizeStartValues
  -> ControlDirection
  -> PointerPosition
  -> ResizeBoundaries
  -> Boolean -- keepAspectRatio
  -> NodeOrigin
  -> Maybe CoordinateExtent
  -> Maybe CoordinateExtent
  -> ResizeParams
getDimensionsAfterResize startValues controlDirection pointerPos boundaries
  keepAspectRatio (NodeOrigin origin) extentMaybe childExtentMaybe =
  let
    affectsX0 = controlDirection.affectsX
    affectsY0 = controlDirection.affectsY
    isHorizontal = controlDirection.isHorizontal
    isVertical = controlDirection.isVertical
    isDiagonal = isHorizontal && isVertical

    xSnapped = pointerPos.xSnapped
    ySnapped = pointerPos.ySnapped

    minWidth = boundaries.minWidth
    maxWidth = boundaries.maxWidth
    minHeight = boundaries.minHeight
    maxHeight = boundaries.maxHeight

    startX = startValues.x
    startY = startValues.y
    startWidth = startValues.width
    startHeight = startValues.height
    aspectRatio = startValues.aspectRatio

    -- distX / distY: pointer delta in renderer coordinates, floored.
    distX0 = Number.floor
      (if isHorizontal then xSnapped - startValues.pointerX else 0.0)
    distY0 = Number.floor
      (if isVertical then ySnapped - startValues.pointerY else 0.0)

    newWidth = startWidth + (if affectsX0 then -distX0 else distX0)
    newHeight = startHeight + (if affectsY0 then -distY0 else distY0)

    originOffsetX = -origin.ox * startWidth
    originOffsetY = -origin.oy * startHeight

    -- 1. min/max size clamp.
    clampX0 = getSizeClamp newWidth minWidth maxWidth
    clampY0 = getSizeClamp newHeight minHeight maxHeight

    -- 2. parent-extent clamp.
    extClamp = case extentMaybe of
      Just (CoordinateExtent e) ->
        let
          xExt =
            if affectsX0 && distX0 < 0.0 then
              getLowerExtentClamp (startX + distX0 + originOffsetX) e.minX
            else if not affectsX0 && distX0 > 0.0 then
              getUpperExtentClamp (startX + newWidth + originOffsetX) e.maxX
            else 0.0
          yExt =
            if affectsY0 && distY0 < 0.0 then
              getLowerExtentClamp (startY + distY0 + originOffsetY) e.minY
            else if not affectsY0 && distY0 > 0.0 then
              getUpperExtentClamp (startY + newHeight + originOffsetY) e.maxY
            else 0.0
        in { xExt, yExt }
      Nothing ->{ xExt: 0.0, yExt: 0.0 }
    clampX1 = max clampX0 extClamp.xExt
    clampY1 = max clampY0 extClamp.yExt

    -- 3. child-extent clamp.
    childClamp = case childExtentMaybe of
      Just (CoordinateExtent e) ->
        let
          xExt =
            if affectsX0 && distX0 > 0.0 then
              getUpperExtentClamp (startX + distX0) e.minX
            else if not affectsX0 && distX0 < 0.0 then
              getLowerExtentClamp (startX + newWidth) e.maxX
            else 0.0
          yExt =
            if affectsY0 && distY0 > 0.0 then
              getUpperExtentClamp (startY + distY0) e.minY
            else if not affectsY0 && distY0 < 0.0 then
              getLowerExtentClamp (startY + newHeight) e.maxY
            else 0.0
        in { xExt, yExt }
      Nothing ->{ xExt: 0.0, yExt: 0.0 }
    clampX2 = max clampX1 childClamp.xExt
    clampY2 = max clampY1 childClamp.yExt

    -- 4. aspect-ratio clamp (horizontal half).
    aspectClampHorizontal =
      if keepAspectRatio && isHorizontal then
        let
          aspectHeightClamp =
            getSizeClamp (newWidth / aspectRatio) minHeight maxHeight
              * aspectRatio
          extClampH = case extentMaybe of
            Just (CoordinateExtent e) ->
              let
                useUpper =
                  (not affectsX0 && not affectsY0)
                    || (affectsX0 && not affectsY0 && isDiagonal)
              in
                if useUpper then
                  getUpperExtentClamp
                    (startY + originOffsetY + newWidth / aspectRatio)
                    e.maxY * aspectRatio
                else
                  getLowerExtentClamp
                    (startY + originOffsetY
                      + (if affectsX0 then distX0 else -distX0) / aspectRatio)
                    e.minY * aspectRatio
            Nothing ->0.0
          childClampH = case childExtentMaybe of
            Just (CoordinateExtent e) ->
              let
                useLower =
                  (not affectsX0 && not affectsY0)
                    || (affectsX0 && not affectsY0 && isDiagonal)
              in
                if useLower then
                  getLowerExtentClamp (startY + newWidth / aspectRatio) e.maxY
                    * aspectRatio
                else
                  getUpperExtentClamp
                    (startY
                      + (if affectsX0 then distX0 else -distX0) / aspectRatio)
                    e.minY * aspectRatio
            Nothing ->0.0
        in
          max (max aspectHeightClamp extClampH) childClampH
      else 0.0
    clampX3 = max clampX2 aspectClampHorizontal

    -- 5. aspect-ratio clamp (vertical half).
    aspectClampVertical =
      if keepAspectRatio && isVertical then
        let
          aspectWidthClamp =
            getSizeClamp (newHeight * aspectRatio) minWidth maxWidth
              / aspectRatio
          extClampV = case extentMaybe of
            Just (CoordinateExtent e) ->
              let
                useUpper =
                  (not affectsX0 && not affectsY0)
                    || (affectsY0 && not affectsX0 && isDiagonal)
              in
                if useUpper then
                  getUpperExtentClamp
                    (startX + newHeight * aspectRatio + originOffsetX)
                    e.maxX / aspectRatio
                else
                  getLowerExtentClamp
                    (startX
                      + (if affectsY0 then distY0 else -distY0) * aspectRatio
                      + originOffsetX)
                    e.minX / aspectRatio
            Nothing ->0.0
          childClampV = case childExtentMaybe of
            Just (CoordinateExtent e) ->
              let
                useLower =
                  (not affectsX0 && not affectsY0)
                    || (affectsY0 && not affectsX0 && isDiagonal)
              in
                if useLower then
                  getLowerExtentClamp
                    (startX + newHeight * aspectRatio) e.maxX / aspectRatio
                else
                  getUpperExtentClamp
                    (startX
                      + (if affectsY0 then distY0 else -distY0) * aspectRatio)
                    e.minX / aspectRatio
            Nothing ->0.0
        in max (max aspectWidthClamp extClampV) childClampV
      else 0.0
    clampY3 = max clampY2 aspectClampVertical

    -- Apply clamps to distances (TS lines 250–251).
    distY1 = distY0 + (if distY0 < 0.0 then clampY3 else -clampY3)
    distX1 = distX0 + (if distX0 < 0.0 then clampX3 else -clampX3)

    -- 6. aspect-ratio fixup (TS lines 253–269).
    -- The fixup writes back distX/distY and may flip affectsY/affectsX; we
    -- compute new values and swap-affect bools in a single pass.
    fixup =
      if keepAspectRatio then
        if isDiagonal then
          if newWidth > newHeight * aspectRatio then
            { dx: distX1
            , dy: (if xor_ affectsX0 affectsY0 then -distX1 else distX1)
                / aspectRatio
            , ax: affectsX0
            , ay: affectsY0
            }
          else
            { dx: (if xor_ affectsX0 affectsY0 then -distY1 else distY1)
                * aspectRatio
            , dy: distY1
            , ax: affectsX0
            , ay: affectsY0
            }
        else if isHorizontal then
          { dx: distX1
          , dy: distX1 / aspectRatio
          , ax: affectsX0
          , ay: affectsX0
          }
        else
          { dx: distY1 * aspectRatio
          , dy: distY1
          , ax: affectsY0
          , ay: affectsY0
          }
      else { dx: distX1, dy: distY1, ax: affectsX0, ay: affectsY0 }

    distX = fixup.dx
    distY = fixup.dy
    affectsX = fixup.ax
    affectsY = fixup.ay

    x = if affectsX then startX + distX else startX
    y = if affectsY then startY + distY else startY
  in
    { width: startWidth + (if affectsX then -distX else distX)
    , height: startHeight + (if affectsY then -distY else distY)
    , x: origin.ox * distX * (if not affectsX then 1.0 else -1.0) + x
    , y: origin.oy * distY * (if not affectsY then 1.0 else -1.0) + y
    }

