-- | Refusing a prop the boundary has not crossed.
-- |
-- | A **deferred prop** resolves on the JS surface and has no converter yet.
-- | It throws at mount, because a prop that was silently ignored would be
-- | indistinguishable from a prop the consumer never set — the exact failure
-- | shape of the unrun `Effect` thunk that produced this whole effort. The
-- | compiler is no help: a record forces you to write *something* per field,
-- | and `Nothing` compiles perfectly.
-- |
-- | So each converter carries a **table** of what it refuses, and this module
-- | holds the two things every table shares: the entry shape, and the "first
-- | one that applies wins" lookup. The message is the caller's, because the
-- | thing being refused reads differently in each place — a flow prop, a
-- | member of an options bag, a prop of one of the chrome components — and a
-- | message that named none of them would send the consumer to the wrong file.
module Boundary.Refusal
  ( Refusal
  , refuseFirst
  ) where

import Data.Array (find)
import Data.Maybe (Maybe(..))
import Effect.Exception.Unsafe (unsafeThrow)

-- | One prop, or one member of one prop, that resolves on the JS surface and
-- | does not cross. `props` is whichever record it sits on.
type Refusal props =
  { name :: String
  , stage :: Int
  , note :: String
  , supplied :: props -> Boolean
  }

-- | Throw on the first refusal the consumer tripped, and otherwise hand the
-- | record straight back.
-- |
-- | Returning the record rather than `Unit` is what makes a guard
-- | unskippable: a conversion written as `convert <<< guard` has no way to
-- | reach a converted field without having gone through here first.
refuseFirst :: forall props. (Refusal props -> String) -> Array (Refusal props) -> props -> props
refuseFirst message refusals p = case find (\r -> r.supplied p) refusals of
  Nothing -> p
  Just r -> unsafeThrow (message r)
