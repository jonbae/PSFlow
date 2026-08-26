-- | React's `Dispatch<SetStateAction<T[]>>` — `T[] | ((prev: T[]) => T[])`.
-- |
-- | ps-flow's setters are the function form only. A JavaScript consumer writing
-- | `setNodes([])` is writing correct upstream code, so the array form is
-- | adapted rather than refused: it is React's contract, not an unimplemented
-- | prop, and `Boundary.Refusal` is for the latter.
-- |
-- | ## Why this is its own module
-- |
-- | Stage 1 wrote this inside `Boundary.Hooks`, where `useNodesState` and
-- | `useEdgesState` were the only two setters on the surface. Stage 3 adds
-- | `instance.setNodes` and `instance.setEdges`, whose PureScript type is the
-- | same `(Array ps -> Array ps) -> Effect Unit` — and `Boundary.Instance` and
-- | `Boundary.Hooks` cannot import each other, because `useReactFlow` returns
-- | the instance. Four call sites, one representation, so it moves down here
-- | rather than being written twice or reached for through a cycle.
-- |
-- | ## Both forms round-trip
-- |
-- | The previous array goes out through `outward` before the consumer's
-- | function sees it, and whatever comes back goes in through `inward`. So a
-- | consumer is handed the same JS-shaped values `applyNodeChanges` hands them
-- | and may build the next array out of either — the ones they were given, or
-- | ones they wrote themselves.
-- |
-- | `setNodes(fn)` returning an unrun `Effect` thunk is the failure the whole
-- | boundary effort started from. What holds it here is that the result type is
-- | `EffectFn1 … Unit`, which compiles to a JavaScript function that has
-- | already run by the time it returns `undefined`.
module Boundary.SetState
  ( setStateOut
  ) where

import Prelude

import Boundary.Untagged (asArray, asFunction, typeName)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried (EffectFn1, mkEffectFn1)
import Foreign (Foreign)
import Unsafe.Coerce (unsafeCoerce)

-- | `name` is the setter as the consumer wrote it, so a bad argument names
-- | `setEdges` rather than some helper of ours.
setStateOut
  :: forall js ps
   . String
  -> (js -> ps)
  -> (ps -> js)
  -> ((Array ps -> Array ps) -> Effect Unit)
  -> EffectFn1 Foreign Unit
setStateOut name inward outward set = mkEffectFn1 \action ->
  case asFunction action of
    Just update ->
      set \previous -> map inward (expect "returned" (update (unsafeCoerce (map outward previous))))
    Nothing ->
      -- Read *before* the updater is built, not inside it. The instance's
      -- `setNodes` hands its updater to the store's batch queue, which is
      -- drained by an effect, so a check inside the closure would report a bad
      -- argument on some later tick and from inside React rather than at the
      -- call that made the mistake. The array form is already fully known here,
      -- so there is nothing to wait for.
      let
        next = map inward (expect "was called with" action)
      in
        set \_ -> next
  where
  expect what raw = case asArray raw of
    Just entries -> unsafeCoerce entries
    Nothing ->
      unsafeThrow $
        "ps-flow: `" <> name <> "` " <> what <> " " <> typeName raw
          <> " — it takes the next array, or a function of the previous one."
