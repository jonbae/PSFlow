-- | Refusing a prop rather than dropping it.
-- |
-- | A prop that was silently ignored would be indistinguishable from a prop
-- | the consumer never set — the exact failure shape of the unrun `Effect`
-- | thunk that produced this whole effort. The compiler is no help: a record
-- | forces you to write *something* per field, and `Nothing` compiles
-- | perfectly. So a converter that cannot honour a prop carries a **table** of
-- | what it refuses, and this module holds what every such table shares: the
-- | entry shape, and the "first one that applies wins" lookup.
-- |
-- | **One table is left**, and it is not the kind this module was built for.
-- |
-- | A **deferred prop** — one that resolves on the JS surface and whose
-- | converter has not landed — used to be most of what these tables held, and
-- | there are none. Each stage emptied one and deleted the entry kind it was
-- | the last user of: stage 2 took `callbackProp` and its 47 entries, stage 3
-- | took `instanceProp` and `onInit`, and stage 4 took `componentProp` and the
-- | last three — `edgeTypes`, `connectionLineComponent` and
-- | `MiniMap.nodeComponent`, crossed by `Boundary.Edges` and
-- | `Boundary.Chrome`. An entry kind nobody constructs is a register outliving
-- | its cause, which is the one thing this repo's registers are built not to
-- | do, so each kind went with its entries and what stays here is the two
-- | pieces a new one would be written from.
-- |
-- | What still refuses was never a deferred prop: `defaultEdgeOptions`'
-- | thirteen dropped members, in `Boundary.Flow`, refused because ps-flow's
-- | record does not model them rather than because a converter is pending —
-- | so no stage retires them. That is why the message was always a parameter
-- | of `refuseFirst`, since a refusal that sent the consumer to the wrong file
-- | would be worse than none, and it is what keeps this machinery exercised
-- | and provably able to go red now that the deferred half is gone.
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
