-- | `useViewportSync` — when the consumer passes an external
-- | `viewport` prop, this hook moves the pan-zoom instance to it and then
-- | writes it to the store's `transform`.
-- |
-- | Mirrors `xyflow-main/packages/react/src/hooks/useViewportSync.ts`.
-- | The instance has to hear about the change as well as the store: d3
-- | keeps its own transform, and a gesture starts from that one. A store
-- | that moved without it leaves the next pan starting from wherever the
-- | viewport was before. `syncViewport` marks its d3 event as a sync, so
-- | the pan-zoom handler does not echo the change back through
-- | `onViewportChange`.
-- |
-- | The effect re-runs when the instance changes as well as when the
-- | viewport does, as upstream's depends on `syncViewport`. On mount the
-- | instance does not exist yet — `<ZoomPane />` creates it in an effect of
-- | its own — so the first run writes the store alone, and the run after
-- | the instance lands moves d3 off `defaultViewport`.
module React.Hook.ViewportSync
  ( UseViewportSyncHook(..)
  , ViewportSync
  , runViewportSync
  , useViewportSync
  ) where

import Prelude

import Data.Foldable (for_)
import Data.Maybe (Maybe)
import Data.Newtype (class Newtype)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseEffect, coerceHook, useEffect)
import React.Basic.Hooks as React
import React.Hook.Store (UseStore, UseStoreApi, useStore, useStoreApi)
import React.Store.Action (Action(..))
import System.Types.Connection (Viewport)
import System.Types.Geometry (mkTransform)
import System.Types.PanZoom (PanZoomInstance)

newtype UseViewportSyncHook hooks =
  UseViewportSyncHook
    ( UseEffect (Tuple (Maybe Viewport) (UnsafeReference (Maybe PanZoomInstance)))
        (UseStore (UnsafeReference (Maybe PanZoomInstance)) (UseStoreApi hooks))
    )

derive instance newtypeUseViewportSyncHook ::
  Newtype (UseViewportSyncHook hooks) _

useViewportSync :: Maybe Viewport -> Hook UseViewportSyncHook Unit
useViewportSync mViewport = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi _)
  UnsafeReference mPanZoom <- useStore \s -> UnsafeReference s.panZoom
  useEffect (Tuple mViewport (UnsafeReference mPanZoom)) do
    runViewportSync
      { syncViewport: _.syncViewport <$> mPanZoom
      , dispatch: store.dispatch
      }
      mViewport
    pure (pure unit)

-- | What one run of the hook's effect reaches: upstream's selected
-- | `panZoom?.syncViewport`, and the store.
type ViewportSync n e =
  { syncViewport :: Maybe (Viewport -> Effect Unit)
  , dispatch :: Action n e -> Effect Unit
  }

-- | One run of the hook's effect, in upstream's order: the instance first,
-- | then the store.
runViewportSync :: forall n e. ViewportSync n e -> Maybe Viewport -> Effect Unit
runViewportSync sync mViewport =
  for_ mViewport \vp -> do
    for_ sync.syncViewport \f -> f vp
    sync.dispatch
      ( PatchState \s -> s
          { transform = mkTransform vp.x vp.y vp.zoom }
      )
