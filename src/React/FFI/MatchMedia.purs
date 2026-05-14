-- | Hand-rolled FFI shim around `window.matchMedia('(prefers-color-scheme: dark)')`.
-- | Used by `React.Hook.ColorModeClass` to react to the user's OS-level
-- | colour-scheme preference when the consumer chooses `ColorMode =
-- | System`.
-- |
-- | Returns a tiny imperative subscription record. The `subscribe`
-- | function takes a handler and returns an `Effect Unit` cleanup
-- | (`removeEventListener`).
module React.FFI.MatchMedia
  ( PrefersDarkSubscription
  , prefersDarkMode
  ) where

import Prelude

import Effect (Effect)

type PrefersDarkSubscription =
  { current :: Effect Boolean
  , subscribe :: (Boolean -> Effect Unit) -> Effect (Effect Unit)
  }

-- | Acquire a subscription to the `(prefers-color-scheme: dark)` media
-- | query. `current` returns the current boolean; `subscribe` installs
-- | a `change` listener and returns its cleanup.
foreign import prefersDarkMode :: Effect PrefersDarkSubscription
