-- | The store's lookups, read with the operation upstream's line uses.
-- |
-- | ps-flow's `nodeLookup`, `parentLookup`, `edgeLookup` and
-- | `connectionLookup` are `Data.Map`s, and upstream's are JavaScript `Map`s.
-- | A consumer who writes one with another value, such as
-- | `setState({ nodeLookup: [] })`, leaves upstream calling `Map` methods on
-- | that value: `.get` on an array throws a `TypeError`, `for…of` walks it,
-- | `.size` is `undefined`. The store holds such a value as it was written
-- | (`System.Utils.AsWritten`), and each function here calls the method its
-- | name says on it. On a `Data.Map` each is the `Data.Map` operation that
-- | answers the same.
module System.Utils.Lookup
  ( get
  , has
  , hasEntries
  , isEmptyBySize
  , values
  , entryValues
  , entryKeys
  , fillOrderKeys
  , fillOrderEntries
  , forEachValues
  , copied
  , cleared
  , set
  , after
  , onThrow
  , foldlKeepingProgress
  ) where

import Prelude

import Data.Array (fromFoldable, mapMaybe, nub) as Array
import Data.Foldable (foldr)
import Data.Function.Uncurried (Fn2, Fn3, Fn4, runFn2, runFn3, runFn4)
import Data.Map (Map)
import Data.Map (delete, empty, insert, isEmpty, keys, lookup, member, toUnfoldable, values) as Map
import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toMaybe)
import Data.Tuple (Tuple(..), fst)
import System.Utils.AsWritten (hold, isHeld)

foreign import getImpl :: forall k v. Fn2 k (Map k v) (Nullable v)
foreign import hasImpl :: forall k v. Fn2 k (Map k v) Boolean
foreign import sizeAboveZero :: forall k v. Map k v -> Boolean
foreign import sizeIsZeroImpl :: forall k v. Map k v -> Boolean
foreign import valuesImpl :: forall k v. Map k v -> Array v
foreign import entryValuesImpl :: forall k v. Map k v -> Array v
foreign import forEachValuesImpl :: forall k v. Map k v -> Array v
foreign import entryKeysImpl :: forall k v. Map k v -> Array k
foreign import entriesImpl :: forall k v. Map k v -> Array { key :: k, value :: v }
foreign import copiedImpl :: forall k v. Map k v -> Map k v
foreign import clearImpl :: forall k v. Map k v -> Map k v
foreign import setImpl :: forall k v. Fn3 k v (Map k v) (Map k v)
foreign import afterImpl :: forall a b. Fn2 a b b
foreign import onThrowImpl :: forall a. Fn2 (Unit -> Unit) (Unit -> a) a
foreign import foldlKeepingProgressImpl :: forall a b. Fn4 (b -> Unit) (b -> a -> b) b (Array a) b

-- | `lookup.get(key)`.
get :: forall k v. Ord k => k -> Map k v -> Maybe v
get key lookup
  | isHeld lookup = toMaybe (runFn2 getImpl key lookup)
  | otherwise = Map.lookup key lookup

-- | `lookup.has(key)`.
has :: forall k v. Ord k => k -> Map k v -> Boolean
has key lookup
  | isHeld lookup = runFn2 hasImpl key lookup
  | otherwise = Map.member key lookup

-- | `lookup.size > 0`.
hasEntries :: forall k v. Map k v -> Boolean
hasEntries lookup
  | isHeld lookup = sizeAboveZero lookup
  | otherwise = not (Map.isEmpty lookup)

-- | `lookup.size === 0`.
isEmptyBySize :: forall k v. Map k v -> Boolean
isEmptyBySize lookup
  | isHeld lookup = sizeIsZeroImpl lookup
  | otherwise = Map.isEmpty lookup

-- | `[...lookup.values()]`, in key order for a `Data.Map`.
values :: forall k v. Map k v -> Array v
values lookup
  | isHeld lookup = valuesImpl lookup
  | otherwise = Array.fromFoldable (Map.values lookup)

