-- | `<NodeResizer />` and `<NodeResizeControl />`, crossing.
-- |
-- | These are the third pair a **consumer's own node component** mounts, after
-- | the two in `Boundary.NodeChrome`, and they come forward out of boundary
-- | stage 4 for one reason: their three lifecycle handlers are **callback
-- | props**, and stage 2 is where those cross wherever they appear. A callback
-- | cannot cross without the record it hangs off — a consumer who cannot mount
-- | `<NodeResizer />` cannot pass it an `onResize` — so the two components come
-- | with their handlers rather than the handlers waiting two stages for them.
-- |
-- | ## The lifecycle this crossing exposes
-- |
-- | `onResizeStart`, `onResize` and `onResizeEnd` are one of the two
-- | divergences that were known before any of this apparatus existed:
-- | `System.XYResizer`'s drag lifecycle is a typed scaffold, so `onResize`
-- | emits literal zeros and `onResizeEnd` fires whether or not the node was
-- | resized (`tickets/073-*`). Crossing the handlers does not fix that and is
-- | not meant to — what it does is make the divergence **reachable from
-- | JavaScript**, which is what a gate needs before it can report it. A handler
-- | ps-flow never calls and a handler it calls with zeros are the same green
-- | run while the prop throws at mount.
-- |
-- | ## Wrapper kinds are upstream's here
-- |
-- | `<NodeResizer />` is a plain function upstream and `<NodeResizeControl />`
-- | is memoized, and both already agreed with upstream while they were
-- | passthrough — so neither has a surface-parity allowlist entry to hide
-- | behind, and the wrappers below keep the shapes they had.
module Boundary.Resizer
  ( JsNodeResizeControlProps
  , JsNodeResizerProps
  , nodeResizeControl
  , nodeResizer
  ) where

import Prelude

import Boundary.Callbacks
  ( JsOnResize
  , JsOnResizeEnd
  , JsOnResizeStart
  , JsShouldResize
  , onResizeEndIn
  , onResizeIn
  , onResizeStartIn
  , shouldResizeIn
  )
import Boundary.Elements (asCssObject)
import Boundary.Enums (controlPositionIn, resizeControlVariantIn, resizeDirectionIn)
import Boundary.Undefined (Undefinable, fromUndefinable)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Additional.NodeResizer (nodeResizer) as PS
import React.Additional.NodeResizer.Control (nodeResizeControl) as PS
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (ReactChildren, memo, reactComponent, reactComponentWithChildren)
import React.Types.Component (NodeResizeControlProps, NodeResizerProps)

-- ────────────────────────────────────────────────────────────────────────
-- NodeResizer
-- ────────────────────────────────────────────────────────────────────────

-- | Upstream's `NodeResizerProps`, field for field. Every member is optional
-- | there and every one has a default in the PureScript component, so this
-- | record adds no defaults of its own — unlike `<Handle />`, whose two sum
-- | types have no absent state.
type JsNodeResizerProps =
  { nodeId :: Undefinable String
  , isVisible :: Undefinable Boolean
  , color :: Undefinable String
  , handleClassName :: Undefinable String
  , handleStyle :: Undefinable Foreign
  , lineClassName :: Undefinable String
  , lineStyle :: Undefinable Foreign
  , minWidth :: Undefinable Number
  , minHeight :: Undefinable Number
  , maxWidth :: Undefinable Number
  , maxHeight :: Undefinable Number
  , keepAspectRatio :: Undefinable Boolean
  , autoScale :: Undefinable Boolean
  , shouldResize :: Undefinable JsShouldResize
  , onResizeStart :: Undefinable JsOnResizeStart
  , onResize :: Undefinable JsOnResize
  , onResizeEnd :: Undefinable JsOnResizeEnd
  }

