module System.Utils.ShallowNodeData
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
-- | TS compares `data` with `Object.is`; this compares it with `Eq nodeData`.
-- | `Boundary.Hooks` instantiates it with a newtype whose `Eq` is `Object.is`,
-- | so `useNodesData` from JavaScript compares as upstream's does. A
-- | PureScript caller's own `Eq` decides what counts as the same data.
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
