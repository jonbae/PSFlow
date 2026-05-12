-- | Pure CSS-transform string generators for node and edge toolbars.
-- | Mirrors `xyflow-main/packages/system/src/utils/{node,edge}-toolbar.ts`.
module System.Utils.Toolbar
  ( getNodeToolbarTransform
  , getEdgeToolbarTransform
  , defaultAlignX
  , defaultAlignY
  ) where

import Prelude

import Data.Number.Format (toString) as NumberFormat
import System.Types.Connection (Viewport)
import System.Types.Edge (AlignX(..), AlignY(..))
import System.Types.Geometry (Position(..), Rect)
import System.Types.Node (Align(..))

-- | Renders the same character-for-character output as `Number.toString` in
-- | JavaScript so the resulting CSS strings stay byte-identical to the TS
-- | implementation.
showN :: Number -> String
showN = NumberFormat.toString

defaultAlignX :: AlignX
defaultAlignX = AlignXCenter

defaultAlignY :: AlignY
defaultAlignY = AlignYCenter

alignToFraction :: Align -> Number
alignToFraction = case _ of
  AlignStart -> 0.0
  AlignCenter -> 0.5
  AlignEnd -> 1.0

alignXToPercent :: AlignX -> Number
alignXToPercent = case _ of
  AlignXLeft -> 0.0
  AlignXCenter -> 50.0
  AlignXRight -> 100.0

alignYToPercent :: AlignY -> Number
alignYToPercent = case _ of
  AlignYTop -> 0.0
  AlignYCenter -> 50.0
  AlignYBottom -> 100.0

getNodeToolbarTransform
  :: Rect
  -> Viewport
  -> Position
  -> Number
  -> Align
  -> String
getNodeToolbarTransform nodeRect viewport position offset align =
  "translate(" <> showN posX <> "px, " <> showN posY <> "px) "
    <> "translate("
    <> showN shiftX
    <> "%, "
    <> showN shiftY
    <> "%)"
  where
  alignmentOffset = alignToFraction align

  defaultPosX =
    (nodeRect.x + nodeRect.width * alignmentOffset) * viewport.zoom + viewport.x

  defaultPosY =
    nodeRect.y * viewport.zoom + viewport.y - offset

  defaultShiftX = -100.0 * alignmentOffset
  defaultShiftY = -100.0

  { posX, posY, shiftX, shiftY } = case position of
    PosTop ->
      { posX: defaultPosX
      , posY: defaultPosY
      , shiftX: defaultShiftX
      , shiftY: defaultShiftY
      }
    PosRight ->
      { posX:
          (nodeRect.x + nodeRect.width) * viewport.zoom + viewport.x + offset
      , posY:
          (nodeRect.y + nodeRect.height * alignmentOffset) * viewport.zoom
            + viewport.y
      , shiftX: 0.0
      , shiftY: -100.0 * alignmentOffset
      }
    PosBottom ->
      { posX: defaultPosX
      , posY:
          (nodeRect.y + nodeRect.height) * viewport.zoom + viewport.y + offset
      , shiftX: defaultShiftX
      , shiftY: 0.0
      }
    PosLeft ->
      { posX: nodeRect.x * viewport.zoom + viewport.x - offset
      , posY:
          (nodeRect.y + nodeRect.height * alignmentOffset) * viewport.zoom
            + viewport.y
      , shiftX: -100.0
      , shiftY: -100.0 * alignmentOffset
      }

getEdgeToolbarTransform
  :: Number
  -> Number
  -> Number
  -> AlignX
  -> AlignY
  -> String
getEdgeToolbarTransform x y zoom alignX alignY =
  "translate(" <> showN x <> "px, " <> showN y <> "px) "
    <> "scale("
    <> showN (1.0 / zoom)
    <> ") "
    <> "translate("
    <> showN (-(alignXToPercent alignX))
    <> "%, "
    <> showN (-(alignYToPercent alignY))
    <> "%)"