convertNodeResizer :: JsNodeResizerProps -> NodeResizerProps
convertNodeResizer p =
  { nodeId: fromUndefinable p.nodeId
  , isVisible: fromUndefinable p.isVisible
  , color: fromUndefinable p.color
  , handleClassName: fromUndefinable p.handleClassName
  , handleStyle: map asCssObject (fromUndefinable p.handleStyle)
  , lineClassName: fromUndefinable p.lineClassName
  , lineStyle: map asCssObject (fromUndefinable p.lineStyle)
  , minWidth: fromUndefinable p.minWidth
  , minHeight: fromUndefinable p.minHeight
  , maxWidth: fromUndefinable p.maxWidth
  , maxHeight: fromUndefinable p.maxHeight
  , keepAspectRatio: fromUndefinable p.keepAspectRatio
  , autoScale: fromUndefinable p.autoScale
  , shouldResize: map shouldResizeIn (fromUndefinable p.shouldResize)
  , onResizeStart: map onResizeStartIn (fromUndefinable p.onResizeStart)
  , onResize: map onResizeIn (fromUndefinable p.onResize)
  , onResizeEnd: map onResizeEndIn (fromUndefinable p.onResizeEnd)
  }

nodeResizer :: ReactComponent JsNodeResizerProps
nodeResizer =
  unsafePerformEffect $ reactComponent "NodeResizer"
    \(props :: JsNodeResizerProps) -> pure (element PS.nodeResizer (convertNodeResizer props))

-- ────────────────────────────────────────────────────────────────────────
-- NodeResizeControl
-- ────────────────────────────────────────────────────────────────────────

-- | Upstream's `ResizeControlProps` — `NodeResizerProps` minus the handle and
-- | line styling, plus `position`, `variant`, `resizeDirection` and the three
-- | members a component that takes children has.
type JsNodeResizeControlProps =
  { nodeId :: Undefinable String
  , position :: Undefinable String
  , variant :: Undefinable String
  , color :: Undefinable String
  , minWidth :: Undefinable Number
  , minHeight :: Undefinable Number
  , maxWidth :: Undefinable Number
  , maxHeight :: Undefinable Number
  , keepAspectRatio :: Undefinable Boolean
  , autoScale :: Undefinable Boolean
  , resizeDirection :: Undefinable String
  , shouldResize :: Undefinable JsShouldResize
  , onResizeStart :: Undefinable JsOnResizeStart
  , onResize :: Undefinable JsOnResize
  , onResizeEnd :: Undefinable JsOnResizeEnd
  , className :: Undefinable String
  , style :: Undefinable Foreign
  , children :: ReactChildren JSX
  }

convertNodeResizeControl :: JsNodeResizeControlProps -> NodeResizeControlProps
convertNodeResizeControl p =
  { nodeId: fromUndefinable p.nodeId
  , position:
      map (controlPositionIn "NodeResizeControl.position") (fromUndefinable p.position)
  , variant:
      map (resizeControlVariantIn "NodeResizeControl.variant") (fromUndefinable p.variant)
  , color: fromUndefinable p.color
  , minWidth: fromUndefinable p.minWidth
  , minHeight: fromUndefinable p.minHeight
  , maxWidth: fromUndefinable p.maxWidth
  , maxHeight: fromUndefinable p.maxHeight
  , keepAspectRatio: fromUndefinable p.keepAspectRatio
  , autoScale: fromUndefinable p.autoScale
  , resizeDirection:
      map (resizeDirectionIn "NodeResizeControl.resizeDirection")
        (fromUndefinable p.resizeDirection)
  , shouldResize: map shouldResizeIn (fromUndefinable p.shouldResize)
  , onResizeStart: map onResizeStartIn (fromUndefinable p.onResizeStart)
  , onResize: map onResizeIn (fromUndefinable p.onResize)
  , onResizeEnd: map onResizeEndIn (fromUndefinable p.onResizeEnd)
  , className: fromUndefinable p.className
  , style: map asCssObject (fromUndefinable p.style)
  , children: p.children
  }

-- | Memoized, because upstream's is and the PureScript component this wraps is.
-- | `<NodeResizer />` above is neither, on both sides.
nodeResizeControl :: ReactComponent JsNodeResizeControlProps
nodeResizeControl =
  unsafePerformEffect $ memo $ reactComponentWithChildren "NodeResizeControl"
    \(props :: JsNodeResizeControlProps) ->
      pure (element PS.nodeResizeControl (convertNodeResizeControl props))
