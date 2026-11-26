-- | JavaScript's own numeric operations, for upstream expressions that use
-- | them. `Ord Number` does not propagate `NaN` or tell the two zeros apart,
-- | and upstream's store holds whatever a consumer writes, so a member such as
-- | `minZoom` can reach these as `undefined`, `null` or a string. `Math.min`
-- | and `Math.max` coerce those as upstream's calls do.
module System.Utils.Number (min, max, orDefault) where

-- | `Math.min(a, b)`.
foreign import min :: Number -> Number -> Number

-- | `Math.max(a, b)`.
foreign import max :: Number -> Number -> Number

-- | A default parameter's value: `orDefault d v` is `d` when `v` is
-- | `undefined`, as `(v = d) => …` reads it, and `v` otherwise, `null`
-- | included.
foreign import orDefault :: Number -> Number -> Number
