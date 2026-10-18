-- | The order a measurement reports its nodes in.
-- |
-- | The local proxy for the map's "`Data.Map` key order leaking into render
-- | order" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93),
-- | which the report shows as 194 `args/id` rows across 34 scenarios, all in
-- | the first measurement's `onNodesChange`, and 104 `dimensions` rows they
-- | cause. Upstream's `updateNodeInternals` walks
-- |
-- |     for (const update of updates.values()) { … changes.push({ id, type: 'dimensions', … }) }
-- |
-- | over a JavaScript `Map`, which iterates in insertion order: the order the
-- | `ResizeObserver` reported the nodes, which on a first mount is the nodes'
-- | own. ps-flow's batch was a `Data.Map`, which iterates by key, so nodes
-- | `1` to `12` came out as `1, 10, 11, 12, 2, …`.
module Test.System.Utils.MeasurementOrder
  ( runMeasurementOrderTests
  ) where

import Prelude

import Data.Array (mapMaybe)
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import System.Types.Ids (NodeId(..))
import System.Types.Node (InternalNodeUpdate, NodeBase, NodeChange(..))
import System.Utils.Store (setUpdate, updateNodeInternals)
import Web.HTML.HTMLDivElement (HTMLDivElement)
import Web.HTML.HTMLElement (HTMLElement)

foreign import fakeNodeElement :: Number -> Number -> HTMLDivElement
foreign import fakeFlowRoot :: HTMLElement
foreign import withFakeWindowImpl :: forall a. Effect a -> Effect a

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

nodeAt :: String -> NodeBase Unit
nodeAt id =
  { id: NodeId id
  , position: { x: 0.0, y: 0.0 }
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

update :: String -> Boolean -> InternalNodeUpdate
update id force = { id: NodeId id, nodeElement: fakeNodeElement 50.0 25.0, force }

-- | The ids of the dimension changes a measurement of `batch` reports.
measuredOrder :: Array String -> Array String -> Effect (Array String)
measuredOrder nodes batch = do
  let
    state = initialState
      ((defaultInitialStateOptions :: InitialStateOptions Unit Unit) { nodes = Just (map nodeAt nodes) })
  result <- withFakeWindowImpl
    ( updateNodeInternals (map (\id -> update id false) batch) state.nodeLookup state.parentLookup
        (Just fakeFlowRoot)
        state.nodeOrigin
        state.nodeExtent
        state.zIndexMode
    )
  pure
    ( mapMaybe
        ( case _ of
            NodeDimensionChange c -> Just (unwrap c.id)
            _ -> Nothing
        )
        result.changes
    )

runMeasurementOrderTests :: Effect Unit
runMeasurementOrderTests = do
  log "\n=== A measurement reports its nodes in the order they were batched ==="

  let ids = [ "1", "2", "3", "10", "11", "12", "12-a" ]
  inOrder <- measuredOrder ids ids
  assert "a batch in the nodes' order reports them in that order, not by key"
    (inOrder == ids)

  reordered <- measuredOrder [ "down-1", "hub", "up-1" ] [ "hub", "up-1", "down-1" ]
  assert "the batch's order wins over both the keys and the nodes' order"
    (reordered == [ "hub", "up-1", "down-1" ])

  let
    appended = setUpdate (update "b" true) (setUpdate (update "a" true) [])
    repeated = setUpdate (update "a" false) appended
  assert "setUpdate puts a new id last, as Map.set does"
    (map (unwrap <<< _.id) appended == [ "a", "b" ])
  assert "setUpdate keeps a repeated id's place and takes the new value"
    (map (\u -> unwrap u.id <> (if u.force then "!" else "")) repeated == [ "a", "b!" ])
