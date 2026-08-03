-- | Live differential parity for the pure geometry helpers in
-- | `System.Utils.General`. Same shape as the edge-path parity: generate an
-- | input, run PSFlow and live XYFlow over it, compare within epsilon.
-- |
-- | `snapPosition` (and `pointToRendererPoint` *with* a grid) runs over the
-- | full signed domain, including the exact-half multiples that ticket 057
-- | had excluded — `roundHalfUp` now matches JS `Math.round` there.
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
  , SnapGrid
  , Transform
  , XYPosition
  , mkCoordinateExtent
  , mkSnapGrid
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

-- | Positions sitting *exactly* on a half-multiple of the grid — the rounding
-- | tie-break, and the only place PSFlow and JS `Math.round` ever disagreed
-- | (ticket 057). `genXY`/`genSnapGrid` reach this case only by coincidence
-- | (~1% of draws), so construct it directly: every draw is a tie, half of
-- | them on the negative axis where the old rounding was wrong.
genHalfCell :: Gen { pos :: XYPosition, grid :: SnapGrid }
genHalfCell = do
  gx <- Int.toNumber <$> chooseInt 1 200
  gy <- Int.toNumber <$> chooseInt 1 200
  kx <- Int.toNumber <$> chooseInt (-20) 20
  ky <- Int.toNumber <$> chooseInt (-20) 20
  pure
    { pos: { x: gx * (kx + 0.5), y: gy * (ky + 0.5) }
    , grid: mkSnapGrid gx gy
    }

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

  quickCheck do
    pos <- genXY
    g <- genSnapGrid
    pure
      ( xyMatch "snapPosition"
          (PS.snapPosition pos g)
          (Oracle.snapPosition pos g)
      )

  quickCheck do
    { pos, grid } <- genHalfCell
    pure
      ( xyMatch "snapPosition (exact half-cell tie-break — ticket 057)"
          (PS.snapPosition pos grid)
          (Oracle.snapPosition pos grid)
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
    g <- genSnapGrid
    pure
      ( xyMatch "pointToRendererPoint (snap to grid)"
          (PS.pointToRendererPoint pos t (Just g))
          (Oracle.pointToRendererPoint pos t (Just g))
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
