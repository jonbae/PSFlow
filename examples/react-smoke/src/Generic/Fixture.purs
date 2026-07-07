-- | PureScript ports of xyflow's generic-test fixtures
-- | (`xyflow/examples/react/src/generic-tests/**`). Each fixture is the
-- | declarative node/edge data + a few flow-prop overrides that the adopted
-- | Playwright specs run against. `fixtureForRoute` maps a hash route
-- | (`#/tests/generic/<area>/<name>`) to its fixture.
module Generic.Fixture
  ( Fixture
  , nodesGeneral
  , paneGeneral
  , paneNonDefaults
  , edgesGeneral
  , fixtureForRoute
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), stripPrefix)
import Foreign.Object as Object
import Generic.DragHandleNode (dragHandleNode)
import React (Edge, Node, NodeTypesMap)
import System.Types.Connection (KeyCode(..), Viewport)
import System.Types.Edge (EdgeMarker, EdgeMarkerType(..), MarkerType(..))
import System.Types.Ids (NodeId(..), ParentId(..))
import Unsafe.Coerce (unsafeCoerce)

-- | A fixture: the node/edge data plus the flow-prop overrides the upstream
-- | fixture sets (`deleteKeyCode`, `multiSelectionKeyCode`, …). The pan/zoom
-- | props (`minZoom` … `autoPanOnNodeDrag`) surface the `Nothing` defaults that
-- | already exist in `Generic.Defaults` so the pane fixtures can override them.
type Fixture =
  { nodes :: Array (Node Unit)
  , edges :: Array (Edge Unit)
  , deleteKeyCode :: Maybe KeyCode
  , multiSelectionKeyCode :: Maybe KeyCode
  , nodeDragThreshold :: Maybe Number
  , fitView :: Maybe Boolean
  , nodeTypes :: Maybe NodeTypesMap
  , minZoom :: Maybe Number
  , maxZoom :: Maybe Number
  , panOnScroll :: Maybe Boolean
  , defaultViewport :: Maybe Viewport
  , autoPanOnConnect :: Maybe Boolean
  , autoPanOnNodeDrag :: Maybe Boolean
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
  , className: Nothing
  , style: Nothing
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
  , minZoom: Nothing
  , maxZoom: Nothing
  , panOnScroll: Nothing
  , defaultViewport: Nothing
  , autoPanOnConnect: Nothing
  , autoPanOnNodeDrag: Nothing
  }

-- | Shared node/edge data for both pane fixtures: 3 nodes (`1` = input, `2`/`3`
-- | default) + 2 edges (`first-edge`, `second-edge`). Mirrors the `nodes`/`edges`
-- | in both `generic-tests/pane/{general,non-defaults}.ts`.
paneNodes :: Array (Node Unit)
paneNodes =
  [ (baseNode "1" 0.0 0.0) { nodeType = Just "input" }
  , baseNode "2" (-100.0) 100.0
  , baseNode "3" 100.0 100.0
  ]

paneEdges :: Array (Edge Unit)
paneEdges =
  [ baseEdge "first-edge" "1" "2"
  , baseEdge "second-edge" "1" "3"
  ]

-- | Port of `generic-tests/pane/general.ts` — `minZoom:0.25, maxZoom:4, fitView`.
paneGeneral :: Fixture
paneGeneral =
  { nodes: paneNodes
  , edges: paneEdges
  , deleteKeyCode: Nothing
  , multiSelectionKeyCode: Nothing
  , nodeDragThreshold: Nothing
  , fitView: Just true
  , nodeTypes: Nothing
  , minZoom: Just 0.25
  , maxZoom: Just 4.0
  , panOnScroll: Nothing
  , defaultViewport: Nothing
  , autoPanOnConnect: Nothing
  , autoPanOnNodeDrag: Nothing
  }

-- | Port of `generic-tests/pane/non-defaults.ts` — `panOnScroll:true`,
-- | `defaultViewport:{1.23, 9.87, 1.234}`, `autoPanOnConnect/NodeDrag:false`.
paneNonDefaults :: Fixture
paneNonDefaults =
  { nodes: paneNodes
  , edges: paneEdges
  , deleteKeyCode: Nothing
  , multiSelectionKeyCode: Nothing
  , nodeDragThreshold: Nothing
  , fitView: Nothing
  , nodeTypes: Nothing
  , minZoom: Nothing
  , maxZoom: Nothing
  , panOnScroll: Just true
  , defaultViewport: Just { x: 1.23, y: 9.87, zoom: 1.234 }
  , autoPanOnConnect: Just false
  , autoPanOnNodeDrag: Just false
  }

