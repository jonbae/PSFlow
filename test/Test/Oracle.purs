-- | The single XYFlow-coupled module in the test suite. Wraps the FFI in
-- | `Test.Oracle.js` (which imports the `@psflow/oracle` bundle) behind
-- | PureScript signatures that mirror the PSFlow functions under parity test,
-- | so a property can write `PS.getBezierPath p` and `Oracle.getBezierPath p`
-- | over the *same* input value.
-- |
-- | The only XYFlow-shape knowledge expressible in PureScript lives here: the
-- | `posStr` translation of the `Position` sum type into XYFlow's lowercase
-- | string, and the newtype→plain-array translations (`Transform`,
-- | `SnapGrid`, `CoordinateExtent`). These are stable; an upstream change to
-- | the math touches the bundle, not this file.
module Test.Oracle
  ( getEdgeCenter
  , getBezierEdgeCenter
  , getStraightPath
  , getBezierPath
  , getSimpleBezierPath
  , getSmoothStepPath
  , clamp
  , getBoundsOfBoxes
  , rectToBox
  , boxToRect
  , getBoundsOfRects
  , getOverlappingArea
  , snapPosition
  , clampPosition
  , pointToRendererPoint
  , rendererPointToPoint
  ) where

import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable, toNullable)
import System.Types.Geometry
  ( Box
  , CoordinateExtent(..)
  , Position(..)
  , Rect
  , SnapGrid(..)
  , Transform(..)
  , XYPosition
  )
import System.Utils.Edges.Bezier (BezierControlPoints, BezierPathParams)
import System.Utils.Edges.General (EdgeCenter, EdgePathResult)
import System.Utils.Edges.SimpleBezier (SimpleBezierPathParams)
import System.Utils.Edges.SmoothStep (SmoothStepPathParams)
import System.Utils.Edges.Straight (StraightPathParams)

-- | `Position` → XYFlow's lowercase string. The only XYFlow enum knowledge in
-- | PureScript; matches `enum Position { Left = 'left', … }` upstream.
posStr :: Position -> String
posStr = case _ of
  PosLeft -> "left"
  PosTop -> "top"
  PosRight -> "right"
  PosBottom -> "bottom"

-- ─── Edge centers ─────────────────────────────────────────────────────────

type EdgeCenterArgs =
  { sourceX :: Number, sourceY :: Number, targetX :: Number, targetY :: Number }

foreign import getEdgeCenterImpl :: EdgeCenterArgs -> EdgeCenter

getEdgeCenter :: EdgeCenterArgs -> EdgeCenter
getEdgeCenter = getEdgeCenterImpl

foreign import getBezierEdgeCenterImpl :: BezierControlPoints -> EdgeCenter

getBezierEdgeCenter :: BezierControlPoints -> EdgeCenter
getBezierEdgeCenter = getBezierEdgeCenterImpl

-- ─── Edge paths ───────────────────────────────────────────────────────────

foreign import getStraightPathImpl :: StraightPathParams -> EdgePathResult

getStraightPath :: StraightPathParams -> EdgePathResult
getStraightPath = getStraightPathImpl

type BezierArgs =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: String
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: String
  , curvature :: Number
  }

foreign import getBezierPathImpl :: BezierArgs -> EdgePathResult

getBezierPath :: BezierPathParams -> EdgePathResult
getBezierPath p = getBezierPathImpl
  { sourceX: p.sourceX
  , sourceY: p.sourceY
  , sourcePosition: posStr p.sourcePosition
  , targetX: p.targetX
  , targetY: p.targetY
  , targetPosition: posStr p.targetPosition
  , curvature: p.curvature
  }

type SimpleBezierArgs =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: String
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: String
  }

foreign import getSimpleBezierPathImpl :: SimpleBezierArgs -> EdgePathResult

