-- | FFI wrapper for `queueMicrotask`, exposed as the one `Aff` that needs it.
-- | Used by the auto-pan loop in `System.XYDrag`.
module System.FFI.Microtask
  ( awaitMicrotask
  ) where

import Prelude

import Data.Either (Either(..))
import Effect (Effect)
import Effect.Aff (Aff, makeAff, nonCanceler)

foreign import queueMicrotaskImpl :: Effect Unit -> Effect Unit

-- | Suspend, and resume on the microtask queue — what `await` does in
-- | JavaScript even when the promise it waits on has already settled.
-- |
-- | `Aff` does not do this on its own. Binding an `Aff` whose effects all ran
-- | synchronously continues on the same stack, so a port that translates
-- | `await f()` as `f` followed by the rest runs the rest *inside* the caller
-- | whenever `f` happens to be synchronous. Put this after `f` where the
-- | continuation must not run until the caller has returned.
awaitMicrotask :: Aff Unit
awaitMicrotask = makeAff \resume -> do
  queueMicrotaskImpl (resume (Right unit))
  pure nonCanceler
