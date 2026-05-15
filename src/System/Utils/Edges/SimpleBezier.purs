-- | Simple-bezier edge path. Mirrors
-- | `xyflow-main/packages/react/src/components/Edges/SimpleBezierEdge.tsx`
-- | (`getSimpleBezierPath`).
-- |
-- | Unlike `System.Utils.Edges.Bezier`, the control points here are not
-- | curvature-weighted — the midpoint between the two endpoints (on the
-- | axis perpendicular to the handle's position) is used directly. Yields
-- | a less expressive curve but matches the TS source exactly.
module System.Utils.Edges.SimpleBezier
  ( SimpleBezierPathParams
  , getSimpleBezierPath
  ) where

import Prelude

import Data.Number.Format (toString) as NumberFormat
import System.Types.Geometry (Position(..))
import System.Utils.Edges.Bezier (getBezierEdgeCenter)
import System.Utils.Edges.General (EdgePathResult)

type SimpleBezierPathParams =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: Position
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: Position
  }

showN :: Number -> String
showN = NumberFormat.toString

-- | TS lines 26-31: for left/right handles the control point sits on the
-- | x-axis midpoint at the source y; for top/bottom handles it sits on
-- | the y-axis midpoint at the source x.
getControl
  :: Position
  -> Number
  -> Number
  -> Number
  -> Number
  -> { x :: Number, y :: Number }
getControl pos x1 y1 x2 y2 = case pos of
  PosLeft -> { x: 0.5 * (x1 + x2), y: y1 }
  PosRight -> { x: 0.5 * (x1 + x2), y: y1 }
  _ -> { x: x1, y: 0.5 * (y1 + y2) }

getSimpleBezierPath :: SimpleBezierPathParams -> EdgePathResult
getSimpleBezierPath p =
  let
    src = getControl p.sourcePosition p.sourceX p.sourceY p.targetX p.targetY
    tgt = getControl p.targetPosition p.targetX p.targetY p.sourceX p.sourceY
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
