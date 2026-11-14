-- | Live differential parity for `System.Utils.Graph.getInternalNodesBounds`
-- | and `getNodesInside`, which read the store's internal nodes for
-- | `<NodesSelection />`, `<MiniMap />`, `<NodeToolbar />`, the pane's
-- | selection rectangle and `onlyRenderVisibleElements`.
-- |
-- | Each property builds both sides' internal nodes from one description, as
-- | `Test.Parity.Adoption` does: each side adopts its own user nodes. The
-- | description adds the members these two read beyond adoption's: every rung
-- | of the dimension fallback, `selectable` and `dragging`. Positions include
-- | `-0` and `NaN`, and a rect is compared member by member as `Object.is`
-- | compares numbers.
-- |
-- | Upstream's `getNodesInside` iterates the `nodeLookup` it's handed. The
-- | PSFlow side hands its port the array `orderedInternalNodes` builds, as
-- | every PSFlow caller does, and the ids each side returns are compared in
-- | order. The generated ids are shuffled, so the lookup's order isn't the
-- | ids' sorted order.
module Test.Parity.InternalNodes
  ( runInternalNodesParity
  ) where

import Prelude

import Data.Array (catMaybes, elem, range, reverse, snoc, zipWith) as Array
import Data.Array.NonEmpty as NEA
import Data.Foldable (foldM)
import Data.Int (toNumber) as Int
import Data.Map (empty) as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Newtype (unwrap)
import Data.Nullable (toNullable)
import Data.Number (nan)
import Data.Traversable (traverse)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Class.Console (log)
import System.Types.Connection (ZIndexMode(..))
import System.Types.Geometry (Rect, mkTransform)
import System.Types.Node (InternalNodeBase, NodeBase, NodeLookup)
import System.Utils.Graph (getInternalNodesBounds, getNodesInside, orderedInternalNodes) as PS
import System.Utils.Store (adoptUserNodes) as PS
import Test.Oracle (OracleBoundsFilter, OracleNodesInsideArgs, OracleSizedNode)
import Test.Oracle (getInternalNodesBounds, getNodesInside) as Oracle
import Test.Parity.Adoption (NodeSpec, Options, genNode, genOptions, node, oracleOptions, psOptions, toOracleNode, toPSNode)
import Test.Parity.Util (expectGreen, falsify, strMatch, strSeqMatch)
import Test.QuickCheck (Result, arbitrary, quickCheck')
import Test.QuickCheck.Gen (Gen, chooseInt, elements, frequency, shuffle)

foreign import exactNumber :: Number -> String
foreign import exactJson :: forall a. a -> String

-- ─── Descriptions ─────────────────────────────────────────────────────────

-- | `node.measured` is ignored: `measured` replaces it, member by member.
type SizedSpec =
  { node :: NodeSpec
  , measured :: { width :: Maybe Number, height :: Maybe Number }
  , width :: Maybe Number
  , height :: Maybe Number
  , initialWidth :: Maybe Number
  , initialHeight :: Maybe Number
  , selectable :: Maybe Boolean
  , dragging :: Maybe Boolean
  }

-- | `Selected` is `<NodesSelection />`'s filter and `Visible` is
-- | `<MiniMap />`'s. `Omitted` passes none, as `<NodeToolbar />` does.
data BoundsFilter = Omitted | Selected | Visible | Ids (Array String)

-- | A `Nothing` argument is one upstream's caller leaves out, so upstream's
-- | default applies.
type InsideArgs =
  { rect :: Rect
  , transform :: Maybe { tx :: Number, ty :: Number, scale :: Number }
  , partially :: Maybe Boolean
  , excludeNonSelectable :: Maybe Boolean
  }

-- ─── PSFlow side ──────────────────────────────────────────────────────────

toPS :: SizedSpec -> NodeBase Unit
toPS s = (toPSNode s.node)
  { measured = s.measured
  , width = s.width
  , height = s.height
  , initialWidth = s.initialWidth
  , initialHeight = s.initialHeight
  , selectable = s.selectable
  , dragging = s.dragging
  }

adoptedLookup :: Options -> Array (NodeBase Unit) -> NodeLookup Unit
adoptedLookup o users = (PS.adoptUserNodes users Map.empty Map.empty (psOptions o)).nodeLookup

psFilter :: BoundsFilter -> Maybe (InternalNodeBase Unit -> Boolean)
psFilter = case _ of
  Omitted -> Nothing
  Selected -> Just \n -> n.selected == Just true
  Visible -> Just \n -> n.hidden /= Just true
  Ids ids -> Just \n -> Array.elem (unwrap n.id) ids

psBounds :: Options -> Array SizedSpec -> BoundsFilter -> Rect
psBounds o specs f = PS.getInternalNodesBounds (adoptedLookup o (map toPS specs)) (psFilter f)

-- | Upstream's defaults are `[0, 0, 1]`, `false` and `false`. Every PSFlow
-- | caller passes all three.
psInside :: Options -> Array SizedSpec -> InsideArgs -> Array String
psInside o specs a =
  let
    users = map toPS specs
    t = fromMaybe { tx: 0.0, ty: 0.0, scale: 1.0 } a.transform
  in
    map (unwrap <<< _.id)
      ( PS.getNodesInside (PS.orderedInternalNodes users (adoptedLookup o users)) a.rect
          (mkTransform t.tx t.ty t.scale)
          { partially: fromMaybe false a.partially
          , excludeNonSelectable: fromMaybe false a.excludeNonSelectable
          }
      )

-- ─── Upstream side ────────────────────────────────────────────────────────

toOracle :: SizedSpec -> OracleSizedNode
toOracle s =
  { node: toOracleNode s.node
  , measured: { width: toNullable s.measured.width, height: toNullable s.measured.height }
  , width: toNullable s.width
  , height: toNullable s.height
  , initialWidth: toNullable s.initialWidth
  , initialHeight: toNullable s.initialHeight
  , selectable: toNullable s.selectable
  , dragging: toNullable s.dragging
  }

oracleFilter :: BoundsFilter -> OracleBoundsFilter
oracleFilter = case _ of
  Omitted -> { kind: "omitted", ids: [] }
  Selected -> { kind: "selected", ids: [] }
  Visible -> { kind: "visible", ids: [] }
  Ids ids -> { kind: "ids", ids }

oracleInsideArgs :: InsideArgs -> OracleNodesInsideArgs
oracleInsideArgs a =
  { rect: a.rect
  , transform: toNullable (map (\t -> [ t.tx, t.ty, t.scale ]) a.transform)
  , partially: toNullable a.partially
  , excludeNonSelectable: toNullable a.excludeNonSelectable
  }

xyBounds :: Options -> Array SizedSpec -> BoundsFilter -> Rect
xyBounds o specs f = Oracle.getInternalNodesBounds (oracleOptions o) (map toOracle specs) (oracleFilter f)

xyInside :: Options -> Array SizedSpec -> InsideArgs -> Array String
xyInside o specs a = Oracle.getNodesInside (oracleOptions o) (map toOracle specs) (oracleInsideArgs a)

-- ─── The comparison ───────────────────────────────────────────────────────

exactRect :: Rect -> String
exactRect r =
  "{ x: " <> exactNumber r.x <> ", y: " <> exactNumber r.y
    <> ", width: " <> exactNumber r.width <> ", height: " <> exactNumber r.height <> " }"

describeNodes :: Options -> Array SizedSpec -> String
describeNodes o specs =
  "adopted under " <> exactJson (oracleOptions o)
    <> "\n  nodes: " <> exactJson (map toOracle specs)

describeFilter :: BoundsFilter -> String
describeFilter f = exactJson (oracleFilter f)

boundsMatch :: Options -> Array SizedSpec -> BoundsFilter -> Result
boundsMatch o specs f =
  strMatch ("getInternalNodesBounds, filter " <> describeFilter f <> ", " <> describeNodes o specs)
    (exactRect (psBounds o specs f))
    (exactRect (xyBounds o specs f))

insideMatch :: Options -> Array SizedSpec -> InsideArgs -> Result
insideMatch o specs a =
  strSeqMatch ("getNodesInside " <> exactJson (oracleInsideArgs a) <> ", " <> describeNodes o specs)
    (psInside o specs a)
    (xyInside o specs a)

-- ─── Generators ───────────────────────────────────────────────────────────

maybeOf :: forall a. Gen a -> Gen (Maybe a)
maybeOf g = frequency (NEA.cons' (Tuple 1.0 (pure Nothing)) [ Tuple 1.0 (Just <$> g) ])

-- | A coordinate, now and then `0`, `-0` or `NaN`: `Math.min` and `Math.max`
-- | put `-0` below `0` and keep a `NaN`.
genCoordinate :: Gen Number
genCoordinate = frequency
  ( NEA.cons' (Tuple 14.0 (Int.toNumber <$> chooseInt (-40) 160))
      [ Tuple 2.0 (pure 0.0), Tuple 2.0 (pure (-0.0)), Tuple 0.3 (pure nan) ]
  )

genLength :: Gen Number
genLength = elements (NEA.cons' 0.0 [ 10.0, 12.5, 25.0, 40.0, 60.0 ])

-- | Adoption's node, at a generated coordinate, with every dimension rung,
-- | `selectable` and `dragging` drawn independently.
genSized :: Array String -> String -> Gen SizedSpec
genSized earlier id = do
  base <- genNode earlier id
  x <- genCoordinate
  y <- genCoordinate
  measuredWidth <- maybeOf genLength
  measuredHeight <- maybeOf genLength
  width <- maybeOf genLength
  height <- maybeOf genLength
  initialWidth <- maybeOf genLength
  initialHeight <- maybeOf genLength
  selectable <- elements (NEA.cons' Nothing [ Just true, Just false ])
  dragging <- frequency
    (NEA.cons' (Tuple 3.0 (pure Nothing)) [ Tuple 1.0 (pure (Just false)), Tuple 1.0 (pure (Just true)) ])
  pure
    { node: base { position = { x, y } }
    , measured: { width: measuredWidth, height: measuredHeight }
    , width
    , height
    , initialWidth
    , initialHeight
    , selectable
    , dragging
    }

-- | Up to eight nodes, each parent before its children, under shuffled ids.
genNodes :: Gen (Array SizedSpec)
genNodes = do
  n <- chooseInt 0 8
  ids <- shuffle [ "a", "b", "c", "d", "e", "f", "g", "h" ]
  if n == 0 then pure []
  else foldM
    (\acc id -> Array.snoc acc <$> genSized (map _.node.id acc) id)
    []
    (Array.zipWith const ids (Array.range 1 n))

-- | Each node's id kept or not, and an id no node has.
genFilter :: Array SizedSpec -> Gen BoundsFilter
genFilter specs = do
  kept <- traverse (\s -> map (\keep -> if keep then Just s.node.id else Nothing) arbitrary) specs
  frequency
    ( NEA.cons' (Tuple 1.0 (pure Omitted))
        [ Tuple 1.0 (pure Selected)
        , Tuple 1.0 (pure Visible)
        , Tuple 1.0 (pure (Ids (Array.snoc (Array.catMaybes kept) "absent")))
        ]
    )

genInsideArgs :: Gen InsideArgs
genInsideArgs = do
  x <- Int.toNumber <$> chooseInt (-80) 200
  y <- Int.toNumber <$> chooseInt (-80) 200
  width <- Int.toNumber <$> chooseInt 0 320
  height <- Int.toNumber <$> chooseInt 0 320
  transform <- frequency
    ( NEA.cons' (Tuple 1.0 (pure Nothing))
        [ Tuple 4.0 do
            tx <- Int.toNumber <$> chooseInt (-60) 60
            ty <- Int.toNumber <$> chooseInt (-60) 60
            scale <- elements (NEA.cons' 0.5 [ 0.75, 1.0, 1.5, 2.0 ])
            pure (Just { tx, ty, scale })
        ]
    )
  partially <- elements (NEA.cons' Nothing [ Just false, Just true ])
  excludeNonSelectable <- elements (NEA.cons' Nothing [ Just false, Just true ])
  pure { rect: { x, y, width, height }, transform, partially, excludeNonSelectable }

-- ─── Fixed witnesses ──────────────────────────────────────────────────────

-- | A node measured 50×25 with no static handles, so adoption leaves it no
-- | handle bounds.
sized :: String -> SizedSpec
sized id =
  { node: node id
  , measured: { width: Just 50.0, height: Just 25.0 }
  , width: Nothing
  , height: Nothing
  , initialWidth: Nothing
  , initialHeight: Nothing
  , selectable: Nothing
  , dragging: Nothing
  }

at :: Number -> Number -> SizedSpec -> SizedSpec
at x y s = s { node = s.node { position = { x, y } } }

-- | An empty list of static handles, so adoption gives the node handle
-- | bounds, and `getNodesInside` doesn't keep it for its first render.
bounded :: SizedSpec -> SizedSpec
bounded s = s { node = s.node { handles = Just [] } }

unsized :: SizedSpec -> SizedSpec
unsized s = s { measured = { width: Nothing, height: Nothing } }

plain :: Options
plain = { nodeOrigin: Tuple 0.0 0.0, elevateNodesOnSelect: true, zIndexMode: ZBasic }

within :: Rect -> InsideArgs
within rect = { rect, transform: Nothing, partially: Nothing, excludeNonSelectable: Nothing }

-- | Measured, width and initial width each supply one node's dimensions, and
-- | the fourth node has none.
everyRung :: Array SizedSpec
everyRung =
  [ at 10.0 10.0 (sized "m")
  , at 80.0 (-20.0) (unsized (sized "w")) { width = Just 30.0, height = Just 40.0 }
  , at (-30.0) 60.0 (unsized (sized "i")) { initialWidth = Just 15.0, initialHeight = Just 5.0 }
  , at 200.0 150.0 (unsized (sized "z"))
  ]

-- | Two nodes on `0` and `-0`, with no dimensions.
signedZeros :: Array SizedSpec
signedZeros = [ at (-0.0) 0.0 (unsized (sized "a")), at 0.0 (-0.0) (unsized (sized "b")) ]

-- | A parent at `(100, 100)` and its child at `(10, 10)`, at `(110, 110)`
-- | absolutely.
subflow :: Array SizedSpec
subflow = [ at 100.0 100.0 (sized "p"), at 10.0 10.0 (sized "c") { node { parentId = Just "p" } } ]

-- | A node 50 wide in a rect 49 wide.
halfInside :: Array SizedSpec
halfInside = [ bounded (sized "a") ]

-- ─── Run ──────────────────────────────────────────────────────────────────

runInternalNodesParity :: Effect Unit
runInternalNodesParity = do
  log "running internal-node parity properties (PSFlow vs live XYFlow)..."

  expectGreen "getInternalNodesBounds: no nodes give the zero rect"
    (boundsMatch plain [] Omitted)
  expectGreen "getInternalNodesBounds: a filter that keeps no node gives the zero rect"
    (boundsMatch plain everyRung Selected)
  expectGreen "getInternalNodesBounds: each dimension rung, and none"
    (boundsMatch plain everyRung Omitted)
  expectGreen "getInternalNodesBounds: -0 bounds below 0"
    (boundsMatch plain signedZeros Omitted)
  expectGreen "getInternalNodesBounds: a NaN position is kept"
    (boundsMatch plain (Array.snoc everyRung (at nan 0.0 (sized "n"))) Omitted)
  expectGreen "getInternalNodesBounds: a child at its absolute position"
    (boundsMatch plain subflow (Ids [ "c" ]))
  expectGreen "getInternalNodesBounds: <NodesSelection />'s filter"
    (boundsMatch plain (map (\s -> s { node { selected = Just (s.node.id /= "w") } }) everyRung) Selected)
  expectGreen "getInternalNodesBounds: <MiniMap />'s filter"
    (boundsMatch plain (map (\s -> s { node { hidden = Just (s.node.id == "z") } }) everyRung) Visible)

  quickCheck' 500 do
    o <- genOptions
    specs <- genNodes
    f <- genFilter specs
    pure (boundsMatch o specs f)

  let
    rect50x25 = { x: 0.0, y: 0.0, width: 50.0, height: 25.0 }
    rect49x25 = rect50x25 { width = 49.0 }
  expectGreen "getNodesInside: a node that fills the rect is inside"
    (insideMatch plain halfInside (within rect50x25))
  expectGreen "getNodesInside: a node past the rect's edge is outside"
    (insideMatch plain halfInside (within rect49x25))
  expectGreen "getNodesInside: a node past the rect's edge is partially inside"
    (insideMatch plain halfInside (within rect49x25) { partially = Just true })
  expectGreen "getNodesInside: a dragging node outside the rect is kept"
    (insideMatch plain [ at 500.0 500.0 (bounded (sized "a")) { dragging = Just true } ] (within rect50x25))
  expectGreen "getNodesInside: a node with no handle bounds is kept wherever it is"
    (insideMatch plain [ at 500.0 500.0 (sized "a") ] (within rect50x25))
  expectGreen "getNodesInside: a hidden node is dropped, even with no handle bounds"
    (insideMatch plain [ (sized "a") { node { hidden = Just true } } ] (within rect50x25))
  expectGreen "getNodesInside: a node that isn't selectable is kept unless excluded"
    (insideMatch plain [ (bounded (sized "a")) { selectable = Just false } ] (within rect50x25))
  expectGreen "getNodesInside: a node that isn't selectable is dropped when excluded"
    ( insideMatch plain [ (bounded (sized "a")) { selectable = Just false } ]
        (within rect50x25) { excludeNonSelectable = Just true }
    )
  -- The pane rect is 9.95 wide at scale 2, so the overlap is 99.5 of the
  -- node's 100, which `Math.ceil` rounds up to the whole node.
  expectGreen "getNodesInside: the overlap is rounded up"
    ( insideMatch plain [ (bounded (sized "a")) { measured = { width: Just 10.0, height: Just 10.0 } } ]
        (within { x: 0.0, y: 0.0, width: 19.9, height: 20.0 })
          { transform = Just { tx: 0.0, ty: 0.0, scale: 2.0 } }
    )
  -- A JavaScript `Map` keeps an id's first place and its last value.
  expectGreen "getNodesInside: a repeated id keeps its first place"
    ( insideMatch plain
        [ bounded (sized "a"), at 10.0 10.0 (bounded (sized "b")), at 20.0 20.0 (bounded (sized "a")) ]
        (within { x: 0.0, y: 0.0, width: 100.0, height: 100.0 })
    )
  expectGreen "getNodesInside: a repeated id is read as its last node"
    ( insideMatch plain
        [ bounded (sized "a"), at 10.0 10.0 (bounded (sized "b")), at 500.0 500.0 (bounded (sized "a")) ]
        (within { x: 0.0, y: 0.0, width: 100.0, height: 100.0 })
    )
  expectGreen "getNodesInside: the lookup's order, not the ids'"
    ( insideMatch plain [ at 10.0 0.0 (sized "b"), sized "a", at 20.0 0.0 (sized "c") ]
        (within { x: 0.0, y: 0.0, width: 100.0, height: 100.0 })
    )

  quickCheck' 500 do
    o <- genOptions
    specs <- genNodes
    a <- genInsideArgs
    pure (insideMatch o specs a)

  falsify "getInternalNodesBounds: XYFlow keeps the selected nodes, PSFlow every node"
    ( let
        specs = map (\s -> s { node { selected = Just (s.node.id == "m") } }) everyRung
      in
        strMatch "filter" (exactRect (psBounds plain specs Omitted)) (exactRect (xyBounds plain specs Selected))
    )
  falsify "getInternalNodesBounds: XYFlow's node on -0, PSFlow's on 0"
    ( let
        positive = [ at 0.0 0.0 (unsized (sized "a")), at 0.0 0.0 (unsized (sized "b")) ]
      in
        strMatch "sign" (exactRect (psBounds plain positive Omitted)) (exactRect (xyBounds plain signedZeros Omitted))
    )
  falsify "getNodesInside: XYFlow counts a partial overlap, PSFlow doesn't"
    ( strSeqMatch "partially"
        (psInside plain halfInside (within rect49x25))
        (xyInside plain halfInside (within rect49x25) { partially = Just true })
    )
  falsify "getNodesInside: XYFlow reads the lookup in order, PSFlow in reverse"
    ( let
        specs = [ at 10.0 0.0 (sized "b"), sized "a", at 20.0 0.0 (sized "c") ]
        args = within { x: 0.0, y: 0.0, width: 100.0, height: 100.0 }
      in
        strSeqMatch "order" (psInside plain (Array.reverse specs) args) (xyInside plain specs args)
    )

  log "internal-node parity passed"
