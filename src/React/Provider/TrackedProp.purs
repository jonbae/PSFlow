-- | How `<StoreUpdater />` decides that a tracked prop changed.
-- |
-- | Upstream keeps the previous value of every tracked field in a ref and
-- | dispatches only the fields whose value differs, comparing the raw prop
-- | with `!==`
-- | (`xyflow-main/packages/react/src/components/StoreUpdater/index.tsx`).
-- | The PS port needs no such ref: `useEffect` already caches its deps and
-- | re-runs when the `Eq` instance says they differ. It needs the instance to
-- | compare what upstream compares.
-- |
-- | `UnsafeReference (Maybe a)` does not. Each field reaches the component as
-- | a `Maybe` that `Boundary.Flow` rebuilds with `fromUndefinable` on every
-- | render, and `fromUndefinable` applies `Just` at run time — so `Just true`
-- | is a fresh allocation each render, reference equality on the wrapper is
-- | always false, and every effect fired on every render.
-- |
-- | Most fields shrug that off, because a repeated dispatch of the same value
-- | is idempotent. `fitView` does not. Each dispatch sets `fitViewQueued`, and
-- | `React.Store.Reduce.reduceMergeNodeInternals` resolves a queued fit on the
-- | next node-internals update, so dragging a node on a `fitView: true` flow
-- | re-queued a fit per render and dragged the viewport along with it.
-- |
-- | So compare the payload rather than the wrapper. That is upstream's
-- | comparison exactly: `!==` on a raw prop is by value for a boolean, a
-- | number or a string and by reference for an object, which is what
-- | `unsafeRefEq` gives on the payload, and `Nothing` — upstream's `undefined`
-- | — equals itself.
-- |
-- | What this does *not* buy is a stable payload. `Boundary.Flow` wraps every
-- | callback and rebuilds every array and record on each render, so a field
-- | holding one of those still differs by reference and still re-dispatches.
-- | That is the same thing upstream does when a consumer passes a fresh object
-- | inline, and it is safe for the same reason: the fields where a repeated
-- | dispatch is not idempotent hold primitives, and those now compare equal.
module React.Provider.TrackedProp
  ( TrackedProp(..)
  , changed
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Unsafe.Reference (unsafeRefEq)

-- | A tracked prop, wrapped so `useEffect` compares it the way upstream's
-- | `previousFields` check does.
newtype TrackedProp a = TrackedProp (Maybe a)

instance eqTrackedProp :: Eq (TrackedProp a) where
  eq (TrackedProp (Just a)) (TrackedProp (Just b)) = unsafeRefEq a b
  eq (TrackedProp Nothing) (TrackedProp Nothing) = true
  eq _ _ = false

-- | Whether `<StoreUpdater />` re-dispatches this field. The component asks
-- | through `useEffect`'s deps cache; a test asks here, without rendering.
changed :: forall a. Maybe a -> Maybe a -> Boolean
changed prev next = TrackedProp prev /= TrackedProp next
