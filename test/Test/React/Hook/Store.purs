-- | `useStore`, run against a stand-in for React's hook dispatcher.
-- |
-- | The local proxy for "Port useStore onto useSyncExternalStore, so a
-- | slice that moved before the subscription re-renders on upstream's
-- | lane" (#133). Upstream's `useStore` is zustand's
-- | `useStoreWithEqualityFn`, which is React's `useSyncExternalStore`
-- | behind a selection memo. ps-flow's was a `useState` that a
-- | subscription in a `useEffect` kept up to date, and #128 added a
-- | re-read after subscribing so a slice that moved before the
-- | subscription was not missed. That re-read called `setValue`, which
-- | renders on React's default lane, while `useSyncExternalStore` renders
-- | on the synchronous one. A mount-time sync then raced the first
-- | measurement, and `mount-baseline--viewport-controlled` disagreed with
-- | itself.
-- |
-- | The lane lives in React's scheduler, which needs a DOM `spago test`
-- | does not have. What can be checked here is what the hook asks React
-- | for. `Test.React.Hook.Store.js` installs a fake dispatcher, renders the
-- | hook outside a component, and keeps what React would have been handed.
-- | The `useState` hook from before this ticket fails the first check.
-- |
-- | The rest hold `useSyncExternalStore`'s side of the contract. React
-- | resubscribes whenever `subscribe` changes and re-renders whenever
-- | `getSnapshot` returns a new object, so the subscription has to be the
-- | same function on every render, and an unchanged slice has to come back
-- | as the same object. The second is the guarantee #94 drew: a consumer
-- | that already holds the current slice is not rendered again for it.
module Test.React.Hook.Store
  ( runUseStoreTests
  , FakeRenderer
  , SubscribeIdentity
  , rendererFor
  , sameReference
  ) where

import Prelude

import Data.Array (elem)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Basic.Hooks (Hook)
import React.Context.Store (OpaqueStore)
import React.Hook.Store (UseStore, useStore)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import React.Types.Store (ReactFlowState)
import Unsafe.Coerce (unsafeCoerce)

type FakeRenderer a =
  { render :: Effect a -> Effect a
  , calls :: Effect (Array String)
  , hasExternalStore :: Effect Boolean
  , subscribeIdentity :: Effect SubscribeIdentity
  , snapshot :: Effect a
  , subscribe :: Effect Unit -> Effect (Effect Unit)
  }

foreign import data SubscribeIdentity :: Type

foreign import newFakeRenderer :: forall a. Maybe OpaqueStore -> Effect (FakeRenderer a)
foreign import sameReference :: forall a. a -> a -> Boolean

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | A `Hook` is an `Effect` with a phantom tag, run here outside React.
runHook :: forall hooks a. Hook hooks a -> Effect a
runHook = unsafeCoerce

-- | Both dimensions, so a check can move one and read the other.
type Size = { width :: Number, height :: Number }

selectSize :: ReactFlowState Unit Unit -> Size
selectSize s = { width: s.width, height: s.height }

selectHeight :: ReactFlowState Unit Unit -> Number
selectHeight = _.height

setWidth :: Store Unit Unit -> Number -> Effect Unit
setWidth store w = store.dispatch (PatchState _ { width = w })

newStore :: Effect (Store Unit Unit)
newStore = createStore (defaultInitialStateOptions :: InitialStateOptions Unit Unit)

-- | A fake renderer for `useStore selector` against `store`.
rendererFor
  :: forall a
   . Eq a
  => Store Unit Unit
  -> (ReactFlowState Unit Unit -> a)
  -> Effect { fake :: FakeRenderer a, render :: Effect a }
rendererFor store selector = do
  fake <- newFakeRenderer (Just (unsafeCoerce store))
  let
    hook :: Hook (UseStore a) a
    hook = useStore selector
  pure { fake, render: fake.render (runHook hook) }

runUseStoreTests :: Effect Unit
runUseStoreTests = do
  log "\n=== useStore: React's useSyncExternalStore behind a selection memo (#133) ==="

  store <- newStore
  sized <- rendererFor store selectSize
  _ <- sized.render
  calls <- sized.fake.calls
  external <- sized.fake.hasExternalStore
  assert "useStore reads the store through React's useSyncExternalStore"
    (external && elem "useSyncExternalStore" calls && not (elem "useState" calls))

  first <- sized.fake.subscribeIdentity
  _ <- sized.render
  second <- sized.fake.subscribeIdentity
  assert "the subscription is the same function on every render, so React does not resubscribe"
    (sameReference first second)

  before <- sized.fake.snapshot
  again <- sized.fake.snapshot
  assert "an unchanged store hands back the same slice object"
    (sameReference before again)

  setWidth store 1280.0
  moved <- sized.fake.snapshot
  assert "a slice that moved comes back as a new object, holding the new value"
    (not (sameReference before moved) && moved.width == 1280.0)

  -- A selector that does not see the width: the store moved, the slice did
  -- not. A fresh record each time, so only the memo's `Eq` keeps it stable.
  heightStore <- newStore
  tall <- rendererFor heightStore selectSize
  _ <- tall.render
  base <- tall.fake.snapshot
  heightStore.dispatch (PatchState _ { nodesDraggable = false })
  unchanged <- tall.fake.snapshot
  assert "a store change the selector cannot see hands back the same slice, so nothing re-renders (#94)"
    (sameReference base unchanged)

  heights <- rendererFor heightStore selectHeight
  _ <- heights.render
  fired <- Ref.new 0
  unsubscribe <- heights.fake.subscribe (Ref.modify_ (_ + 1) fired)
  setWidth heightStore 640.0
  afterDispatch <- Ref.read fired
  unsubscribe
  setWidth heightStore 320.0
  afterUnsubscribe <- Ref.read fired
  assert "React's listener runs after a dispatch, and not after it unsubscribes"
    (afterDispatch == 1 && afterUnsubscribe == 1)
