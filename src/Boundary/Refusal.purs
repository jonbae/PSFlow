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
-- | holds what every table shares: the entry shape, the two kinds of entry
-- | that recur, the message a deferred prop gives, and the "first one that
-- | applies wins" lookup.
-- |
-- | Stage 2 emptied the largest of those tables. `callbackProp` — the entry
-- | kind every one of the 47 callback props used — is gone, because the
-- | callbacks cross now; what is left is the two kinds whose *arguments* have
-- | not crossed, which is a different claim and lands in a different stage.
-- |
-- | The message is still a parameter of `refuseFirst`, because not everything
-- | refused is a deferred prop: `defaultEdgeOptions`' thirteen dropped members
-- | are refused for a different reason and have to say so, or the consumer is
-- | sent to the wrong file.
module Boundary.Refusal
  ( Refusal
  , componentProp
  , deferredMessage
  , instanceProp
  , refuseFirst
  ) where

import Prelude

import Boundary.Undefined (Undefinable, isDefined)
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

-- | A prop whose value is a **handler of the imperative instance**.
-- |
-- | The callback props crossed in stage 2 and this is the one that could not
-- | come with them: `onInit`'s single argument is the `ReactFlowInstance`, and
-- | converting that is stage 3's whole subject rather than something a handler
-- | converter could do on the side. A callback whose arguments have not crossed
-- | has not crossed.
instanceProp :: forall props a. String -> (props -> Undefinable a) -> Refusal props
instanceProp name get =
  { name
  , stage: 3
  , note: "the imperative instance and the 21 hooks"
  , supplied: \p -> isDefined (get p)
  }

-- | A prop whose value is the consumer's own component, so crossing it means
-- | an outbound converter for the props that component receives.
componentProp :: forall props a. String -> (props -> Undefinable a) -> Refusal props
componentProp name get =
  { name
  , stage: 4
  , note: "the props that hand a consumer's own component its props record"
  , supplied: \p -> isDefined (get p)
  }

-- | What a deferred prop says. One wording for every one of them: they are
-- | refused for the same reason and land in the stage the entry names.
-- |
-- | Qualify `name` with the component (`"MiniMap.onClick"`) wherever a bare
-- | prop name would be ambiguous — `ReactFlow` has props of its own by some of
-- | the chrome components' names.
deferredMessage :: forall props. Refusal props -> String
deferredMessage d =
  "ps-flow: the `" <> d.name
    <> "` prop has not crossed the JavaScript boundary yet — it lands in "
    <> "boundary stage "
    <> show d.stage
    <> " ("
    <> d.note
    <> "). It is refused rather than ignored so that a prop ps-flow has not "
    <> "implemented fails loudly instead of looking like a prop you did not "
    <> "set."

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
