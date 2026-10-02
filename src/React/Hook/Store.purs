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
-- | **`useStore` re-renders on selector-result change only.** It is
-- | upstream's `useStore` — zustand's `useStoreWithEqualityFn`, which is
-- | React's `useSyncExternalStore` behind a selection memo — with the
-- | selector's `Eq` instance as the equality function. Consumers either
-- | derive `Eq` on the projection type or wrap it in a `newtype` with a
-- | custom instance. The TS source's optional `equalityFn` parameter is
-- | intentionally omitted; the `Eq` type-class instance is the PS
-- | equivalent.
module React.Hook.Store
  ( UseStoreApi(..)
  , UseStore(..)
  , UseSyncExternalStoreWithSelector
  , useStore
  , useStoreApi
  , opaqueToStore
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried (EffectFn3, runEffectFn3)
import React.Basic.Hooks (Hook, UseContext, coerceHook, useContext)
import React.Basic.Hooks as React
import React.Basic.Hooks.Internal (unsafeHook)
import React.Context.Store (OpaqueStore, storeContext)
import React.Store.Shell (Store)
import React.Types.Store (ReactFlowState)
import System.Constants (ErrorCode(..), errorMessage)
import Unsafe.Coerce (unsafeCoerce)

-- | Hook-effect tag for `useStoreApi`. The wrapped type expresses the
-- | single underlying effect: reading the store context.
newtype UseStoreApi hooks =
  UseStoreApi (UseContext (Maybe OpaqueStore) hooks)

derive instance newtypeUseStoreApi :: Newtype (UseStoreApi hooks) _

-- | Hook-effect tag for `useStore`: read the context, then the hooks
-- | `useStoreImpl` calls, which are `useSyncExternalStoreWithSelector`'s.
newtype UseStore a hooks =
  UseStore (UseSyncExternalStoreWithSelector a (UseContext (Maybe OpaqueStore) hooks))

derive instance newtypeUseStore :: Newtype (UseStore a hooks) _

foreign import data UseSyncExternalStoreWithSelector :: Type -> Type -> Type

foreign import useStoreImpl
  :: forall n e a
   . EffectFn3 (Store n e) (ReactFlowState n e -> a) (a -> a -> Boolean) a

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
-- | A slice that moved before this component subscribed — React runs a
-- | child's effects before its parent's, and `<ZoomPane />` creates the
-- | pan-zoom instance in one of them — re-renders on the synchronous
-- | lane, at the end of the effect pass that noticed it, as upstream's
-- | does. A slice that did not move re-renders nothing, which is the
-- | guarantee #94 drew for the store's own `subscribe`.
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
  unsafeHook (runEffectFn3 useStoreImpl store selector eq)

-- | The sanctioned `OpaqueStore -> Store n e` cast. Documented in
-- | `React.Context.Store`'s module header — this is the one place the
-- | cast is performed on the consumer side.
opaqueToStore :: forall n e. OpaqueStore -> Store n e
opaqueToStore = unsafeCoerce
