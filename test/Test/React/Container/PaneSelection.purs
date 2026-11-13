-- | What a selection rectangle selects: upstream #4929, "Optimize selections
-- | and take into account if edges connected to selected nodes are actually
-- | selectable."
-- |
-- | #4929 changed upstream's `<Pane />` `onPointerMove` in two ways, and
-- | PSFlow's pane makes each decision through `React.Container.Pane.Internal`:
-- |
-- | * An edge connected to a selected node is selected only if
-- |   `edge.selectable ?? defaultEdgeOptions?.selectable ?? true`, read from
-- |   the store's `connectionLookup` and `edgeLookup`. Before, every edge
-- |   connected to a selected node was selected. `collectIncidentEdgeIds`
-- |   makes the decision.
-- | * The pane compares this move's sets with the last move's through
-- |   `areSetsEqual`, where it compared their sizes, so a move that trades one
-- |   node for another changes the selection. `selectionStep` makes the
-- |   decision, and `areSetsEqual` is compared with upstream's own over every
-- |   pair of subsets of four ids.
-- |
-- | Upstream makes both decisions inside its pointer handler, which nothing
-- | can call on its own, so the cases state what upstream's expressions give.
module Test.React.Container.PaneSelection
  ( runPaneSelectionTests
  ) where

import Prelude

import Data.Array (foldl) as Array
import Data.Maybe (Maybe(..))
import Data.Set (Set)
import Data.Set as Set
import Effect (Effect)
import Effect.Class.Console (log)
import React.Container.Pane.Internal (collectIncidentEdgeIds, selectionStep)
import System.Types.Connection (ConnectionLookup)
import System.Types.Edge (EdgeLookup)
import System.Types.Ids (NodeId(..))
import System.Utils.General (areSetsEqual) as PS
import System.Utils.Store (updateConnectionLookup)
import Test.Oracle (areSetsEqual) as Oracle
import Test.Parity.Builders (mkEdge)
import Test.Parity.Util (allGreen, expectGreen, falsify, strMatch)
import Test.QuickCheck (Result)

-- | `a → b` takes the default, `a → c` is unselectable, `b → c` is
-- | selectable, and `c → d` takes the default.
graph
  :: forall d
   . Maybe { selectable :: Maybe Boolean | d }
  -> { edgeLookup :: EdgeLookup Unit
     , connectionLookup :: ConnectionLookup
     , defaultEdgeOptions :: Maybe { selectable :: Maybe Boolean | d }
     }
graph defaultEdgeOptions =
  let
    lookups = updateConnectionLookup
      [ mkEdge "ab" "a" "b"
      , (mkEdge "ac" "a" "c") { selectable = Just false }
      , (mkEdge "bc" "b" "c") { selectable = Just true }
      , mkEdge "cd" "c" "d"
      ]
  in
    { edgeLookup: lookups.edgeLookup
    , connectionLookup: lookups.connectionLookup
    , defaultEdgeOptions
    }

nodes :: Array String -> Set NodeId
nodes = Set.fromFoldable <<< map NodeId

edgeCase :: String -> Set String -> Array String -> Result
edgeCase label actual expected =
  strMatch label (show (Set.toUnfoldable actual :: Array String)) (show expected)

edgeCases :: Array Result
edgeCases =
  let
    plain = graph (Nothing :: Maybe { selectable :: Maybe Boolean })
    unselectable = graph (Just { selectable: Just false })
    unset = graph (Just { selectable: (Nothing :: Maybe Boolean) })
  in
    [ edgeCase "selecting a leaves its unselectable edge to c"
        (collectIncidentEdgeIds plain (nodes [ "a" ]))
        [ "ab" ]
    , edgeCase "selecting c selects its edges to b and d, not the unselectable one to a"
        (collectIncidentEdgeIds plain (nodes [ "c" ]))
        [ "bc", "cd" ]
    , edgeCase "with defaultEdgeOptions.selectable false, only the edge that says it's selectable"
        (collectIncidentEdgeIds unselectable (nodes [ "a", "b", "c" ]))
        [ "bc" ]
    , edgeCase "defaultEdgeOptions without selectable leaves the default true"
        (collectIncidentEdgeIds unset (nodes [ "c" ]))
        [ "bc", "cd" ]
    , edgeCase "a node with no edges selects none"
        (collectIncidentEdgeIds plain (nodes [ "e" ]))
        []
    ]

stepCase
  :: String
  -> { nodes :: Array String, edges :: Array String }
  -> Array String
  -> { nodesChanged :: Boolean, edgesChanged :: Boolean }
  -> Result
stepCase label previous next expected =
  let
    step = selectionStep (graph (Nothing :: Maybe { selectable :: Maybe Boolean }))
      { nodeIds: nodes previous.nodes, edgeIds: Set.fromFoldable previous.edges }
      (nodes next)
    shown :: forall r. { nodesChanged :: Boolean, edgesChanged :: Boolean | r } -> String
    shown r = "nodes " <> show r.nodesChanged <> ", edges " <> show r.edgesChanged
  in
    strMatch label (shown step) (shown expected)

stepCases :: Array Result
stepCases =
  [ stepCase "trading b for c, the same number of nodes, changes both selections"
      { nodes: [ "a", "b" ], edges: [ "ab", "bc" ] }
      [ "a", "c" ]
      { nodesChanged: true, edgesChanged: true }
  , stepCase "trading a for d changes both, though each set keeps its size"
      { nodes: [ "a" ], edges: [ "ab" ] }
      [ "d" ]
      { nodesChanged: true, edgesChanged: true }
  , stepCase "the same nodes change nothing"
      { nodes: [ "a" ], edges: [ "ab" ] }
      [ "a" ]
      { nodesChanged: false, edgesChanged: false }
  ]

-- | Every subset of four ids.
subsets :: Array (Array String)
subsets = Array.foldl (\acc id -> acc <> map (_ <> [ id ]) acc) [ [] ] [ "a", "b", "c", "d" ]

setsMatch :: Array String -> Array String -> Result
setsMatch a b =
  strMatch ("areSetsEqual " <> show a <> " " <> show b)
    (show (PS.areSetsEqual (Set.fromFoldable a) (Set.fromFoldable b)))
    (show (Oracle.areSetsEqual a b))

runPaneSelectionTests :: Effect Unit
runPaneSelectionTests = do
  log "\n=== Pane: what a selection rectangle selects (upstream #4929) ==="

  expectGreen "collectIncidentEdgeIds selects only selectable edges" (allGreen edgeCases)
  expectGreen "selectionStep compares the sets, not their sizes" (allGreen stepCases)
  expectGreen "areSetsEqual agrees with upstream's over all 256 pairs of subsets"
    (allGreen (subsets >>= \a -> map (setsMatch a) subsets))

  falsify "areSetsEqual: upstream handed a set one id short"
    (strMatch "areSetsEqual" (show (PS.areSetsEqual (nodes [ "a", "b" ]) (nodes [ "a", "b" ]))) (show (Oracle.areSetsEqual [ "a", "b" ] [ "a" ])))
  falsify "collectIncidentEdgeIds: expecting the unselectable edge as well"
    (edgeCase "a" (collectIncidentEdgeIds (graph (Nothing :: Maybe { selectable :: Maybe Boolean })) (nodes [ "a" ])) [ "ab", "ac" ])
