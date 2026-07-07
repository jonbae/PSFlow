-- | Live differential parity for the pure graph-traversal helpers in
-- | `System.Utils.Graph` (`getOutgoers`, `getIncomers`, `getConnectedEdges`).
-- | These read only string ids, so we generate a small random graph over a
-- | fixed id pool, run PSFlow and live XYFlow over the same data, and compare
-- | the returned id sets (order-insensitive).
module Test.Parity.Graph
  ( runGraphParity
  ) where

import Prelude

import Data.Array (filterA, mapWithIndex) as Array
import Data.Array.NonEmpty as NEA
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import System.Types.Edge (EdgeBase)
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeBase)
import System.Utils.Graph (getConnectedEdges, getIncomers, getOutgoers) as PS
import Test.Oracle (OracleEdge, OracleNode)
import Test.Oracle (getConnectedEdges, getIncomers, getOutgoers) as Oracle
import Test.Parity.Util (strArrayMatch)
import Test.QuickCheck (quickCheck)
import Test.QuickCheck.Gen (Gen, chooseInt, elements, vectorOf)

-- ─── Fixtures ─────────────────────────────────────────────────────────────

mkNode :: String -> NodeBase Unit
mkNode nid =
  { id: NodeId nid
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
  , width: Just 50.0
  , height: Just 25.0
  , initialWidth: Nothing
  , initialHeight: Nothing
  , parentId: Nothing
  , zIndex: Nothing
  , extent: Nothing
  , expandParent: false
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Just 50.0, height: Just 25.0 }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

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

runGraphParity :: Effect Unit
runGraphParity = do
  log "running graph-traversal parity properties (PSFlow vs live XYFlow)..."

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

  log "graph-traversal parity passed"
