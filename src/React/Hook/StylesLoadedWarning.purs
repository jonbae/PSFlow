-- | `useStylesLoadedWarning` — one-shot dev-time check that the React
-- | Flow stylesheet is present. Mirrors
-- | `xyflow-main/packages/react/src/container/GraphView/useStylesLoadedWarning.ts`.
-- |
-- | The TS source asserts `getComputedStyle(.react-flow__pane).zIndex
-- | === '1'` because the bundled stylesheet sets that exact value — if
-- | the user forgot to import `@xyflow/react/dist/style.css`, the rule
-- | doesn't apply and the check fires E013.
-- |
-- | **The gating flag** is `React.FFI.Env.isDevelopment` — a build-time
-- | `Boolean` exposed via FFI that bundlers can constant-fold via
-- | `define`. Defaults to `true` so the check fires unless explicitly
-- | silenced. Same mechanism as
-- | [React.Hook.NodeOrEdgeTypesWarning](src/React/Hook/NodeOrEdgeTypesWarning.purs).
module React.Hook.StylesLoadedWarning
  ( UseStylesLoadedWarning(..)
  , useStylesLoadedWarning
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Nullable (Nullable, toMaybe)
import Effect (Effect)
import React.Basic.Hooks (Hook, UseEffect, UseRef, coerceHook, readRef, useEffectOnce, useRef, writeRef)
import React.Basic.Hooks as React
import React.FFI.Env (isDevelopment)
import React.Hook.Store (UseStoreApi, useStoreApi)
import System.Constants (ErrorCode(..), errorMessage)

-- | FFI: query `.react-flow__pane` and return its computed `z-index`
-- | string, or `null` if no element matches. Used to decide whether the
-- | bundled stylesheet has loaded — the rule sets `z-index: 1`.
foreign import checkPaneZIndex :: Effect (Nullable String)

-- | Hook-effect tag.
newtype UseStylesLoadedWarning hooks =
  UseStylesLoadedWarning
    ( UseEffect Unit
        ( UseRef Boolean
            (UseStoreApi hooks)
        )
    )

derive instance newtypeUseStylesLoadedWarning ::
  Newtype (UseStylesLoadedWarning hooks) _

useStylesLoadedWarning :: Hook UseStylesLoadedWarning Unit
useStylesLoadedWarning = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi _)
  checkedRef <- useRef false
  useEffectOnce do
    when isDevelopment do
      s <- store.getState
      checked <- readRef checkedRef
      when (not checked) do
        mZIndex <- toMaybe <$> checkPaneZIndex
        case mZIndex of
          Just z | z /= "1" -> case s.onError of
            Just cb -> cb "013" (errorMessage (E013 "react"))
            Nothing -> pure unit
          _ -> pure unit
        writeRef checkedRef true
    pure (pure unit)

