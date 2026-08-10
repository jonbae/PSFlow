-- | Live differential parity for `System.Utils.Edges.*`.
-- |
-- | * **Paths** — the highest-value parity layer, because the SVG `d` string is
-- |   the clearest shared artifact between PSFlow and XYFlow. Each property
-- |   generates a random parameter record, runs the PSFlow function and the
-- |   corresponding `Oracle.*` (live XYFlow) function over the *same* input,
-- |   and asserts the results agree (path tokenized + numeric within epsilon;
-- |   labels/offsets within epsilon). Fresh random inputs every run — true
-- |   live property-based testing.
-- | * **Edge-list mutation** (`addEdge`, `reconnectEdge`) — no arithmetic at
-- |   all, so the comparison is exact: the resulting edges in order, and the
-- |   refusal channel, which upstream reports by calling `onError` and PSFlow
-- |   by returning `Left`.
module Test.Parity.Edges
  ( runEdgeParity
  ) where

import Prelude

import Data.Array (mapWithIndex) as Array
import Data.Array.NonEmpty as NEA
import Data.Either (Either, either, isLeft)
import Data.Int (toNumber) as Int
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.Nullable (toMaybe, toNullable)
import Effect (Effect)
import Effect.Class.Console (log)
import System.Types.Connection (Connection)
import System.Types.Edge (EdgeBase)
import System.Types.Ids (NodeId(..))
import System.Utils.Edges.Bezier (BezierControlPoints, BezierPathParams)
import System.Utils.Edges.Bezier (getBezierEdgeCenter, getBezierPath) as PS
import System.Utils.Edges.General (addEdge, getEdgeCenter, getEdgeId, reconnectEdge) as PS
import System.Utils.Edges.SimpleBezier (SimpleBezierPathParams)
import System.Utils.Edges.SimpleBezier (getSimpleBezierPath) as PS
import System.Utils.Edges.SmoothStep (SmoothStepPathParams)
import System.Utils.Edges.SmoothStep (getSmoothStepPath) as PS
import System.Utils.Edges.Straight (StraightPathParams)
import System.Utils.Edges.Straight (getStraightPath) as PS
import Test.Oracle (OracleConnection, OracleEdgeResult, OracleEdgeShape)
import Test.Oracle as Oracle
import Test.Parity.Builders (mkEdge)
import Test.Parity.Util
  ( allGreen
  , edgeCenterMatch
  , edgeResultsMatch
  , expectGreen
  , falsify
  , strSeqMatch
  )
import Test.Properties (coin, genFiniteNumber, genPosition)
import Test.QuickCheck (Result, quickCheck, (<?>))
import Test.QuickCheck.Gen (Gen, chooseInt, elements, vectorOf)

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

-- ─── Edge-list mutation ───────────────────────────────────────────────────

-- | One generated edge, in the terms `addEdge` and `reconnectEdge` read.
-- | `animated` is read by neither and carried by both, so a rebuild that
-- | dropped the rest of the edge record would show up here.
type EdgeSpec =
  { id :: String
  , source :: String
  , target :: String
  , sourceHandle :: Maybe String
  , targetHandle :: Maybe String
  , animated :: Boolean
  }

type ConnectionSpec =
  { source :: String
  , target :: String
  , sourceHandle :: Maybe String
  , targetHandle :: Maybe String
  }

edgeSpec :: String -> String -> String -> EdgeSpec
edgeSpec id source target =
  { id
  , source
  , target
  , sourceHandle: Nothing
  , targetHandle: Nothing
  , animated: false
  }

toPSEdge :: EdgeSpec -> EdgeBase Unit
toPSEdge s = (mkEdge s.id s.source s.target)
  { sourceHandle = s.sourceHandle
  , targetHandle = s.targetHandle
  , animated = s.animated
  }

toOracleEdge :: EdgeSpec -> OracleEdgeShape
toOracleEdge s =
  { id: s.id
  , source: s.source
  , target: s.target
  , sourceHandle: toNullable s.sourceHandle
  , targetHandle: toNullable s.targetHandle
  , animated: s.animated
  }

