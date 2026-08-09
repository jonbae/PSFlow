-- | Live differential parity for the pure helpers in `System.Utils.Graph`.
-- |
-- | * **Traversal** (`getOutgoers`, `getIncomers`, `getConnectedEdges`) reads
-- |   only string ids, so we generate a small random graph over a fixed id
-- |   pool, run PSFlow and live XYFlow over the same data, and compare the
-- |   returned id sets (order-insensitive).
-- | * **Bounds** (`getNodesBounds`) is arithmetic over positions, the
-- |   three-deep dimension fallback and the node origin. What it proves is that
-- |   arithmetic — *not* the measured DOM dimensions that feed it, which no
-- |   oracle can reach.
-- | * **Shape guards** (`isNode`, `isEdge`, as `React.Util.General` surfaces
-- |   them) read own-property names, so their input domain is finite and is
-- |   exhausted rather than sampled.
module Test.Parity.Graph
  ( runGraphParity
  ) where

import Prelude

import Data.Array (catMaybes, filterA, mapWithIndex) as Array
import Data.Array.NonEmpty as NEA
import Data.Int (toNumber) as Int
import Data.Maybe (Maybe(..))
import Data.Nullable (toNullable)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign (Foreign, unsafeToForeign)
import Foreign.Object as FO
import React.Util.General (isEdge, isNode) as PS
import System.Types.Edge (EdgeBase)
import System.Types.Geometry (NodeOrigin(..), XYPosition)
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeBase)
import System.Utils.Graph (getConnectedEdges, getIncomers, getNodesBounds, getOutgoers) as PS
import Test.Oracle (OracleBoundsNode, OracleEdge, OracleNode)
import Test.Oracle (getConnectedEdges, getIncomers, getNodesBounds, getOutgoers, isEdge, isNode) as Oracle
import Test.Parity.Fixtures (mkEdge, mkNode)
import Test.Parity.Util (allGreen, expectGreen, falsify, rectMatch, strArrayMatch)
import Test.Properties (genFiniteNumber)
import Test.QuickCheck (Result, quickCheck, (<?>))
import Test.QuickCheck.Gen (Gen, chooseInt, elements, vectorOf)

-- ─── Fixtures ─────────────────────────────────────────────────────────────

unId :: NodeId -> String
unId (NodeId s) = s

toPSNodes :: Array String -> Array (NodeBase Unit)
toPSNodes = map mkNode

toPSEdges :: Array OracleEdge -> Array (EdgeBase Unit)
toPSEdges = map \e -> mkEdge e.id e.source e.target

toONodes :: Array String -> Array OracleNode
toONodes = map \id -> { id }

-- ─── Generators ───────────────────────────────────────────────────────────

pool :: Array String
pool = [ "a", "b", "c", "d" ]

