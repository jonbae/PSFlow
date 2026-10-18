-- | What the store does with a measurement, as upstream's
-- | `updateNodeInternals` action does it.
-- |
-- | The local proxy for `reduceMergeNodeInternals` on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93),
-- | which 80 `callbacks` rows showed ordered differently: on a flow that
-- | mounts with `fitView`, upstream fires `onMoveStart` before the first
-- | `onNodesChange`, and ps-flow fired them the other way round. Upstream's
-- | action returns early when nothing was measured, runs
-- | `updateAbsolutePositions` over the lookup, resolves a queued fit, and only
-- | then triggers the node changes. It doesn't touch `nodesInitialized`.
-- | ps-flow's triggered the changes before the fit, never ran
-- | `updateAbsolutePositions`, and set `nodesInitialized`.
module Test.React.Store.MergeNodeInternals
  ( runMergeNodeInternalsTests
  ) where

import Prelude

import Data.Map as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Store.Action (Action(..), Effect_(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import React.Store.Reduce (reduce)
import React.Types.Store (ReactFlowState)
import System.Types.Geometry (XYPosition, mkNodeOrigin)
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeBase, NodeChange(..))

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

nodeAt :: String -> XYPosition -> NodeBase Unit
nodeAt id at =
  { id: NodeId id
  , position: at
  , data: unit
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
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Nothing, height: Nothing }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

type State = ReactFlowState Unit Unit

-- | A controlled flow with one unmeasured node at (100, 100).
mounted :: InitialStateOptions Unit Unit -> State
mounted opts = initialState (opts { nodes = Just [ nodeAt "a" { x: 100.0, y: 100.0 } ] })

-- | What the shell hands back after measuring node `a` at 50 by 40.
measuredIn :: State -> Boolean -> Action Unit Unit
measuredIn s updatedInternals =
  MergeNodeInternalsResult
    { nodeLookup: Map.update (\n -> Just n { measured = { width: Just 50.0, height: Just 40.0 } }) (NodeId "a") s.nodeLookup
    , parentLookup: s.parentLookup
    , changes:
        if updatedInternals then
          [ NodeDimensionChange { id: NodeId "a", dimensions: Just { width: 50.0, height: 40.0 }, resizing: Nothing, setAttributes: Nothing } ]
        else []
    , updatedInternals
    , triggerFitView: false
    }

describe :: Effect_ Unit Unit -> String
describe = case _ of
  ResolveFitView _ -> "fit"
  FireOnNodesChange _ -> "onNodesChange"
  _ -> "other"

positionAbsoluteOf :: State -> Maybe XYPosition
positionAbsoluteOf s = map _.internals.positionAbsolute (Map.lookup (NodeId "a") s.nodeLookup)

runMergeNodeInternalsTests :: Effect Unit
runMergeNodeInternalsTests = do
  log "\n=== updateNodeInternals: what the store does with a measurement ==="

  let
    queued = mounted (defaultInitialStateOptions { fitView = Just true })
    fitted = reduce queued (measuredIn queued true)
  assert "a queued fit resolves before the node changes fire"
    (map describe fitted.effects == [ "fit", "onNodesChange" ])
  assert "the queued fit is cleared"
    (not fitted.state.fitViewQueued)

  let
    plain = mounted defaultInitialStateOptions
  assert "without a queued fit, only the node changes fire"
    (map describe (reduce plain (measuredIn plain true)).effects == [ "onNodesChange" ])

  let
    idle = reduce queued (measuredIn queued false)
  assert "when nothing was measured, nothing is set, fitted, or reported"
    ( map describe idle.effects == [] && idle.state.fitViewQueued
        && map _.measured.width (Map.lookup (NodeId "a") idle.state.nodeLookup) == Just Nothing
    )

  assert "a measurement doesn't set nodesInitialized"
    (not (reduce plain (measuredIn plain true)).state.nodesInitialized)

  let
    centred = mounted (defaultInitialStateOptions { nodeOrigin = Just (mkNodeOrigin 0.5 0.5) })
  assert "the absolute positions are recomputed with the measured dimensions"
    (positionAbsoluteOf (reduce centred (measuredIn centred true)).state == Just { x: 75.0, y: 80.0 })
