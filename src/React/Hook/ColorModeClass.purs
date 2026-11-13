-- | `useColorModeClass` — resolves a `ColorMode` setting into a
-- | concrete `ColorModeClass` (`Light`/`Dark`). When the consumer
-- | passes `SystemMode` (or `Nothing`), the hook subscribes to
-- | `(prefers-color-scheme: dark)` via `React.FFI.MatchMedia` and
-- | re-renders whenever the OS preference changes.
-- |
-- | Mirrors `xyflow/packages/react/src/hooks/useColorModeClass.ts`.
module React.Hook.ColorModeClass
  ( UseColorModeClassHook(..)
  , useColorModeClass
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Tuple.Nested ((/\))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic.Hooks (Hook, UseEffect, UseState, coerceHook, useEffect, useState)
import React.Basic.Hooks as React
import React.FFI.MatchMedia (prefersDarkMode)
import System.Types.Connection (ColorMode(..), ColorModeClass(..))

newtype UseColorModeClassHook hooks =
  UseColorModeClassHook
    ( UseEffect ColorMode
        (UseState (Maybe ColorModeClass) hooks)
    )

derive instance newtypeUseColorModeClassHook ::
  Newtype (UseColorModeClassHook hooks) _

-- | TS's hook, step for step. The state starts as the mode itself unless it
-- | is `'system'`; the effect sets it again, which changes nothing for a
-- | fixed mode, or follows the media query. Until the state holds a class,
-- | the render reads the media query directly, so the first render of a
-- | `'system'` flow already carries one. `<ReactFlow />` passes `'light'`
-- | when the consumer passes nothing, as TS's default does.
useColorModeClass
  :: ColorMode
  -> Hook UseColorModeClassHook ColorModeClass
useColorModeClass mode = coerceHook React.do
  cls /\ setCls <- useState (resolveStatic mode)
  let
    -- TS sets a string, which React compares with `Object.is` and skips when
    -- it is unchanged. A fresh `Just` is never `Object.is` the one held, so
    -- keep the held one when the class is the same.
    setClass next = setCls \held -> if held == Just next then held else Just next
  useEffect mode case mode of
    LightMode -> do
      setClass Light
      pure (pure unit)
    DarkMode -> do
      setClass Dark
      pure (pure unit)
    SystemMode -> do
      sub <- prefersDarkMode
      isDark <- sub.current
      setClass (if isDark then Dark else Light)
      cleanup <- sub.subscribe \dark ->
        setClass (if dark then Dark else Light)
      pure cleanup
  pure case cls of
    Just c -> c
    Nothing ->
      if unsafePerformEffect (prefersDarkMode >>= _.current) then Dark else Light
  where
  resolveStatic = case _ of
    LightMode -> Just Light
    DarkMode -> Just Dark
    SystemMode -> Nothing
