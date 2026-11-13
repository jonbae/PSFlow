-- | Connection snapping, against upstream: upstream #5266, "Fix connection
-- | snapping for handles larger than connectionRadius".
-- |
-- | During a connection drag, `onPointerMove` asks `isValidHandle` about the
-- | handle under the pointer, or failing that the closest handle, and snaps
-- | the connection's end to the handle it settles on. #5266 changed two
-- | things, and each has its own check here:
-- |
-- | * `isValidHandle` returns that handle at its absolute centre, through
-- |   `getHandle(…, true)`, rather than at its offset inside the node. The
-- |   differential runs PSFlow's `isValidHandle` and upstream's
-- |   `XYHandle.isValid` from the oracle bundle over the same stand-in
-- |   document, with internal nodes each side adopts from the same
-- |   description, and compares the element, validity, connection and
-- |   handle they return.
-- | * `onPointerMove` snaps to that handle, not to the closest one. A handle
-- |   larger than `connectionRadius` can be under the pointer with its centre
-- |   out of reach, so there is no closest handle. Upstream's move handler
-- |   can't be called on its own, so `connectionEnd`, which PSFlow's move
-- |   handler snaps with, is checked against what upstream's expression
-- |   gives for that case and its neighbours.
module Test.Parity.Handle
  ( runHandleParity
  ) where

import Prelude

