-- | `undefined`, which is what a JavaScript consumer means by "I did not set
-- | this".
-- |
-- | PureScript ships `Data.Nullable`, and it is *nearly* right: `toMaybe`
-- | already folds `undefined` in with `null`, so the inbound direction could
-- | use it as-is. The outbound direction cannot. `toNullable Nothing` produces
-- | `null`, and upstream produces `undefined` — a prop object built by
-- | `@xyflow/react` has the key present with the value `undefined`, never
-- | `null`. The net serializes every enumerable own property, so `null` where
-- | upstream has `undefined` is a divergence the net would report on every
-- | optional field of every node on every run.
-- |
-- | So this is `Nullable` with the other absent value. Inbound is deliberately
-- | lenient — `null` and `undefined` both read as `Nothing`, because upstream's
-- | own types say `string | null` in places (`Edge.sourceHandle`) and a
-- | consumer following them must not be punished.
-- |
-- | Two readers live here beside the type, because both are about what an
-- | absent value *means* and both are shared by more than one converter
-- | module: `requiredProp`, for the props upstream declares required and a
-- | JavaScript caller can omit anyway, and `orNullable`, for `ref` — the one
-- | place React puts a value in one of two absent-shaped places depending on
-- | its major version.
module Boundary.Undefined
  ( Undefinable
  , undefined
  , defined
  , toUndefinable
  , fromUndefinable
  , isDefined
  , isNull
  , mapUndefinable
  , orNullable
  , requiredProp
  ) where

import Prelude

import Data.Function.Uncurried (Fn3, runFn3)
import Data.Maybe (Maybe(..), maybe)
import Data.Nullable (Nullable, notNull)
import Effect.Exception.Unsafe (unsafeThrow)

-- | `a | undefined`, as a JavaScript value.
foreign import data Undefinable :: Type -> Type

foreign import undefined :: forall a. Undefinable a

foreign import defined :: forall a. a -> Undefinable a

foreign import undefinableImpl :: forall a r. Fn3 r (a -> r) (Undefinable a) r

toUndefinable :: forall a. Maybe a -> Undefinable a
toUndefinable = maybe undefined defined

fromUndefinable :: forall a. Undefinable a -> Maybe a
fromUndefinable = runFn3 undefinableImpl Nothing Just

-- | Whether a JavaScript caller supplied the field at all. The deferred-prop
-- | guard is written in terms of this: a prop that is present but `undefined`
-- | reads as unsupplied, which is how React and upstream both treat it.
isDefined :: forall a. Undefinable a -> Boolean
isDefined = runFn3 undefinableImpl false (const true)

mapUndefinable :: forall a b. (a -> b) -> Undefinable a -> Undefinable b
mapUndefinable f = toUndefinable <<< map f <<< fromUndefinable

-- | `null` specifically, told apart from `undefined`. Almost nothing needs the
-- | distinction — the two mean the same thing everywhere on this surface bar
-- | one place, the five key-code props, where upstream types them
-- | `KeyCode | null` and `null` means *disable the key* while absence means
-- | *use the default*. Three states, and `Maybe KeyCode` holds two.
foreign import isNull :: forall a. Undefinable a -> Boolean

-- | The one place the two absent values are both in play at once, which is
-- | `ref`. React 18 strips `ref` out of the props object and hands it to a
-- | `forwardRef` render function separately, where absence is `null`; React 19
-- | leaves it in the props object, where absence is `undefined`. So a crossing
-- | that wants to work on both reads the field and falls back to the argument,
-- | which is this.
-- |
-- | `Nullable` on the way out because the value goes straight back to React,
-- | which reads a null ref as no ref.
orNullable :: forall a. Undefinable a -> Nullable a -> Nullable a
orNullable supplied fallback = case fromUndefinable supplied of
  Just v -> notNull v
  Nothing -> fallback

-- | A prop upstream declares required, read off a record that types it
-- | `Undefinable` anyway — because a JavaScript caller can always omit it and
-- | TypeScript is not running. `field` is the JS-facing path the value arrived
-- | on, qualified by its component (`"Panel.position"`, `"BaseEdge.path"`),
-- | because several records on this surface share a member name and the
-- | message is the only thing that says which element to go and look at.
-- |
-- | Shared rather than written per converter module: an omission met by a
-- | pattern-match failure names nothing, and one wording is what makes that
-- | true everywhere instead of wherever someone remembered.
requiredProp :: forall a. String -> Undefinable a -> a
requiredProp field u = case fromUndefinable u of
  Just v -> v
  Nothing ->
    unsafeThrow $
      "ps-flow: `" <> field <> "` is required and was not supplied."
