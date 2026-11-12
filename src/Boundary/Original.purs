-- | The consumer's own JavaScript value behind a converted one.
-- |
-- | Upstream's store keeps what the consumer handed it: the `onConnect` they
-- | wrote, the `defaultEdgeOptions` object they passed. ps-flow's store keeps
-- | the PureScript conversions of those, so a raw store read from JavaScript
-- | has to find its way back to the originals. Nodes and edges carry their
-- | own association in `System.Types.Node` and `System.Types.Edge`; this one
-- | is for everything else a converter builds.
module Boundary.Original
  ( remembering
  , originalOf
  ) where

import Prelude

import Data.Function.Uncurried (Fn2, runFn2)
import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toMaybe)
import Foreign (Foreign, unsafeToForeign)

foreign import rememberOriginal :: forall a. Fn2 Foreign a a
foreign import originalOf_ :: forall a. a -> Nullable Foreign

-- | Convert, and keep the original beside the result.
remembering :: forall js ps. (js -> ps) -> js -> ps
remembering convert js = runFn2 rememberOriginal (unsafeToForeign js) (convert js)

originalOf :: forall a. a -> Maybe Foreign
originalOf = toMaybe <<< originalOf_
