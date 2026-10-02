-- | `useStore` and `useStoreApi` — the two foundational hooks that every
-- | other React-layer hook (028–031) builds on. Mirrors
-- | `xyflow-main/packages/react/src/hooks/useStore.ts`.
-- |
-- | Both hooks read the singleton `Store n e` from
-- | `React.Context.Store.storeContext`, which carries it as an opaque
-- | placeholder (`OpaqueStore`) because PureScript `ReactContext` is
-- | monomorphic but `Store n e` is polymorphic in the user node/edge data
-- | rows. The cast from `OpaqueStore` back to `Store n e` happens here
-- | with `unsafeCoerce`, exactly once at this seam, per the contract
-- | documented in `React.Context.Store`.
-- |
-- | **Throws on missing provider.** Both hooks throw the upstream
-- | `errorMessage E001` string when the `StoreContext` is `Nothing` —
-- | matching the TS `Error("...zustand provider...")` exactly.
-- |
-- | **`useStoreApi` is stable across re-renders.** The store reference
-- | does not change once the provider has mounted; the consumer gets the
-- | same record back every render and no re-render fires when the
-- | underlying state mutates.
-- |
-- | **`useStore` re-renders on selector-result change only.** The
-- | subscriber registered in `React.Store.Shell.createStore` already
-- | guards by the `Eq` instance on the selector result — we inherit
-- | that for free. Consumers either derive `Eq` on the projection type
-- | or wrap it in a `newtype` with a custom instance. The TS source's
-- | optional `equalityFn` parameter is intentionally omitted; the
-- | `Eq` type-class instance is the PS equivalent.
module React.Hook.Store
  ( UseStoreApi(..)
  , UseStore(..)
  , Store_
  , useStore
  , useStoreApi
  , opaqueToStore
  , subscribeSlice
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseContext, UseEffect, UseState, coerceHook, useContext, useEffect, useState)
import React.Basic.Hooks as React
import React.Context.Store (OpaqueStore, storeContext)
import React.Store.Shell (Store, Subscribe(..))
import React.Types.Store (ReactFlowState)
import System.Constants (ErrorCode(..), errorMessage)
import Unsafe.Coerce (unsafeCoerce)

-- | Hook-effect tag for `useStoreApi`. The wrapped type expresses the
-- | single underlying effect: reading the store context.
newtype UseStoreApi hooks =
  UseStoreApi (UseContext (Maybe OpaqueStore) hooks)

derive instance newtypeUseStoreApi :: Newtype (UseStoreApi hooks) _

-- | Hook-effect tag for `useStore`. The chain is: read the context,
-- | seed local state with the initial selector value, then subscribe
-- | once per store reference.
newtype UseStore a hooks =
  UseStore
    ( UseEffect (UnsafeReference (Store_ a))
        (UseState a (UseContext (Maybe OpaqueStore) hooks))
    )

derive instance newtypeUseStore :: Newtype (UseStore a hooks) _

-- | Opaque tag so `UseStore`'s effect parameter can be monomorphic. The
-- | hook works for any `Store n e`; we discard the `n`/`e` parameters
-- | when recording the hook-effect chain. Reference equality is the
-- | only property we need on the wrapped store, and that is preserved
-- | by `unsafeCoerce`.
foreign import data Store_ :: Type -> Type

-- | Return the full `Store n e` API record. The store reference is
-- | stable across re-renders, so the surrounding component is not
-- | re-rendered when state mutates — `useStoreApi` is effectively
-- | `const` within a component instance. Use this hook when you want
-- | to imperatively `dispatch` / `setState` / `getState` without
-- | re-rendering when the state changes.
useStoreApi :: forall n e. Hook UseStoreApi (Store n e)
useStoreApi = coerceHook React.do
  mStore <- useContext storeContext
  case mStore of
    Nothing -> unsafeThrow (errorMessage E001)
    Just opaque -> pure (opaqueToStore opaque)

-- | Subscribe to a selected slice of the store. Re-renders the calling
-- | component when (and only when) the selector projection changes per
-- | its `Eq` instance.
-- |
-- | Selector functions should be stable — declare them as top-level
-- | values or capture them in a `where` clause so the reference does
-- | not change across renders.
useStore
  :: forall n e a
   . Eq a
  => (ReactFlowState n e -> a)
  -> Hook (UseStore a) a
useStore selector = coerceHook React.do
  mStore <- useContext storeContext
  let
    store :: Store n e
    store = case mStore of
      Nothing -> unsafeThrow (errorMessage E001)
      Just opaque -> opaqueToStore opaque
  -- Seed with the current selector value. `unsafePerformEffect` here
  -- is safe because `store.getState` is referentially transparent at
  -- the initial-render boundary — matches Zustand's pattern.
  let initial = unsafePerformEffect (selector <$> store.getState)
  value /\ setValue <- useState initial
  -- Subscribe once per store instance. Wrap the store reference in
  -- `UnsafeReference` so `useEffect`'s `Eq deps` constraint is
  -- satisfied (the store record has no `Eq` of its own — it is a
  -- record of functions). The store ref is stable for the lifetime of
  -- the provider, so this effect runs exactly once per consumer mount.
  --
  -- The store can change between the render that seeded `value` and this
  -- subscription: React runs a child's effects before its parent's, and
  -- `<ZoomPane />` creates the pan-zoom instance in one of them. That
  -- change fired no listener here, so the slice is read again once the
  -- listener is in place, and kept only if it differs — what React's
  -- `useSyncExternalStore`, under upstream's `useStore`, does after it
  -- subscribes. The `Eq` check is what keeps this from being the redundant
  -- `setValue` the store's own `subscribe` no longer fires (#94).
  useEffect (UnsafeReference (storeAsTagged store)) $
    subscribeSlice store selector value (\v -> setValue (const v))
  pure value

-- | `useStore`'s subscription effect: subscribe, then hand `set` the slice
-- | again if it has moved off `rendered`, the value the render read.
-- | Returns the unsubscribe. Public for testing.
subscribeSlice
  :: forall n e a
   . Eq a
  => Store n e
  -> (ReactFlowState n e -> a)
  -> a
  -> (a -> Effect Unit)
  -> Effect (Effect Unit)
subscribeSlice store selector rendered set = do
  unsubscribe <- case store.subscribe of
    Subscribe sub -> sub selector set
  current <- selector <$> store.getState
  when (current /= rendered) (set current)
  pure unsubscribe

-- | The sanctioned `OpaqueStore -> Store n e` cast. Documented in
-- | `React.Context.Store`'s module header — this is the one place the
-- | cast is performed on the consumer side.
opaqueToStore :: forall n e. OpaqueStore -> Store n e
opaqueToStore = unsafeCoerce

-- | Erase the `n`/`e` parameters of the store so the `UseStore` hook
-- | tag can be parameterised on the selector result alone. The
-- | underlying value is still the same JS object — `UnsafeReference`'s
-- | reference-equality check works regardless of the wrapper type.
storeAsTagged :: forall n e a. Store n e -> Store_ a
storeAsTagged = unsafeCoerce
