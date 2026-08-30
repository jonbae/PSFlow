-- | Straight-line edge path. Mirrors `straight-edge.ts`.
module System.Utils.Edges.Straight
  ( StraightPathParams
  , GetStraightPathParams
  , getStraightPath
  ) where

import Prelude

import Data.Number.Format (toString) as NumberFormat
import System.Utils.Edges.General (EdgePathResult, getEdgeCenter)

type StraightPathParams =
  { sourceX :: Number
  , sourceY :: Number
  , targetX :: Number
  , targetY :: Number
  }

-- | TS-name alias for `StraightPathParams` — see `GetBezierPathParams`.
type GetStraightPathParams = StraightPathParams

showN :: Number -> String
showN = NumberFormat.toString

getStraightPath :: StraightPathParams -> EdgePathResult
getStraightPath p =
  let
    c = getEdgeCenter
      { sourceX: p.sourceX
      , sourceY: p.sourceY
      , targetX: p.targetX
      , targetY: p.targetY
      }
    path =
      "M " <> showN p.sourceX <> "," <> showN p.sourceY
        <> "L "
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
