-- | What an arrow key on a selected node announces in the aria-live region.
-- |
-- | The local proxy for the aria-live row in the report's
-- | `arrow-key-selected-node` scenario, which
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name. Upstream's `NodeWrapper` sets `ariaLiveMessage` from
-- | `ariaLabelConfig['node.a11yDescription.ariaLiveMessage']` before it
-- | moves the selected nodes, with the key's direction and the node's
-- | position before the move, truncated with `~~`. ps-flow's `NodeWrapper`
-- | moved the nodes and announced nothing, so the scenario's region read
-- | "Moved selected node right. New position, x: 5, y: 20" upstream and
-- | was empty in ps-flow.
module Test.React.Node.ArrowKeyMessage
  ( runArrowKeyMessageTests
  ) where

import Prelude

import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Number.Format (toString) as NumberFormat
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Hook.MoveSelectedNodes (moveSelectedNodes)
import React.Node.Util (moveNodesByArrowKey)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import React.Types.Nodes (Node)
import System.Types.Geometry (XYPosition)
import System.Types.Ids (NodeId(..))

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

node :: String -> XYPosition -> Node Unit
node id position =
  { id: NodeId id
  , position
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: Nothing
  , selected: Just true
  , resizing: Nothing
  , dragging: Nothing
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
  , measured: { width: Just 150.0, height: Just 40.0 }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

type Flow =
  { store :: Store Unit Unit
  -- | `ariaLiveMessage` as each `onNodesChange` call found it.
  , heard :: Effect (Array String)
  }

-- | A controlled flow of `nodes`, whose `onNodesChange` doesn't apply the
-- | changes, as a flow between a move and its re-render.
flow :: Array (Node Unit) -> Effect Flow
flow nodes = do
  store <- createStore ((defaultInitialStateOptions :: InitialStateOptions Unit Unit) { nodes = Just nodes })
  heard <- Ref.new ([] :: Array String)
  store.setState _
    { onNodesChange = Just \_ -> do
        s <- store.getState
        Ref.modify_ (_ <> [ s.ariaLiveMessage ]) heard
    }
  pure { store, heard: Ref.read heard }

-- | A press of `key` on the node `id`, which the wrapper last rendered at
-- | `rendered`.
press :: Flow -> String -> String -> XYPosition -> XYPosition -> Effect Unit
press f id key direction rendered =
  moveNodesByArrowKey
    { id: NodeId id
    , store: f.store
    , key
    , direction
    , factor: 1.0
    , positionAbsolute: rendered
    , moveSelectedNodes: moveSelectedNodes f.store
    }

message :: Flow -> Effect String
message f = _.ariaLiveMessage <$> f.store.getState

positionOf :: Flow -> String -> Effect (Maybe XYPosition)
positionOf f id = map _.position <<< Map.lookup (NodeId id) <<< _.nodeLookup <$> f.store.getState

origin :: XYPosition
origin = { x: 0.0, y: 0.0 }

runArrowKeyMessageTests :: Effect Unit
runArrowKeyMessageTests = do
  log "\n=== NodeWrapper's arrow keys: what a move announces in the aria-live region ==="

  down <- flow [ node "a" origin ]
  press down "a" "ArrowDown" { x: 0.0, y: 1.0 } origin
  downMessage <- message down
  downAt <- positionOf down "a"
  assert "a press announces the direction and the position before the move, and moves the node"
    (downMessage == "Moved selected node down. New position, x: 0, y: 0" && downAt == Just { x: 0.0, y: 5.0 })
  downHeard <- down.heard
  assert "and announces before it moves, so onNodesChange finds the message set"
    (downHeard == [ "Moved selected node down. New position, x: 0, y: 0" ])

  press down "a" "ArrowRight" { x: 1.0, y: 0.0 } origin
  rightMessage <- message down
  assert "a second press before a re-render announces the position the first press left in the lookup"
    (rightMessage == "Moved selected node right. New position, x: 0, y: 5")

  press down "a" "ArrowLeft" { x: -1.0, y: 0.0 } origin
  press down "a" "ArrowUp" { x: 0.0, y: -1.0 } origin
  upMessage <- message down
  assert "the direction is the key without its Arrow, in lower case"
    (upMessage == "Moved selected node up. New position, x: 0, y: 5")

  fractional <- flow [ node "a" { x: 10.7, y: -3.9 } ]
  press fractional "a" "ArrowDown" { x: 0.0, y: 1.0 } origin
  fractionalMessage <- message fractional
  assert "the position is truncated toward zero, as ~~ does"
    (fractionalMessage == "Moved selected node down. New position, x: 10, y: -3")

  huge <- flow [ node "a" { x: 4294967301.0, y: 0.0 } ]
  press huge "a" "ArrowDown" { x: 0.0, y: 1.0 } origin
  hugeMessage <- message huge
  assert "and wrapped to 32 bits, as ~~ does"
    (hugeMessage == "Moved selected node down. New position, x: 5, y: 0")

  custom <- flow [ node "a" origin ]
  custom.store.setState \s -> s
    { ariaLabelConfig = s.ariaLabelConfig
        { nodeA11yDescriptionAriaLiveMessage = \r -> r.direction <> " to " <> NumberFormat.toString r.x <> "/" <> NumberFormat.toString r.y }
    }
  press custom "a" "ArrowDown" { x: 0.0, y: 1.0 } origin
  customMessage <- message custom
  assert "the message comes from the store's ariaLabelConfig"
    (customMessage == "down to 0/0")

  gone <- flow [ node "a" origin ]
  press gone "z" "ArrowDown" { x: 0.0, y: 1.0 } { x: 7.0, y: 8.0 }
  goneMessage <- message gone
  assert "a node the lookup no longer holds announces the position it was rendered at"
    (goneMessage == "Moved selected node down. New position, x: 7, y: 8")
