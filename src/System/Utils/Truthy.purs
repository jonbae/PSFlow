-- | JavaScript truthiness, for upstream's `if (callback)` checks.
-- |
-- | Upstream's store holds whatever a consumer writes, and most of its calls
-- | are `callback?.(…)`: any value but `null` or `undefined` is called, so
-- | `0` or `false` throws there. A few places ask `if (callback)` instead and
-- | skip a falsy value: `getElementsToRemove`'s `onBeforeDelete`, the edge
-- | queue's `onEdgesChange`, and the drag's gates. `Boundary.Store` converts a
-- | falsy value to a function that throws when called, as calling it would,
-- | and marks it here, so those places can tell.
module System.Utils.Truthy
  ( markFalsy
  , isTruthy
  , isSet
  ) where

import Data.Maybe (Maybe, maybe)

-- | `f`, recorded as the conversion of a falsy JavaScript value.
foreign import markFalsy :: forall a. a -> a

-- | `!!value`, where a function `markFalsy` recorded answers `false`.
foreign import isTruthy :: forall a. a -> Boolean

-- | `if (callback)`: present and truthy.
isSet :: forall a. Maybe a -> Boolean
isSet = maybe false isTruthy
