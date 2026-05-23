-- | `useStylesLoadedWarning` — one-shot dev-time check that the React
-- | Flow stylesheet is present. Mirrors
-- | `xyflow-main/packages/react/src/container/GraphView/useStylesLoadedWarning.ts`.
-- |
-- | The TS source asserts `getComputedStyle(.react-flow__pane).zIndex
-- | === '1'` because the bundled stylesheet sets that exact value — if
-- | the user forgot to import `@xyflow/react/dist/style.css`, the rule
-- | doesn't apply and the check fires E013.
-- |
-- | **PS divergence: gate on `state.debug`** rather than
-- | `process.env.NODE_ENV === 'development'`. Same rationale as
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
import Effect.Ref as Ref
import React.Basic (Ref)
import React.Basic.Hooks (Hook, UseEffect, UseRef, coerceHook, useEffectOnce, useRef)
import React.Basic.Hooks as React
import React.Hook.Store (UseStoreApi, useStoreApi)
import System.Constants (ErrorCode(..), errorMessage)
import Unsafe.Coerce (unsafeCoerce)

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
    s <- store.getState
    when s.debug do
      checked <- Ref.read (toEffectRef checkedRef)
      when (not checked) do
        mZIndex <- toMaybe <$> checkPaneZIndex
        case mZIndex of
          Just z | z /= "1" -> case s.onError of
            Just cb -> cb "013" (errorMessage (E013 "react"))
            Nothing -> pure unit
          _ -> pure unit
        Ref.write true (toEffectRef checkedRef)
    pure (pure unit)

-- | `react-basic`'s `Ref` and `effect-ref`'s `Ref` are the same JS cell.
toEffectRef :: forall a. Ref a -> Ref.Ref a
toEffectRef = unsafeCoerce
