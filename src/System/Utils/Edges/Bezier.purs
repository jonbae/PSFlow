-- | Cubic-bezier edge path. Mirrors `bezier-edge.ts`.
module System.Utils.Edges.Bezier
  ( BezierPathParams
  , GetBezierPathParams
  , BezierControlPoints
  , getBezierEdgeCenter
  , getBezierPath
  ) where

import Prelude

import Data.Number (abs, sqrt) as Number
import Data.Number.Format (toString) as NumberFormat
import System.Types.Geometry (Position(..))
import System.Utils.Edges.General (EdgeCenter, EdgePathResult)

type BezierPathParams =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: Position
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: Position
  , curvature :: Number
  }

-- | TS-name alias for `BezierPathParams`. Upstream names the argument
-- | record after the function that takes it (`GetBezierPathParams`); PS
-- | drops the `Get` prefix. Both names are on the surface so the upstream
-- | one resolves and the PS one stays the idiomatic spelling.
type GetBezierPathParams = BezierPathParams

type BezierControlPoints =
  { sourceX :: Number
  , sourceY :: Number
  , targetX :: Number
  , targetY :: Number
  , sourceControlX :: Number
  , sourceControlY :: Number
  , targetControlX :: Number
  , targetControlY :: Number
  }

showN :: Number -> String
showN = NumberFormat.toString

getBezierEdgeCenter :: BezierControlPoints -> EdgeCenter
getBezierEdgeCenter p =
  let
    centerX =
      p.sourceX * 0.125
        + p.sourceControlX * 0.375
        + p.targetControlX * 0.375
        + p.targetX * 0.125
    centerY =
      p.sourceY * 0.125
        + p.sourceControlY * 0.375
        + p.targetControlY * 0.375
        + p.targetY * 0.125
  in
    { centerX
    , centerY
    , offsetX: Number.abs (centerX - p.sourceX)
    , offsetY: Number.abs (centerY - p.sourceY)
    }

calculateControlOffset :: Number -> Number -> Number
calculateControlOffset distance curvature
  | distance >= 0.0 = 0.5 * distance
  | otherwise = curvature * 25.0 * Number.sqrt (-distance)

getControlWithCurvature
  :: Position
  -> Number
  -> Number
  -> Number
  -> Number
  -> Number
  -> { x :: Number, y :: Number }
getControlWithCurvature pos x1 y1 x2 y2 c = case pos of
  PosLeft -> { x: x1 - calculateControlOffset (x1 - x2) c, y: y1 }
  PosRight -> { x: x1 + calculateControlOffset (x2 - x1) c, y: y1 }
  PosTop -> { x: x1, y: y1 - calculateControlOffset (y1 - y2) c }
  PosBottom -> { x: x1, y: y1 + calculateControlOffset (y2 - y1) c }

getBezierPath :: BezierPathParams -> EdgePathResult
getBezierPath p =
  let
    src = getControlWithCurvature
      p.sourcePosition
      p.sourceX
      p.sourceY
      p.targetX
      p.targetY
      p.curvature
    tgt = getControlWithCurvature
      p.targetPosition
      p.targetX
      p.targetY
      p.sourceX
      p.sourceY
      p.curvature
    c = getBezierEdgeCenter
      { sourceX: p.sourceX
      , sourceY: p.sourceY
      , targetX: p.targetX
      , targetY: p.targetY
      , sourceControlX: src.x
      , sourceControlY: src.y
      , targetControlX: tgt.x
      , targetControlY: tgt.y
      }
    path =
      "M" <> showN p.sourceX <> "," <> showN p.sourceY
        <> " C"
        <> showN src.x
        <> ","
        <> showN src.y
        <> " "
        <> showN tgt.x
        <> ","
        <> showN tgt.y
        <> " "
        <> showN p.targetX
        <> ","
        <> showN p.targetY
  in
    { path
    , labelX: c.centerX
    , labelY: c.centerY
    , offsetX: c.offsetX
    , offsetY: c.offsetY
    }
