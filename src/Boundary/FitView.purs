-- | `FitViewOptions`, and the padding inside it.
-- |
-- | One options bag with three consumers: `ReactFlow`'s `fitViewOptions` prop,
-- | `<Controls />`' prop of the same name, and — since stage 3 —
-- | `instance.fitView(options)`. Stage 1 kept it in `Boundary.Flow` and
-- | `Boundary.Chrome` reached across for it, which was fine while both were
-- | above it. Stage 3 is not: `Boundary.Instance` needs the same converter, and
-- | `onInit` puts `Boundary.Callbacks` above `Boundary.Instance`, which
-- | `Boundary.Flow` is already above. So the bag moves below all three rather
-- | than being written a second time.
-- |
-- | ## Invalid padding: reproduced, not refused
-- |
-- | Ticket 30 left this open and it is settled here, because stage 3 is where
-- | `FitViewOptions` first crosses as a *value a consumer passes to a method*
-- | rather than as a prop.
-- |
-- | ps-flow's `Padding` is a sum type: `UniformPadding`, `DirectionalPadding`,
-- | and a `PaddingValue` that is one of pixels, percent or ratio. Upstream's is
-- | the string union `` `${number}px` | `${number}%` | number ``, which is
-- | inhabited by strings the sum type cannot represent — `"10em"`,
-- | `"nonsense"`, `{}`. Upstream does not reject those. It
-- | `console.error`s a specific message and treats the value as **zero**.
-- |
-- | So the crossing does the same: same message, same zero. Three reasons,
-- | in the order they carry weight.
-- |
-- |   1. **The destination is behavioural parity, and a throw is the largest
-- |      divergence available.** Upstream renders a flow with no padding;
-- |      ps-flow would render nothing and unwind the caller's stack. That is
-- |      not a difference the net could ever be argued into overlooking.
-- |   2. **Upstream's behaviour here is specified, not accidental.** The
-- |      `console.error` and the `return 0` are written down in
-- |      `parsePadding`, one beside the other. Reproducing them is porting;
-- |      improving on them is forking.
-- |   3. **It is not silent.** The rule this module lives under is that a
-- |      value ps-flow cannot honour must not *look like* a value the consumer
-- |      never passed. An error on the console is not silence — and it is the
-- |      same error, on the same console, that the consumer would have got
-- |      from upstream, which the net's `console` section compares.
-- |
-- | This is deliberately *not* the rule `Boundary.Refusal` applies. A deferred
-- | prop is one ps-flow has not implemented, where upstream has behaviour and
-- | ps-flow has none, and throwing is the only honest answer. An invalid
-- | padding is one **upstream** has no behaviour for either, beyond a
-- | documented fallback — so there is a right answer to copy, and copying it
-- | is the whole job.
-- |
-- | The well-formed cases are unchanged and still throw nothing, because there
-- | is nothing wrong with them. What changed is the shape of the *malformed*
-- | branch, which used to end in `unsafeThrow`.
module Boundary.FitView
  ( JsFitViewOptions
  , fitViewOptionsIn
  , paddingIn
  ) where

import Prelude

