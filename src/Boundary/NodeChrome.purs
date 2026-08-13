-- | The two components a custom node mounts, crossing: `<Handle />` and
-- | `<NodeToolbar />`.
-- |
-- | `Boundary.Chrome` holds the four a *driver* mounts inside the flow. These
-- | two are the other half of the same idea one level down: they are mounted by
-- | the consumer's own node component, which is why they were the two exports
-- | of stage 1's set that neither driver reached, and why they cross with the
-- | node-toolbar fixture rather than with either driver.
-- |
-- | That fixture is what makes this module worth more than two wrappers.
-- | Upstream's `ToolbarNode.tsx` is the first **user-authored custom node**
-- | any gate has run: it is handed `NodeProps` by ps-flow (crossed already, in
-- | `Boundary.Elements.nodePropsOut`), reads `data.toolbarPosition` off it, and
-- | hands the string straight back to `<NodeToolbar position={…} />`. So the
-- | round trip is the consumer's, and both ends of it are here.
-- |
-- | ## Upstream's defaults are this module's job
-- |
-- | `<Handle />` needs no props at all upstream: `type` defaults to `'source'`
-- | and `position` to `Position.Top`. ps-flow's `HandleProps` makes both
-- | required — a sum type has no absent state — so a JavaScript caller omitting
-- | them would meet a pattern-match failure rather than a source handle on the
-- | top edge. The defaults are applied here, where the record forces the
-- | question to be answered.
-- |
-- | `<NodeToolbar />`'s three defaults (`position`, `offset`, `align`) stay in
-- | the PureScript component, which already models them as `Maybe` and fills
-- | them in. Repeating them here would be a second copy of a default, free to
-- | drift from the one that renders.
-- |
-- | ## What is refused
-- |
-- | `Handle.onConnect` and `Handle.isValidConnection` are **callbacks**, which
-- | are boundary stage 2 wherever they appear, so they are refused with the
-- | message every deferred prop gives.
-- |
-- | Neither record names upstream's `HTMLAttributes<HTMLDivElement>`, which
-- | both components spread onto their div. That is a gap in the internals
-- | rather than something a converter could close, and it is the same gap
-- | `Boundary.Chrome`'s `JsPanelProps` records: an unmodelled DOM attribute is
-- | dropped here as silently as it is on the PureScript surface.
module Boundary.NodeChrome
  ( JsHandleProps
  , JsNodeToolbarProps
  , handle
  , nodeToolbar
  ) where

import Prelude

import Boundary.Elements (asCssObject, asCssStyle)
import Boundary.Enums (alignIn, handleTypeIn, positionIn)
import Boundary.Refusal (Refusal, callbackProp, deferredMessage, refuseFirst)
import Boundary.Undefined (Undefinable, fromUndefinable)
import Boundary.Untagged (asArray, asString, typeName)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), maybe)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Additional.NodeToolbar (nodeToolbar) as PS
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (ReactChildren, memo, reactComponent, reactComponentWithChildren)
import React.Handle (handle) as PS
import React.Types.Component (HandleProps, NodeToolbarProps)
import System.Types.Geometry (Position(..))
import System.Types.Handle (HandleType(..))

-- ────────────────────────────────────────────────────────────────────────
-- Handle
-- ────────────────────────────────────────────────────────────────────────

-- | Upstream's tag is `type`; ps-flow calls it `handleType`, leaving `type`
-- | free for the element's own tag the way `JsNode` and `JsEdge` do.
type JsHandleProps =
  { type :: Undefinable String
  , position :: Undefinable String
  , id :: Undefinable String
  , isConnectable :: Undefinable Boolean
  , isConnectableStart :: Undefinable Boolean
  , isConnectableEnd :: Undefinable Boolean
  , onConnect :: Undefinable Foreign
  , isValidConnection :: Undefinable Foreign
  , className :: Undefinable String
  , style :: Undefinable Foreign
  }

deferredHandleProps :: Array (Refusal JsHandleProps)
deferredHandleProps =
  [ callbackProp "Handle.onConnect" _.onConnect
  , callbackProp "Handle.isValidConnection" _.isValidConnection
  ]

handlePropsIn :: JsHandleProps -> HandleProps
handlePropsIn = convertHandle <<< refuseFirst deferredMessage deferredHandleProps

convertHandle :: JsHandleProps -> HandleProps
convertHandle p =
  { handleType: maybe Source (handleTypeIn "Handle.type") (fromUndefinable p.type)
  , position: maybe PosTop (positionIn "Handle.position") (fromUndefinable p.position)
  , id: fromUndefinable p.id
  , isConnectable: fromUndefinable p.isConnectable
  , isConnectableStart: fromUndefinable p.isConnectableStart
  , isConnectableEnd: fromUndefinable p.isConnectableEnd
  , onConnect: Nothing
  , isValidConnection: Nothing
  , className: fromUndefinable p.className
  , style: map asCssStyle (fromUndefinable p.style)
  }

-- | Memoized, because upstream's is and the component ps-flow wraps is: a
-- | wrapper that dropped it would re-render every handle of every node on each
-- | store notification, which is the divergence `Boundary.Chrome` took on the
-- | four chrome components and is recorded against them in the surface-parity
-- | allowlist. Upstream's inner component is a `forwardRef` and this one is
-- | not; that half is boundary stage 4's.
handle :: ReactComponent JsHandleProps
handle =
  unsafePerformEffect $ memo $ reactComponent "Handle"
    \(props :: JsHandleProps) -> pure (element PS.handle (handlePropsIn props))

-- ────────────────────────────────────────────────────────────────────────
-- NodeToolbar
-- ────────────────────────────────────────────────────────────────────────

-- | `nodeId` is `string | string[]` upstream, narrowed below. Everything else
-- | is a scalar or an enum member.
type JsNodeToolbarProps =
  { nodeId :: Undefinable Foreign
  , isVisible :: Undefinable Boolean
  , position :: Undefinable String
  , offset :: Undefinable Number
  , align :: Undefinable String
  , style :: Undefinable Foreign
  , className :: Undefinable String
  , children :: ReactChildren JSX
  }

convertNodeToolbar :: JsNodeToolbarProps -> NodeToolbarProps
convertNodeToolbar p =
  { nodeId: map nodeIdIn (fromUndefinable p.nodeId)
  , isVisible: fromUndefinable p.isVisible
  , position: map (positionIn "NodeToolbar.position") (fromUndefinable p.position)
  , offset: fromUndefinable p.offset
  , align: map (alignIn "NodeToolbar.align") (fromUndefinable p.align)
  , style: map asCssObject (fromUndefinable p.style)
  , className: fromUndefinable p.className
  , children: p.children
  }

-- | `string | string[]` — one node, or the group of them one toolbar floats
-- | above.
nodeIdIn :: Foreign -> Either String (Array String)
nodeIdIn raw = case asString raw of
  Just s -> Left s
  Nothing -> case asArray raw of
    Just ids -> Right (map readId ids)
    Nothing ->
      unsafeThrow $
        "ps-flow: `NodeToolbar.nodeId` must be a node id or an array of them, got "
          <> typeName raw
          <> "."
  where
  readId entry = case asString entry of
    Just s -> s
    Nothing ->
      unsafeThrow $
        "ps-flow: every entry of `NodeToolbar.nodeId` must be a node id, got "
          <> typeName entry
          <> "."

nodeToolbar :: ReactComponent JsNodeToolbarProps
nodeToolbar =
  unsafePerformEffect $ reactComponentWithChildren "NodeToolbar"
    \(props :: JsNodeToolbarProps) -> pure (element PS.nodeToolbar (convertNodeToolbar props))
