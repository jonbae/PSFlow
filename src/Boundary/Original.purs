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
  , stably
  ) where

import Prelude

import Data.Function.Uncurried (Fn2, Fn3, runFn2, runFn3)
import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toMaybe)
import Foreign (Foreign, unsafeToForeign)

foreign import rememberOriginal :: forall a. Fn2 Foreign a a
foreign import originalOf_ :: forall a. a -> Nullable Foreign
foreign import stablyImpl :: forall js ps. Fn3 String (js -> ps) js ps

-- | Convert, and keep the original beside the result.
remembering :: forall js ps. (js -> ps) -> js -> ps
remembering convert js = runFn2 rememberOriginal (unsafeToForeign js) (convert js)

originalOf :: forall a. a -> Maybe Foreign
originalOf = toMaybe <<< originalOf_

-- | `convert`, made once per consumer value for the prop `key`. Upstream
-- | compares a prop the consumer passes again with `!==` and finds nothing
-- | changed; a conversion made on every render would be a new value each time,
-- | which `<StoreUpdater />` re-dispatches and a `memo` boundary re-renders on.
-- | The conversion must depend on nothing but the value it is handed.
stably :: forall js ps. String -> (js -> ps) -> js -> ps
stably key convert js = runFn3 stablyImpl key convert js
