-- | What a measured node holds for a side it has no handle on.
-- |
-- | The local proxy for the `api/queries/getInternalNode/internals/handleBounds/target`
-- | row that nearly every scenario in the report carries, which
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name. Upstream's `getHandleBounds` returns `null` when a
-- | node's element holds no handle of the side it queries, and
-- | `updateNodeInternals` stores that `null` as the side. `parseHandles`,
-- | which reads a node's own `handles`, always returns both arrays. ps-flow's
-- | `processUpdate` turned each `null` into `[]`, so an `input` node read
-- | back `target: []` where upstream's reads `target: null`.
-- |
-- | Every upstream reader folds a `null` side into `[]` with `?? []`, or
-- | finds no handle on it with `?.`. The last checks hold the port's readers
-- | to the same.
module Test.System.Utils.HandleBoundsNull
  ( runHandleBoundsNullTests
  ) where

import Prelude

import Boundary.Elements (JsInternalNode, internalNodeOut)
import Data.Map as Map
import Data.Maybe (Maybe(..), isJust)
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign (Foreign)
import Partial.Unsafe (unsafeCrashWith)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import System.Types.Connection (ConnectionMode(..))
import System.Types.Geometry (Position(..))
import System.Types.Handle (HandleIdField(..), HandleType(..))
import System.Types.Ids (NodeId(..))
import System.Types.Node (InternalNodeBase, NodeBase, NodeLookup)
import System.Utils.Edges.Positions (getEdgePosition)
import System.Utils.Store (updateNodeInternals)
import System.XYHandle.Utils (getHandle)
import Unsafe.Coerce (unsafeCoerce)
import Web.HTML.HTMLDivElement (HTMLDivElement)
import Web.HTML.HTMLElement (HTMLElement)

foreign import sourceOnlyElement :: HTMLDivElement
foreign import targetOnlyElement :: HTMLDivElement
foreign import handlelessElement :: HTMLDivElement
foreign import fakeFlowRoot :: HTMLElement
foreign import withFakeWindowImpl :: forall a. Effect a -> Effect a
foreign import handleBoundsSides :: JsInternalNode -> String

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

nodeAt :: String -> Number -> NodeBase Foreign
nodeAt id x =
  { id: NodeId id
  , position: { x, y: 0.0 }
  , data: unsafeCoerce {}
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: Nothing
  , selected: Nothing
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
  , resizing: Nothing
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Nothing, height: Nothing }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

-- | The lookup after `updateNodeInternals` measures each node in `nodes`
-- | against the element beside it.
measure :: Array { node :: NodeBase Foreign, element :: HTMLDivElement } -> Effect (NodeLookup Foreign)
measure nodes = do
  let
    state = initialState
      ((defaultInitialStateOptions :: InitialStateOptions Foreign Foreign) { nodes = Just (map _.node nodes) })
    updates = map (\n -> { id: n.node.id, nodeElement: n.element, force: false }) nodes
  result <- withFakeWindowImpl
    ( updateNodeInternals updates state.nodeLookup state.parentLookup (Just fakeFlowRoot)
        state.nodeOrigin
        state.nodeExtent
        state.zIndexMode
    )
  pure result.nodeLookup

-- | A node's `internals.handleBounds` as a consumer reads it off
-- | `getInternalNode`.
sidesOf :: String -> NodeLookup Foreign -> Maybe String
sidesOf id lookup = handleBoundsSides <<< internalNodeOut <$> Map.lookup (NodeId id) lookup

internal :: String -> NodeLookup Foreign -> InternalNodeBase Foreign
internal id lookup = case Map.lookup (NodeId id) lookup of
  Just n -> n
  Nothing -> unsafeCrashWith ("no node " <> id)

runHandleBoundsNullTests :: Effect Unit
runHandleBoundsNullTests = do
  log "\n=== updateNodeInternals: a side with no handle is null, as upstream's getHandleBounds returns ==="

  measured <- measure
    [ { node: nodeAt "in" 0.0, element: sourceOnlyElement }
    , { node: nodeAt "out" 200.0, element: targetOnlyElement }
    , { node: nodeAt "bare" 400.0, element: handlelessElement }
    ]
  assert "a node with only a source handle reads back target: null"
    (sidesOf "in" measured == Just "source 1, target null")
  assert "a node with only a target handle reads back source: null"
    (sidesOf "out" measured == Just "source null, target 1")
  assert "a node with no handles reads back both sides null"
    (sidesOf "bare" measured == Just "source null, target null")

  let
    declared = (nodeAt "declared" 0.0)
      { handles = Just
          [ { id: HandleIdUnset, x: 44.0, y: 10.0, position: PosRight, handleType: Source, width: Nothing, height: Nothing } ]
      , measured = { width: Just 50.0, height: Just 25.0 }
      }
    adopted = (initialState
      ((defaultInitialStateOptions :: InitialStateOptions Foreign Foreign) { nodes = Just [ declared ] })).nodeLookup
  assert "a node's own handles give both sides as arrays, as parseHandles does"
    (sidesOf "declared" adopted == Just "source 1, target 0")

  let
    edgeBetween mode = getEdgePosition
      { id: "in-out"
      , sourceNode: internal "in" measured
      , sourceHandle: Nothing
      , targetNode: internal "out" measured
      , targetHandle: Nothing
      , connectionMode: mode
      }
  assert "an edge still finds its handles across the null sides, in strict mode"
    (isJust (edgeBetween Strict))
  assert "and in loose mode"
    (isJust (edgeBetween Loose))
  assert "an edge out of a null source side, into a null target side, finds no handles"
    ( getEdgePosition
        { id: "out-in"
        , sourceNode: internal "out" measured
        , sourceHandle: Nothing
        , targetNode: internal "in" measured
        , targetHandle: Nothing
        , connectionMode: Strict
        }
        == Nothing
    )
  assert "getHandle finds no handle on a null side in strict mode"
    (getHandle (NodeId "in") Target Nothing measured Strict false == Nothing)
  assert "and finds the other side's handle in loose mode, as the spread with ?? [] does"
    (map _.handleType (getHandle (NodeId "in") Target Nothing measured Loose false) == Just Source)
