-- | `<NodeResizer />` — renders 4 line + 4 corner `NodeResizeControl`
-- | instances. Mirrors `xyflow-main/.../NodeResizer/NodeResizer.tsx`.
module React.Additional.NodeResizer
  ( nodeResizer
  , module React.Types.Component
  ) where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactComponent, element, fragment)
import React.Basic.Hooks (reactChildrenFromArray, reactComponent)
import React.Additional.NodeResizer.Control (nodeResizeControl)
import React.Types.Component (NodeResizerProps)
import System.XYResizer
  ( ControlPosition(..)
  , ResizeControlVariant(..)
  , xyResizerHandlePositions
  , xyResizerLinePositions
  )

nodeResizer :: ReactComponent NodeResizerProps
nodeResizer =
  unsafePerformEffect $ reactComponent "NodeResizer"
    \(props :: NodeResizerProps) ->
      let
        visible = fromMaybe true props.isVisible
      in
        if not visible then pure mempty
        else
          let
            lineControls = map (mkControl LineVariant props <<< ControlLine) xyResizerLinePositions
            handleControls = map (mkControl HandleVariant props) xyResizerHandlePositions
          in
            pure $ fragment (lineControls <> handleControls)

mkControl
  :: ResizeControlVariant
  -> NodeResizerProps
  -> ControlPosition
  -> JSX
mkControl variant props pos = element nodeResizeControl
  { nodeId: props.nodeId
  , position: Just pos
  , variant: Just variant
  , color: props.color
  , minWidth: props.minWidth
  , minHeight: props.minHeight
  , maxWidth: props.maxWidth
  , maxHeight: props.maxHeight
  , keepAspectRatio: props.keepAspectRatio
  , autoScale: props.autoScale
  , resizeDirection: Nothing
  , shouldResize: props.shouldResize
  , onResizeStart: props.onResizeStart
  , onResize: props.onResize
  , onResizeEnd: props.onResizeEnd
  , className: case variant of
      LineVariant -> props.lineClassName
      HandleVariant -> props.handleClassName
  , style: case variant of
      LineVariant -> props.lineStyle
      HandleVariant -> props.handleStyle
  , children: reactChildrenFromArray []
  }