getSimpleBezierPath :: SimpleBezierPathParams -> EdgePathResult
getSimpleBezierPath p = getSimpleBezierPathImpl
  { sourceX: p.sourceX
  , sourceY: p.sourceY
  , sourcePosition: posStr p.sourcePosition
  , targetX: p.targetX
  , targetY: p.targetY
  , targetPosition: posStr p.targetPosition
  }

type SmoothStepArgs =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: String
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: String
  , borderRadius :: Number
  , centerX :: Nullable Number
  , centerY :: Nullable Number
  , offset :: Number
  , stepPosition :: Number
  }

foreign import getSmoothStepPathImpl :: SmoothStepArgs -> EdgePathResult

getSmoothStepPath :: SmoothStepPathParams -> EdgePathResult
getSmoothStepPath p = getSmoothStepPathImpl
  { sourceX: p.sourceX
  , sourceY: p.sourceY
  , sourcePosition: posStr p.sourcePosition
  , targetX: p.targetX
  , targetY: p.targetY
  , targetPosition: posStr p.targetPosition
  , borderRadius: p.borderRadius
  , centerX: toNullable p.centerX
  , centerY: toNullable p.centerY
  , offset: p.offset
  , stepPosition: p.stepPosition
  }

-- ─── Geometry ─────────────────────────────────────────────────────────────

foreign import clampImpl :: Number -> Number -> Number -> Number

clamp :: Number -> Number -> Number -> Number
clamp = clampImpl

foreign import getBoundsOfBoxesImpl :: Box -> Box -> Box

getBoundsOfBoxes :: Box -> Box -> Box
getBoundsOfBoxes = getBoundsOfBoxesImpl

foreign import rectToBoxImpl :: Rect -> Box

rectToBox :: Rect -> Box
rectToBox = rectToBoxImpl

foreign import boxToRectImpl :: Box -> Rect

boxToRect :: Box -> Rect
boxToRect = boxToRectImpl

foreign import getBoundsOfRectsImpl :: Rect -> Rect -> Rect

getBoundsOfRects :: Rect -> Rect -> Rect
getBoundsOfRects = getBoundsOfRectsImpl

foreign import getOverlappingAreaImpl :: Rect -> Rect -> Number

getOverlappingArea :: Rect -> Rect -> Number
getOverlappingArea = getOverlappingAreaImpl

foreign import snapPositionImpl :: XYPosition -> Array Number -> XYPosition

snapPosition :: XYPosition -> SnapGrid -> XYPosition
snapPosition pos (SnapGrid g) = snapPositionImpl pos [ g.gx, g.gy ]

type DimsArg = { width :: Nullable Number, height :: Nullable Number }

foreign import clampPositionImpl
  :: XYPosition -> Array (Array Number) -> DimsArg -> XYPosition

clampPosition
  :: XYPosition
  -> CoordinateExtent
  -> { width :: Maybe Number, height :: Maybe Number }
  -> XYPosition
clampPosition pos (CoordinateExtent e) dims = clampPositionImpl pos
  [ [ e.minX, e.minY ], [ e.maxX, e.maxY ] ]
  { width: toNullable dims.width, height: toNullable dims.height }

foreign import pointToRendererPointImpl
  :: XYPosition -> Array Number -> Boolean -> Array Number -> XYPosition

pointToRendererPoint :: XYPosition -> Transform -> Maybe SnapGrid -> XYPosition
pointToRendererPoint p (Transform t) mGrid = case mGrid of
  Nothing -> pointToRendererPointImpl p [ t.tx, t.ty, t.scale ] false [ 1.0, 1.0 ]
  Just (SnapGrid g) ->
    pointToRendererPointImpl p [ t.tx, t.ty, t.scale ] true [ g.gx, g.gy ]

foreign import rendererPointToPointImpl :: XYPosition -> Array Number -> XYPosition

rendererPointToPoint :: XYPosition -> Transform -> XYPosition
rendererPointToPoint p (Transform t) = rendererPointToPointImpl p [ t.tx, t.ty, t.scale ]
