-- | QuickCheck properties for `System.Utils.Store` after ticket 022a
-- | (Refs lifted out, helpers now value-in / value-out).
-- |
-- | These properties exercise algebraic invariants of the four newly-pure
-- | functions (`adoptUserNodes`, `updateAbsolutePositions`,
-- | `updateConnectionLookup`, `handleExpandParent`) so that future
-- | implementation tweaks cannot silently break the contract the React
-- | reducer (ticket 026) will rely on.
module Test.System.Utils.Store
  ( runStoreProperties
  ) where

import Prelude

import Data.Array (any, length, nub, nubBy) as Array
import Data.Array.NonEmpty as NEA
import Data.Foldable (all) as Foldable
import Data.Int (toNumber) as Int
import Data.Map (empty, keys, size) as Map
import Data.Maybe (Maybe(..))
import Data.Set as Set
import Effect (Effect)
import Effect.Class.Console (log)
import System.Types.Edge (EdgeBase)
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeBase)
import System.Utils.Store
  ( UpdateNodesOptions
  , adoptUserNodes
  , defaultUpdateNodesOptions
  , handleExpandParent
  , updateAbsolutePositions
  , updateConnectionLookup
  )
import System.Types.Geometry (mkNodeOrigin)
import Test.QuickCheck (quickCheck, (<?>))
import Test.QuickCheck.Gen (Gen, chooseInt, elements, vectorOf)

-- | Build a `NodeBase Unit` with most fields at their neutral defaults.
-- | Only the fields the properties care about (`id`, `position`, `selected`,
-- | `measured`) are exposed as parameters.
mkNode
  :: { id :: String
     , x :: Number
     , y :: Number
     , selected :: Boolean
     , measured :: { width :: Maybe Number, height :: Maybe Number }
     }
  -> NodeBase Unit
mkNode r =
  { id: NodeId r.id
  , position: { x: r.x, y: r.y }
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: false
  , selected: r.selected
  , dragging: false
  , draggable: Nothing
  , selectable: Nothing
  , connectable: Nothing
  , deletable: Nothing
  , dragHandle: Nothing
  , width: Nothing
  , height: Nothing
  , initialWidth: Nothing
  , initialHeight: Nothing
  , parentId: Nothing
  , zIndex: Nothing
  , extent: Nothing
  , expandParent: false
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: r.measured
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

-- | Generate a node id from a small alphabet so duplicate ids occur often
-- | enough for the dedup-by-id behaviour to be exercised.
genNodeId :: Gen String
genNodeId = elements (NEA.cons' "a" [ "b", "c", "d", "e" ])

genNumber :: Gen Number
genNumber = Int.toNumber <$> chooseInt (-100) 100

genMeasured :: Gen { width :: Maybe Number, height :: Maybe Number }
genMeasured = do
  hasDims <- elements (NEA.cons' true [ false ])
  if hasDims then do
    w <- Int.toNumber <$> chooseInt 0 200
    h <- Int.toNumber <$> chooseInt 0 200
    pure { width: Just w, height: Just h }
  else pure { width: Nothing, height: Nothing }

genNode :: Gen (NodeBase Unit)
genNode = do
  id <- genNodeId
  x <- genNumber
  y <- genNumber
  selected <- elements (NEA.cons' true [ false ])
  measured <- genMeasured
  pure (mkNode { id, x, y, selected, measured })

genNodeArray :: Gen (Array (NodeBase Unit))
genNodeArray = do
  n <- chooseInt 0 5
  vectorOf n genNode

-- | Minimal `EdgeBase Unit` builder (mirrors the one in `Test.Properties`).
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
  }

genEdge :: Gen (EdgeBase Unit)
genEdge = do
  src <- genNodeId
  tgt <- genNodeId
  pure (mkEdge (src <> "-" <> tgt) src tgt)

genEdgeArray :: Gen (Array (EdgeBase Unit))
genEdgeArray = do
  n <- chooseInt 0 5
  -- Distinct edge ids are required by the lookup contract; dedupe by id.
  edges <- vectorOf n genEdge
  pure (Array.nubBy (\a b -> compare a.id b.id) edges)

runStoreProperties :: Effect Unit
runStoreProperties = do
  log "running System.Utils.Store properties..."

  let opts = (defaultUpdateNodesOptions :: UpdateNodesOptions Unit)

  -- 1. adoptUserNodes is idempotent under default options.
  --
  --    Run 1 from empty maps, then run 2 from run 1's output, with the same
  --    node array. The two outputs must agree on nodeLookup, parentLookup,
  --    and the boolean returns. (Idempotence here relies on ZBasic mode —
  --    ZAuto bumps parent z each time shouldBump fires, see Store.purs.)
  quickCheck do
    ns <- genNodeArray
    let
      r1 = adoptUserNodes ns Map.empty Map.empty opts
      r2 = adoptUserNodes ns r1.nodeLookup r1.parentLookup opts
    pure
      ( r1.nodeLookup == r2.nodeLookup
          && r1.parentLookup == r2.parentLookup
          && r1.nodesInitialized == r2.nodesInitialized
          && r1.hasSelectedNodes == r2.hasSelectedNodes
          <?> "adoptUserNodes not idempotent"
      )

  -- 2. hasSelectedNodes mirrors the input's selected flags exactly.
  quickCheck do
    ns <- genNodeArray
    let r = adoptUserNodes ns Map.empty Map.empty opts
    pure
      ( r.hasSelectedNodes == Array.any _.selected ns
          <?> "hasSelectedNodes disagrees with input"
      )

  -- 3. When every node has parentId == Nothing, parentLookup stays empty.
  quickCheck do
    ns <- genNodeArray
    let r = adoptUserNodes ns Map.empty Map.empty opts
    pure
      ( Map.size r.parentLookup == 0
          <?> "parentLookup non-empty for all-unparented input"
      )

  -- 4. updateAbsolutePositions preserves the parentLookup it was given
  --    when no node in the input has a parentId (the parentId branch never
  --    fires, so the second component of the fold result equals the input).
  quickCheck do
    ns <- genNodeArray
    let
      r0 = adoptUserNodes ns Map.empty Map.empty opts
      r1 = updateAbsolutePositions r0.nodeLookup r0.parentLookup opts
    pure
      ( Map.keys r1.parentLookup == Map.keys r0.parentLookup
          <?> "updateAbsolutePositions changed parentLookup keys"
      )

  -- 5. updateConnectionLookup's edgeLookup has one entry per input edge id.
  quickCheck do
    es <- genEdgeArray
    let
      r = updateConnectionLookup es
      uniqueIds = Array.nub (map _.id es)
    pure
      ( Map.size r.edgeLookup == Array.length uniqueIds
          <?> "edgeLookup size disagrees with unique edge id count"
      )

  -- 6. updateConnectionLookup is total on its edge array (no edge id
  --    silently dropped).
  quickCheck do
    es <- genEdgeArray
    let r = updateConnectionLookup es
    pure
      ( Foldable.all (\e -> Set.member e.id (Map.keys r.edgeLookup)) es
          <?> "edge id missing from edgeLookup"
      )

  -- 7. handleExpandParent with no children is the empty change list.
  quickCheck do
    ns <- genNodeArray
    let
      r = adoptUserNodes ns Map.empty Map.empty opts
      changes = handleExpandParent [] r.nodeLookup r.parentLookup
        (mkNodeOrigin 0.0 0.0)
    pure
      ( Array.length changes == 0
          <?> "handleExpandParent produced changes for empty children"
      )

  log "all System.Utils.Store properties passed"