import Boundary.Enums (interpolateModeIn)
import Boundary.Undefined (Undefinable, fromUndefinable)
import Boundary.Untagged (asNumber, asString)
import Data.Int (round) as Int
import Data.Maybe (Maybe(..), fromMaybe, fromMaybe', isJust)
import Data.Newtype (wrap)
import Data.Number as Number
import Data.String (Pattern(..), stripSuffix)
import Effect.Console (error) as Console
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import System.Types.Connection (Padding(..), PaddingValue(..))
import System.Utils.Graph (FitViewOptions)
import Unsafe.Coerce (unsafeCoerce)

type JsFitViewOptions =
  { padding :: Undefinable Foreign
  , includeHiddenNodes :: Undefinable Boolean
  , minZoom :: Undefinable Number
  , maxZoom :: Undefinable Number
  , duration :: Undefinable Number
  , ease :: Undefinable (Number -> Number)
  , interpolate :: Undefinable String
  , nodes :: Undefinable (Array { id :: String })
  }

fitViewOptionsIn :: JsFitViewOptions -> FitViewOptions
fitViewOptionsIn o =
  { padding: map paddingIn (fromUndefinable o.padding)
  , includeHiddenNodes: fromMaybe false (fromUndefinable o.includeHiddenNodes)
  , minZoom: fromUndefinable o.minZoom
  , maxZoom: fromUndefinable o.maxZoom
  , duration: map Int.round (fromUndefinable o.duration)
  , ease: fromUndefinable o.ease
  , interpolate:
      map (interpolateModeIn "fitViewOptions.interpolate") (fromUndefinable o.interpolate)
  , nodes: map (map \n -> { id: wrap n.id }) (fromUndefinable o.nodes)
  }

-- | Upstream's `Padding` is `` `${number}px` | `${number}%` | number `` or a
-- | record of those per side. A bare number is a **ratio** of the viewport,
-- | which is why upstream's default padding of `0.1` means ten percent.
-- |
-- | The three branches are upstream's `parsePaddings`, in its order:
-- | a scalar applies to every side, an object is read per side, and anything
-- | else — a boolean, a function — is zero *without* an error, because
-- | upstream's third branch returns its zeroed record having called
-- | `parsePadding` not at all. `null` and `undefined` never arrive:
-- | `Boundary.Undefined` folds both into an absent option one level up.
paddingIn :: Foreign -> Padding
paddingIn raw
  | isScalar raw = UniformPadding (fromMaybe' (\_ -> invalidPadding raw) (paddingValueIn raw))
  | isObject raw = directionalPaddingIn (unsafeCoerce raw)
  | otherwise = UniformPadding (PxPadding 0.0)

-- | The per-side branch. The sides are read by field rather than looked up by
-- | name, because a name-keyed lookup needs a fallback and the fallback would
-- | answer a misspelled side with some other side's value rather than failing.
-- |
-- | An absent side stays `Nothing`, which is ps-flow's "not set" and is what
-- | drives `System.Utils.General.parsePaddings`' own `?? y` / `?? x` fallback —
-- | the one upstream writes inline. Only a side that is *present and malformed*
-- | takes the zero, which is where upstream's per-side `parsePadding` errors.
directionalPaddingIn :: JsDirectionalPadding -> Padding
directionalPaddingIn sides = DirectionalPadding
  { top: side sides.top
  , right: side sides.right
  , bottom: side sides.bottom
  , left: side sides.left
  , x: side sides.x
  , y: side sides.y
  }
  where
  -- `fromMaybe'` and not `fromMaybe`: PureScript is strict, so the default is
  -- evaluated whether or not it is used, and `invalidPadding` logs. A bare
  -- `fromMaybe` reports every *well-formed* padding as invalid — which is what
  -- it did on the branch above until `parity/boundary/mount.mjs` caught it.
  side :: Undefinable Foreign -> Maybe PaddingValue
  side value = fromUndefinable value <#> \v ->
    fromMaybe' (\_ -> invalidPadding v) (paddingValueIn v)

type JsDirectionalPadding =
  { top :: Undefinable Foreign
  , right :: Undefinable Foreign
  , bottom :: Undefinable Foreign
  , left :: Undefinable Foreign
  , x :: Undefinable Foreign
  , y :: Undefinable Foreign
  }

paddingValueIn :: Foreign -> Maybe PaddingValue
paddingValueIn raw = case asNumber raw of
  Just n -> Just (RatioPadding n)
  Nothing -> case asString raw of
    Just s -> paddingStringIn s
    Nothing -> Nothing

-- | `typeof padding === 'string' || typeof padding === 'number'`, which is the
-- | test upstream's first branch makes.
isScalar :: Foreign -> Boolean
isScalar raw = isJust (asNumber raw) || isJust (asString raw)

-- | `Nothing` for a string with no unit or an unparseable number, which is
-- | upstream's `parseFloat` returning `NaN` or the suffix tests both failing.
paddingStringIn :: String -> Maybe PaddingValue
paddingStringIn s =
  case stripSuffix (Pattern "px") s of
    Just n -> map PxPadding (Number.fromString n)
    Nothing -> case stripSuffix (Pattern "%") s of
      Just n -> map PctPadding (Number.fromString n)
      Nothing -> Nothing

-- | Upstream's `parsePadding` fallback, verbatim: the message, then zero.
-- |
-- | `PxPadding 0.0` and not `RatioPadding 0.0` — both compute to zero through
-- | `System.Utils.General.parsePadding`, but pixels is what upstream's
-- | `return 0` is denominated in, and a ratio of zero reaching the same answer
-- | is arithmetic rather than agreement.
-- |
-- | `unsafePerformEffect` is how a *pure* converter reaches the console. The
-- | precedent is the line this branch replaces, which reached `unsafeThrow`
-- | from the same position — the conversion is pure in the type and this one
-- | member of it is not, in both directions of the decision.
invalidPadding :: Foreign -> PaddingValue
invalidPadding raw = unsafePerformEffect do
  Console.error $
    "The padding value \"" <> describe raw
      <> "\" is invalid. Please provide a number or a string with a valid unit (px or %)."
  pure (PxPadding 0.0)

-- | What upstream's template literal interpolates. `String(value)` rather than
-- | anything of ours, so an object prints `[object Object]` exactly as it does
-- | upstream and the two console lines compare equal.
foreign import describe :: Foreign -> String

foreign import isObject :: Foreign -> Boolean
