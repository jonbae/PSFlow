-- | Binary Math.min/Math.max semantics for upstream numeric expressions.
-- | Ord Number does not propagate NaN or distinguish the two zero signs.
module System.Utils.Number (min, max) where

import Prelude hiding (min, max)

import Data.Number (isNaN)

min :: Number -> Number -> Number
min a b
  | isNaN a = a
  | isNaN b = b
  | a == 0.0 && b == 0.0 = if 1.0 / a < 0.0 then a else b
  | a < b = a
  | otherwise = b

max :: Number -> Number -> Number
max a b
  | isNaN a = a
  | isNaN b = b
  | a == 0.0 && b == 0.0 = if 1.0 / a > 0.0 then a else b
  | a > b = a
  | otherwise = b
