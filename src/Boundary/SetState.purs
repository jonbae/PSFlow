-- | React's `Dispatch<SetStateAction<T[]>>` — `T[] | ((prev: T[]) => T[])`.
-- |
-- | ps-flow's setters are the function form only. A JavaScript consumer writing
-- | `setNodes([])` is writing correct upstream code, so the array form is
-- | adapted rather than refused: it is React's contract, not an unimplemented
-- | prop, and refusing is for the latter.
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
-- | An element the consumer's function returns as it was handed comes back
-- | as the record it was made from, not a copy. Upstream's diff reports a
-- | `replace` only for an item that isn't the object the store holds, so a
-- | copy of every untouched node would read as a change to every node.
-- |
-- | `setNodes(fn)` returning an unrun `Effect` thunk is the failure the whole
-- | boundary effort started from. What holds it here is that the result type is
-- | `EffectFn1 … Unit`, which compiles to a JavaScript function that has
-- | already run by the time it returns `undefined`.
module Boundary.SetState
  ( setStateOut
  ) where

import Prelude

import Boundary.Untagged (asArray, asFunction)
import Data.Function.Uncurried (Fn4, runFn4)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Uncurried (EffectFn1, mkEffectFn1)
import Foreign (Foreign)
import System.Utils.AsWritten (hold, isHeld, orHeld) as AsWritten
import Unsafe.Coerce (unsafeCoerce)

foreign import keepIdentityImpl :: forall js ps. Fn4 (Array ps) (Array js) (Array js) (js -> ps) (Array ps)

-- | Upstream's setters take any value: the instance's queues it, and a
-- | `useNodesState` setter is React's own. An array or a function's result
-- | whose items ps-flow cannot read is held as it was written, as is any
-- | other value, and fails where the flow first uses it, as upstream's does.
-- | A previous value held as written is handed to the function as it is.
setStateOut
  :: forall js ps
   . (js -> ps)
  -> (ps -> js)
  -> ((Array ps -> Array ps) -> Effect Unit)
  -> EffectFn1 Foreign Unit
setStateOut inward outward set = mkEffectFn1 \action ->
  case asFunction action of
    Just update ->
      set \previous ->
        if AsWritten.isHeld previous then nextOf (update (unsafeCoerce previous))
        else
          let
            handed = map outward previous
            returned = update (unsafeCoerce handed)
          in
            case asArray returned of
              Just entries ->
                AsWritten.orHeld (\_ -> runFn4 keepIdentityImpl previous handed (unsafeCoerce entries) inward)
                  (unsafeCoerce returned)
              Nothing -> AsWritten.hold (unsafeCoerce returned)
    Nothing ->
      let
        next = nextOf action
      in
        set \_ -> next
  where
  nextOf :: Foreign -> Array ps
  nextOf raw = case asArray raw of
    Just entries -> AsWritten.orHeld (\_ -> map inward (unsafeCoerce entries)) (unsafeCoerce raw)
    Nothing -> AsWritten.hold (unsafeCoerce raw)
