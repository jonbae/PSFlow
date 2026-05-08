module XYFlow.Utils.ShallowNodeData
  ( NodeSummary
  , shallowNodeData
  , shallowNodeDataSingle
  ) where

import Prelude

import Data.Array (length, zip) as Array
import Data.Foldable (all) as Foldable
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))

-- | Subset of `NodeBase` compared by `shallowNodeData`. Mirrors the TS
-- | `Pick<NodeBase, 'id' | 'type' | 'data'>`. The TS `type` field is renamed
-- | to `nodeType` to match the rest of this codebase (avoiding the PS keyword).
type NodeSummary nodeData =
  { id :: String
  , nodeType :: Maybe String
  , data :: nodeData
  }

-- | Compare two arrays of node summaries field-by-field.
-- |
-- | Divergence from the TS original: TS uses `Object.is` to do reference-
-- | identity equality on `data`, an optimization for React's render cycle. PS
-- | has no reference equality, so this implementation requires `Eq nodeData`
-- | and uses structural equality. The semantics are strictly stronger —
-- | structurally equal but referentially distinct values now compare equal,
-- | which only reduces spurious `false` results.
-- |
-- | The TS variant accepts `NodeData | NodeData[] | null`. Here, `Nothing`
-- | replaces `null` and an `Array` is always required. Use
-- | `shallowNodeDataSingle` for single-node comparisons.
shallowNodeData
  :: forall nodeData
   . Eq nodeData
  => Maybe (Array (NodeSummary nodeData))
  -> Maybe (Array (NodeSummary nodeData))
  -> Boolean
shallowNodeData ma mb = case ma, mb of
  Nothing, _ -> false
  _, Nothing -> false
  Just a, Just b ->
    Array.length a == Array.length b
      && Foldable.all sameSummary (Array.zip a b)
  where
  sameSummary (Tuple x y) = shallowNodeDataSingle x y

shallowNodeDataSingle
  :: forall nodeData
   . Eq nodeData
  => NodeSummary nodeData
  -> NodeSummary nodeData
  -> Boolean
shallowNodeDataSingle x y =
  x.id == y.id
    && x.nodeType == y.nodeType
    && x.data == y.data
