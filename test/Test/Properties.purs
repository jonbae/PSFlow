-- | QuickCheck property tests for pure helpers (ticket 021, item #20).
-- |
-- | Each property exercises an algebraic invariant of a pure function, so the
-- | assertions remain valid even if the underlying implementation is later
-- | refactored. Run via `Test.Main` after the hand-written assertion list.
module Test.Properties
  ( runProperties
  , genFiniteNumber
  , genNonNegNumber
  , genRect
  , genBox
  , genSnapGrid
  , genPosition
  ) where

import Prelude hiding (clamp)

import Data.Array.NonEmpty as NEA
import Data.Either (Either(..))
import Data.Int (toNumber) as Int
import Data.Map (Map)
import Data.Map (singleton) as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Test.QuickCheck (quickCheck, (<?>))
import Test.QuickCheck.Gen (Gen, chooseInt, elements, vectorOf)
import System.Types.Edge (EdgeBase)
import System.Types.Ids (NodeId(..))
import System.Types.Geometry
  ( Box
  , CoordinateExtent(..)
  , Position(..)
  , Rect
  , SnapGrid(..)
  , XYPosition
  , mkCoordinateExtent
  , mkNodeOrigin
  , mkSnapGrid
  , oppositePosition
  )
import System.Types.Node (InternalNodeBase)
import System.Utils.Edges.General (addEdge, getEdgeId)
import System.Utils.General
  ( boxToRect
  , clamp
  , getBoundsOfBoxes
  , rectToBox
  , snapPosition
  )
import System.Utils.Graph (calculateNodePosition)

-- | A finite `Number` generator. The default `Arbitrary Number` returns
-- | values from `uniform` in `[0, 1]`, which is too narrow for the geometric
-- | invariants under test. Going through `Int` also guarantees we never emit
-- | NaN/Infinity, both of which would break `==` round-trip checks.
-- |
-- | Integer-valued so `(x + width) - x == width` exactly under IEEE-754 — the
-- | rect/box round trip relies on that.
genFiniteNumber :: Gen Number
genFiniteNumber = Int.toNumber <$> chooseInt (-1000) 1000

-- | Non-negative `Number` (0..1000), used for widths/heights.
genNonNegNumber :: Gen Number
genNonNegNumber = Int.toNumber <$> chooseInt 0 1000

-- | Generate a `Rect` with non-negative width/height. Negative dimensions
-- | are not meaningful for the round-trip property.
genRect :: Gen Rect
genRect = do
  x <- genFiniteNumber
  y <- genFiniteNumber
  width <- genNonNegNumber
  height <- genNonNegNumber
  pure { x, y, width, height }

-- | Generate a `Box` with `x <= x2` and `y <= y2`.
genBox :: Gen Box
genBox = do
  x <- genFiniteNumber
  y <- genFiniteNumber
  dx <- genNonNegNumber
  dy <- genNonNegNumber
  pure { x, y, x2: x + dx, y2: y + dy }

genPosition :: Gen Position
genPosition = elements (NEA.cons' PosLeft [ PosTop, PosRight, PosBottom ])

-- | Generate a `SnapGrid` whose cell sizes are strictly positive — division
-- | by the grid size sits at the heart of `snapPosition`.
genSnapGrid :: Gen SnapGrid
genSnapGrid = do
  gx <- Int.toNumber <$> chooseInt 1 200
  gy <- Int.toNumber <$> chooseInt 1 200
  pure (mkSnapGrid gx gy)

-- | A minimal `EdgeBase Unit` builder. Keeping optional fields at `Nothing`
-- | and booleans at `false` means two edges with the same `(source, target)`
-- | pair are structurally equal — that's what `addEdge`'s idempotence
-- | depends on (it deduplicates by source/target/handles, not by `id`).
mkEdge :: String -> String -> String -> EdgeBase Unit
mkEdge eid src tgt =
  { id: eid
  , edgeType: Nothing
  , source: NodeId src
  , target: NodeId tgt
  , sourceHandle: Nothing
  , targetHandle: Nothing
  , animated: false
  , hidden: false
  , deletable: Nothing
  , selectable: Nothing
  , data: Nothing
  , selected: false
  , markerStart: Nothing
  , markerEnd: Nothing
  , zIndex: Nothing
  , ariaLabel: Nothing
  , interactionWidth: Nothing
  , className: Nothing
  , style: Nothing
  }

-- | An edge endpoint id is a small letter so we get a non-trivial chance of
-- | duplicates when building random arrays.
genEdgeId :: Gen String
genEdgeId = elements (NEA.cons' "a" [ "b", "c", "d" ])

genEdge :: Gen (EdgeBase Unit)
genEdge = do
  src <- genEdgeId
  tgt <- genEdgeId
  pure (mkEdge (src <> "-" <> tgt) src tgt)

genEdgeArray :: Gen (Array (EdgeBase Unit))
genEdgeArray = do
  n <- chooseInt 0 4
  vectorOf n genEdge

-- | `addEdge` returns `Right` for non-empty endpoints; our generators never
-- | produce empty strings, so the `Left` branch is unreachable here.
runAddEdge :: EdgeBase Unit -> Array (EdgeBase Unit) -> Array (EdgeBase Unit)
runAddEdge e edges = case addEdge e edges getEdgeId of
  Right xs -> xs
  Left _ -> edges

-- | A minimal parent-less `InternalNodeBase Unit` with known measured
-- | width/height. Used to exercise `calculateNodePosition`'s extent
-- | clamping in isolation — the parent-chain, origin-offset, and
-- | `extent == ParentExtent` branches are out of scope for this property.
mkLeafInternalNode :: NodeId -> Number -> Number -> InternalNodeBase Unit
mkLeafInternalNode nid width height =
  { id: nid
  , position: { x: 0.0, y: 0.0 }
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: false
  , selected: false
  , dragging: false
  , draggable: Nothing
  , selectable: Nothing
  , connectable: Nothing
  , deletable: Nothing
  , dragHandle: Nothing
  , width: Just width
  , height: Just height
  , initialWidth: Nothing
  , initialHeight: Nothing
  , parentId: Nothing
  , zIndex: Nothing
  , extent: Nothing
  , expandParent: false
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Just width, height: Just height }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  , internals:
      { positionAbsolute: { x: 0.0, y: 0.0 }
      , z: 0.0
      , rootParentIndex: Nothing
      , handleBounds: Nothing
      , bounds: Nothing
      }
  }

-- | Generate a `CoordinateExtent` whose `max` strictly exceeds `min`. The
-- | spread is bounded so that `maxX - width` and `maxY - height` (the
-- | upper clamp targets) stay finite and non-degenerate for the chosen
-- | node dimensions.
genCoordinateExtent :: Gen CoordinateExtent
genCoordinateExtent = do
  minX <- genFiniteNumber
  minY <- genFiniteNumber
  spreadX <- Int.toNumber <$> chooseInt 200 1000
  spreadY <- Int.toNumber <$> chooseInt 200 1000
  pure (mkCoordinateExtent minX minY (minX + spreadX) (minY + spreadY))

runProperties :: Effect Unit
runProperties = do
  log "running QuickCheck properties..."

  -- clamp x lo hi ∈ [lo, hi]. We canonicalise lo/hi from the two arbitrary
  -- bounds so the property is total.
  quickCheck $ \a b c ->
    let
      lo = min b c
      hi = max b c
      v = clamp a lo hi
    in
      (v >= lo && v <= hi)
        <?> ("clamp " <> show a <> " " <> show lo <> " " <> show hi
              <> " = " <> show v <> " out of range")

  -- boxToRect ∘ rectToBox = id (on Rects with non-negative dimensions).
  quickCheck do
    r <- genRect
    let r' = boxToRect (rectToBox r)
    pure (r' == r <?> "rect round-trip changed value")

  -- getBoundsOfBoxes is associative.
  quickCheck do
    a <- genBox
    b <- genBox
    c <- genBox
    let
      lhs = getBoundsOfBoxes (getBoundsOfBoxes a b) c
      rhs = getBoundsOfBoxes a (getBoundsOfBoxes b c)
    pure (lhs == rhs <?> "getBoundsOfBoxes not associative")

  -- getBoundsOfBoxes is commutative.
  quickCheck do
    a <- genBox
    b <- genBox
    let
      lhs = getBoundsOfBoxes a b
      rhs = getBoundsOfBoxes b a
    pure (lhs == rhs <?> "getBoundsOfBoxes not commutative")

  -- oppositePosition is involutive.
  quickCheck do
    p <- genPosition
    pure (oppositePosition (oppositePosition p) == p
            <?> "oppositePosition not involutive")

  -- addEdge is idempotent — adding the same edge twice yields the same array
  -- as adding it once.
  quickCheck do
    es <- genEdgeArray
    e <- genEdge
    let
      once = runAddEdge e es
      twice = runAddEdge e once
    pure (once == twice <?> "addEdge not idempotent")

  -- snapPosition is a fixed point on snap-aligned input. We construct an
  -- aligned position by multiplying integer coefficients by the grid's cell
  -- size, then assert snapPosition leaves it untouched.
  quickCheck do
    g <- genSnapGrid
    let SnapGrid gr = g
    mx <- chooseInt (-1000) 1000
    my <- chooseInt (-1000) 1000
    let
      aligned :: XYPosition
      aligned = { x: gr.gx * Int.toNumber mx, y: gr.gy * Int.toNumber my }
      snapped = snapPosition aligned g
    pure (snapped == aligned
            <?> "snapPosition not a fixed point on aligned input")

  -- calculateNodePosition respects the supplied CoordinateExtent: for a
  -- parent-less leaf node with known measured dims, the returned
  -- `positionAbsolute` always lies inside the extent (clamped to leave
  -- room for the node's width/height). Demonstrates that the function is
  -- callable from a pure context — no `Effect` callback in scope.
  quickCheck do
    ext@(CoordinateExtent r) <- genCoordinateExtent
    width <- Int.toNumber <$> chooseInt 0 100
    height <- Int.toNumber <$> chooseInt 0 100
    nextX <- genFiniteNumber
    nextY <- genFiniteNumber
    let
      nid = NodeId "n1"
      lookup :: Map NodeId (InternalNodeBase Unit)
      lookup = Map.singleton nid (mkLeafInternalNode nid width height)
      result = calculateNodePosition
        { nodeId: nid
        , nextPosition: { x: nextX, y: nextY }
        , nodeLookup: lookup
        , nodeOrigin: mkNodeOrigin 0.0 0.0
        , nodeExtent: Just ext
        }
    pure case result of
      Nothing ->
        false <?> "calculateNodePosition returned Nothing for present node"
      Just { positionAbsolute: pa } ->
        ( pa.x >= r.minX
            && pa.x <= r.maxX - width
            && pa.y >= r.minY
            && pa.y <= r.maxY - height
        )
          <?>
            ( "positionAbsolute " <> show pa <> " outside extent ("
                <> show r.minX <> "," <> show r.minY <> ")-("
                <> show r.maxX <> "," <> show r.maxY <> ") for dims "
                <> show width <> "x" <> show height
            )

  log "all properties passed"
