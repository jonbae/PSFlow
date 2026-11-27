-- | JavaScript's own numeric operations, for upstream expressions that use
-- | them. `Ord Number` does not propagate `NaN` or tell the two zeros apart,
-- | and upstream's store holds whatever a consumer writes, so a member such as
-- | `minZoom` can reach these as `undefined`, `null` or a string. `Math.min`
-- | and `Math.max` coerce those as upstream's calls do.
module System.Utils.Number (min, max, orDefault, toString) where

-- | `Math.min(a, b)`.
foreign import min :: Number -> Number -> Number

-- | `Math.max(a, b)`.
foreign import max :: Number -> Number -> Number

-- | A default parameter's value: `orDefault d v` is `d` when `v` is
-- | `undefined`, as `(v = d) => …` reads it, and `v` otherwise, `null`
-- | included.
foreign import orDefault :: Number -> Number -> Number

-- | `${n}`, as upstream's template literals and string concatenations write
-- | a number into a style, a path or a label. For a number it is
-- | `Data.Number.Format.toString`'s text; a value a consumer wrote that is
-- | not a number, such as `undefined`, is written as JavaScript writes it.
foreign import toString :: Number -> String
