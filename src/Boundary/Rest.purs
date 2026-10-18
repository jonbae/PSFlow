-- | A JavaScript props object's `...rest`: every prop its JS-shaped record
-- | doesn't name.
-- |
-- | Upstream components spread the props they don't destructure onto their
-- | root element, and their props types extend an `HTMLAttributes` or
-- | `SVGAttributes` too wide to name. A JS-shaped record here names the
-- | members ps-flow converts, so the rest is read off the props object at
-- | runtime, by the record's own labels: a field added to the record leaves
-- | the rest without anyone keeping a second list.
module Boundary.Rest
  ( class RowLabels
  , rowLabels
  , restOf
  ) where

import Data.Array (foldr, (:))
import Data.Maybe (Maybe(..))
import Data.Symbol (class IsSymbol, reflectSymbol)
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object (delete, isEmpty) as Object
import Prim.RowList (class RowToList, Cons, Nil, RowList)
import Type.Proxy (Proxy(..))
import Unsafe.Coerce (unsafeCoerce)

-- | The labels of a row, in `RowToList` order.
class RowLabels :: RowList Type -> Constraint
class RowLabels rl where
  rowLabels :: Proxy rl -> Array String

instance RowLabels Nil where
  rowLabels _ = []

instance (IsSymbol label, RowLabels tail) => RowLabels (Cons label a tail) where
  rowLabels _ = reflectSymbol (Proxy :: Proxy label) : rowLabels (Proxy :: Proxy tail)

-- | The props `r` doesn't name, or `Nothing` if there are none. A props
-- | object is a plain JavaScript object, so it is read as one.
restOf :: forall r rl. RowToList r rl => RowLabels rl => Record r -> Maybe (Object Foreign)
restOf props =
  let
    rest = foldr Object.delete (unsafeCoerce props :: Object Foreign) (rowLabels (Proxy :: Proxy rl))
  in
    if Object.isEmpty rest then Nothing else Just rest
