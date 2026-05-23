-- | `useNodeOrEdgeTypesWarning` — dev-time guard that fires the upstream
-- | E002 error if a `nodeTypes` or `edgeTypes` record reference changes
-- | between renders. Mirrors
-- | `xyflow-main/packages/react/src/container/GraphView/useNodeOrEdgeTypesWarning.ts`.
-- |
-- | **PS divergence: the gating flag.** TS uses
-- | `process.env.NODE_ENV === 'development'`. The PS port keys off the
-- | `state.debug :: Boolean` flag instead, set by the user on the
-- | provider — there is no `process.env` equivalent at compile time in
-- | the PureScript output we produce.
-- |
-- | **One-shot per identity change.** TS holds the previous types record
-- | in a `useRef`. We do the same. When the user passes the *same*
-- | record reference twice, the wrapping `UnsafeReference` dep is equal
-- | and the effect doesn't re-fire — that's the intended behaviour.
-- | The body compares per-key by JS object identity (matching TS) and
-- | fires `state.onError` at most once per identity change.
module React.Hook.NodeOrEdgeTypesWarning
  ( UseNodeOrEdgeTypesWarning(..)
  , useNodeOrEdgeTypesWarning
  ) where

import Prelude

import Data.Array (index) as Array
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Effect.Ref as Ref
import Foreign (Foreign)
import React.Basic (Ref)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseEffect, UseRef, coerceHook, useEffect, useRef)
import React.Basic.Hooks as React
import React.Hook.Store (UseStoreApi, useStoreApi)
import System.Constants (ErrorCode(..), errorMessage)
import Unsafe.Coerce (unsafeCoerce)

-- | FFI: union of own enumerable keys.
foreign import objectKeysUnion :: Foreign -> Foreign -> Array String

-- | FFI: `obj[key]` reduced to a `Foreign` (or `undefined` lifted to
-- | `Foreign`).
foreign import lookupKey :: Foreign -> String -> Foreign

-- | FFI: `a === b`. Used to compare per-key entries between the previous
-- | and current types record.
foreign import referenceEqual :: Foreign -> Foreign -> Boolean

-- | An empty types record used as the seed when the caller passes
-- | `Nothing`. Mirrors TS `const emptyTypes = {}`.
foreign import emptyTypes :: Foreign

-- | Hook-effect tag.
newtype UseNodeOrEdgeTypesWarning hooks =
  UseNodeOrEdgeTypesWarning
    ( UseEffect (UnsafeReference Foreign)
        ( UseRef Foreign
            (UseStoreApi hooks)
        )
    )

derive instance newtypeUseNodeOrEdgeTypesWarning ::
  Newtype (UseNodeOrEdgeTypesWarning hooks) _

useNodeOrEdgeTypesWarning
  :: Maybe Foreign
  -> Hook UseNodeOrEdgeTypesWarning Unit
useNodeOrEdgeTypesWarning mTypes = coerceHook React.do
  let
    current = case mTypes of
      Just t -> t
      Nothing -> emptyTypes
  store <- (useStoreApi :: Hook UseStoreApi _)
  typesRef <- useRef current
  useEffect (UnsafeReference current) do
    s <- store.getState
    when s.debug do
      previous <- Ref.read (toEffectRef typesRef)
      let
        keys = objectKeysUnion previous current
        anyDiffered = checkKeys keys previous current 0
      when anyDiffered do
        case s.onError of
          Just cb -> cb "002" (errorMessage E002)
          Nothing -> pure unit
    Ref.write current (toEffectRef typesRef)
    pure (pure unit)
  where
  checkKeys :: Array String -> Foreign -> Foreign -> Int -> Boolean
  checkKeys ks prev curr i =
    case Array.index ks i of
      Nothing -> false
      Just k ->
        if not (referenceEqual (lookupKey prev k) (lookupKey curr k)) then true
        else checkKeys ks prev curr (i + 1)

-- | `react-basic`'s `Ref` and `effect-ref`'s `Ref` are the same JS cell.
toEffectRef :: forall a. Ref a -> Ref.Ref a
toEffectRef = unsafeCoerce