import Data.Array (concat, elem, length, mapWithIndex, unsafeIndex, (!!)) as Array
import Data.Array.NonEmpty as NEA
import Data.Either (Either(..))
import Data.Int (toNumber) as Int
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Newtype (unwrap)
import Data.Nullable (toMaybe, toNullable)
import Data.String (Pattern(..), stripPrefix)
import Data.Traversable (for, traverse)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafePartial)
import System.Types.Connection (ConnectionMode(..))
import System.Types.Geometry (Position(..), XYPosition, mkTransform)
import System.Types.Handle (Handle, HandleIdField(..), HandleType(..))
import System.Types.Ids (NodeId(..))
import System.Utils.Store (adoptUserNodes, defaultUpdateNodesOptions) as PS
import System.XYHandle (HandleValidationResult, connectionEnd, xyHandle)
import Test.Oracle (FakeDocument, FakeElement, OracleIsValidResult)
import Test.Oracle (fakeDocument, handleElement, isValidHandle, plainElement) as Oracle
import Test.Parity.Adoption (HandleSpec, NodeSpec, adoptedHandle, canonicalJson, handleIdField, node, toOracleNode, toPSNode)
import Test.Parity.Util (allGreen, expectGreen, falsify, strMatch)
import Test.QuickCheck (Result)
import Test.QuickCheck.Gen (Gen, chooseInt, elements, frequency, randomSample', vectorOf)
import Unsafe.Coerce (unsafeCoerce)
import Web.DOM.Document (Document)
import Web.DOM.Element (Element)
import Web.UIEvent.MouseEvent (MouseEvent)

-- | The `tag` a stand-in element carries.
foreign import elementTag :: Element -> String

-- | A mouse event at the point, in the members `getEventPosition` reads.
foreign import mouseAt :: XYPosition -> MouseEvent

-- ─── Scenarios ────────────────────────────────────────────────────────────

-- | One handle element, as `<Handle />` renders it for `handle`, the
-- | `index`th of `nodeId`'s static handles.
type ElementSpec =
  { nodeId :: String
  , index :: Int
  , handle :: HandleSpec
  , connectable :: Boolean
  , connectableEnd :: Boolean
  }

-- | `below` is what `elementFromPoint` answers: no element, an element that
-- | is no handle, or the handle element at that index of `elements`.
data Below = Nothing' | Plain | HandleAt Int

type Scenario =
  { nodes :: Array NodeSpec
  , elements :: Array ElementSpec
  , from :: Int
  , closest :: Maybe Int
  , below :: Below
  , connectionMode :: ConnectionMode
  , validTargets :: Array String
  , pointer :: XYPosition
  }

-- | `<Handle />`'s `handleId`, which is `id || null`, so an empty id renders
-- | as none.
domHandleId :: HandleSpec -> Maybe String
domHandleId h = case stripPrefix (Pattern "set:") h.id of
  Just "" -> Nothing
  other -> other

typeStr :: HandleType -> String
typeStr = case _ of
  Source -> "source"
  Target -> "target"

elementTagFor :: ElementSpec -> String
elementTagFor e = e.nodeId <> ":" <> show e.index

-- | Each element, built once and handed to both sides.
standIns :: Scenario -> { elements :: Array FakeElement, plain :: FakeElement }
standIns sc =
  { elements: map
      ( \e -> Oracle.handleElement "react" "1"
          { tag: elementTagFor e
          , nodeId: e.nodeId
          , handleId: toNullable (domHandleId e.handle)
          , type: typeStr e.handle.handleType
          , connectable: e.connectable
          , connectableEnd: e.connectableEnd
          }
      )
      sc.elements
  , plain: Oracle.plainElement "plain"
  }

documentFor :: Scenario -> FakeDocument
documentFor sc =
  let
    els = standIns sc
    below = case sc.below of
      Nothing' -> Nothing
      Plain -> Just els.plain
      HandleAt i -> els.elements Array.!! i
  in
    Oracle.fakeDocument els.elements below

elementAt :: Scenario -> Int -> ElementSpec
elementAt sc i = unsafePartial (Array.unsafeIndex sc.elements i)

-- ─── Both sides ───────────────────────────────────────────────────────────

psResult :: HandleValidationResult -> OracleIsValidResult
psResult r =
  { handleDomNode: toNullable (map elementTag r.handleDomNode)
  , isValid: r.isValid
  , connection: toNullable
      ( map
          ( \c ->
              { source: unwrap c.source
              , sourceHandle: toNullable c.sourceHandle
              , target: unwrap c.target
              , targetHandle: toNullable c.targetHandle
              }
          )
          r.connection
      )
  , toHandle: toNullable (map adoptedHandle r.toHandle)
  }

psIsValid :: Scenario -> FakeDocument -> Effect OracleIsValidResult
psIsValid sc doc = do
  let
    adopted = PS.adoptUserNodes (map toPSNode sc.nodes) Map.empty Map.empty PS.defaultUpdateNodesOptions
    from = elementAt sc sc.from
  result <- xyHandle.isValid (Left (mouseAt sc.pointer))
    { handle: map
        ( \i ->
            let e = elementAt sc i
            in { nodeId: NodeId e.nodeId, id: handleIdField e.handle.id, handleType: e.handle.handleType }
        )
        sc.closest
    , connectionMode: sc.connectionMode
    , fromNodeId: NodeId from.nodeId
    , fromHandleId: domHandleId from.handle
    , fromType: from.handle.handleType
    , isValidConnection: \c -> Array.elem (unwrap c.target) sc.validTargets
    , doc: Left (unsafeCoerce doc :: Document)
    , lib: "react"
    , flowId: Just "1"
    , nodeLookup: adopted.nodeLookup
    }
  pure (psResult result)

xyIsValid :: Scenario -> FakeDocument -> OracleIsValidResult
xyIsValid sc doc =
  let
    from = elementAt sc sc.from
  in
    Oracle.isValidHandle (map toOracleNode sc.nodes)
      { handle: toNullable
          ( map
              ( \i ->
                  let e = elementAt sc i
                  in { nodeId: e.nodeId, id: e.handle.id, type: typeStr e.handle.handleType }
              )
              sc.closest
          )
      , pointer: sc.pointer
      , connectionMode: case sc.connectionMode of
          Strict -> "strict"
          Loose -> "loose"
      , fromNodeId: from.nodeId
      , fromHandleId: toNullable (domHandleId from.handle)
      , fromType: typeStr from.handle.handleType
      , validTargets: sc.validTargets
      , doc
      , lib: "react"
      , flowId: "1"
      }

describe :: Scenario -> String
describe sc =
  "isValidHandle from " <> elementTagFor (elementAt sc sc.from)
    <> ", closest " <> show (map (elementTagFor <<< elementAt sc) sc.closest)
    <> ", below " <> case sc.below of
      Nothing' -> "nothing"
      Plain -> "a plain element"
      HandleAt i -> elementTagFor (elementAt sc i)
    <> ", " <> (case sc.connectionMode of
      Strict -> "strict"
      Loose -> "loose")
    <> ", valid targets " <> show sc.validTargets
    <> "\n  nodes: " <> canonicalJson (map toOracleNode sc.nodes)

validationsMatch :: Scenario -> Effect Result
validationsMatch sc = do
  let doc = documentFor sc
  ps <- psIsValid sc doc
  pure (strMatch (describe sc) (canonicalJson ps) (canonicalJson (xyIsValid sc doc)))

-- ─── Generators ───────────────────────────────────────────────────────────

genHandle :: Gen HandleSpec
genHandle = do
  id <- elements (NEA.cons' "unset" [ "null", "set:", "set:a", "set:b" ])
  handleType <- elements (NEA.cons' Source [ Target ])
  position <- elements (NEA.cons' PosLeft [ PosTop, PosRight, PosBottom ])
  x <- Int.toNumber <$> chooseInt (-10) 60
  y <- Int.toNumber <$> chooseInt (-10) 30
  -- Some handles larger than any connection radius the move would use.
  size <- frequency (NEA.cons' (Tuple 2.0 (chooseInt 1 12)) [ Tuple 1.0 (chooseInt 40 120) ])
  width <- elements (NEA.cons' (Just (Int.toNumber size)) [ Nothing ])
  height <- elements (NEA.cons' (Just (Int.toNumber size)) [ Nothing ])
  pure { id, handleType, position, x, y, width, height }

genNode :: String -> Gen NodeSpec
genNode id = do
  x <- Int.toNumber <$> chooseInt (-100) 300
  y <- Int.toNumber <$> chooseInt (-100) 300
  n <- chooseInt 1 3
  handles <- vectorOf n genHandle
  pure (node id) { position = { x, y }, handles = Just handles }

genScenario :: Gen Scenario
genScenario = do
  a <- genNode "a"
  b <- genNode "b"
  elementSpecs <- for [ a, b ] \n ->
    for (Array.mapWithIndex Tuple (fromMaybe [] n.handles)) \(Tuple index handle) -> do
      connectable <- frequency (NEA.cons' (Tuple 4.0 (pure true)) [ Tuple 1.0 (pure false) ])
      connectableEnd <- frequency (NEA.cons' (Tuple 4.0 (pure true)) [ Tuple 1.0 (pure false) ])
      pure { nodeId: n.id, index, handle, connectable, connectableEnd }
  let
    els = Array.concat elementSpecs
    count = Array.length els
    fromCount = Array.length (fromMaybe [] a.handles)
  from <- chooseInt 0 (fromCount - 1)
  closest <- frequency
    (NEA.cons' (Tuple 1.0 (pure Nothing)) [ Tuple 2.0 (Just <$> chooseInt 0 (count - 1)) ])
  below <- frequency
    ( NEA.cons' (Tuple 1.0 (pure Nothing'))
        [ Tuple 1.0 (pure Plain), Tuple 3.0 (HandleAt <$> chooseInt 0 (count - 1)) ]
    )
  connectionMode <- elements (NEA.cons' Strict [ Loose ])
  validTargets <- elements (NEA.cons' [ "a", "b" ] [ [ "b" ], [] ])
  px <- Int.toNumber <$> chooseInt (-100) 400
  py <- Int.toNumber <$> chooseInt (-100) 400
  pure
    { nodes: [ a, b ]
    , elements: els
    , from
    , closest
    , below
    , connectionMode
    , validTargets
    , pointer: { x: px, y: py }
    }

-- ─── The large handle ─────────────────────────────────────────────────────

-- | A 100 × 100 target handle at offset (10, -40) on `b`, which sits at
-- | (200, 100), so its centre is (260, 110). The pointer is at (215, 65),
-- | inside the handle and about 64 from its centre, so no handle is within
-- | a `connectionRadius` of 20 and the closest handle is none.
largeHandle :: Scenario
largeHandle =
  let
    source = { id: "set:out", handleType: Source, position: PosRight, x: 50.0, y: 10.0, width: Just 6.0, height: Just 6.0 }
    target = { id: "set:in", handleType: Target, position: PosLeft, x: 10.0, y: -40.0, width: Just 100.0, height: Just 100.0 }
  in
    { nodes:
        [ (node "a") { handles = Just [ source ] }
        , (node "b") { position = { x: 200.0, y: 100.0 }, handles = Just [ target ] }
        ]
    , elements:
        [ { nodeId: "a", index: 0, handle: source, connectable: true, connectableEnd: true }
        , { nodeId: "b", index: 0, handle: target, connectable: true, connectableEnd: true }
        ]
    , from: 0
    , closest: Nothing
    , below: HandleAt 1
    , connectionMode: Strict
    , validTargets: [ "b" ]
    , pointer: { x: 215.0, y: 65.0 }
    }

-- | `largeHandle` with the target handle's offset where upstream's
-- | `getHandle(…, false)` left it, before #5266.
withRelativeHandle :: OracleIsValidResult -> OracleIsValidResult
withRelativeHandle r = r { toHandle = toNullable (map (\h -> h { x = 10.0, y = -40.0 }) (toMaybe r.toHandle)) }

-- ─── connectionEnd ────────────────────────────────────────────────────────

-- | Upstream's `onPointerMove`, after `isValidHandle`:
-- |
-- |     isValid = isConnectionValid(!!closestHandle, result.isValid);
-- |     to: result.toHandle && isValid
-- |       ? rendererPointToPoint({ x: result.toHandle.x, y: result.toHandle.y }, transform)
-- |       : position,
-- |     toPosition: isValid && result.toHandle
-- |       ? result.toHandle.position
-- |       : oppositePosition[fromHandle.position],
type EndCase =
  { label :: String
  , closest :: Maybe Handle
  , valid :: Boolean
  , toHandle :: Maybe Handle
  , expected :: { isValid :: Maybe Boolean, to :: XYPosition, toPosition :: Position }
  }

-- | The large target handle, as `isValidHandle` returns it: at its centre.
centred :: Handle
centred =
  { id: HandleIdSet "in"
  , nodeId: NodeId "b"
  , x: 260.0
  , y: 110.0
  , position: PosLeft
  , handleType: Target
  , width: 100.0
  , height: 100.0
  }

endCases :: Array EndCase
endCases =
  [ { label: "a valid handle under the pointer and no closest handle snaps to the handle's centre"
    , closest: Nothing
    , valid: true
    , toHandle: Just centred
    , expected: { isValid: Just true, to: { x: 530.0, y: 225.0 }, toPosition: PosLeft }
    }
  , { label: "an invalid closest handle leaves the end at the pointer, facing away"
    , closest: Just centred
    , valid: false
    , toHandle: Just centred
    , expected: { isValid: Just false, to: { x: 215.0, y: 65.0 }, toPosition: PosLeft }
    }
  , { label: "no closest handle and an invalid handle below leaves validity unknown"
    , closest: Nothing
    , valid: false
    , toHandle: Just centred
    , expected: { isValid: Nothing, to: { x: 215.0, y: 65.0 }, toPosition: PosLeft }
    }
  , { label: "a valid check with no handle leaves the end at the pointer"
    , closest: Nothing
    , valid: true
    , toHandle: Nothing
    , expected: { isValid: Just true, to: { x: 215.0, y: 65.0 }, toPosition: PosLeft }
    }
  ]

-- | The connection starts at a right-facing source handle, so the end faces
-- | left when it snaps to nothing. The viewport is at (10, 5), zoomed to 2.
endMatches :: EndCase -> Result
endMatches c =
  let
    actual = connectionEnd
      { closest: c.closest
      , result: { handleDomNode: Nothing, isValid: c.valid, connection: Nothing, toHandle: c.toHandle }
      , pointer: { x: 215.0, y: 65.0 }
      , transform: mkTransform 10.0 5.0 2.0
      , fromPosition: PosRight
      }
    render e = show e.isValid <> " to (" <> show e.to.x <> ", " <> show e.to.y <> ") " <> show e.toPosition
  in
    strMatch c.label (render actual) (render c.expected)

-- ─── Run ──────────────────────────────────────────────────────────────────

runHandleParity :: Effect Unit
runHandleParity = do
  log "running connection-snapping parity (PSFlow vs live XYFlow)..."

  large <- validationsMatch largeHandle
  expectGreen "isValidHandle: a handle larger than the connection radius, under the pointer" large

  scenarios <- randomSample' 400 genScenario
  results <- traverse validationsMatch scenarios
  expectGreen "isValidHandle agrees over 400 generated drags" (allGreen results)

  let
    doc = documentFor largeHandle
  falsify "isValidHandle: XYFlow's handle where getHandle(…, false) left it"
    ( strMatch "toHandle"
        (canonicalJson (withRelativeHandle (xyIsValid largeHandle doc)))
        (canonicalJson (xyIsValid largeHandle doc))
    )

  expectGreen "connectionEnd follows upstream's onPointerMove" (allGreen (map endMatches endCases))
  falsify "connectionEnd: the large handle's case, expecting the end at the pointer"
    ( endMatches
        ( (unsafePartial (Array.unsafeIndex endCases 0))
            { expected = { isValid: Just true, to: { x: 215.0, y: 65.0 }, toPosition: PosRight } }
        )
    )

  log "connection-snapping parity passed"
