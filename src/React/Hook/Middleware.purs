-- | Experimental middleware hooks. Each installs an interceptor in
-- | the store's middleware map; the reducer consults the map before
-- | dispatching the corresponding `Trigger*Changes` action so a
-- | registered function can drop, mutate, or pass through changes.
-- |
-- | Mirrors
-- | `xyflow-main/packages/react/src/hooks/useOnNodesChangeMiddleware.ts`
-- | and `useOnEdgesChangeMiddleware.ts`.
-- |
-- | **Storage strategy.** Each registration mints a fresh
-- | `MiddlewareKey` via `store.freshMiddlewareKey` and inserts the
-- | middleware function into the relevant map with `PatchState`. On
-- | unmount the same key is removed. The `MiddlewareKey` is captured
-- | in a `useRef` so unmount can find it again.
-- |
-- | Ticket 051 follow-up: replace the `PatchState` inserts with named
-- | `Action` constructors for cleaner audit semantics.
module React.Hook.Middleware
  ( UseMiddlewareHook(..)
  , useOnNodesChangeMiddleware
  , useOnEdgesChangeMiddleware
  ) where

import Prelude

import Data.Map (delete, insert) as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Effect.Ref as Ref
import React.Basic (Ref)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseEffect, UseRef, coerceHook, useEffect, useRef)
import React.Basic.Hooks as React
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Action (Action(..))
import React.Types.Store (MiddlewareKey)
import System.Types.Edge (EdgeChange)
import System.Types.Node (NodeChange)
import Unsafe.Coerce (unsafeCoerce)

newtype UseMiddlewareHook fn hooks =
  UseMiddlewareHook
    ( UseEffect (UnsafeReference fn)
        ( UseRef (Maybe MiddlewareKey)
            (UseStoreApi hooks)
        )
    )

derive instance newtypeUseMiddlewareHook ::
  Newtype (UseMiddlewareHook fn hooks) _

-- | Register an interceptor on node-change dispatches for the lifetime
-- | of the calling component. The function receives every batch of
-- | `NodeChange n` headed for the reducer and may return a possibly
-- | filtered/transformed batch.
useOnNodesChangeMiddleware
  :: forall n
   . (Array (NodeChange n) -> Array (NodeChange n))
  -> Hook
       (UseMiddlewareHook (Array (NodeChange n) -> Array (NodeChange n)))
       Unit
useOnNodesChangeMiddleware fn = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi _)
  keyRef <- useRef (Nothing :: Maybe MiddlewareKey)
  useEffect (UnsafeReference fn) do
    key <- store.freshMiddlewareKey
    Ref.write (Just key) (toEffectRef keyRef)
    store.dispatch
      ( PatchState \s -> s
          { onNodesChangeMiddlewareMap =
              Map.insert key fn s.onNodesChangeMiddlewareMap
          }
      )
    pure do
      mKey <- Ref.read (toEffectRef keyRef)
      case mKey of
        Just k ->
          store.dispatch
            ( PatchState \s -> s
                { onNodesChangeMiddlewareMap =
                    Map.delete k s.onNodesChangeMiddlewareMap
                }
            )
        Nothing -> pure unit
      Ref.write Nothing (toEffectRef keyRef)

-- | Edge-change counterpart. See `useOnNodesChangeMiddleware`.
useOnEdgesChangeMiddleware
  :: forall e
   . (Array (EdgeChange e) -> Array (EdgeChange e))
  -> Hook
       (UseMiddlewareHook (Array (EdgeChange e) -> Array (EdgeChange e)))
       Unit
useOnEdgesChangeMiddleware fn = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi _)
  keyRef <- useRef (Nothing :: Maybe MiddlewareKey)
  useEffect (UnsafeReference fn) do
    key <- store.freshMiddlewareKey
    Ref.write (Just key) (toEffectRef keyRef)
    store.dispatch
      ( PatchState \s -> s
          { onEdgesChangeMiddlewareMap =
              Map.insert key fn s.onEdgesChangeMiddlewareMap
          }
      )
    pure do
      mKey <- Ref.read (toEffectRef keyRef)
      case mKey of
        Just k ->
          store.dispatch
            ( PatchState \s -> s
                { onEdgesChangeMiddlewareMap =
                    Map.delete k s.onEdgesChangeMiddlewareMap
                }
            )
        Nothing -> pure unit
      Ref.write Nothing (toEffectRef keyRef)

-- | `react-basic`'s `Ref` and `effect-ref`'s `Ref` are the same JS
-- | cell; cast at the seam (same pattern as `React.Hook.Drag`).
toEffectRef :: forall a. Ref a -> Ref.Ref a
toEffectRef = unsafeCoerce