-- | `for (const [, value] of lookup)`.
entryValues :: forall k v. Map k v -> Array v
entryValues lookup
  | isHeld lookup = entryValuesImpl lookup
  | otherwise = Array.fromFoldable (Map.values lookup)

-- | `for (const [key] of lookup)`, in key order for a `Data.Map`.
entryKeys :: forall k v. Map k v -> Array k
entryKeys lookup
  | isHeld lookup = entryKeysImpl lookup
  | otherwise = Array.fromFoldable (Map.keys lookup)

-- | TS `for (const [key] of lookup)` over a lookup filled from `items`: the
-- | keys in the order it was filled, `items`' ids each once, as a JavaScript
-- | `Map` keeps the first position of a key it is given twice. A lookup a
-- | consumer wrote with another value is walked as upstream walks it, and
-- | while `items` holds a value a consumer wrote, which upstream's lookup does
-- | not follow, the walk is in key order.
fillOrderKeys :: forall k v r. Ord k => Array { id :: k | r } -> Map k v -> Array k
fillOrderKeys items lookup
  | isHeld lookup || isHeld items = entryKeys lookup
  | otherwise = Array.nub (map _.id items)

-- | TS `for (const [key, value] of lookup)` over a lookup filled from
-- | `items`: its entries in the order it was filled, which is `fillOrderKeys`'
-- | order. An entry `items` does not name, which only a direct `setState` of
-- | `items` leaves, comes after them, in key order. A lookup a consumer wrote
-- | with another value is walked as upstream walks it.
fillOrderEntries :: forall k v r. Ord k => Array { id :: k | r } -> Map k v -> Array (Tuple k v)
fillOrderEntries items lookup
  | isHeld lookup = map (\entry -> Tuple entry.key entry.value) (entriesImpl lookup)
  | otherwise =
      let
        named = Array.mapMaybe (\key -> Tuple key <$> Map.lookup key lookup) (fillOrderKeys items lookup)
        unnamed = Map.toUnfoldable (foldr (Map.delete <<< fst) lookup named)
      in
        named <> unnamed

-- | `lookup.forEach((value) => …)`.
forEachValues :: forall k v. Map k v -> Array v
forEachValues lookup
  | isHeld lookup = forEachValuesImpl lookup
  | otherwise = Array.fromFoldable (Map.values lookup)

-- | `new Map(lookup)`. A `Data.Map` is immutable, so it is its own copy. A
-- | lookup held as written is copied as the constructor copies it, and the
-- | copy is held too, so it reads with `.get`.
copied :: forall k v. Map k v -> Map k v
copied lookup
  | isHeld lookup = hold (copiedImpl lookup)
  | otherwise = lookup

-- | `lookup.clear()`, in place: an empty `Data.Map`, or the lookup held as
-- | written, cleared.
cleared :: forall k v. Map k v -> Map k v
cleared lookup
  | isHeld lookup = clearImpl lookup
  | otherwise = Map.empty

-- | `lookup.set(key, value)`: the `Data.Map` with the entry inserted, or the
-- | lookup held as written, with the entry set in place.
set :: forall k v. Ord k => k -> v -> Map k v -> Map k v
set key value lookup
  | isHeld lookup = runFn3 setImpl key value lookup
  | otherwise = Map.insert key value lookup

-- | `second`, once `first` is evaluated: the order of upstream's statements,
-- | where each is a call on a lookup that can throw.
after :: forall a b. a -> b -> b
after = runFn2 afterImpl

-- | `run unit`, and when it throws, `handle unit` before the error goes on.
onThrow :: forall a. (Unit -> Unit) -> (Unit -> a) -> a
onThrow = runFn2 onThrowImpl

-- | `foldl step initial items`, walking `items` with `for…of`. When a step
-- | throws, `keep` is handed the result so far before the error goes on:
-- | upstream fills the store's lookups in place, so a throw partway leaves
-- | them holding what came before it.
foldlKeepingProgress :: forall a b. (b -> Unit) -> (b -> a -> b) -> b -> Array a -> b
foldlKeepingProgress = runFn4 foldlKeepingProgressImpl
