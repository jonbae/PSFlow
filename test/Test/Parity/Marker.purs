-- | Live differential parity for `System.Utils.Marker.getMarkerId`. Generates
-- | named/custom markers (custom-marker numeric fields are integer-valued, so
-- | `Number.toString` vs `${n}` agree byte-for-byte) and an optional id prefix,
-- | then asserts PSFlow and live XYFlow produce the same id string.
module Test.Parity.Marker
  ( runMarkerParity
  ) where

import Prelude

import Data.Array.NonEmpty as NEA
import Data.Int (toNumber) as Int
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import System.Types.Edge (EdgeMarker, EdgeMarkerType(..), MarkerType(..))
import System.Utils.Marker (getMarkerId) as PS
import Test.Oracle as Oracle
import Test.Parity.Util (strMatch)
import Test.QuickCheck (quickCheck)
import Test.QuickCheck.Gen (Gen, chooseInt, elements)

genMaybeStr :: Gen String -> Gen (Maybe String)
genMaybeStr g = do
  present <- elements (NEA.cons' true [ false ])
  if present then Just <$> g else pure Nothing

genMaybeNum :: Gen (Maybe Number)
genMaybeNum = do
  present <- elements (NEA.cons' true [ false ])
  if present then (Just <<< Int.toNumber) <$> chooseInt 0 100 else pure Nothing

genMarkerType :: Gen MarkerType
genMarkerType = elements (NEA.cons' Arrow [ ArrowClosed ])

genCustomMarker :: Gen EdgeMarker
genCustomMarker = do
  markerType <- genMarkerType
  color <- genMaybeStr (elements (NEA.cons' "#fff" [ "red", "blue" ]))
  width <- genMaybeNum
  height <- genMaybeNum
  markerUnits <- genMaybeStr (elements (NEA.cons' "userSpaceOnUse" [ "strokeWidth" ]))
  orient <- genMaybeStr (elements (NEA.cons' "auto" [ "auto-start-reverse" ]))
  strokeWidth <- genMaybeNum
  pure { markerType, color, width, height, markerUnits, orient, strokeWidth }

genEdgeMarkerType :: Gen EdgeMarkerType
genEdgeMarkerType = do
  named <- elements (NEA.cons' true [ false ])
  if named then NamedMarker <$> elements (NEA.cons' "arrow" [ "arrowclosed", "myMarker" ])
  else CustomMarker <$> genCustomMarker

-- | Weight toward a present marker so the `Nothing → ""` branch doesn't
-- | dominate the sample.
genMaybeMarker :: Gen (Maybe EdgeMarkerType)
genMaybeMarker = do
  present <- elements (NEA.cons' true [ true, false ])
  if present then Just <$> genEdgeMarkerType else pure Nothing

runMarkerParity :: Effect Unit
runMarkerParity = do
  log "running marker parity properties (PSFlow vs live XYFlow)..."

  quickCheck do
    marker <- genMaybeMarker
    mid <- genMaybeStr (elements (NEA.cons' "e1" [ "edge-2", "x" ]))
    pure
      ( strMatch "getMarkerId"
          (PS.getMarkerId marker mid)
          (Oracle.getMarkerId marker mid)
      )

  log "marker parity passed"
