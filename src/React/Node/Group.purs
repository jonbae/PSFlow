-- | `<GroupNode />` — empty built-in node used for grouping/parenting
-- | other nodes. Renders nothing. Mirrors
-- | `xyflow-main/packages/react/src/components/Nodes/GroupNode.tsx`.
module React.Node.Group
  ( groupNode
  ) where

import Prelude

import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Basic (ReactComponent)
import React.Basic.Hooks (reactComponent)
import React.Types.Nodes (NodeProps)

groupNode :: ReactComponent (NodeProps Foreign)
groupNode = unsafePerformEffect $ reactComponent "GroupNode" \(_ :: NodeProps Foreign) ->
  pure mempty
