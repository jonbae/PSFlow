-- | Upstream's in-place writes into the store's state.
-- |
-- | A few of upstream's store actions change an object the state holds
-- | rather than call `set`, such as a selection's
-- | `internalNode.selected = true`. Zustand notifies its subscribers only
-- | when `set` hands it a new state object, so nobody hears of such a write:
-- | `getState` reads it at once, and a `useStore` selector reads it at the
-- | next `set`, whatever that changes. `useStore`'s memo keys on the state's
-- | identity, so a re-render in between keeps the selection it had.
module React.Store.InPlace
  ( inPlace
  ) where

-- | `inPlace f s` writes the fields of `f s` into `s` itself, and returns
-- | `s`. A reducer that returns it hands the shell back the state it
-- | had, so the shell notifies nobody, as zustand doesn't.
foreign import inPlace :: forall r. (Record r -> Record r) -> Record r -> Record r
