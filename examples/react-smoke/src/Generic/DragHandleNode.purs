-- | Port of xyflow's generic-test `DragHandleNode`
-- | (`xyflow/examples/react/src/generic-tests/nodes/components/DragHandleNode.tsx`):
-- | a red `container` box wrapping a green `drag-handle custom-drag-handle` square.
-- | The `nodes/general` fixture's `drag-handle` node registers this under
-- | `type: "DragHandleNode"` with `dragHandle: ".custom-drag-handle"`, so only the
-- | inner square initiates a drag. Component pattern: `React.Node.Default`.
module Generic.DragHandleNode
  ( dragHandleNode
  ) where

import Prelude

import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Basic (JSX, ReactComponent)
import React.Basic.Hooks (reactComponent)
import React.FFI.DOM (div_)
import React.Types.Nodes (NodeProps)
import Unsafe.Coerce (unsafeCoerce)

-- | `style` on the DOM-prop records is `Foreign`; build an inline-style object
-- | by coercing a plain record (mirrors `toForeignStyle` in NodeWrapper et al.).
toForeignStyle :: forall r. Record r -> Foreign
toForeignStyle = unsafeCoerce

dragHandleNode :: ReactComponent (NodeProps Foreign)
dragHandleNode = unsafePerformEffect $ reactComponent "DragHandleNode" \(_ :: NodeProps Foreign) ->
  pure $
    div_
      { className: "container"
      , style: toForeignStyle
          { width: "100px"
          , height: "50px"
          , background: "red"
          , display: "flex"
          , alignItems: "center"
          , justifyContent: "center"
          }
      }
      [ innerHandle ]
  where
  innerHandle :: JSX
  innerHandle =
    div_
      { className: "drag-handle custom-drag-handle"
      , style: toForeignStyle
          { display: "inline-block"
          , width: "25px"
          , height: "25px"
          , backgroundColor: "green"
          }
      }
      []
