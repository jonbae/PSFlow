-- | The resolver a queued `fitView` waits on: upstream's
-- | `withResolvers<boolean>()` object, `{ promise, resolve, reject }`.
-- |
-- | Upstream's `fitView` reuses the store's resolver or makes one, and its
-- | `resolveFitView` calls `fitViewResolver?.resolve(true)` once the viewport
-- | has been fitted. A consumer can write a resolver of its own through
-- | `setState`, and upstream then calls that object's `resolve` and returns
-- | its `promise`. So the store holds the JavaScript object itself, and these
-- | read its members when they are used rather than when it was stored.
module React.Store.FitViewResolver
  ( newFitViewResolver
  , resolveFitView
  , awaitFitView
  ) where

import Prelude

import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Aff.Compat (EffectFnAff, fromEffectFnAff)
import React.Types.Store (FitViewResolver)

-- | Upstream's `withResolvers<boolean>()`.
foreign import newFitViewResolver :: Effect FitViewResolver

-- | `resolver.resolve(value)`. A promise settles once, so a second call
-- | changes nothing, as upstream's does.
foreign import resolveFitView :: FitViewResolver -> Boolean -> Effect Unit

foreign import awaitFitViewImpl :: FitViewResolver -> EffectFnAff Boolean

-- | What upstream's `fitView` returns: the resolver's `promise`, settled.
awaitFitView :: FitViewResolver -> Aff Boolean
awaitFitView = fromEffectFnAff <<< awaitFitViewImpl
