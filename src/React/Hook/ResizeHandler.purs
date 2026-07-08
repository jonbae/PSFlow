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
import System.Utils.Dom (getDimensions)
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
        let
          -- Mirror upstream `getDimensions` + its `|| 500` fallback
          -- (`useResizeHandler.ts`): read `offsetWidth/Height` and never
          -- let a zero/unmeasured container reach the store, which would
          -- otherwise produce a broken initial `fitView` viewport.
          updateDimensions :: Effect Unit
          updateDimensions = do
            { width: w, height: h } <- getDimensions divEl
            let
              w' = if w == 0.0 then 500.0 else w
              h' = if h == 0.0 then 500.0 else h
            store.dispatch (PatchState \s -> s { width = w', height = h' })
            case onResize of
              Just cb -> cb w' h'
              Nothing -> pure unit
        -- Synchronous initial measurement on mount (upstream line 29):
        -- seeds `width`/`height` *before* the node ResizeObservers fire
        -- and resolve the queued initial `fitView`. Without this the fit
        -- runs against a ~0 container and positions nodes off-screen.
        updateDimensions
        observer <- createResizeObserver \_ -> updateDimensions
        observe observer (toElement divEl)
        pure (disconnect observer)