toPSConnection :: ConnectionSpec -> Connection
toPSConnection s =
  { source: NodeId s.source
  , target: NodeId s.target
  , sourceHandle: s.sourceHandle
  , targetHandle: s.targetHandle
  }

toOracleConnection :: ConnectionSpec -> OracleConnection
toOracleConnection s =
  { source: s.source
  , target: s.target
  , sourceHandle: toNullable s.sourceHandle
  , targetHandle: toNullable s.targetHandle
  }

-- | The PSFlow result, projected onto the oracle's shape so that one renderer
-- | serves both sides — two renderers would be two chances to describe the
-- | same edge differently and call it a difference.
psEdgeShape :: EdgeBase Unit -> OracleEdgeShape
psEdgeShape e =
  { id: e.id
  , source: unwrap e.source
  , target: unwrap e.target
  , sourceHandle: toNullable e.sourceHandle
  , targetHandle: toNullable e.targetHandle
  , animated: e.animated
  }

renderEdgeShape :: OracleEdgeShape -> String
renderEdgeShape s =
  s.id
    <> "|" <> s.source
    <> "|" <> s.target
    <> "|" <> show (toMaybe s.sourceHandle)
    <> "|" <> show (toMaybe s.targetHandle)
    <> "|" <> show s.animated

-- | Compare a PSFlow edge-list result against the oracle's, on both channels:
-- | the edges in order, and whether the input was refused. `input` is the
-- | array PSFlow was handed — upstream returns it unchanged on refusal, which
-- | is what PSFlow's `Left` means and what the boundary module does with it.
edgeListMatch
  :: String
  -> Array (EdgeBase Unit)
  -> Either String (Array (EdgeBase Unit))
  -> OracleEdgeResult
  -> Result
edgeListMatch ctx input ps xy =
  allGreen
    [ strSeqMatch ctx
        (map (renderEdgeShape <<< psEdgeShape) (either (const input) identity ps))
        (map renderEdgeShape xy.edges)
    , (isLeft ps == xy.errored) <?>
        ( ctx <> ": the two refusal channels disagreed"
            <> "\n  PSFlow returned Left: " <> show (isLeft ps)
            <> "\n  XYFlow called onError: " <> show xy.errored
        )
    ]

