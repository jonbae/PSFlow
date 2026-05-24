-- | Runtime guards for `Node` / `Edge` values. Mirrors
-- | `xyflow-main/packages/react/src/utils/general.ts`, which re-exports
-- | `isNodeBase` / `isEdgeBase` from `system/src/utils/graph.ts`.
-- |
-- | The implementations live in [System.Utils.Graph](src/System/Utils/Graph.purs)
-- | so the file layout matches TS; this module renames them to the
-- | shorter React-layer names (`isNode`, `isEdge`).
module React.Util.General
  ( isNode
  , isEdge
  ) where

import System.Utils.Graph (isNodeBase, isEdgeBase)

isNode :: forall a. a -> Boolean
isNode = isNodeBase

isEdge :: forall a. a -> Boolean
isEdge = isEdgeBase
