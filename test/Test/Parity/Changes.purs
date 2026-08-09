-- | Live differential parity for `React.Store.Changes.applyNodeChanges` and
-- | `applyEdgeChanges` — the two functions a controlled flow calls on every
-- | interaction, and the only ones of the seven whose result depends on the
-- | *order* changes arrive in.
-- |
-- | Where the other parity modules generate an XYFlow-shaped input and a
-- | PSFlow-shaped one from a shared description, this one generates the PSFlow
-- | `NodeChange` / `EdgeChange` value and derives the oracle's carrier from it.
-- | The change types are sum types on one side and a `type` discriminant on
-- | the other, so a shared description would be a third encoding of the same
-- | thing — and the sum type is the one that cannot silently grow a case.
-- |
-- | Neither function does arithmetic: every number in the result was copied
-- | from an input. The comparison is therefore exact, not `epsilon`.
module Test.Parity.Changes
  ( runChangesParity
  ) where

import Prelude

import Data.Array (mapWithIndex) as Array
import Data.Array.NonEmpty as NEA
import Data.Int (toNumber) as Int
import Data.Maybe (Maybe(..))
import Data.Nullable (toMaybe, toNullable)
import Effect (Effect)
import Effect.Class.Console (log)
import React.Store.Changes (applyEdgeChanges, applyNodeChanges) as PS
import System.Types.Edge (EdgeBase, EdgeChange(..))
import System.Types.Geometry (Dimensions, XYPosition)
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeBase, NodeChange(..))
import Test.Oracle (OracleChangeEdge, OracleChangeNode, OracleEdgeChange, OracleNodeChange)
import Test.Oracle (applyEdgeChanges, applyNodeChanges, setAttributesArg) as Oracle
import Test.Parity.Fixtures (mkEdge, mkNode)
import Test.Parity.Util (falsify, strSeqMatch)
import Test.QuickCheck (Result, quickCheck)
import Test.QuickCheck.Gen (Gen, chooseInt, elements, vectorOf)

-- ─── Nodes ────────────────────────────────────────────────────────────────

unId :: NodeId -> String
unId (NodeId s) = s

-- | The node fields `applyChange` writes, plus the id it dispatches on. The
-- | oracle's `OracleChangeNode` names the same set, so it doubles as the
-- | generated description and as the projection both results land in.
toPSNode :: OracleChangeNode -> NodeBase Unit
toPSNode s = (mkNode s.id)
  { position = s.position
  , selected = s.selected
  , dragging = s.dragging
  , width = toMaybe s.width
  , height = toMaybe s.height
  , measured =
      { width: toMaybe s.measured.width
      , height: toMaybe s.measured.height
      }
  }

psNodeShape :: NodeBase Unit -> OracleChangeNode
psNodeShape n =
  { id: unId n.id
  , position: n.position
  , selected: n.selected
  , dragging: n.dragging
  , width: toNullable n.width
  , height: toNullable n.height
  , measured:
      { width: toNullable n.measured.width
      , height: toNullable n.measured.height
      }
  }

renderNode :: OracleChangeNode -> String
renderNode n =
  n.id
    <> "|" <> show n.position.x <> "," <> show n.position.y
    <> "|" <> show n.selected
    <> "|" <> show n.dragging
    <> "|" <> show (toMaybe n.width) <> "x" <> show (toMaybe n.height)
    <> "|" <> show (toMaybe n.measured.width) <> "x" <> show (toMaybe n.measured.height)

-- | The `OracleNodeChange` fields a given tag does not use. The JS side reads
-- | only the ones its branch names, so these are never seen — they exist
-- | because one record type carries all six constructors.
emptyNodeChange :: OracleNodeChange
emptyNodeChange =
  { tag: ""
  , id: ""
  , selected: false
  , position: toNullable (Nothing :: Maybe XYPosition)
  , dragging: false
  , dimensions: toNullable (Nothing :: Maybe Dimensions)
  , setAttributes: toNullable (Nothing :: Maybe String)
  , resizing: false
  , item: toNullable (Nothing :: Maybe OracleChangeNode)
  , index: toNullable (Nothing :: Maybe Int)
  }