-- | Endpoints are drawn from a two-node pool so duplicate connections turn up
-- | often, and include the empty string — upstream's refusal test is `!source`,
-- | which is falsy for `''` and nothing else a `NodeId` can hold.
genEndpoint :: Gen String
genEndpoint = elements (NEA.cons' "a" [ "b", "" ])

-- | Handles are absent, named, or the empty string. `''` matters because
-- | upstream's duplicate check treats a falsy handle as equal to a missing
-- | one — `el.sourceHandle === edge.sourceHandle || (!el.sourceHandle &&
-- | !edge.sourceHandle)`.
genHandle :: Gen (Maybe String)
genHandle = elements (NEA.cons' Nothing [ Just "h1", Just "h2", Just "" ])

genEdgeSpec :: Gen EdgeSpec
genEdgeSpec = do
  id <- elements (NEA.cons' "e1" [ "e2", "e3" ])
  source <- genEndpoint
  target <- genEndpoint
  sourceHandle <- genHandle
  targetHandle <- genHandle
  animated <- coin
  pure { id, source, target, sourceHandle, targetHandle, animated }

genConnectionSpec :: Gen ConnectionSpec
genConnectionSpec = do
  source <- genEndpoint
  target <- genEndpoint
  sourceHandle <- genHandle
  targetHandle <- genHandle
  pure { source, target, sourceHandle, targetHandle }

-- | Distinct ids, so `reconnectEdge`'s `find` has one edge to hit and the
-- | filter one to drop.
genEdgeList :: Gen (Array EdgeSpec)
genEdgeList = do
  n <- chooseInt 0 3
  specs <- vectorOf n genEdgeSpec
  pure (Array.mapWithIndex (\i s -> s { id = "e" <> show i }) specs)

runEdgeParity :: Effect Unit
runEdgeParity = do
  log "running edge parity properties (PSFlow vs live XYFlow)..."

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

  -- The divergence the addEdge property below found, pinned — and run ahead of
  -- it, because a named deterministic case says which behaviour broke where a
  -- random abort only says that something did. The generator reaches this one
  -- only when source and target both match and exactly one handle pair is
  -- `(Nothing, Just "")`, well under a percent of draws, so sampling alone
  -- would let the fix rot back out without a standing red to say so.
  expectGreen "addEdge: an empty-string handle duplicates a missing one"
    ( let
        existing = edgeSpec "e1" "a" "b"
        blankHandled = (edgeSpec "e2" "a" "b") { sourceHandle = Just "" }
      in
        edgeListMatch "addEdge with a blank source handle"
          [ toPSEdge existing ]
          (PS.addEdge (toPSEdge blankHandled) [ toPSEdge existing ] PS.getEdgeId)
          (Oracle.addEdge (toOracleEdge blankHandled) [ toOracleEdge existing ])
    )

  -- addEdge. PSFlow's signature takes an `EdgeBase`, never upstream's
  -- `Edge | Connection` union, so the id-generating branch of upstream's
  -- `isEdgeBase(edgeParams)` split is unreachable from here — it lives on the
  -- boundary module, which picks the branch and is gated by `parity:boundary`.
  -- What this proves is the branch PSFlow does implement: the endpoint
  -- refusal, the duplicate-connection check, and the append.
  quickCheck do
    edge <- genEdgeSpec
    edges <- genEdgeList
    pure
      ( edgeListMatch "addEdge"
          (map toPSEdge edges)
          (PS.addEdge (toPSEdge edge) (map toPSEdge edges) PS.getEdgeId)
          (Oracle.addEdge (toOracleEdge edge) (map toOracleEdge edges))
      )

  quickCheck do
    oldEdge <- genEdgeSpec
    connection <- genConnectionSpec
    edges <- genEdgeList
    shouldReplaceId <- coin
    pure
      ( edgeListMatch "reconnectEdge"
          (map toPSEdge edges)
          ( PS.reconnectEdge (toPSEdge oldEdge) (toPSConnection connection)
              (map toPSEdge edges)
              shouldReplaceId
              PS.getEdgeId
          )
          ( Oracle.reconnectEdge (toOracleEdge oldEdge) (toOracleConnection connection)
              (map toOracleEdge edges)
              shouldReplaceId
          )
      )

  -- Falsification probes.
  falsify "addEdge: XYFlow given the edge already in the list"
    ( let
        existing = edgeSpec "e1" "a" "b"
        fresh = edgeSpec "e2" "c" "d"
      in
        edgeListMatch "addEdge falsification probe"
          [ toPSEdge existing ]
          (PS.addEdge (toPSEdge fresh) [ toPSEdge existing ] PS.getEdgeId)
          (Oracle.addEdge (toOracleEdge existing) [ toOracleEdge existing ])
    )

  falsify "addEdge: XYFlow given endpoints PSFlow had to refuse"
    ( let
        refused = (edgeSpec "e1" "a" "b") { source = "" }
        accepted = edgeSpec "e1" "a" "b"
      in
        edgeListMatch "addEdge falsification probe"
          []
          (PS.addEdge (toPSEdge refused) [] PS.getEdgeId)
          (Oracle.addEdge (toOracleEdge accepted) [])
    )

  falsify "reconnectEdge: XYFlow told to keep the old id, PSFlow to replace it"
    ( let
        old = edgeSpec "e1" "a" "b"
        connection = { source: "a", target: "c", sourceHandle: Nothing, targetHandle: Nothing }
      in
        edgeListMatch "reconnectEdge falsification probe"
          [ toPSEdge old ]
          ( PS.reconnectEdge (toPSEdge old) (toPSConnection connection) [ toPSEdge old ]
              true
              PS.getEdgeId
          )
          ( Oracle.reconnectEdge (toOracleEdge old) (toOracleConnection connection)
              [ toOracleEdge old ]
              false
          )
    )

  log "edge parity passed"
