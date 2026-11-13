-- | The TS source picks the hook once, when the module loads, so component
-- | libraries can render on Node SSR without React firing the
-- | not-isomorphic warning:
-- |
-- | ```ts
-- | const useIsomorphicLayoutEffect =
-- |   typeof window !== 'undefined' ? useLayoutEffect : useEffect;
-- | ```
-- |
-- | A server render runs neither effect, but React's development build warns
-- | about every layout effect it meets on the server. The choice keeps a
-- | server render as quiet as upstream's, and in a browser it is
-- | `useLayoutEffect`, as before. Both branches keep the `UseLayoutEffect`
-- | type: it and `UseEffect` are phantom markers of hook order, and the
-- | choice is fixed for the life of the process, so every render of a
-- | component calls the same hook.
module React.Hook.IsomorphicLayoutEffect
  ( useIsomorphicLayoutEffect
  ) where

import Prelude

import Effect (Effect)
import React.Basic.Hooks (Hook, UseLayoutEffect, useEffect, useLayoutEffect)
import Unsafe.Coerce (unsafeCoerce)

-- | `typeof window !== 'undefined'`, read once when the module loads.
foreign import hasWindow :: Boolean

useIsomorphicLayoutEffect
  :: forall deps
   . Eq deps
  => deps
  -> Effect (Effect Unit)
  -> Hook (UseLayoutEffect deps) Unit
useIsomorphicLayoutEffect =
  if hasWindow then useLayoutEffect
  else \deps effect -> unsafeCoerce (useEffect deps effect)
