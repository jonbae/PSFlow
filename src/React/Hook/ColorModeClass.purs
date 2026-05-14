-- | `useColorModeClass` — resolves a `ColorMode` setting into a
-- | concrete `ColorModeClass` (`Light`/`Dark`). When the consumer
-- | passes `SystemMode` (or `Nothing`), the hook subscribes to
-- | `(prefers-color-scheme: dark)` via `React.FFI.MatchMedia` and
-- | re-renders whenever the OS preference changes.
-- |
-- | Mirrors `xyflow-main/packages/react/src/hooks/useColorModeClass.ts`.
module React.Hook.ColorModeClass
  ( UseColorModeClassHook(..)
  , useColorModeClass
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Tuple.Nested ((/\))
import React.Basic.Hooks (Hook, UseEffect, UseState, coerceHook, useEffect, useState)
import React.Basic.Hooks as React
import React.FFI.MatchMedia (prefersDarkMode)
import System.Types.Connection (ColorMode(..), ColorModeClass(..))

newtype UseColorModeClassHook hooks =
  UseColorModeClassHook
    ( UseEffect (Maybe ColorMode)
        (UseState (Maybe ColorModeClass) hooks)
    )

derive instance newtypeUseColorModeClassHook ::
  Newtype (UseColorModeClassHook hooks) _

useColorModeClass
  :: Maybe ColorMode
  -> Hook UseColorModeClassHook (Maybe ColorModeClass)
useColorModeClass mode = coerceHook React.do
  cls /\ setCls <- useState (resolveStatic mode)
  useEffect mode case mode of
    Just LightMode -> do
      setCls (const (Just Light))
      pure (pure unit)
    Just DarkMode -> do
      setCls (const (Just Dark))
      pure (pure unit)
    _ -> do
      -- Either `Nothing` or `SystemMode`: subscribe to the
      -- media-query preference.
      sub <- prefersDarkMode
      isDark <- sub.current
      setCls (const (Just (if isDark then Dark else Light)))
      cleanup <- sub.subscribe \dark ->
        setCls (const (Just (if dark then Dark else Light)))
      pure cleanup
  pure cls
  where
  resolveStatic = case _ of
    Just LightMode -> Just Light
    Just DarkMode -> Just Dark
    _ -> Nothing
