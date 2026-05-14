-- | The TS source defines `useIsomorphicLayoutEffect` so component
-- | libraries can render on Node SSR without React firing the
-- | not-isomorphic warning:
-- |
-- | ```ts
-- | const useIsomorphicLayoutEffect =
-- |   typeof window !== 'undefined' ? useLayoutEffect : useEffect;
-- | ```
-- |
-- | The PS port runs PureScript-compiled JS on a browser only (no
-- | server-side rendering pipeline is on the roadmap), so the
-- | conditional collapses to `useLayoutEffect`. Documented here so a
-- | future SSR effort can locate the seam.
module React.Hook.IsomorphicLayoutEffect
  ( useIsomorphicLayoutEffect
  ) where

import Prelude

import Effect (Effect)
import React.Basic.Hooks (Hook, UseLayoutEffect, useLayoutEffect)

useIsomorphicLayoutEffect
  :: forall deps
   . Eq deps
  => deps
  -> Effect (Effect Unit)
  -> Hook (UseLayoutEffect deps) Unit
useIsomorphicLayoutEffect = useLayoutEffect
