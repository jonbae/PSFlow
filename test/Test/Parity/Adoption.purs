-- | Live differential parity for `System.Utils.Store.adoptUserNodes`, which
-- | turns the consumer's nodes into the internal nodes everything after
-- | adoption reads.
-- |
-- | Each property generates a forest of user nodes and adopts it twice into
-- | the same lookups, as the store adopts every `setNodes`. The second round
-- | hands back some first-round nodes unchanged, so `checkEquality` reuses
-- | their internal nodes, and rebuilds the rest. After each round, both sides
-- | report every internal node's absolute position, `z`, `rootParentIndex`
-- | and handle bounds, the parent lookup, and the two flags adoption returns.
-- |
-- | Two upstream changes are what this holds:
-- |
-- | * **#5515** reads each static handle's `id` into its handle bounds. The
-- |   handles carry absent, `null`, empty and named ids.
-- | * **#5550** raises each root parent above the ones adopted before it, by
-- |   `rootParentIndex × 10`, under `zIndexMode: 'auto'`, so the children of
-- |   different parents don't interleave. The forests have several root
-- |   parents, children in any order, and grandchildren, and they're adopted
-- |   under all three `zIndexMode`s.
module Test.Parity.Adoption
  ( runAdoptionParity
  ) where

import Prelude

