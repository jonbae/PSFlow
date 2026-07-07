-- | PureScript ports of xyflow's generic-test fixtures
-- | (`xyflow/examples/react/src/generic-tests/**`). Each fixture is the
-- | declarative node/edge data + a few flow-prop overrides that the adopted
-- | Playwright specs run against. `fixtureForRoute` maps a hash route
-- | (`#/tests/generic/<area>/<name>`) to its fixture.
module Generic.Fixture
  ( Fixture
  , nodesGeneral
  , fixtureForRoute
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), stripPrefix)
import Foreign.Object as Object
import Generic.DragHandleNode (dragHandleNode)
import React (Edge, Node, NodeTypesMap)
import System.Types.Connection (KeyCode(..))
import System.Types.Ids (NodeId(..))
import Unsafe.Coerce (unsafeCoerce)

-- | A fixture: the node/edge data plus the flow-prop overrides the upstream
-- | fixture sets (`deleteKeyCode`, `multiSelectionKeyCode`, …).
type Fixture =
  { nodes :: Array (Node Unit)
  , edges :: Array (Edge Unit)
  , deleteKeyCode :: Maybe KeyCode
  , multiSelectionKeyCode :: Maybe KeyCode
  , nodeDragThreshold :: Maybe Number
  , fitView :: Maybe Boolean
  , nodeTypes :: Maybe NodeTypesMap
  }

-- | A node at `(x, y)` with the documented defaults; callers record-update the
-- | few fields they need (`{ nodeType = Just "input" }`, `{ draggable = Just
-- | false }`, …). `measured` is pre-filled so the node is `visibility: visible`
-- | on first paint (the real ResizeObserver overwrites it after mount).
baseNode :: String -> Number -> Number -> Node Unit
baseNode nid x y =
  { id: NodeId nid
  , position: { x, y }
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
  , measured: { width: Just 150.0, height: Just 40.0 }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

baseEdge :: String -> String -> String -> Edge Unit
baseEdge eid src tgt =
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

-- | Port of `generic-tests/nodes/general.ts`.
nodesGeneral :: Fixture
nodesGeneral =
  { nodes:
      [ (baseNode "Node-1" 0.0 0.0)
          { nodeType = Just "input"
          , className = Just "playwright-test-class-123"
          , style = Just (Object.singleton "backgroundColor" "red")
          }
      , (baseNode "Node-2" (-100.0) 100.0) { nodeType = Just "output" }
      , baseNode "Node-3" 100.0 100.0
      , (baseNode "Node-4" 0.0 200.0) { nodeType = Just "output" }
      , (baseNode "drag-handle" 200.0 0.0)
          { nodeType = Just "DragHandleNode", dragHandle = Just ".custom-drag-handle" }
      , (baseNode "notConnectable" 0.0 300.0)
          { nodeType = Just "output", connectable = Just false }
      , (baseNode "notDraggable" 0.0 400.0) { draggable = Just false }
      , (baseNode "notSelectable" 0.0 500.0) { selectable = Just false }
      , (baseNode "notDeletable" 0.0 600.0) { deletable = Just false }
      , (baseNode "hidden" 0.0 700.0) { hidden = true }
      ]
  , edges:
      [ baseEdge "1-2" "Node-1" "Node-2"
      , baseEdge "1-3" "Node-1" "Node-3"
      ]
  , deleteKeyCode: Just (SingleKey "d")
  , multiSelectionKeyCode: Just (SingleKey "s")
  , nodeDragThreshold: Just 0.0
  , fitView: Just true
  -- `NodeTypesMap` is opaque (`foreign import data`); NodeWrapper resolution
  -- treats it as an `Object` of components (cf. `builtinNodeTypes`), so a
  -- coerced single-entry object registers the custom node under its type key.
  , nodeTypes: Just (unsafeCoerce (Object.singleton "DragHandleNode" dragHandleNode) :: NodeTypesMap)
  }

-- | Map a hash route (`#/tests/generic/nodes/general`) to its fixture.
fixtureForRoute :: String -> Maybe Fixture
fixtureForRoute route =
  case dropHash route of
    "/tests/generic/nodes/general" -> Just nodesGeneral
    _ -> Nothing
  where
  dropHash r = case stripPrefix (Pattern "#") r of
    Just r' -> r'
    Nothing -> r