-- | A custom marker carrying only its `type` (all other fields absent), matching
-- | the fixture's `{ type: MarkerType.X }`. `getMarkerId` encodes it as
-- | `<rfId>__type=arrow[closed]`.
markerOfType :: MarkerType -> EdgeMarker
markerOfType t =
  { markerType: t
  , color: Nothing
  , width: Nothing
  , height: Nothing
  , markerUnits: Nothing
  , orient: Nothing
  , strokeWidth: Nothing
  }

-- | Port of `generic-tests/edges/general.ts` — 14 nodes (incl. subflow parent
-- | `12` with children `12-a`/`12-b`) + 12 edges, each exercising one edge prop.
-- | Labels are dropped (no test asserts label text; `EdgeBase` carries none).
edgesGeneral :: Fixture
edgesGeneral =
  { nodes:
      [ (baseNode "1" 0.0 0.0) { nodeType = Just "input" }
      , baseNode "2" (-100.0) 100.0
      , baseNode "3" 100.0 100.0
      , baseNode "4" (-100.0) 200.0
      , baseNode "5" 100.0 200.0
      , baseNode "6" (-100.0) 300.0
      , baseNode "7" 100.0 300.0
      , baseNode "8" (-100.0) 400.0
      , baseNode "9" 100.0 400.0
      , baseNode "10" (-100.0) 500.0
      , baseNode "11" 100.0 500.0
      , (baseNode "12" 100.0 600.0)
          { width = Just 200.0
          , height = Just 100.0
          , measured = { width: Just 200.0, height: Just 100.0 }
          }
      , (baseNode "12-a" 10.0 20.0)
          { parentId = Just (ParentId "12")
          , width = Just 50.0
          , height = Just 50.0
          , measured = { width: Just 50.0, height: Just 50.0 }
          }
      , (baseNode "12-b" 140.0 20.0)
          { parentId = Just (ParentId "12")
          , width = Just 50.0
          , height = Just 50.0
          , measured = { width: Just 50.0, height: Just 50.0 }
          }
      ]
  , edges:
      [ (baseEdge "edge-with-class" "1" "2") { className = Just "edge-class-test" }
      , (baseEdge "edge-with-style" "1" "3") { style = Just (Object.singleton "stroke" "red") }
      , (baseEdge "hidden-edge" "2" "4") { hidden = true }
      , (baseEdge "animated-edge" "3" "5") { animated = true }
      , (baseEdge "not-selectable-edge" "4" "6") { selectable = Just false }
      , (baseEdge "not-deletable" "5" "7") { deletable = Just false }
      , (baseEdge "z-index" "6" "8") { zIndex = Just 3141592 }
      , (baseEdge "aria-label" "7" "9") { ariaLabel = Just "aria-label-test" }
      -- Upstream uses `interactionWidth: 42` and the spec clicks a fixed +21px
      -- (= 42/2) off-centre, which assumes zoom 1. This graph is ~700 flow-units
      -- tall, so fitView (default 0.1 padding, 720px viewport) settles at zoom
      -- ~0.937 — identical to upstream — making the 42-unit interaction stroke
      -- render ~39px wide and a +21px click land ~1px *outside* it (Playwright's
      -- SVG boundingBox is the stroke-independent geometric box, so widening the
      -- stroke moves its outer edge past the click without shifting the box centre).
      -- Bump to 50 so the on-screen half-width (~23px) comfortably covers the
      -- unmodified spec's +21px probe; the value itself is not asserted.
      , (baseEdge "interaction-width" "8" "10") { interactionWidth = Just 50.0 }
      , (baseEdge "markers" "9" "11")
          { markerStart = Just (CustomMarker (markerOfType ArrowClosed))
          , markerEnd = Just (CustomMarker (markerOfType Arrow))
          }
      , baseEdge "subflow-edge" "11" "12-a"
      , baseEdge "subflow-edge-2" "12-a" "12-b"
      ]
  , deleteKeyCode: Just (SingleKey "d")
  , multiSelectionKeyCode: Just (SingleKey "s")
  , nodeDragThreshold: Nothing
  , fitView: Just true
  , nodeTypes: Nothing
  , minZoom: Nothing
  , maxZoom: Nothing
  , panOnScroll: Nothing
  , defaultViewport: Nothing
  , autoPanOnConnect: Nothing
  , autoPanOnNodeDrag: Nothing
  }

-- | Map a hash route (`#/tests/generic/nodes/general`) to its fixture.
fixtureForRoute :: String -> Maybe Fixture
fixtureForRoute route =
  case dropHash route of
    "/tests/generic/nodes/general" -> Just nodesGeneral
    "/tests/generic/pane/general" -> Just paneGeneral
    "/tests/generic/pane/non-defaults" -> Just paneNonDefaults
    "/tests/generic/edges/general" -> Just edgesGeneral
    _ -> Nothing
  where
  dropHash r = case stripPrefix (Pattern "#") r of
    Just r' -> r'
    Nothing -> r
