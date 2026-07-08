-- | Live differential parity for the toolbar CSS-transform generators in
-- | `System.Utils.Toolbar`. Same shape as the edge/geometry parity: generate an
-- | input, run PSFlow and live XYFlow over it, compare the transform strings
-- | with the tokenize-then-epsilon contract (`transformMatch`).
module Test.Parity.Toolbar
  ( runToolbarParity
  ) where

import Prelude

import Data.Array.NonEmpty as NEA
import Data.Int (toNumber) as Int
import Effect (Effect)
import Effect.Class.Console (log)
import System.Types.Connection (Viewport)
import System.Types.Edge (AlignX(..), AlignY(..))
import System.Types.Node (Align(..))
import System.Utils.Toolbar (getEdgeToolbarTransform, getNodeToolbarTransform) as PS
import Test.Oracle as Oracle
import Test.Parity.Util (transformMatch)
import Test.Properties (genFiniteNumber, genPosition, genRect)
import Test.QuickCheck (quickCheck)
import Test.QuickCheck.Gen (Gen, chooseInt, elements)

-- | A `Viewport` with a non-zero zoom — `getEdgeToolbarTransform` divides by it.
genViewport :: Gen Viewport
genViewport = do
  x <- genFiniteNumber
  y <- genFiniteNumber
  zoom <- (\n -> Int.toNumber n / 2.0) <$> chooseInt 1 20
  pure { x, y, zoom }

genAlign :: Gen Align
genAlign = elements (NEA.cons' AlignStart [ AlignCenter, AlignEnd ])

genAlignX :: Gen AlignX
genAlignX = elements (NEA.cons' AlignXLeft [ AlignXCenter, AlignXRight ])

genAlignY :: Gen AlignY
genAlignY = elements (NEA.cons' AlignYTop [ AlignYCenter, AlignYBottom ])

runToolbarParity :: Effect Unit
runToolbarParity = do
  log "running toolbar parity properties (PSFlow vs live XYFlow)..."

  quickCheck do
    rect <- genRect
    viewport <- genViewport
    position <- genPosition
    offset <- genFiniteNumber
    align <- genAlign
    pure
      ( transformMatch "getNodeToolbarTransform"
          (PS.getNodeToolbarTransform rect viewport position offset align)
          (Oracle.getNodeToolbarTransform rect viewport position offset align)
      )

  quickCheck do
    x <- genFiniteNumber
    y <- genFiniteNumber
    viewport <- genViewport
    alignX <- genAlignX
    alignY <- genAlignY
    pure
      ( transformMatch "getEdgeToolbarTransform"
          (PS.getEdgeToolbarTransform x y viewport.zoom alignX alignY)
          (Oracle.getEdgeToolbarTransform x y viewport.zoom alignX alignY)
      )

  log "toolbar parity passed"
