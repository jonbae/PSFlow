-- | The order of the drag items, and the three things that read it.
-- |
-- | The local proxy for "Snap a multi-node drag to the grabbed node, not the
-- | lowest-keyed one" (#110), whose premise this corrects. Upstream builds
-- | `dragItems` as a JS `Map` by iterating `nodeLookup`, so the items are in
-- | the order of the `nodes` array the lookup was adopted from
-- | (`xyflow/packages/system/src/xydrag/utils.ts`). Then:
-- |
-- |   * `calculateSnapOffset` snaps the first item exactly to the grid and
-- |     moves the rest by the same offset;
-- |   * `getEventHandlerParams` reports the first item as the current node
-- |     when no node was grabbed, which is a selection drag;
-- |   * `updateNodePositions` emits its changes in item order, which is the
-- |     order `onNodesChange` receives them in.
-- |
-- | ps-flow built a `Data.Map`, which iterates by key, so the first item was
-- | whichever id sorted first. The ticket read upstream's first item as the
-- | grabbed node, but `getDragItems` doesn't put the grabbed node first.
-- |
-- | Here `b` comes before `a` in the `nodes` array and `a` sorts first, and
-- | the pointer grabs `a`. Building the items in key order fails every check,
-- | and so does taking the grabbed node as the reference.
module Test.System.XYDrag.DragItemOrder
  ( runDragItemOrderTests
  ) where

import Prelude

import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import System.Types.Geometry (XYPosition, mkSnapGrid)
import System.Types.Ids (NodeId(..))
import System.Types.Node (InternalNodeBase, NodeLookup)
import System.XYDrag.Utils (calculateSnapOffset, getDragItems, getEventHandlerParams)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | A selected, draggable 50 × 25 node at `at`.
nodeAt :: NodeId -> XYPosition -> InternalNodeBase Unit
nodeAt id at =
  { id
  , position: at
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: Nothing
  , selected: Just true
  , dragging: Nothing
  , draggable: Just true
  , selectable: Nothing
  , connectable: Nothing
  , deletable: Nothing
  , dragHandle: Nothing
  , width: Just 50.0
  , height: Just 25.0
  , initialWidth: Nothing
  , initialHeight: Nothing
  , parentId: Nothing
  , zIndex: Nothing
  , extent: Nothing
  , expandParent: Nothing
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Just 50.0, height: Just 25.0 }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  , internals:
      { positionAbsolute: at
      , z: 0.0
      , rootParentIndex: Nothing
      , handleBounds: Nothing
      , bounds: Nothing
      }
  }

idA :: NodeId
idA = NodeId "a"

idB :: NodeId
idB = NodeId "b"

lookup :: NodeLookup Unit
lookup = Map.fromFoldable
  [ Tuple idA (nodeAt idA { x: 0.0, y: 0.0 })
  , Tuple idB (nodeAt idB { x: 4.0, y: 0.0 })
  ]

-- | The `nodes` array the lookup was adopted from: `b` first.
nodesOrder :: Array NodeId
nodesOrder = [ idB, idA ]

-- | The pointer goes down on `a`'s top-left corner.
grab :: XYPosition
grab = { x: 0.0, y: 0.0 }

runDragItemOrderTests :: Effect Unit
runDragItemOrderTests = do
  log "\n=== XYDrag: drag items keep the nodes array's order (#110) ==="

  let items = getDragItems nodesOrder lookup true grab (Just idA)
  assert "getDragItems keeps the order of the nodes array, not of the ids"
    (map _.id items == [ idB, idA ])

  -- The pointer moves 3px right on a 10px grid. `a` would land at 3 and `b`
  -- at 7, so the reference decides which one snaps: `b` goes to 10 and takes
  -- `a` to 6 with it. With `a` as the reference, `a` goes to 0 and `b` to 4.
  let offset = calculateSnapOffset items (mkSnapGrid 10.0 10.0) 3.0 0.0
  assert "a multi-node drag snaps the first node in the nodes array, not the grabbed one"
    (offset == Just { x: 3.0, y: 0.0 })

  let selection = getEventHandlerParams Nothing items lookup true
  assert "a selection drag reports the first node in the nodes array as current"
    (map _.id selection.currentNode == Just idB)
  assert "a selection drag lists its nodes in the nodes array's order"
    (map _.id selection.allNodes == [ idB, idA ])
