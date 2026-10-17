-- | The order `connectionLookup` hands back a node's connections in.
-- |
-- | The local proxy for the `useNodeConnections` lists in the map's
-- | "`Data.Map` key order leaking into render order" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's `updateConnectionLookup` fills a JavaScript `Map` per lookup
-- | key with `nodeMap.set(connectionKey, connection)`, so
-- | `getNodeConnections`, `useNodeConnections`, and
-- | `useHandleConnections` read a node's connections in edge order, with a
-- | repeated connection key at its first position and holding its last
-- | connection. ps-flow's inner map was a `Data.Map`, which iterates by
-- | connection key.
module Test.System.Utils.ConnectionOrder
  ( runConnectionOrderTests
  ) where

import Prelude

import Data.Map as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import System.Types.Edge (EdgeBase)
import System.Types.Ids (NodeId(..))
import System.Utils.Store (handleConnectionsInOrder, updateConnectionLookup)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

edge :: String -> String -> String -> EdgeBase Unit
edge id source target =
  { id
  , edgeType: Nothing
  , source: NodeId source
  , target: NodeId target
  , sourceHandle: Nothing
  , targetHandle: Nothing
  , animated: Nothing
  , hidden: Nothing
  , deletable: Nothing
  , selectable: Nothing
  , data: Nothing
  , selected: false
  , markerStart: Nothing
  , markerEnd: Nothing
  , zIndex: Nothing
  , label: Nothing
  , ariaLabel: Nothing
  , interactionWidth: Nothing
  , className: Nothing
  , style: Nothing
  }

-- | The edge ids of `key`'s connections, in the order the lookup gives them.
edgeIdsAt :: String -> Array (EdgeBase Unit) -> Array String
edgeIdsAt key edges =
  case Map.lookup key (updateConnectionLookup edges).connectionLookup of
    Just connections -> map _.edgeId (handleConnectionsInOrder connections)
    Nothing -> []

runConnectionOrderTests :: Effect Unit
runConnectionOrderTests = do
  log "\n=== connectionLookup: a node's connections come in edge order ==="

  -- `hub-z`'s connection key, `z-null--hub-null`, sorts after `hub-a`'s.
  let edges = [ edge "hub-z" "hub" "z", edge "hub-a" "hub" "a" ]
  assert "a node's connections come in edge order"
    (edgeIdsAt "hub" edges == [ "hub-z", "hub-a" ])
  assert "a node's source connections come in edge order"
    (edgeIdsAt "hub-source" edges == [ "hub-z", "hub-a" ])

  -- `hub-z-again` has `hub-z`'s endpoints, so its connection key too.
  assert "a repeated connection key keeps its first position and its last connection, as a Map's set does"
    (edgeIdsAt "hub" (edges <> [ edge "hub-z-again" "hub" "z" ]) == [ "hub-z-again", "hub-a" ])
