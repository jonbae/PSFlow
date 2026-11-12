-- | A consumer's JavaScript value that ps-flow carries and never reads.
-- |
-- | Upstream's `domAttributes` is the one such field on a node and an edge:
-- | "General escape hatch for adding custom attributes to the node's DOM
-- | element", spread onto the wrapper element after every attribute the
-- | wrapper sets itself. Nothing in the library inspects it, so nothing here
-- | gives it a PureScript shape. Building one would only add a place for it to
-- | drift from React's own attribute names.
-- |
-- | Equality is reference equality. That is what keeps `NodeBase` and
-- | `EdgeBase` derivable `Eq` records, and it is also upstream's comparison:
-- | the store's slices go through zustand's `shallow`, which is `Object.is` on
-- | each member, so a new bag with the same attributes is a change there too.
module System.Types.Opaque
  ( Opaque
  , opaque
  , unOpaque
  ) where

import Prelude

import Foreign (Foreign)
import Unsafe.Reference (unsafeRefEq)

newtype Opaque = Opaque Foreign

instance eqOpaque :: Eq Opaque where
  eq (Opaque a) (Opaque b) = unsafeRefEq a b

instance showOpaque :: Show Opaque where
  show _ = "(Opaque)"

opaque :: Foreign -> Opaque
opaque = Opaque

unOpaque :: Opaque -> Foreign
unOpaque (Opaque value) = value
