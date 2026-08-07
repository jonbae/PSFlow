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
-- | Everything here is a fold: each function takes the `Foreign` and returns
-- | `Maybe`, so the caller writes the branch order explicitly and there is no
-- | coercion that could succeed on the wrong shape. A value matching no branch
-- | is the caller's error to report, with the field name it has and this
-- | module does not.
module Boundary.Untagged
  ( asArray
  , asBoolean
  , asNumber
  , asString
  , typeName
  ) where

import Data.Function.Uncurried (Fn3, runFn3)
import Data.Maybe (Maybe(..))
import Foreign (Foreign)

foreign import asStringImpl :: forall r. Fn3 r (String -> r) Foreign r
foreign import asNumberImpl :: forall r. Fn3 r (Number -> r) Foreign r
foreign import asBooleanImpl :: forall r. Fn3 r (Boolean -> r) Foreign r
foreign import asArrayImpl :: forall r. Fn3 r (Array Foreign -> r) Foreign r

asString :: Foreign -> Maybe String
asString = runFn3 asStringImpl Nothing Just

asNumber :: Foreign -> Maybe Number
asNumber = runFn3 asNumberImpl Nothing Just

asBoolean :: Foreign -> Maybe Boolean
asBoolean = runFn3 asBooleanImpl Nothing Just

asArray :: Foreign -> Maybe (Array Foreign)
asArray = runFn3 asArrayImpl Nothing Just

-- | What the value actually is, for the "expected one of" half of an error
-- | message. `"array"` and `"null"` are separated out of `typeof`'s `"object"`
-- | because those are the two a caller is most likely to have got wrong.
foreign import typeName :: Foreign -> String
