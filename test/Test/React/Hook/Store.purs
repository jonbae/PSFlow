-- | `useStore`'s subscription effect, against a store that moved before it
-- | ran.
-- |
-- | Found under "Wire controlled viewport changes to panZoom.syncViewport
-- | and drive them in the net" (#128). `useStore` seeds its value at render
-- | and subscribes in an effect, and React runs a child's effects before
-- | its parent's. `<ZoomPane />` creates the pan-zoom instance in one of
-- | them, so by the time `<GraphView />`'s `useStore` subscribed, the
-- | change had fired no listener it could hear, and `useViewportSync` never
-- | saw an instance to sync. Upstream's `useStore` goes through React's
-- | `useSyncExternalStore`, which reads the snapshot again after
-- | subscribing.
-- |
-- | `subscribeSlice` is the effect's whole body, run here against a real
-- | store. One that only subscribes, which is what the hook did before the
-- | fix, fails the first check. The second holds the line #94 drew: a
-- | consumer that already holds the current value is not handed it again.
module Test.React.Hook.Store
  ( runUseStoreTests
  ) where

import Prelude

import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Hook.Store (subscribeSlice)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import React.Types.Store (ReactFlowState)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

selectWidth :: ReactFlowState Unit Unit -> Number
selectWidth = _.width

setWidth :: Store Unit Unit -> Number -> Effect Unit
setWidth store w = store.dispatch (PatchState _ { width = w })

-- | Render, let `between` touch the store, run the effect, and then let
-- | `after` touch it. Returns every value handed to the consumer.
subscribeAround
  :: (Store Unit Unit -> Effect Unit)
  -> (Store Unit Unit -> Effect Unit)
  -> Effect (Array Number)
subscribeAround between after = do
  store <- createStore (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
  rendered <- selectWidth <$> store.getState
  between store
  handed <- Ref.new []
  _ <- subscribeSlice store selectWidth rendered \v -> Ref.modify_ (_ <> [ v ]) handed
  after store
  Ref.read handed

runUseStoreTests :: Effect Unit
runUseStoreTests = do
  log "\n=== useStore: a change before the subscription still reaches the consumer (#128) ==="

  missed <- subscribeAround (\s -> setWidth s 500.0) (const (pure unit))
  assert "a change between the render and the subscription reaches the consumer"
    (missed == [ 500.0 ])

  unchanged <- subscribeAround (const (pure unit)) (const (pure unit))
  assert "a consumer that already holds the current value is not handed it again"
    (unchanged == [])

  later <- subscribeAround (\s -> setWidth s 500.0) (\s -> setWidth s 600.0)
  assert "a change after the subscription still arrives through it"
    (later == [ 500.0, 600.0 ])
