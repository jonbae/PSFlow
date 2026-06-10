-- | Live differential parity for the edge-path functions — the highest-value
-- | parity layer, because the SVG `d` string is the clearest shared artifact
-- | between PSFlow and XYFlow. Each property generates a random parameter
-- | record, runs the PSFlow function and the corresponding `Oracle.*`
-- | (live XYFlow) function over the *same* input, and asserts the results
-- | agree (path tokenized + numeric within epsilon; labels/offsets within
-- | epsilon). Fresh random inputs every run — true live property-based
-- | testing.
module Test.Parity.Edges
  ( runEdgeParity
  ) where

import Prelude

import Data.Array.NonEmpty as NEA
import Data.Int (toNumber) as Int
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import System.Utils.Edges.Bezier (BezierControlPoints, BezierPathParams)
import System.Utils.Edges.Bezier (getBezierEdgeCenter, getBezierPath) as PS
import System.Utils.Edges.General (getEdgeCenter) as PS
import System.Utils.Edges.SimpleBezier (SimpleBezierPathParams)
import System.Utils.Edges.SimpleBezier (getSimpleBezierPath) as PS
import System.Utils.Edges.SmoothStep (SmoothStepPathParams)
import System.Utils.Edges.SmoothStep (getSmoothStepPath) as PS
import System.Utils.Edges.Straight (StraightPathParams)
import System.Utils.Edges.Straight (getStraightPath) as PS
import Test.Oracle as Oracle
import Test.Parity.Util (edgeCenterMatch, edgeResultsMatch)
import Test.Properties (genFiniteNumber, genPosition)
import Test.QuickCheck (quickCheck)
import Test.QuickCheck.Gen (Gen, chooseInt, elements)

-- | Curvature in [0, 1] (XYFlow's default is 0.25). Stays integer-derived so
-- | both sides feed identical doubles into the `sqrt` branch.
genCurvature :: Gen Number
genCurvature = (\n -> Int.toNumber n / 100.0) <$> chooseInt 0 100

genStraightParams :: Gen StraightPathParams
genStraightParams = do
  sourceX <- genFiniteNumber
  sourceY <- genFiniteNumber
  targetX <- genFiniteNumber
  targetY <- genFiniteNumber
  pure { sourceX, sourceY, targetX, targetY }

genEdgeCenterArgs
  :: Gen { sourceX :: Number, sourceY :: Number, targetX :: Number, targetY :: Number }
genEdgeCenterArgs = genStraightParams

genBezierControlPoints :: Gen BezierControlPoints
genBezierControlPoints = do
  sourceX <- genFiniteNumber
  sourceY <- genFiniteNumber
  targetX <- genFiniteNumber
  targetY <- genFiniteNumber
  sourceControlX <- genFiniteNumber
  sourceControlY <- genFiniteNumber
  targetControlX <- genFiniteNumber
  targetControlY <- genFiniteNumber
  pure
    { sourceX, sourceY, targetX, targetY
    , sourceControlX, sourceControlY, targetControlX, targetControlY
    }

genBezierParams :: Gen BezierPathParams
genBezierParams = do
  sourceX <- genFiniteNumber
  sourceY <- genFiniteNumber
  sourcePosition <- genPosition
  targetX <- genFiniteNumber
  targetY <- genFiniteNumber
  targetPosition <- genPosition
  curvature <- genCurvature
  pure { sourceX, sourceY, sourcePosition, targetX, targetY, targetPosition, curvature }

genSimpleBezierParams :: Gen SimpleBezierPathParams
genSimpleBezierParams = do
  sourceX <- genFiniteNumber
  sourceY <- genFiniteNumber
  sourcePosition <- genPosition
  targetX <- genFiniteNumber
  targetY <- genFiniteNumber
  targetPosition <- genPosition
  pure { sourceX, sourceY, sourcePosition, targetX, targetY, targetPosition }

genNonNegSmall :: Int -> Gen Number
genNonNegSmall hi = Int.toNumber <$> chooseInt 0 hi

genMaybeCoord :: Gen (Maybe Number)
genMaybeCoord = do
  present <- elements (NEA.cons' false [ true ])
  if present then Just <$> genFiniteNumber else pure Nothing

genSmoothStepParams :: Gen SmoothStepPathParams
genSmoothStepParams = do
  sourceX <- genFiniteNumber
  sourceY <- genFiniteNumber
  sourcePosition <- genPosition
  targetX <- genFiniteNumber
  targetY <- genFiniteNumber
  targetPosition <- genPosition
  borderRadius <- genNonNegSmall 20
  centerX <- genMaybeCoord
  centerY <- genMaybeCoord
  offset <- genNonNegSmall 40
  stepPosition <- (\n -> Int.toNumber n / 100.0) <$> chooseInt 0 100
  pure
    { sourceX, sourceY, sourcePosition, targetX, targetY, targetPosition
    , borderRadius, centerX, centerY, offset, stepPosition
    }

runEdgeParity :: Effect Unit
runEdgeParity = do
  log "running edge-path parity properties (PSFlow vs live XYFlow)..."

  quickCheck do
    args <- genEdgeCenterArgs
    pure (edgeCenterMatch "getEdgeCenter" (PS.getEdgeCenter args) (Oracle.getEdgeCenter args))

  quickCheck do
    cp <- genBezierControlPoints
    pure
      ( edgeCenterMatch "getBezierEdgeCenter"
          (PS.getBezierEdgeCenter cp)
          (Oracle.getBezierEdgeCenter cp)
      )

  quickCheck do
    p <- genStraightParams
    pure (edgeResultsMatch "getStraightPath" (PS.getStraightPath p) (Oracle.getStraightPath p))

  quickCheck do
    p <- genBezierParams
    pure (edgeResultsMatch "getBezierPath" (PS.getBezierPath p) (Oracle.getBezierPath p))

  quickCheck do
    p <- genSimpleBezierParams
    pure
      ( edgeResultsMatch "getSimpleBezierPath"
          (PS.getSimpleBezierPath p)
          (Oracle.getSimpleBezierPath p)
      )

  quickCheck do
    p <- genSmoothStepParams
    pure
      ( edgeResultsMatch "getSmoothStepPath"
          (PS.getSmoothStepPath p)
          (Oracle.getSmoothStepPath p)
      )

  log "edge-path parity passed"