-- | `NodeChange` → upstream's tagged change. `NodeAddChange` carries no id
-- | upstream either; the item's id goes in the carrier because the record has
-- | the field, and the JS side's `add` branch does not emit it.
toOracleNodeChange :: NodeChange Unit -> OracleNodeChange
toOracleNodeChange = case _ of
  NodeSelectionChange c ->
    emptyNodeChange { tag = "select", id = unId c.id, selected = c.selected }
  NodePositionChange c -> emptyNodeChange
    { tag = "position"
    , id = unId c.id
    , position = toNullable c.position
    , dragging = c.dragging
    }
  NodeDimensionChange c -> emptyNodeChange
    { tag = "dimensions"
    , id = unId c.id
    , dimensions = toNullable c.dimensions
    , setAttributes = Oracle.setAttributesArg c.setAttributes
    , resizing = c.resizing
    }
  NodeRemoveChange c -> emptyNodeChange { tag = "remove", id = unId c.id }
  NodeReplaceChange c -> emptyNodeChange
    { tag = "replace"
    , id = unId c.id
    , item = toNullable (Just (psNodeShape c.item))
    }
  NodeAddChange c -> emptyNodeChange
    { tag = "add"
    , id = unId c.item.id
    , item = toNullable (Just (psNodeShape c.item))
    , index = toNullable c.index
    }

-- ─── Edges ────────────────────────────────────────────────────────────────

toPSEdge :: OracleChangeEdge -> EdgeBase Unit
toPSEdge s = (mkEdge s.id "a" "b") { selected = s.selected, animated = s.animated }

psEdgeShape :: EdgeBase Unit -> OracleChangeEdge
psEdgeShape e = { id: e.id, selected: e.selected, animated: e.animated }

renderEdge :: OracleChangeEdge -> String
renderEdge e = e.id <> "|" <> show e.selected <> "|" <> show e.animated

emptyEdgeChange :: OracleEdgeChange
emptyEdgeChange =
  { tag: ""
  , id: ""
  , selected: false
  , item: toNullable (Nothing :: Maybe OracleChangeEdge)
  , index: toNullable (Nothing :: Maybe Int)
  }

toOracleEdgeChange :: EdgeChange Unit -> OracleEdgeChange
toOracleEdgeChange = case _ of
  EdgeSelectionChange c ->
    emptyEdgeChange { tag = "select", id = c.id, selected = c.selected }
  EdgeRemoveChange c -> emptyEdgeChange { tag = "remove", id = c.id }
  EdgeReplaceChange c -> emptyEdgeChange
    { tag = "replace", id = c.id, item = toNullable (Just (psEdgeShape c.item)) }
  EdgeAddChange c -> emptyEdgeChange
    { tag = "add"
    , id = c.item.id
    , item = toNullable (Just (psEdgeShape c.item))
    , index = toNullable c.index
    }

-- ─── Generators ───────────────────────────────────────────────────────────