import Data.Array (fromFoldable, length, mapWithIndex, range, snoc, sortWith, unsafeIndex) as Array
import Data.Array.NonEmpty as NEA
import Data.Either (Either(..), either)
import Data.Foldable (foldM)
import Data.Int (toNumber) as Int
import Data.Map (empty, toUnfoldable, values) as Map
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.Newtype (unwrap)
import Data.Nullable (toNullable)
import Data.String (Pattern(..), stripPrefix)
import Data.Traversable (sequence)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafePartial)
import System.Types.Connection (ZIndexMode(..))
import System.Types.Geometry (Position(..), XYPosition, mkNodeOrigin)
import System.Types.Handle (Handle, HandleIdField(..), HandleType(..), unSourceHandle, unTargetHandle)
import System.Types.Ids (ParentId(..))
import System.Types.Node (InternalNodeBase, NodeBase, NodeExtent(..), NodeHandle, NodeLookup, ParentLookup)
import System.Utils.Store (UpdateNodesOptions, adoptUserNodes, defaultUpdateNodesOptions) as PS
import Test.Oracle (AdoptedHandle, AdoptedNode, Adoption, OracleAdoptNode, OracleAdoptOptions, OracleNodeHandle)
import Test.Oracle (adoptUserNodes) as Oracle
import Test.Parity.Builders (mkNode)
import Test.Parity.Util (expectGreen, falsify, strMatch)
import Test.QuickCheck (Result, quickCheck')
import Test.QuickCheck.Gen (Gen, chooseInt, elements, frequency, vectorOf)

-- | `JSON.stringify` with every object's keys sorted, so two results compare
-- | as strings whichever order their members were written in.
foreign import canonicalJson :: forall a. a -> String

-- ─── Descriptions ─────────────────────────────────────────────────────────

-- | `id` uses `OracleNodeHandle`'s tags: `"unset"`, `"null"` or `"set:<id>"`.
type HandleSpec =
  { id :: String
  , handleType :: HandleType
  , position :: Position
  , x :: Number
  , y :: Number
  , width :: Maybe Number
  , height :: Maybe Number
  }

type NodeSpec =
  { id :: String
  , position :: XYPosition
  , parentId :: Maybe String
  , zIndex :: Maybe Int
  , selected :: Maybe Boolean
  , hidden :: Maybe Boolean
  , extentParent :: Boolean
  , measured :: Boolean
  , handles :: Maybe (Array HandleSpec)
  }

type Options =
  { nodeOrigin :: Tuple Number Number
  , elevateNodesOnSelect :: Boolean
  , zIndexMode :: ZIndexMode
  }

-- | A second round. `Left i` hands back the first round's node `i` itself,
-- | and `Right` builds a node afresh, as `applyNodeChanges` does for a node
-- | that changed.
type Round2 = Array (Either Int NodeSpec)

-- ─── PSFlow side ──────────────────────────────────────────────────────────

handleIdField :: String -> HandleIdField
handleIdField = case _ of
  "unset" -> HandleIdUnset
  "null" -> HandleIdNull
  tag -> HandleIdSet (fromMaybe tag (stripPrefix (Pattern "set:") tag))

handleIdTag :: HandleIdField -> String
handleIdTag = case _ of
  HandleIdUnset -> "unset"
  HandleIdNull -> "null"
  HandleIdSet s -> "set:" <> s

toPSHandle :: HandleSpec -> NodeHandle
toPSHandle h =
  { id: handleIdField h.id
  , x: h.x
  , y: h.y
  , position: h.position
  , handleType: h.handleType
  , width: h.width
  , height: h.height
  }

toPSNode :: NodeSpec -> NodeBase Unit
toPSNode s = (mkNode s.id)
  { position = s.position
  , parentId = map ParentId s.parentId
  , zIndex = s.zIndex
  , selected = s.selected
  , hidden = s.hidden
  , extent = if s.extentParent then Just ParentExtent else Nothing
  , width = Nothing
  , height = Nothing
  , measured =
      if s.measured then { width: Just 50.0, height: Just 25.0 }
      else { width: Nothing, height: Nothing }
  , handles = map (map toPSHandle) s.handles
  }

psOptions :: Options -> PS.UpdateNodesOptions Unit
psOptions o = PS.defaultUpdateNodesOptions
  { nodeOrigin = case o.nodeOrigin of Tuple x y -> mkNodeOrigin x y
  , elevateNodesOnSelect = o.elevateNodesOnSelect
  , zIndexMode = o.zIndexMode
  }

posStr :: Position -> String
posStr = case _ of
  PosLeft -> "left"
  PosTop -> "top"
  PosRight -> "right"
  PosBottom -> "bottom"

typeStr :: HandleType -> String
typeStr = case _ of
  Source -> "source"
  Target -> "target"

adoptedHandle :: Handle -> AdoptedHandle
adoptedHandle h =
  { id: handleIdTag h.id
  , nodeId: unwrap h.nodeId
  , type: typeStr h.handleType
  , position: posStr h.position
  , x: h.x
  , y: h.y
  , width: h.width
  , height: h.height
  }

adoptedNode :: InternalNodeBase Unit -> AdoptedNode
adoptedNode node =
  { id: unwrap node.id
  , x: node.internals.positionAbsolute.x
  , y: node.internals.positionAbsolute.y
  , z: node.internals.z
  , rootParentIndex: toNullable node.internals.rootParentIndex
  , handleBounds: toNullable
      ( map
          ( \hb ->
              { source: toNullable (map (map (adoptedHandle <<< unSourceHandle)) hb.source)
              , target: toNullable (map (map (adoptedHandle <<< unTargetHandle)) hb.target)
              }
          )
          node.internals.handleBounds
      )
  }

psAdoption
  :: { nodeLookup :: NodeLookup Unit
     , parentLookup :: ParentLookup Unit
     , nodesInitialized :: Boolean
     , hasSelectedNodes :: Boolean
     }
  -> Adoption
psAdoption r =
  { nodes: Array.sortWith _.id (map adoptedNode (Array.fromFoldable (Map.values r.nodeLookup)))
  , parents: Array.sortWith _.parentId (map parent (Map.toUnfoldable r.parentLookup))
  , nodesInitialized: r.nodesInitialized
  , hasSelectedNodes: r.hasSelectedNodes
  }
  where
  parent (Tuple pid children) =
    { parentId: unwrap pid
    , children: map (\(Tuple nid _) -> unwrap nid) (Map.toUnfoldable children :: Array _)
    }

-- | Adopt the first round into empty lookups and the second into what the
-- | first left.
psRounds :: Options -> Array (NodeBase Unit) -> Array (NodeBase Unit) -> Array Adoption
psRounds o first second =
  let
    opts = psOptions o
    r1 = PS.adoptUserNodes first Map.empty Map.empty opts
    r2 = PS.adoptUserNodes second r1.nodeLookup r1.parentLookup opts
  in
    [ psAdoption r1, psAdoption r2 ]

-- ─── Upstream side ────────────────────────────────────────────────────────

toOracleHandle :: HandleSpec -> OracleNodeHandle
toOracleHandle h =
  { id: h.id
  , type: typeStr h.handleType
  , position: posStr h.position
  , x: h.x
  , y: h.y
  , width: toNullable h.width
  , height: toNullable h.height
  }

toOracleNode :: NodeSpec -> OracleAdoptNode
toOracleNode s =
  { id: s.id
  , position: s.position
  , parentId: toNullable s.parentId
  , zIndex: toNullable s.zIndex
  , selected: toNullable s.selected
  , hidden: toNullable s.hidden
  , extentParent: s.extentParent
  , measured: toNullable (if s.measured then Just { width: 50.0, height: 25.0 } else Nothing)
  , handles: toNullable (map (map toOracleHandle) s.handles)
  }

oracleOptions :: Options -> OracleAdoptOptions
oracleOptions o =
  { nodeOrigin: case o.nodeOrigin of Tuple x y -> [ x, y ]
  , elevateNodesOnSelect: o.elevateNodesOnSelect
  , zIndexMode: case o.zIndexMode of
      ZBasic -> "basic"
      ZAuto -> "auto"
      ZManual -> "manual"
  }

-- ─── The comparison ───────────────────────────────────────────────────────

-- | Build both sides' nodes from one description, each once, so a second
-- | round's `Left i` is the very node the first round adopted, on both sides.
adoptBoth
  :: Options
  -> Array NodeSpec
  -> Round2
  -> { ps :: Array Adoption, xy :: Array Adoption }
adoptBoth o first second =
  let
    ps1 = map toPSNode first
    xy1 = map toOracleNode first
    from :: forall a. Array a -> (NodeSpec -> a) -> Either Int NodeSpec -> a
    from earlier build = either (\i -> unsafePartial (Array.unsafeIndex earlier i)) build
  in
    { ps: psRounds o ps1 (map (from ps1 toPSNode) second)
    , xy: Oracle.adoptUserNodes (oracleOptions o) [ xy1, map (from xy1 toOracleNode) second ]
    }

describe :: Options -> Array NodeSpec -> Round2 -> String
describe o first second =
  "adoptUserNodes under " <> canonicalJson (oracleOptions o)
    <> "\n  round 1: " <> canonicalJson (map toOracleNode first)
    <> "\n  round 2: "
    <> canonicalJson (map (either (\i -> "reuse " <> show i) (canonicalJson <<< toOracleNode)) second)

adoptionsMatch :: Options -> Array NodeSpec -> Round2 -> Result
adoptionsMatch o first second =
  let r = adoptBoth o first second
  in strMatch (describe o first second) (canonicalJson r.ps) (canonicalJson r.xy)

-- ─── Generators ───────────────────────────────────────────────────────────

maybeOf :: forall a. Gen a -> Gen (Maybe a)
maybeOf g = frequency (NEA.cons' (Tuple 1.0 (pure Nothing)) [ Tuple 1.0 (Just <$> g) ])

smallNumber :: Gen Number
smallNumber = Int.toNumber <$> chooseInt (-40) 120

genHandle :: Gen HandleSpec
genHandle = do
  id <- elements (NEA.cons' "unset" [ "null", "set:", "set:a", "set:b" ])
  handleType <- elements (NEA.cons' Source [ Target ])
  position <- elements (NEA.cons' PosLeft [ PosTop, PosRight, PosBottom ])
  x <- smallNumber
  y <- smallNumber
  width <- maybeOf (Int.toNumber <$> chooseInt 1 40)
  height <- maybeOf (Int.toNumber <$> chooseInt 1 40)
  pure { id, handleType, position, x, y, width, height }

-- | A node whose parent, if it has one, comes earlier in the array, as
-- | upstream requires.
genNode :: Array String -> String -> Gen NodeSpec
genNode earlier id = do
  parentId <- case NEA.fromArray earlier of
    Nothing -> pure Nothing
    Just ids -> frequency (NEA.cons' (Tuple 2.0 (pure Nothing)) [ Tuple 3.0 (Just <$> elements ids) ])
  x <- smallNumber
  y <- smallNumber
  zIndex <- frequency
    (NEA.cons' (Tuple 3.0 (pure Nothing)) [ Tuple 2.0 (Just <$> elements (NEA.cons' (-1) [ 0, 2, 5 ])) ])
  selected <- elements (NEA.cons' Nothing [ Just false, Just true ])
  hidden <- frequency (NEA.cons' (Tuple 4.0 (pure Nothing)) [ Tuple 1.0 (pure (Just true)) ])
  extentParent <-
    if isJust parentId then frequency (NEA.cons' (Tuple 4.0 (pure false)) [ Tuple 1.0 (pure true) ])
    else pure false
  measured <- frequency (NEA.cons' (Tuple 3.0 (pure true)) [ Tuple 1.0 (pure false) ])
  handles <- maybeOf do
    n <- chooseInt 0 3
    vectorOf n genHandle
  pure { id, position: { x, y }, parentId, zIndex, selected, hidden, extentParent, measured, handles }

genForest :: Gen (Array NodeSpec)
genForest = do
  n <- chooseInt 1 7
  foldM
    (\acc i -> Array.snoc acc <$> genNode (map _.id acc) ("n" <> show i))
    []
    (Array.range 0 (n - 1))

-- | Rebuild a node as a consumer's change would: a new object, moved or
-- | reselected, or neither.
rebuild :: NodeSpec -> Gen NodeSpec
rebuild s = do
  dx <- elements (NEA.cons' 0.0 [ 10.0, -25.0 ])
  selected <- elements (NEA.cons' s.selected [ Just true, Just false ])
  pure s { position = { x: s.position.x + dx, y: s.position.y }, selected = selected }

genRound2 :: Array NodeSpec -> Gen Round2
genRound2 first = do
  kept <- sequence
    ( Array.mapWithIndex
        (\i s -> frequency (NEA.cons' (Tuple 1.0 (pure (Left i))) [ Tuple 1.0 (Right <$> rebuild s) ]))
        first
    )
  added <- frequency
    ( NEA.cons' (Tuple 2.0 (pure []))
        [ Tuple 1.0 (pure <<< Right <$> genNode (map _.id first) ("n" <> show (Array.length first))) ]
    )
  pure (kept <> added)

genOptions :: Gen Options
genOptions = do
  nodeOrigin <- elements (NEA.cons' (Tuple 0.0 0.0) [ Tuple 0.5 0.5, Tuple 1.0 0.0 ])
  elevateNodesOnSelect <- elements (NEA.cons' true [ false ])
  zIndexMode <- elements (NEA.cons' ZBasic [ ZAuto, ZManual ])
  pure { nodeOrigin, elevateNodesOnSelect, zIndexMode }

-- ─── Fixed witnesses ──────────────────────────────────────────────────────

node :: String -> NodeSpec
node id =
  { id
  , position: { x: 0.0, y: 0.0 }
  , parentId: Nothing
  , zIndex: Nothing
  , selected: Nothing
  , hidden: Nothing
  , extentParent: false
  , measured: true
  , handles: Nothing
  }

childOf :: String -> String -> NodeSpec
childOf parent id = (node id) { parentId = Just parent }

-- | Two root parents whose children arrive interleaved, and a grandchild:
-- | under `'auto'`, `p2` takes `rootParentIndex` 1 because its child comes
-- | first, and `p1` takes 2.
subflows :: Array NodeSpec
subflows =
  [ node "p1", node "p2", childOf "p2" "c2", childOf "p1" "c1", childOf "c1" "g1" ]

auto :: Options
auto = { nodeOrigin: Tuple 0.0 0.0, elevateNodesOnSelect: true, zIndexMode: ZAuto }

-- | A node with a named and an unnamed handle on each side.
handled :: NodeSpec
handled = (node "h")
  { handles = Just
      [ { id: "set:a", handleType: Source, position: PosRight, x: 40.0, y: 10.0, width: Just 8.0, height: Nothing }
      , { id: "unset", handleType: Target, position: PosLeft, x: 0.0, y: 10.0, width: Nothing, height: Nothing }
      ]
  }

-- ─── Run ──────────────────────────────────────────────────────────────────

runAdoptionParity :: Effect Unit
runAdoptionParity = do
  log "running adoption parity properties (PSFlow vs live XYFlow)..."

  expectGreen "adoptUserNodes: interleaved subflows under 'auto', every root parent kept"
    (adoptionsMatch auto subflows (Array.mapWithIndex (\i _ -> Left i) subflows))
  expectGreen "adoptUserNodes: interleaved subflows under 'auto', every node rebuilt"
    (adoptionsMatch auto subflows (map Right subflows))
  expectGreen "adoptUserNodes: interleaved subflows under 'auto', the root parents rebuilt"
    (adoptionsMatch auto subflows [ Right (node "p1"), Right (node "p2"), Left 2, Left 3, Left 4 ])
  expectGreen "adoptUserNodes: static handles keep their ids"
    (adoptionsMatch auto [ handled ] [ Right handled ])

  quickCheck' 300 do
    o <- genOptions
    first <- genForest
    second <- genRound2 first
    pure (adoptionsMatch o first second)

  falsify "adoptUserNodes: XYFlow adopts under 'auto', PSFlow under 'basic'"
    ( let
        r = adoptBoth auto subflows (map Right subflows)
        basic = adoptBoth auto { zIndexMode = ZBasic } subflows (map Right subflows)
      in
        strMatch "zIndexMode" (canonicalJson basic.ps) (canonicalJson r.xy)
    )
  falsify "adoptUserNodes: XYFlow's source handle named, PSFlow's unnamed"
    ( let
        unnamed = handled
          { handles = map (map (\h -> h { id = "unset" })) handled.handles }
        r = adoptBoth auto [ handled ] []
        bare = adoptBoth auto [ unnamed ] []
      in
        strMatch "handle id" (canonicalJson bare.ps) (canonicalJson r.xy)
    )

  log "adoption parity passed"
