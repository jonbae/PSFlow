-- | `defaultEdgeOptions` with all 23 of upstream's members, against
-- | upstream's own merge.
-- |
-- | Until Step 3 G ps-flow's options record carried ten members and the
-- | boundary refused the other thirteen at mount. These check the two places
-- | upstream spreads the options: under every edge `<EdgeWrapper />` renders,
-- | including an edge that owns a key holding `undefined`, and under the
-- | connection `onConnect` receives, which is also the edge an uncontrolled
-- | flow adds. The JavaScript side builds upstream's answer from the same
-- | objects with object spread and upstream's exported `addEdge`.
module Test.Boundary.DefaultEdgeOptions
  ( runDefaultEdgeOptionsTests
  ) where

import Prelude

import Boundary.Callbacks (onConnectIn)
import Boundary.Elements (JsConnection, JsDefaultEdgeOptions, JsEdge, defaultEdgeOptionsIn, edgeIn, edgeOut)
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable, toMaybe)
import Data.Newtype (wrap)
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Effect.Uncurried (mkEffectFn1)
import Foreign (Foreign)
import React.Component.EdgeWrapper (applyDefaults)
import React.Handle (onConnectExtended)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (createStore)

foreign import checkMerge :: (JsDefaultEdgeOptions -> JsEdge -> JsEdge) -> Effect Unit
foreign import checkConnect
  :: (Nullable JsDefaultEdgeOptions -> Effect { params :: Array JsConnection, edges :: Array JsEdge })
  -> Effect Unit

runDefaultEdgeOptionsTests :: Effect Unit
runDefaultEdgeOptionsTests = do
  checkMerge \defaults edge ->
    edgeOut (applyDefaults (Just (defaultEdgeOptionsIn defaults)) (edgeIn edge))
  log "ok  defaultEdgeOptions: all 23 members merge under an edge as upstream's spread does"
  checkConnect \defaults -> do
    received <- Ref.new []
    store <- createStore ((defaultInitialStateOptions :: InitialStateOptions Foreign Foreign)
      { defaultEdges = Just [] })
    store.dispatch $ PatchState _
      { defaultEdgeOptions = map defaultEdgeOptionsIn (toMaybe defaults)
      , onConnect = Just (onConnectIn (mkEffectFn1 \params -> Ref.modify_ (_ <> [ params ]) received))
      }
    onConnectExtended store Nothing
      { source: wrap "a", target: wrap "b", sourceHandle: Nothing, targetHandle: Nothing }
    params <- Ref.read received
    state <- store.getState
    pure { params, edges: map edgeOut state.edges }
  log "ok  defaultEdgeOptions: onConnect and an uncontrolled flow get upstream's merged connection"