-- | Ids come from a pool small enough that changes land on existing elements
-- | far more often than not — a change list that misses every element proves
-- | only that both sides can copy an array.
idPool :: Gen String
idPool = elements (NEA.cons' "a" [ "b", "c" ])

coin :: Gen Boolean
coin = elements (NEA.cons' true [ false ])

genCoord :: Gen Number
genCoord = Int.toNumber <$> chooseInt (-200) 200

genMaybeDimension :: Gen (Maybe Number)
genMaybeDimension = do
  present <- coin
  if present then Just <<< Int.toNumber <$> chooseInt 0 300 else pure Nothing

genNode :: Gen OracleChangeNode
genNode = do
  id <- idPool
  x <- genCoord
  y <- genCoord
  selected <- coin
  dragging <- coin
  width <- genMaybeDimension
  height <- genMaybeDimension
  measuredWidth <- genMaybeDimension
  measuredHeight <- genMaybeDimension
  pure
    { id
    , position: { x, y }
    , selected
    , dragging
    , width: toNullable width
    , height: toNullable height
    , measured:
        { width: toNullable measuredWidth
        , height: toNullable measuredHeight
        }
    }

-- | Distinct ids: upstream keys its change map by id, so two elements sharing
-- | one would make the result depend on which is looked up first rather than
-- | on the changes.
genNodes :: Gen (Array OracleChangeNode)
genNodes = do
  n <- chooseInt 0 3
  nodes <- vectorOf n genNode
  pure (Array.mapWithIndex (\i node -> node { id = "n" <> show i }) nodes)

-- | Targets an element that is present three times in four; the fourth is the
-- | branch where a change has nothing to apply to.
genTargetId :: Array String -> Gen String
genTargetId ids = do
  hit <- elements (NEA.cons' true [ true, true, false ])
  case NEA.fromArray ids, hit of
    Just present, true -> elements present
    _, _ -> idPool

-- | The four `setAttributes` values, including PSFlow's both-axes-off case —
-- | upstream's plain `false`, which its truthiness guard treats as absent.
genSetAttributes :: Gen (Maybe { width :: Boolean, height :: Boolean })
genSetAttributes = do
  present <- coin
  if not present then pure Nothing
  else do
    width <- coin
    height <- coin
    pure (Just { width, height })

genNodeChange :: Array OracleChangeNode -> Gen (NodeChange Unit)
genNodeChange nodes = do
  which <- chooseInt 0 5
  id <- genTargetId (map _.id nodes)
  case which of
    0 -> do
      selected <- coin
      pure (NodeSelectionChange { id: NodeId id, selected })
    1 -> do
      present <- elements (NEA.cons' true [ true, false ])
      x <- genCoord
      y <- genCoord
      dragging <- coin
      pure
        ( NodePositionChange
            { id: NodeId id
            , position: if present then Just { x, y } else Nothing
            -- Upstream's `applyChange` never reads `positionAbsolute`; it is
            -- the store's business, not this function's.
            , positionAbsolute: Nothing
            , dragging
            }
        )
    2 -> do
      present <- elements (NEA.cons' true [ true, false ])
      width <- Int.toNumber <$> chooseInt 0 300
      height <- Int.toNumber <$> chooseInt 0 300
      setAttributes <- genSetAttributes
      resizing <- coin
      pure
        ( NodeDimensionChange
            { id: NodeId id
            , dimensions: if present then Just { width, height } else Nothing
            , resizing
            , setAttributes
            }
        )
    3 -> pure (NodeRemoveChange { id: NodeId id })
    4 -> do
      item <- genNode
      pure (NodeReplaceChange { id: NodeId id, item: toPSNode (item { id = id }) })
    _ -> do
      item <- genNode
      index <- genIndex
      pure (NodeAddChange { item: toPSNode item, index })

-- | `add` with an index splices; without one it appends. Indices reach past
-- | the end of a three-element array, where `splice` clamps.
genIndex :: Gen (Maybe Int)
genIndex = do
  present <- coin
  if present then Just <$> chooseInt 0 4 else pure Nothing

genNodeChanges :: Array OracleChangeNode -> Gen (Array (NodeChange Unit))
genNodeChanges nodes = do
  n <- chooseInt 0 4
  vectorOf n (genNodeChange nodes)

genEdge :: Gen OracleChangeEdge
genEdge = do
  id <- idPool
  selected <- coin
  animated <- coin
  pure { id, selected, animated }

genEdges :: Gen (Array OracleChangeEdge)
genEdges = do
  n <- chooseInt 0 3
  edges <- vectorOf n genEdge
  pure (Array.mapWithIndex (\i e -> e { id = "e" <> show i }) edges)

genEdgeChange :: Array OracleChangeEdge -> Gen (EdgeChange Unit)
genEdgeChange edges = do
  which <- chooseInt 0 3
  id <- genTargetId (map _.id edges)
  case which of
    0 -> do
      selected <- coin
      pure (EdgeSelectionChange { id, selected })
    1 -> pure (EdgeRemoveChange { id })
    2 -> do
      item <- genEdge
      pure (EdgeReplaceChange { id, item: toPSEdge (item { id = id }) })
    _ -> do
      item <- genEdge
      index <- genIndex
      pure (EdgeAddChange { item: toPSEdge item, index })

genEdgeChanges :: Array OracleChangeEdge -> Gen (Array (EdgeChange Unit))
genEdgeChanges edges = do
  n <- chooseInt 0 4
  vectorOf n (genEdgeChange edges)

-- ─── Comparison ───────────────────────────────────────────────────────────
--
-- The failure context carries the change list, rendered off the oracle carrier
-- so one renderer describes what both sides were asked to do. Order is the
-- whole subject here — a diff of two element arrays with the changes withheld
-- says which elements ended up different but not which change did it.

renderNodeChange :: OracleNodeChange -> String
renderNodeChange c = case c.tag of
  "select" -> "select(" <> c.id <> ", " <> show c.selected <> ")"
  "position" ->
    "position(" <> c.id <> ", " <> show (map renderXY (toMaybe c.position))
      <> ", dragging=" <> show c.dragging <> ")"
  "dimensions" ->
    "dimensions(" <> c.id <> ", "
      <> show (map (\d -> show d.width <> "x" <> show d.height) (toMaybe c.dimensions))
      <> ", setAttributes=" <> show (toMaybe c.setAttributes)
      <> ", resizing=" <> show c.resizing <> ")"
  "remove" -> "remove(" <> c.id <> ")"
  "replace" -> "replace(" <> c.id <> ", " <> show (map renderNode (toMaybe c.item)) <> ")"
  "add" ->
    "add(" <> show (map renderNode (toMaybe c.item))
      <> ", index=" <> show (toMaybe c.index) <> ")"
  other -> other <> "(?)"
  where
  renderXY p = show p.x <> "," <> show p.y

renderEdgeChange :: OracleEdgeChange -> String
renderEdgeChange c = case c.tag of
  "select" -> "select(" <> c.id <> ", " <> show c.selected <> ")"
  "remove" -> "remove(" <> c.id <> ")"
  "replace" -> "replace(" <> c.id <> ", " <> show (map renderEdge (toMaybe c.item)) <> ")"
  "add" ->
    "add(" <> show (map renderEdge (toMaybe c.item))
      <> ", index=" <> show (toMaybe c.index) <> ")"
  other -> other <> "(?)"

nodesMatch
  :: String
  -> Array OracleNodeChange
  -> Array (NodeBase Unit)
  -> Array OracleChangeNode
  -> Result
nodesMatch label changes ps xy =
  strSeqMatch (label <> " applying " <> show (map renderNodeChange changes))
    (map (renderNode <<< psNodeShape) ps)
    (map renderNode xy)

edgesMatch
  :: String
  -> Array OracleEdgeChange
  -> Array (EdgeBase Unit)
  -> Array OracleChangeEdge
  -> Result
edgesMatch label changes ps xy =
  strSeqMatch (label <> " applying " <> show (map renderEdgeChange changes))
    (map (renderEdge <<< psEdgeShape) ps)
    (map renderEdge xy)

runChangesParity :: Effect Unit
runChangesParity = do
  log "running change-application parity properties (PSFlow vs live XYFlow)..."

  quickCheck do
    nodes <- genNodes
    changes <- genNodeChanges nodes
    let carried = map toOracleNodeChange changes
    pure
      ( nodesMatch "applyNodeChanges" carried
          (PS.applyNodeChanges changes (map toPSNode nodes))
          (Oracle.applyNodeChanges carried nodes)
      )

  quickCheck do
    edges <- genEdges
    changes <- genEdgeChanges edges
    let carried = map toOracleEdgeChange changes
    pure
      ( edgesMatch "applyEdgeChanges" carried
          (PS.applyEdgeChanges changes (map toPSEdge edges))
          (Oracle.applyEdgeChanges carried edges)
      )

  -- Falsification probes.
  falsify "applyNodeChanges: XYFlow given the opposite selection"
    ( let
        nodes = [ plainNode "n0" ]
        select v = [ NodeSelectionChange { id: NodeId "n0", selected: v } ]
      in
        nodesMatch "applyNodeChanges probe" (map toOracleNodeChange (select false))
          (PS.applyNodeChanges (select true) (map toPSNode nodes))
          (Oracle.applyNodeChanges (map toOracleNodeChange (select false)) nodes)
    )

  falsify "applyNodeChanges: XYFlow given the add change PSFlow was denied"
    ( let
        nodes = [ plainNode "n0" ]
        add = [ NodeAddChange { item: toPSNode (plainNode "n1"), index: Nothing } ]
      in
        nodesMatch "applyNodeChanges probe" (map toOracleNodeChange add)
          (PS.applyNodeChanges [] (map toPSNode nodes))
          (Oracle.applyNodeChanges (map toOracleNodeChange add) nodes)
    )

  falsify "applyEdgeChanges: XYFlow given a remove where PSFlow got a select"
    ( let
        edges = [ plainEdge "e0" ]
        select = [ EdgeSelectionChange { id: "e0", selected: true } ]
        remove = [ EdgeRemoveChange { id: "e0" } ]
      in
        edgesMatch "applyEdgeChanges probe" (map toOracleEdgeChange remove)
          (PS.applyEdgeChanges select (map toPSEdge edges))
          (Oracle.applyEdgeChanges (map toOracleEdgeChange remove) edges)
    )

  log "change-application parity passed"

plainNode :: String -> OracleChangeNode
plainNode id =
  { id
  , position: { x: 0.0, y: 0.0 }
  , selected: false
  , dragging: false
  , width: toNullable (Just 50.0)
  , height: toNullable (Just 25.0)
  , measured: { width: toNullable (Just 50.0), height: toNullable (Just 25.0) }
  }

plainEdge :: String -> OracleChangeEdge
plainEdge id = { id, selected: false, animated: false }
