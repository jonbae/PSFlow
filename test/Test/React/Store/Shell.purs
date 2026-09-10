-- | Subscription semantics for `React.Store.Shell`.
-- |
-- | One claim, and it is the local proxy for the first of the two causes
-- | named by "Diagnose why ps-flow does not reproduce itself on 52 of 94
-- | scenarios" (#94): **`subscribe` does not fire on subscribe.**
-- |
-- | Zustand's `subscribe` calls back only when the selected slice changes.
-- | Firing once at subscribe time is `subscribeWithSelector`'s opt-in
-- | `fireImmediately`, which upstream never asks for. The shell used to fire
-- | anyway, which was redundant — `React.Hook.Store.useStore` seeds its own
-- | `useState` from `store.getState` before subscribing — and, because each
-- | consumer subscribes inside its own `useEffect`, nondeterministic: the
-- | extra `setValue`s arrived in mount order and React batched them
-- | differently run to run.
-- |
-- | The net is what measures that, and the net cannot run without a browser
-- | and the vendored upstream. This runs in `spago test` and holds the
-- | property the fix turns on, so a regression fails here first.
module Test.React.Store.Shell
  ( runStoreShellTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Subscribe(..), createStore)
import React.Types.Store (ReactFlowState)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | A slice that is cheap to move: `PatchState` can set it directly and
-- | nothing else in the reducer touches it.
selectWidth :: ReactFlowState Unit Unit -> Number
selectWidth = _.width

runStoreShellTests :: Effect Unit
runStoreShellTests = do
  log "running store-shell subscription tests..."

  -- Subscribing is silent. A consumer that already read `getState` must not
  -- be handed the same value a second time.
  store <- createStore
    (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
  calls <- Ref.new ([] :: Array Number)
  unsubscribe <- case store.subscribe of
    Subscribe sub -> sub selectWidth \v -> Ref.modify_ (_ <> [ v ]) calls

  afterSubscribe <- Ref.read calls
  assert "subscribe does not fire with the current value"
    (afterSubscribe == [])

  -- It still fires when the slice actually changes.
  store.dispatch (PatchState _ { width = 640.0 })
  afterChange <- Ref.read calls
  assert "a changed slice fires the subscriber once"
    (afterChange == [ 640.0 ])

  -- And stays silent when the slice is written its own value, because the
  -- subscriber compares projections rather than counting dispatches.
  store.dispatch (PatchState _ { width = 640.0 })
  afterNoChange <- Ref.read calls
  assert "an unchanged slice does not fire the subscriber"
    (afterNoChange == [ 640.0 ])

  -- A second subscriber joining later is equally silent, which is the case
  -- the mount-order race was made of: consumers subscribe at different
  -- times and none of them may speak until the state moves.
  late <- Ref.new ([] :: Array Number)
  unsubscribeLate <- case store.subscribe of
    Subscribe sub -> sub selectWidth \v -> Ref.modify_ (_ <> [ v ]) late

  afterLateSubscribe <- Ref.read late
  assert "a subscriber joining after a change is also silent"
    (afterLateSubscribe == [])

  store.dispatch (PatchState _ { width = 800.0 })
  bothFired <- Ref.read calls
  lateFired <- Ref.read late
  assert "both subscribers see the next change"
    (bothFired == [ 640.0, 800.0 ] && lateFired == [ 800.0 ])

  -- Unsubscribing removes only its own slot.
  unsubscribe
  store.dispatch (PatchState _ { width = 900.0 })
  afterUnsub <- Ref.read calls
  lateAfterUnsub <- Ref.read late
  assert "an unsubscribed slot stops firing"
    (afterUnsub == [ 640.0, 800.0 ])
  assert "and the surviving slot keeps firing"
    (lateAfterUnsub == [ 800.0, 900.0 ])

  unsubscribeLate
  log "store-shell subscription tests passed"
