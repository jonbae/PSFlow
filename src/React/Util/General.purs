-- | Runtime guards for `Node` / `Edge` values. Mirrors
-- | `xyflow-main/packages/react/src/utils/general.ts` (`isNode`, `isEdge`)
-- | which delegate to `isNodeBase` / `isEdgeBase` in
-- | `xyflow-main/packages/system/src/utils/graph.ts`.
-- |
-- | **Divergence from ticket text.** Ticket 042 says these "already
-- | exist in system layer. Re-export." A grep showed no `isNodeBase`
-- | / `isEdgeBase` exports in `src/System/` — only the implicit
-- | shape check at the `nodeToRect` site. Rather than block on the
-- | system-layer addition, we add the guards here at the React layer.
-- | A follow-up can move the implementation down.
module React.Util.General
  ( isNode
  , isEdge
  ) where

import Prelude

import Foreign (Foreign)
import Unsafe.Coerce (unsafeCoerce)

foreign import isNodeImpl :: Foreign -> Boolean
foreign import isEdgeImpl :: Foreign -> Boolean

-- | True iff the value has `id` + `position` and lacks `source`/`target`.
isNode :: forall a. a -> Boolean
isNode = isNodeImpl <<< unsafeToForeign
  where
  unsafeToForeign :: a -> Foreign
  unsafeToForeign = unsafeCoerce

-- | True iff the value has `id`, `source`, and `target`.
isEdge :: forall a. a -> Boolean
isEdge = isEdgeImpl <<< unsafeToForeign
  where
  unsafeToForeign :: a -> Foreign
  unsafeToForeign = unsafeCoerce
