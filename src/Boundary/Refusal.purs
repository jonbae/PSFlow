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
-- | The message is still a parameter of `refuseFirst`, because not everything
-- | refused is a deferred prop: `defaultEdgeOptions`' thirteen dropped members
-- | are refused for a different reason and have to say so, or the consumer is
-- | sent to the wrong file.
module Boundary.Refusal
  ( Refusal
  , callbackProp
  , componentProp
  , deferredMessage
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

-- | A callback prop. Boundary stage 2, wherever it appears.
callbackProp :: forall props a. String -> (props -> Undefinable a) -> Refusal props
callbackProp name get =
  { name
  , stage: 2
  , note: "the callback props"
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
