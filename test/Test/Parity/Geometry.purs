-- | Live differential parity for the pure geometry helpers in
-- | `System.Utils.General`. Same shape as the edge-path parity: generate an
-- | input, run PSFlow and live XYFlow over it, compare within epsilon.
-- |
-- | One documented divergence is excluded by generator construction:
-- | `snapPosition` (and therefore `pointToRendererPoint` *with* a grid) uses
-- | PSFlow's `roundHalfAwayFromZero`, which disagrees with JS `Math.round`
-- | on negative exact-half multiples — see ticket 057. The `snapPosition`
-- | property below stays on the non-negative domain where the two agree;
-- | `pointToRendererPoint` is tested with `Nothing` (no snap).
module Test.Parity.Geometry
  ( runGeometryParity
  ) where

import Prelude

import Data.Array.NonEmpty as NEA
import Data.Int (toNumber) as Int
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import System.Types.Geometry
  ( CoordinateExtent
  , Transform
  , XYPosition
  , mkCoordinateExtent
  , mkTransform
  )
import System.Utils.General
  ( boxToRect
  , clamp
  , clampPosition
  , getBoundsOfBoxes
  , getBoundsOfRects
  , getOverlappingArea
  , pointToRendererPoint
  , rectToBox
  , rendererPointToPoint
  , snapPosition
  ) as PS
import Test.Oracle as Oracle
import Test.Parity.Util (boxMatch, numMatch, rectMatch, xyMatch)
import Test.Properties (genBox, genFiniteNumber, genNonNegNumber, genRect, genSnapGrid)
import Test.QuickCheck (quickCheck)
import Test.QuickCheck.Gen (Gen, chooseInt, elements)

genXY :: Gen XYPosition
genXY = do
  x <- genFiniteNumber
  y <- genFiniteNumber
  pure { x, y }

genNonNegXY :: Gen XYPosition
genNonNegXY = do
  x <- genNonNegNumber
  y <- genNonNegNumber
  pure { x, y }

-- | A `Transform` with a non-zero scale (division by scale sits in
-- | `pointToRendererPoint`).
genTransform :: Gen Transform
genTransform = do
  tx <- genFiniteNumber
  ty <- genFiniteNumber
  scale <- (\n -> Int.toNumber n / 2.0) <$> chooseInt 1 20
  pure (mkTransform tx ty scale)

genExtent :: Gen CoordinateExtent
genExtent = do
  minX <- genFiniteNumber
  minY <- genFiniteNumber
  spreadX <- Int.toNumber <$> chooseInt 0 1000
  spreadY <- Int.toNumber <$> chooseInt 0 1000
  pure (mkCoordinateExtent minX minY (minX + spreadX) (minY + spreadY))

genMaybeDim :: Gen (Maybe Number)
genMaybeDim = do
  present <- elements (NEA.cons' true [ false ])
  if present then Just <$> genNonNegNumber else pure Nothing

genDims :: Gen { width :: Maybe Number, height :: Maybe Number }
genDims = do
  width <- genMaybeDim
  height <- genMaybeDim
  pure { width, height }

runGeometryParity :: Effect Unit
runGeometryParity = do
  log "running geometry parity properties (PSFlow vs live XYFlow)..."

  quickCheck do
    val <- genFiniteNumber
    mn <- genFiniteNumber
    mx <- genFiniteNumber
    pure (numMatch "clamp" (PS.clamp val mn mx) (Oracle.clamp val mn mx))

  quickCheck do
    a <- genBox
    b <- genBox
    pure (boxMatch "getBoundsOfBoxes" (PS.getBoundsOfBoxes a b) (Oracle.getBoundsOfBoxes a b))

  quickCheck do
    r <- genRect
    pure (boxMatch "rectToBox" (PS.rectToBox r) (Oracle.rectToBox r))

  quickCheck do
    b <- genBox
    pure (rectMatch "boxToRect" (PS.boxToRect b) (Oracle.boxToRect b))

  quickCheck do
    a <- genRect
    b <- genRect
    pure (rectMatch "getBoundsOfRects" (PS.getBoundsOfRects a b) (Oracle.getBoundsOfRects a b))

  quickCheck do
    a <- genRect
    b <- genRect
    pure
      ( numMatch "getOverlappingArea"
          (PS.getOverlappingArea a b)
          (Oracle.getOverlappingArea a b)
      )

  quickCheck do
    pos <- genXY
    ext <- genExtent
    dims <- genDims
    pure
      ( xyMatch "clampPosition"
          (PS.clampPosition pos ext dims)
          (Oracle.clampPosition pos ext dims)
      )

  -- Non-negative domain only: PSFlow and XYFlow rounding agree there (the
  -- negative exact-half divergence is ticket 057).
  quickCheck do
    pos <- genNonNegXY
    g <- genSnapGrid
    pure
      ( xyMatch "snapPosition (non-negative domain — ticket 057)"
          (PS.snapPosition pos g)
          (Oracle.snapPosition pos g)
      )

  quickCheck do
    pos <- genXY
    t <- genTransform
    pure
      ( xyMatch "pointToRendererPoint (no snap)"
          (PS.pointToRendererPoint pos t Nothing)
          (Oracle.pointToRendererPoint pos t Nothing)
      )

  quickCheck do
    pos <- genXY
    t <- genTransform
    pure
      ( xyMatch "rendererPointToPoint"
          (PS.rendererPointToPoint pos t)
          (Oracle.rendererPointToPoint pos t)
      )

  log "geometry parity passed"
