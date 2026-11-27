-- | Upstream's `set(partial)` and `store.setState(partial)`: a write of some
-- | of the state's members, by name.
-- |
-- | zustand merges `partial` over the state with `Object.assign`, so the
-- | members it names are the ones written, whether or not their values
-- | change, and a member the state lacked is added after the ones it has,
-- | in the order `partial` names it. A JavaScript consumer sees both after
-- | `setState(next, true)` has left members out. So a write here keeps its
-- | record: the members it names are the record's labels, in the order the
-- | record lists them, and `Union` holds each to the state's type for it.
module React.Store.Partial
  ( StatePartial
  , partial
  , partialFrom
  , partialWhen
  , applyPartial
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Foreign (Foreign, unsafeToForeign)
import Prim.Row (class Union)

-- | Some members of a state record `s`, or nothing at all.
newtype StatePartial s = StatePartial (s -> Maybe Foreign)

-- | `set({ … })`.
partial :: forall r rest row. Union r rest row => Record r -> StatePartial (Record row)
partial r = StatePartial \_ -> Just (unsafeToForeign r)

-- | `setState((state) => ({ … }))`.
partialFrom :: forall r rest row. Union r rest row => (Record row -> Record r) -> StatePartial (Record row)
partialFrom f = StatePartial \s -> Just (unsafeToForeign (f s))

-- | `setState((state) => unchanged ? state : { … })`: `Nothing` hands the
-- | state back, which zustand's `Object.is` check reads as no write.
partialWhen :: forall r rest row. Union r rest row => (Record row -> Maybe (Record r)) -> StatePartial (Record row)
partialWhen f = StatePartial \s -> map unsafeToForeign (f s)

-- | The state with the partial written over it, and the members it names in
-- | its order. `Nothing` when the partial is no write.
applyPartial :: forall s. StatePartial s -> s -> Maybe { state :: s, written :: Array String }
applyPartial (StatePartial f) s = case f s of
  Nothing -> Nothing
  Just p -> Just { state: assignImpl s p, written: keysImpl p }

foreign import assignImpl :: forall s. s -> Foreign -> s
foreign import keysImpl :: Foreign -> Array String
