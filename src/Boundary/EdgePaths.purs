-- | The six edge-path helpers, as upstream publishes them: one object of
-- | parameters in, a positional array out.
-- |
-- | Half of boundary stage 5 (`tickets/082-boundary-stage-5-pure-functions.md`).
-- | Stage 4 crossed `edgeTypes`, so a JavaScript consumer can register a
-- | custom edge component, and the first line of one is upstream's
-- | `const [edgePath, labelX, labelY] = getBezierPath({ ... })`. Passed
-- | through raw, these took PureScript `Position` constructors, so the
-- | `sourcePosition` string a custom edge is handed threw a pattern-match
-- | failure, and they answered with a labelled record, so the destructuring
-- | bound `undefined`. They also wanted every parameter, where upstream
-- | defaults the positions and the shape options.
-- |
-- | Each converter reads the JavaScript object, applies upstream's defaults
-- | to what the caller left out, calls the PureScript function, and spreads
-- | its record into upstream's array. The PureScript surface is unchanged.
module Boundary.EdgePaths
  ( JsEdgePoints
  , JsBezierEdgeCenterParams
  , JsBezierPathParams
  , JsSimpleBezierPathParams
  , JsSmoothStepPathParams
  , getBezierEdgeCenter
  , getBezierPath
  , getEdgeCenter
  , getSimpleBezierPath
  , getSmoothStepPath
  , getStraightPath
  ) where

import Prelude

import Boundary.Enums (positionIn)
import Boundary.Undefined (Undefinable, fromUndefinable)
import Data.Maybe (fromMaybe, maybe)
import Foreign (Foreign, unsafeToForeign)
import System.Types.Geometry (Position(..))
import System.Utils.Edges.Bezier as Bezier
import System.Utils.Edges.General (EdgeCenter, EdgePathResult)
import System.Utils.Edges.General as General
import System.Utils.Edges.SimpleBezier as SimpleBezier
import System.Utils.Edges.SmoothStep as SmoothStep
import System.Utils.Edges.Straight as Straight

-- | TS `{ sourceX, sourceY, targetX, targetY }`.
type JsEdgePoints =
  { sourceX :: Number
  , sourceY :: Number
  , targetX :: Number
  , targetY :: Number
  }

type JsBezierEdgeCenterParams =
  { sourceX :: Number
  , sourceY :: Number
  , targetX :: Number
  , targetY :: Number
  , sourceControlX :: Number
  , sourceControlY :: Number
  , targetControlX :: Number
  , targetControlY :: Number
  }

-- | TS `GetBezierPathParams`.
type JsBezierPathParams =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: Undefinable String
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: Undefinable String
  , curvature :: Undefinable Number
  }

-- | TS `GetSimpleBezierPathParams`.
type JsSimpleBezierPathParams =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: Undefinable String
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: Undefinable String
  }

-- | TS `GetSmoothStepPathParams`.
type JsSmoothStepPathParams =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: Undefinable String
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: Undefinable String
  , borderRadius :: Undefinable Number
  , centerX :: Undefinable Number
  , centerY :: Undefinable Number
  , offset :: Undefinable Number
  , stepPosition :: Undefinable Number
  }

-- | `[path, labelX, labelY, offsetX, offsetY]`.
pathTuple :: EdgePathResult -> Array Foreign
pathTuple r =
  [ unsafeToForeign r.path
  , unsafeToForeign r.labelX
  , unsafeToForeign r.labelY
  , unsafeToForeign r.offsetX
  , unsafeToForeign r.offsetY
  ]

-- | `[centerX, centerY, offsetX, offsetY]`.
centerTuple :: EdgeCenter -> Array Number
centerTuple c = [ c.centerX, c.centerY, c.offsetX, c.offsetY ]

-- | A destructuring default: `sourcePosition = Position.Bottom`.
positionOr :: String -> Position -> Undefinable String -> Position
positionOr field fallback = maybe fallback (positionIn field) <<< fromUndefinable

numberOr :: Number -> Undefinable Number -> Number
numberOr fallback = fromMaybe fallback <<< fromUndefinable

points :: forall r. { sourceX :: Number, sourceY :: Number, targetX :: Number, targetY :: Number | r } -> JsEdgePoints
points p = { sourceX: p.sourceX, sourceY: p.sourceY, targetX: p.targetX, targetY: p.targetY }

getBezierEdgeCenter :: JsBezierEdgeCenterParams -> Array Number
getBezierEdgeCenter p =
  centerTuple $ Bezier.getBezierEdgeCenter
    { sourceX: p.sourceX
    , sourceY: p.sourceY
    , targetX: p.targetX
    , targetY: p.targetY
    , sourceControlX: p.sourceControlX
    , sourceControlY: p.sourceControlY
    , targetControlX: p.targetControlX
    , targetControlY: p.targetControlY
    }

getBezierPath :: JsBezierPathParams -> Array Foreign
getBezierPath p =
  pathTuple $ Bezier.getBezierPath
    { sourceX: p.sourceX
    , sourceY: p.sourceY
    , sourcePosition: positionOr "sourcePosition" PosBottom p.sourcePosition
    , targetX: p.targetX
    , targetY: p.targetY
    , targetPosition: positionOr "targetPosition" PosTop p.targetPosition
    , curvature: numberOr 0.25 p.curvature
    }

getEdgeCenter :: JsEdgePoints -> Array Number
getEdgeCenter p = centerTuple (General.getEdgeCenter (points p))

getSimpleBezierPath :: JsSimpleBezierPathParams -> Array Foreign
getSimpleBezierPath p =
  pathTuple $ SimpleBezier.getSimpleBezierPath
    { sourceX: p.sourceX
    , sourceY: p.sourceY
    , sourcePosition: positionOr "sourcePosition" PosBottom p.sourcePosition
    , targetX: p.targetX
    , targetY: p.targetY
    , targetPosition: positionOr "targetPosition" PosTop p.targetPosition
    }

getSmoothStepPath :: JsSmoothStepPathParams -> Array Foreign
getSmoothStepPath p =
  pathTuple $ SmoothStep.getSmoothStepPath
    { sourceX: p.sourceX
    , sourceY: p.sourceY
    , sourcePosition: positionOr "sourcePosition" PosBottom p.sourcePosition
    , targetX: p.targetX
    , targetY: p.targetY
    , targetPosition: positionOr "targetPosition" PosTop p.targetPosition
    , borderRadius: numberOr 5.0 p.borderRadius
    , centerX: fromUndefinable p.centerX
    , centerY: fromUndefinable p.centerY
    , offset: numberOr 20.0 p.offset
    , stepPosition: numberOr 0.5 p.stepPosition
    }

getStraightPath :: JsEdgePoints -> Array Foreign
getStraightPath p = pathTuple (Straight.getStraightPath (points p))
