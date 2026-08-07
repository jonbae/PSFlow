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
module Boundary.Undefined
  ( Undefinable
  , undefined
  , defined
  , toUndefinable
  , fromUndefinable
  , isDefined
  , isNull
  , mapUndefinable
  ) where

import Prelude

import Data.Function.Uncurried (Fn3, runFn3)
import Data.Maybe (Maybe(..), maybe)

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
