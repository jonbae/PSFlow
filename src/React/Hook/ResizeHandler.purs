-- | `useResizeHandler` — installs a `ResizeObserver` on the flow's
-- | root `<div>` and dispatches the new `width`/`height` into the
-- | store. Mirrors
-- | `xyflow-main/packages/react/src/hooks/useResizeHandler.ts`.
-- |
-- | The TS source supports an optional `onResize` callback prop. PS
-- | accepts the same as a `Maybe (Number -> Number -> Effect Unit)`.
module React.Hook.ResizeHandler
  ( UseResizeHandlerHook(..)
  , useResizeHandler
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Nullable (Nullable, toMaybe)
import Effect (Effect)
import React.Basic (Ref)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseEffect, coerceHook, readRef, useEffect)
import React.Basic.Hooks as React
import React.FFI.ResizeObserver (createResizeObserver, disconnect, observe)
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Action (Action(..))
import Web.HTML.HTMLDivElement (HTMLDivElement, toElement)

newtype UseResizeHandlerHook hooks =
  UseResizeHandlerHook
    ( UseEffect (UnsafeReference (Ref (Nullable HTMLDivElement)))
        (UseStoreApi hooks)
    )

derive instance newtypeUseResizeHandlerHook ::
  Newtype (UseResizeHandlerHook hooks) _

useResizeHandler
  :: Ref (Nullable HTMLDivElement)
  -> Maybe (Number -> Number -> Effect Unit)
  -> Hook UseResizeHandlerHook Unit
useResizeHandler divRef onResize = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi _)
  useEffect (UnsafeReference divRef) do
    mDiv <- toMaybe <$> readRef divRef
    case mDiv of
      Nothing -> pure (pure unit)
      Just divEl -> do
        observer <- createResizeObserver \entries ->
          case entries of
            [] -> pure unit
            _ ->
              -- Take the last entry (matches TS) — usually only one
              -- since we observe a single element.
              let
                e = lastEntry entries
                w = e.contentRect.width
                h = e.contentRect.height
              in do
                store.dispatch (PatchState \s -> s { width = w, height = h })
                case onResize of
                  Just cb -> cb w h
                  Nothing -> pure unit
        observe observer (toElement divEl)
        pure (disconnect observer)

-- | `Array.last`-equivalent. Inlined to avoid an extra import.
lastEntry :: forall a. Array a -> a
lastEntry xs = lastEntryImpl xs

foreign import lastEntryImpl :: forall a. Array a -> a