poolElem :: Gen String
poolElem = elements (NEA.cons' "a" [ "b", "c", "d" ])

coin :: Gen Boolean
coin = elements (NEA.cons' true [ false ])

-- | A unique subset of the id pool (distinct nodes — no duplicate ids).
genNodeSubset :: Gen (Array String)
genNodeSubset = Array.filterA (const coin) pool

-- | A random edge list over the pool; ids are the array index so each edge is
-- | distinct even when its endpoints repeat.
genEdges :: Gen (Array OracleEdge)
genEdges = do
  n <- chooseInt 0 6
  pairs <- vectorOf n do
    source <- poolElem
    target <- poolElem
    pure { source, target }
  pure (Array.mapWithIndex (\i p -> { id: show i, source: p.source, target: p.target }) pairs)

-- ─── Bounds ───────────────────────────────────────────────────────────────

-- | One generated node in the only terms `getNodesBounds` reads: where it
-- | sits, what its dimensions resolve to through the three-deep fallback, and
-- | whether it overrides the shared origin.
type BoundsNodeSpec =
  { id :: String
  , position :: XYPosition
  , width :: Maybe Number
  , height :: Maybe Number
  , initialWidth :: Maybe Number
  , initialHeight :: Maybe Number
  , measured :: { width :: Maybe Number, height :: Maybe Number }
  , origin :: Maybe NodeOrigin
  }

toPSBoundsNode :: BoundsNodeSpec -> NodeBase Unit
toPSBoundsNode s = (mkNode s.id)
  { position = s.position
  , width = s.width
  , height = s.height
  , initialWidth = s.initialWidth
  , initialHeight = s.initialHeight
  , measured = s.measured
  , origin = s.origin
  }

toOracleBoundsNode :: BoundsNodeSpec -> OracleBoundsNode
toOracleBoundsNode s =
  { id: s.id
  , position: s.position
  , width: toNullable s.width
  , height: toNullable s.height
  , initialWidth: toNullable s.initialWidth
  , initialHeight: toNullable s.initialHeight
  , measured:
      { width: toNullable s.measured.width
      , height: toNullable s.measured.height
      }
  , origin: toNullable (map (\(NodeOrigin o) -> [ o.ox, o.oy ]) s.origin)
  }

genDimension :: Gen Number
genDimension = Int.toNumber <$> chooseInt 0 400

-- | Absent about a third of the time, so every rung of upstream's
-- | `measured ?? width ?? initialWidth ?? 0` fallback is reached — including
-- | the bottom one, where a node contributes a zero-size box at its position.
genMaybeDimension :: Gen (Maybe Number)
genMaybeDimension = do
  present <- elements (NEA.cons' true [ true, false ])
  if present then Just <$> genDimension else pure Nothing

-- | The corner and centre fractions upstream documents, drawn per axis so the
-- | offset subtraction is exercised on each independently.
genOrigin :: Gen NodeOrigin
genOrigin = do
  ox <- elements (NEA.cons' 0.0 [ 0.5, 1.0 ])
  oy <- elements (NEA.cons' 0.0 [ 0.5, 1.0 ])
  pure (NodeOrigin { ox, oy })

genBoundsNodeSpec :: Gen BoundsNodeSpec
genBoundsNodeSpec = do
  x <- genFiniteNumber
  y <- genFiniteNumber
  width <- genMaybeDimension
  height <- genMaybeDimension
  initialWidth <- genMaybeDimension
  initialHeight <- genMaybeDimension
  measuredWidth <- genMaybeDimension
  measuredHeight <- genMaybeDimension
  -- A per-node origin overrides the shared one; most nodes leave it unset.
  overrides <- elements (NEA.cons' false [ false, true ])
  origin <- if overrides then Just <$> genOrigin else pure Nothing
  pure
    { id: "n"
    , position: { x, y }
    , width
    , height
    , initialWidth
    , initialHeight
    , measured: { width: measuredWidth, height: measuredHeight }
    , origin
    }

-- | Includes the empty array — both sides short-circuit it to a zero rect
-- | rather than letting the `(+Inf, -Inf)` fold seed through.
genBoundsNodes :: Gen (Array BoundsNodeSpec)
genBoundsNodes = do
  n <- chooseInt 0 4
  specs <- vectorOf n genBoundsNodeSpec
  pure (Array.mapWithIndex (\i s -> s { id = "n" <> show i }) specs)

-- ─── Shape guards ─────────────────────────────────────────────────────────

-- | Which of the four keys the candidate carries. `isNode` and `isEdge` read
-- | own-property names and nothing else, so this record *is* their input
-- | domain — sixteen values, exhausted below.
type KeySet =
  { id :: Boolean, position :: Boolean, source :: Boolean, target :: Boolean }

allKeySets :: Array KeySet
allKeySets = do
  id <- [ false, true ]
  position <- [ false, true ]
  source <- [ false, true ]
  target <- [ false, true ]
  pure { id, position, source, target }

-- | The candidate both sides see, built once per call and handed to each
-- | unchanged.
-- |
-- | Objects only: upstream's guards are `'id' in element`, and `in` throws a
-- | `TypeError` on a primitive. PSFlow's FFI puts a `typeof e === "object"`
-- | test in front, so it answers `false` where upstream throws — a deliberate
-- | divergence towards totality, and out of this property's reach because a
-- | throwing oracle leaves nothing to compare.
candidate :: KeySet -> Foreign
candidate keys = unsafeToForeign (FO.fromFoldable (Array.catMaybes entries))
  where
  entry present key value = if present then Just (Tuple key value) else Nothing
  entries =
    [ entry keys.id "id" (unsafeToForeign "e1")
    , entry keys.position "position" (unsafeToForeign { x: 1.0, y: 2.0 })
    , entry keys.source "source" (unsafeToForeign "a")
    , entry keys.target "target" (unsafeToForeign "b")
    ]

guardsMatch :: KeySet -> Result
guardsMatch keys =
  let
    el = candidate keys
    psNode = PS.isNode el
    psEdge = PS.isEdge el
    xyNode = Oracle.isNode el
    xyEdge = Oracle.isEdge el
  in
    (psNode == xyNode && psEdge == xyEdge) <?>
      ( "shape guards on keys " <> show keys
          <> "\n  PSFlow: isNode=" <> show psNode <> " isEdge=" <> show psEdge
          <> "\n  XYFlow: isNode=" <> show xyNode <> " isEdge=" <> show xyEdge
      )

runGraphParity :: Effect Unit
runGraphParity = do
  log "running graph parity properties (PSFlow vs live XYFlow)..."

  quickCheck do
    nodeIds <- genNodeSubset
    edges <- genEdges
    target <- poolElem
    let
      ps = map (unId <<< _.id)
        (PS.getOutgoers { id: NodeId target } (toPSNodes nodeIds) (toPSEdges edges))
      xy = Oracle.getOutgoers { id: target } (toONodes nodeIds) edges
    pure (strArrayMatch "getOutgoers" ps xy)

  quickCheck do
    nodeIds <- genNodeSubset
    edges <- genEdges
    target <- poolElem
    let
      ps = map (unId <<< _.id)
        (PS.getIncomers { id: NodeId target } (toPSNodes nodeIds) (toPSEdges edges))
      xy = Oracle.getIncomers { id: target } (toONodes nodeIds) edges
    pure (strArrayMatch "getIncomers" ps xy)

  quickCheck do
    nodeIds <- genNodeSubset
    edges <- genEdges
    let
      ps = map _.id (PS.getConnectedEdges (toPSNodes nodeIds) (toPSEdges edges))
      xy = Oracle.getConnectedEdges (toONodes nodeIds) edges
    pure (strArrayMatch "getConnectedEdges" ps xy)

  -- getNodesBounds. No `nodeLookup` is passed on either side: resolving a node
  -- through the store's lookup is what makes sub-flows work, and that is a
  -- store concern rather than arithmetic. This is the bounded claim — the
  -- chain from positions and dimensions to a rect, never where the dimensions
  -- came from.
  quickCheck do
    specs <- genBoundsNodes
    origin <- genOrigin
    let
      ps = PS.getNodesBounds (map toPSBoundsNode specs) Nothing origin
      xy = Oracle.getNodesBounds (map toOracleBoundsNode specs) origin
    pure (rectMatch "getNodesBounds" ps xy)

  expectGreen "isNode / isEdge agree across all 16 key combinations"
    (allGreen (map guardsMatch allKeySets))

  -- Falsification probes.
  falsify "getNodesBounds: XYFlow given a centre origin, PSFlow a corner one"
    ( let
        specs = [ boundsSpec "n0" 10.0 20.0 60.0 40.0 ]
        corner = NodeOrigin { ox: 0.0, oy: 0.0 }
        centre = NodeOrigin { ox: 0.5, oy: 0.5 }
      in
        rectMatch "getNodesBounds probe"
          (PS.getNodesBounds (map toPSBoundsNode specs) Nothing corner)
          (Oracle.getNodesBounds (map toOracleBoundsNode specs) centre)
    )

  falsify "getNodesBounds: XYFlow given one node fewer"
    ( let
        specs =
          [ boundsSpec "n0" 0.0 0.0 10.0 10.0
          , boundsSpec "n1" 500.0 500.0 10.0 10.0
          ]
        origin = NodeOrigin { ox: 0.0, oy: 0.0 }
      in
        rectMatch "getNodesBounds probe"
          (PS.getNodesBounds (map toPSBoundsNode specs) Nothing origin)
          (Oracle.getNodesBounds (map toOracleBoundsNode [ boundsSpec "n0" 0.0 0.0 10.0 10.0 ]) origin)
    )

  -- The guards return a `Boolean`, so a probe cannot perturb magnitudes — it
  -- has to hand the two sides different objects. A node shape against an edge
  -- shape is the pair whose four answers all disagree.
  falsify "isNode / isEdge: XYFlow given an edge where PSFlow got a node"
    ( let
        node = candidate { id: true, position: true, source: false, target: false }
        edge = candidate { id: true, position: false, source: true, target: true }
      in
        (PS.isNode node == Oracle.isNode edge && PS.isEdge node == Oracle.isEdge edge) <?>
          "isNode / isEdge probe: a node and an edge compared equal"
    )

  log "graph parity passed"

-- | A bounds node with everything pinned: no fallback rungs, no origin
-- | override. Probes want a single moving part.
boundsSpec :: String -> Number -> Number -> Number -> Number -> BoundsNodeSpec
boundsSpec id x y width height =
  { id
  , position: { x, y }
  , width: Just width
  , height: Just height
  , initialWidth: Nothing
  , initialHeight: Nothing
  , measured: { width: Just width, height: Just height }
  , origin: Nothing
  }
