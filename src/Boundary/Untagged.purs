-- | Runtime inspection for upstream's untagged unions.
-- |
-- | TypeScript expresses a good deal of `@xyflow/react`'s surface as unions
-- | with no discriminant: `deleteKeyCode` is `string | string[]`, `panOnDrag`
-- | is `boolean | number[]`, `Node.extent` is `'parent' | CoordinateExtent`,
-- | `Edge.markerEnd` is `string | EdgeMarker`. TypeScript narrows those with
-- | `typeof` and `Array.isArray` at the use site and erases the types
-- | entirely at runtime; PureScript's sum types carry a tag, so the crossing
-- | has to do the narrowing itself.
-- |
-- | Almost everything here is a fold: each function takes the `Foreign` and
-- | returns `Maybe`, so the caller writes the branch order explicitly and there
-- | is no coercion that could succeed on the wrong shape. A value matching no
-- | branch is the caller's error to report, with the field name it has and this
-- | module does not.
-- |
-- | `oneOrMany` is the exception, and answers total rather than `Maybe`,
-- | because its union has no wrong branch: `T | T[]` is upstream's way of
-- | letting a caller skip the brackets, both sides mean a list, and a value
-- | that is not an array is the singleton. There is nothing for a caller to
-- | report, so there is no `Maybe` to fold.
module Boundary.Untagged
  ( asArray
  , asBoolean
  , asFunction
  , asNumber
  , asString
  , oneOrMany
  , typeName
  ) where

import Data.Function.Uncurried (Fn3, runFn3)
import Data.Maybe (Maybe(..), fromMaybe)
import Foreign (Foreign)

foreign import asStringImpl :: forall r. Fn3 r (String -> r) Foreign r
foreign import asNumberImpl :: forall r. Fn3 r (Number -> r) Foreign r
foreign import asBooleanImpl :: forall r. Fn3 r (Boolean -> r) Foreign r
foreign import asArrayImpl :: forall r. Fn3 r (Array Foreign -> r) Foreign r
foreign import asFunctionImpl :: forall r. Fn3 r ((Foreign -> Foreign) -> r) Foreign r

asString :: Foreign -> Maybe String
asString = runFn3 asStringImpl Nothing Just

asNumber :: Foreign -> Maybe Number
asNumber = runFn3 asNumberImpl Nothing Just

asBoolean :: Foreign -> Maybe Boolean
asBoolean = runFn3 asBooleanImpl Nothing Just

asArray :: Foreign -> Maybe (Array Foreign)
asArray = runFn3 asArrayImpl Nothing Just

-- | `T | T[]`, as the array both sides mean. Upstream spells four members of
-- | the surface this way — `addNodes`, `addEdges`, the id argument of
-- | `useUpdateNodeInternals`, and `KeyCode` — so a caller may write
-- | `addNodes(node)` or `addNodes([node])` and mean the same thing. ps-flow's
-- | counterparts all take an array, which is the wider of the two.
oneOrMany :: Foreign -> Array Foreign
oneOrMany raw = fromMaybe [ raw ] (asArray raw)

-- | The other half of React's `SetStateAction<T>`: `T | ((prev: T) => T)`. A
-- | JavaScript unary function *is* a `Foreign -> Foreign`, so nothing is
-- | wrapped here — the branch exists so the caller can tell the two forms
-- | apart before coercing either.
asFunction :: Foreign -> Maybe (Foreign -> Foreign)
asFunction = runFn3 asFunctionImpl Nothing Just

-- | What the value actually is, for the "expected one of" half of an error
-- | message. `"array"` and `"null"` are separated out of `typeof`'s `"object"`
-- | because those are the two a caller is most likely to have got wrong.
foreign import typeName :: Foreign -> String
