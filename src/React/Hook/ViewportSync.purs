-- | `useViewportSync` — when the consumer passes an external
-- | `viewport` prop, this hook keeps the store's `transform` in sync
-- | by dispatching `PatchState` on every change.
-- |
-- | Mirrors `xyflow-main/packages/react/src/hooks/useViewportSync.ts`,
-- | minus the imperative `panZoom.setViewport` animation — that part
-- | lives inside `useReactFlow` / ticket 030. We only mutate the
-- | reactive state record here.
module React.Hook.ViewportSync
  ( UseViewportSyncHook(..)
  , useViewportSync
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import React.Basic.Hooks (Hook, UseEffect, coerceHook, useEffect)
import React.Basic.Hooks as React
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Action (Action(..))
import System.Types.Connection (Viewport)
import System.Types.Geometry (mkTransform)

newtype UseViewportSyncHook hooks =
  UseViewportSyncHook (UseEffect (Maybe Viewport) (UseStoreApi hooks))

derive instance newtypeUseViewportSyncHook ::
  Newtype (UseViewportSyncHook hooks) _

useViewportSync :: Maybe Viewport -> Hook UseViewportSyncHook Unit
useViewportSync mViewport = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi _)
  useEffect mViewport do
    case mViewport of
      Nothing -> pure unit
      Just vp ->
        store.dispatch
          ( PatchState \s -> s
              { transform = mkTransform vp.x vp.y vp.zoom }
          )
    pure (pure unit)
