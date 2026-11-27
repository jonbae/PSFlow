-- | Store members a consumer wrote with a value of the wrong shape.
-- |
-- | Upstream's store is a plain object, so after `setState({ nodes: 'x' })`
-- | its `nodes` is the string `'x'`, and each line of upstream's code that
-- | reads it does what JavaScript does with a string: `.map` throws a
-- | `TypeError`, `for…of` walks its characters, `!!` is `true`. ps-flow's
-- | store holds such a value as it was written too. `Boundary.Store` hands it
-- | to `hold` when the member's converter cannot read it, and ps-flow's code
-- | reads it where upstream's does, with the operation upstream's line uses.
-- |
-- | A member's converted value is always a reference: an array, a record, a
-- | `Data.Map`, a `Maybe`. So `isHeld` is true of a primitive and of a
-- | reference `hold` was given, and nothing else.
-- |
-- | `[x, y, zoom]` and the other tuples are records here and arrays
-- | upstream, which reads them by index. A tuple ps-flow cannot convert is
-- | `indexed`: a record whose fields read the written value by index when
-- | they are read, so `transform[0]` of `'x'` is `'x'` and `transform[0]` of
-- | `null` throws, wherever ps-flow reads `tx`. The few places upstream
-- | destructures a tuple, `const [x, y, zoom] = transform`, walk the written
-- | value with `destructured`.
module System.Utils.AsWritten
  ( hold
  , isHeld
  , orHeld
  , indexed
  , writtenOf
  , orElse
  , destructured
  , iterated
  , forEachItems
  , mapped
  , some
  , reduced
  , truthy
  , nullish
  , member
  , optionalMember
  , spread
  , spreadWith
  , absent
  , orIfUndefined
  , copies
  ) where

import Prelude

import Data.Function.Uncurried (Fn3, runFn3)
import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toMaybe)
import Foreign (Foreign)
import Unsafe.Coerce (unsafeCoerce)

-- | Marks a value a member holds as it was written, and returns it. An
-- | array's items are marked with it.
foreign import hold :: forall a. a -> a

-- | Whether a member's value is one it holds as written. Only meaningful for
-- | a member whose converted value is a reference.
foreign import isHeld :: forall a. a -> Boolean

-- | The conversion, or the value itself, held, when the conversion throws.
foreign import orHeld :: forall a b. (a -> b) -> a -> b

foreign import indexedImpl :: forall r. Array (Array Foreign) -> Foreign -> r

foreign import destructuredImpl :: forall r. r -> Nullable (Array Foreign)

foreign import writtenOfImpl :: forall r. r -> Nullable { value :: Foreign }

foreign import orElseImpl :: forall a b. Fn3 (a -> b) (a -> b) a b

-- | `for (const item of value)`: the items JavaScript's iteration protocol
-- | gives, so a string walks its characters and a number throws a
-- | `TypeError`. An array is returned as it is.
foreign import iterated :: forall a. Array a -> Array a

-- | `value.forEach((item) => …)`: the items it is called with. An array is
-- | returned as it is.
foreign import forEachItems :: forall a. Array a -> Array a

-- | `value.map((item) => f(item))`.
foreign import mapped :: forall a b. (a -> b) -> Array a -> Array b

-- | `value.some((item) => f(item))`.
foreign import some :: forall a. (a -> Boolean) -> Array a -> Boolean

foreign import reducedImpl :: forall a b. Fn3 (b -> a -> b) b (Array a) b

-- | `value.reduce(step, initial)`.
reduced :: forall a b. (b -> a -> b) -> b -> Array a -> b
reduced = runFn3 reducedImpl

-- | `value === null || value === undefined`. A record `indexed` reads from
-- | a value stands for that value.
foreign import nullish :: forall a. a -> Boolean

-- | JavaScript's `!!value`. A record `indexed` reads from a value stands
-- | for that value.
foreign import truthy :: forall a. a -> Boolean

-- | `value[name]`, for a value held as written, so `null` and `undefined`
-- | throw a `TypeError`.
foreign import member :: forall a. String -> a -> Foreign

-- | `value?.[name]`.
foreign import optionalMember :: forall a. String -> a -> Foreign

-- | `{ ...object }`.
foreign import spread :: forall a. a -> Foreign

-- | `{ ...object, [name]: value }`.
foreign import spreadWith :: forall a. String -> Foreign -> a -> Foreign

-- | JavaScript's `undefined`, for reading a member of it where upstream
-- | does.
foreign import absent :: forall a. a

-- | A destructuring default, `const { nodes = [] } = state`: the fallback
-- | in place of `undefined`, and the value itself otherwise. A record
-- | `indexed` reads from `undefined` stands for `undefined`.
foreign import orIfUndefined :: forall a. a -> a -> a

-- | `value.map((item) => ({ ...item }))`.
foreign import copies :: forall a. Array a -> Array Foreign

-- | A record whose fields read `written` by index each time they are read:
-- | each field names the indexes upstream reads it at, such as
-- | `{ field: "maxX", at: [ 1, 0 ] }` for `extent[1][0]`.
indexed :: forall r. Array { field :: String, at :: Array Int } -> Foreign -> r
indexed fields = indexedImpl (map (\f -> [ unsafeCoerce f.field, unsafeCoerce f.at ]) fields)

-- | The value a record `indexed` reads, and `Nothing` for any other record.
writtenOf :: forall r. r -> Maybe Foreign
writtenOf = map _.value <<< toMaybe <<< writtenOfImpl

-- | `first value`, or `second value` when the first throws.
orElse :: forall a b. (a -> b) -> (a -> b) -> a -> b
orElse first second = runFn3 orElseImpl first second

-- | `const [a, b, c] = written` for a record `indexed` read from `written`,
-- | and `Nothing` for any other record. A value JavaScript cannot iterate,
-- | such as a number, throws a `TypeError`.
destructured :: forall r. r -> Maybe (Array Foreign)
destructured = toMaybe <<< destructuredImpl
