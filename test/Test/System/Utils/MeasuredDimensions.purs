-- | What a node's first measurement hands `onNodesChange`, and what applying
-- | it does to the node.
-- |
-- | The local proxy for the map's "`setAttributes` emitted unconditionally in
-- | `System.Utils.Store`" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's `updateNodeInternals` pushes `{ id, type: 'dimensions',
-- | dimensions }` for a node whose measured size changed, and only
-- | `handleExpandParent`'s change for a parent carries `setAttributes: true`.
-- | `applyNodeChanges` copies the size onto the node's own `width` and
-- | `height` only when `setAttributes` is set, so on upstream a measured node
-- | keeps the `width` and `height` the consumer gave it, which is usually
-- | none. ps-flow set `setAttributes` on every measurement, so every node a
-- | consumer read back had a `width` and a `height`, and rendered them as
-- | inline style.
module Test.System.Utils.MeasuredDimensions
  ( runMeasuredDimensionsTests
  ) where

import Prelude

import Data.Array (findMap) as Array
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Store.Changes (applyNodeChanges)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import System.Types.Geometry (Dimensions)
import System.Types.Ids (NodeId(..), nodeToParent)
import System.Types.Node (NodeBase, NodeChange(..), SetAttributesMode)
import System.Utils.Store (updateNodeInternals)
import Web.HTML.HTMLDivElement (HTMLDivElement)
import Web.HTML.HTMLElement (HTMLElement)

foreign import fakeNodeElement :: Number -> Number -> HTMLDivElement
foreign import fakeFlowRoot :: HTMLElement
foreign import withFakeWindowImpl :: forall a. Effect a -> Effect a

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | A user node at `at` with no `width` or `height` of its own.
nodeAt :: String -> { x :: Number, y :: Number } -> NodeBase Unit
nodeAt id at =
  { id: NodeId id
  , position: at
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
  , measured: { width: Nothing, height: Nothing }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

type DimensionChange = { dimensions :: Maybe Dimensions, setAttributes :: SetAttributesMode }

dimensionChangeFor :: NodeId -> Array (NodeChange Unit) -> Maybe DimensionChange
dimensionChangeFor id = Array.findMap case _ of
  NodeDimensionChange c | c.id == id -> Just { dimensions: c.dimensions, setAttributes: c.setAttributes }
  _ -> Nothing

-- | The changes `updateNodeInternals` returns when each of `measured` is
-- | measured at 50 × 25, in a flow holding `nodes`.
measure :: Array (NodeBase Unit) -> Array String -> Effect (Array (NodeChange Unit))
measure nodes measured = do
  let
    state = initialState
      ((defaultInitialStateOptions :: InitialStateOptions Unit Unit) { nodes = Just nodes })
    updates = Map.fromFoldable
      ( map
          (\id -> Tuple (NodeId id) { id: NodeId id, nodeElement: fakeNodeElement 50.0 25.0, force: false })
          measured
      )
  result <- withFakeWindowImpl
    ( updateNodeInternals updates state.nodeLookup state.parentLookup (Just fakeFlowRoot)
        state.nodeOrigin
        state.nodeExtent
        state.zIndexMode
    )
  pure result.changes

runMeasuredDimensionsTests :: Effect Unit
runMeasuredDimensionsTests = do
  log "\n=== updateNodeInternals: a measurement doesn't set the node's width and height ==="

  let a = nodeAt "a" { x: 0.0, y: 0.0 }
  changes <- measure [ a ] [ "a" ]
  let measuredA = dimensionChangeFor (NodeId "a") changes
  assert "a node's first measurement reports its size"
    (map _.dimensions measuredA == Just (Just { width: 50.0, height: 25.0 }))
  assert "a node's measurement change carries no setAttributes"
    (map _.setAttributes measuredA == Just Nothing)

  let applied = applyNodeChanges changes [ a ]
  assert "applying the measurement sets the node's measured size"
    (map _.measured applied == [ { width: Just 50.0, height: Just 25.0 } ])
  assert "applying the measurement leaves the node's own width and height unset"
    (map _.width applied == [ Nothing ] && map _.height applied == [ Nothing ])

  -- `c` sits 40px into a 50px-wide parent and measures 50px wide, so the
  -- parent has to grow to 90px to hold it.
  let
    parent = (nodeAt "p" { x: 0.0, y: 0.0 }) { measured = { width: Just 50.0, height: Just 25.0 } }
    child = (nodeAt "c" { x: 40.0, y: 0.0 })
      { parentId = Just (nodeToParent (NodeId "p")), expandParent = Just true }
  expandChanges <- measure [ parent, child ] [ "c" ]
  let grown = dimensionChangeFor (NodeId "p") expandChanges
  assert "an expandParent child grows its parent"
    (map (map _.width <<< _.dimensions) grown == Just (Just 90.0))
  assert "the parent's change still carries setAttributes, as upstream's does"
    (map _.setAttributes grown == Just (Just { width: true, height: true }))
