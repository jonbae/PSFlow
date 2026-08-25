-- | `Promise`, which is what a JavaScript caller means by an `Aff`.
-- |
-- | Stage 2 needed the *inbound* direction and got it from
-- | `Effect.Aff.Compat`: `onBeforeDelete` answers with a promise and ps-flow
-- | wants an `Aff`, so `Boundary.Callbacks`' `awaitPromise` bridges one call
-- | site and nothing more.
-- |
-- | Stage 3 needs the other direction, and needs it eleven times. Every
-- | animated method of the imperative instance is `Aff Boolean` on the
-- | PureScript side and `Promise<boolean>` upstream, and `deleteElements` is
-- | `Aff` of a record against `Promise` of an object. An `Aff` reaching a
-- | JavaScript caller unconverted is the `Effect`-thunk failure one type
-- | further along: it is a value with a `.then`-shaped hole where `.then` is
-- | not, so `await instance.fitView()` resolves immediately to the `Aff`
-- | itself and the caller proceeds as though the animation had finished.
-- |
-- | So this is one small module rather than a helper inside
-- | `Boundary.Instance`, for the reason `Boundary.Undefined` is one: it is a
-- | representation the whole surface shares, and the next stage's converters
-- | should reach for it rather than write a second bridge.
-- |
-- | ## Running the `Aff` is the point, and is where the care is
-- |
-- | `toPromise` **starts** the `Aff` — `runAff_` is called inside the promise
-- | executor, so the work begins when the JavaScript caller calls the method,
-- | which is when upstream's begins. An `Aff` that were merely stored and run
-- | later would resolve the promise on a different turn from upstream's and
-- | show up in the net as a settling difference rather than as the wiring bug
-- | it would be.
-- |
-- | The error channel maps to rejection rather than being swallowed. `Aff`'s
-- | is typed `Error`, which is already what a JavaScript `catch` expects, so
-- | nothing is wrapped on the way out — the value the internals threw is the
-- | value the consumer catches.
module Boundary.Promise
  ( Promise
  , toPromise
  ) where

import Prelude

import Data.Either (Either(..))
import Effect (Effect)
import Effect.Aff (Aff, runAff_)
import Effect.Exception (Error)
import Effect.Uncurried
  ( EffectFn1
  , EffectFn2
  , mkEffectFn2
  , runEffectFn1
  )

-- | A JavaScript `Promise`. Opaque: ps-flow only ever hands one to a consumer,
-- | and the one place it reads one — `onBeforeDelete`'s answer — is inbound and
-- | belongs to `Boundary.Callbacks`.
foreign import data Promise :: Type -> Type

foreign import mkPromise
  :: forall a
   . EffectFn1 (EffectFn2 (EffectFn1 a Unit) (EffectFn1 Error Unit) Unit) (Promise a)

-- | `Aff a` as `Promise<a>`, started.
-- |
-- | The result is an `Effect` and not a bare `Promise` because constructing one
-- | *is* the side effect: it runs the `Aff`. Every caller in
-- | `Boundary.Instance` is inside an `EffectFn`, which is exactly where the
-- | JavaScript caller's own call lands, so the two clocks start together.
toPromise :: forall a. Aff a -> Effect (Promise a)
toPromise aff = runEffectFn1 mkPromise $ mkEffectFn2 \resolve reject ->
  runAff_
    ( case _ of
        Left err -> runEffectFn1 reject err
        Right value -> runEffectFn1 resolve value
    )
    aff
