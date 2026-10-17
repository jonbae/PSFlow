-- | The order `NodeRenderer` renders nodes in.
-- |
-- | The local proxy for the map's "`Data.Map` key order leaking into render
-- | order" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93),
-- | for node DOM order. Upstream's `useVisibleNodeIds` returns
-- | `Array.from(s.nodeLookup.keys())`, or `getNodesInside(s.nodeLookup, …)`
-- | when only visible elements render, and both iterate the lookup in
-- | insertion order: `nodes`' order, with a repeated id at its first
-- | position. ps-flow's lookup is a `Data.Map`, which iterates by key, so
-- | `["hub", "up-1", "down-1"]` rendered as `["down-1", "hub", "up-1"]`.
module Test.React.Hook.NodeRenderOrder
  ( runNodeRenderOrderTests
  ) where

import Prelude

import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Hook.VisibleIds.Pure (selectVisibleNodeIds)
import React.Store.InitialState (defaultInitialStateOptions, initialState)
import React.Types.Store (ReactFlowState)
import System.Types.Ids (NodeId(..))
import System.Types.Node (InternalNodeBase, NodeBase)
import Unsafe.Coerce (unsafeCoerce)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | A measured 50 × 50 node at `x`, `y`.
internalNode :: String -> Number -> Number -> InternalNodeBase Unit
internalNode id x y =
  { id: NodeId id
  , position: { x, y }
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: Nothing
  , selected: false
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
  , expandParent: Nothing
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Just 50.0, height: Just 50.0 }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  , internals:
      { positionAbsolute: { x, y }
      , z: 0.0
      , rootParentIndex: Nothing
      , handleBounds: Just { source: [], target: [] }
      , bounds: Nothing
      }
  }

-- | The node without its `internals`, as the store's `nodes` holds it.
toUserNode :: InternalNodeBase Unit -> NodeBase Unit
toUserNode = unsafeCoerce

-- | A 100 × 100 flow whose `nodes` are `internals`, in that order. `hub` and
-- | `up-1` sit inside the viewport, and `down-1` outside it.
flowOf :: Array (InternalNodeBase Unit) -> ReactFlowState Unit Unit
flowOf internals =
  (initialState defaultInitialStateOptions)
    { width = 100.0
    , height = 100.0
    , nodes = map toUserNode internals
    , nodeLookup = Map.fromFoldable (map (\n -> Tuple n.id n) internals)
    }

hub :: InternalNodeBase Unit
hub = internalNode "hub" 10.0 10.0

up1 :: InternalNodeBase Unit
up1 = internalNode "up-1" 30.0 30.0

down1 :: InternalNodeBase Unit
down1 = internalNode "down-1" 500.0 500.0

runNodeRenderOrderTests :: Effect Unit
runNodeRenderOrderTests = do
  log "\n=== NodeRenderer: nodes render in nodes' order, not by id ==="

  let flow = flowOf [ hub, up1, down1 ]
  assert "every node comes in nodes' order"
    (selectVisibleNodeIds false flow == [ NodeId "hub", NodeId "up-1", NodeId "down-1" ])
  assert "the visible nodes come in nodes' order"
    (selectVisibleNodeIds true (flowOf [ up1, down1, hub ]) == [ NodeId "up-1", NodeId "hub" ])
  assert "a repeated id renders once, at its first position, as a Map keeps it"
    (selectVisibleNodeIds false (flowOf [ up1, hub, up1 ]) == [ NodeId "up-1", NodeId "hub" ])
