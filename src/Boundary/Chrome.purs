-- | The chrome components, crossing: `<Panel />`, `<Background />`,
-- | `<Controls />` and `<MiniMap />` — the four a driver mounts inside the
-- | flow — and, since boundary stage 4, `<ControlButton />` and
-- | `<MiniMapNode />`, the two a consumer reaches inside two of those.
-- |
-- | All four have been in stage 1's set since it was derived — upstream's
-- | `generic-tests/Flow.tsx` mounts each of them from a fixture's
-- | `panelProps` / `backgroundProps` / `controlsProps` / `minimapProps`. None
-- | of the four fixtures ported so far sets one, so nothing had reached them
-- | until the ColorMode driver, which mounts all four in the one file.
-- |
-- | ## Why a component needs a converter at all
-- |
-- | `<MiniMap />` with no props is the sharpest case. React calls the
-- | component with `{}`; a PureScript record field typed `Maybe a` arrives as
-- | `undefined`, and the first `case` over it falls off the end of a pattern
-- | match. Not a wrong colour — a crash, on the plainest possible use. So
-- | "takes no props" is exactly the case a crossing is needed for, and it is
-- | why these four cross whole rather than field by field.
-- |
-- | ## The two sub-components, and the prop that waited for one
-- |
-- | Boundary stage 4 adds `<ControlButton />` and `<MiniMapNode />` — the two
-- | pieces of chrome a consumer reaches *inside* one of the four above, the way
-- | `Boundary.NodeChrome`'s pair is reached inside a custom node. Neither had
-- | crossed, so neither could be mounted from JavaScript, and one of them was
-- | blocking a prop: `MiniMap.nodeComponent` is a consumer's own component
-- | receiving `MiniMapNodeProps`, so crossing it needed an outbound converter
-- | for that record. It is the third and last of the three props whose values
-- | are consumer components (`Boundary.Wrapper`), and it crosses here now.
-- |
-- | ## What is refused, and what that costs
-- |
-- | Nothing on these six records is deferred any more. `Controls`' four
-- | handlers and `MiniMap`'s two were refused until boundary stage 2, which
-- | crossed the callbacks wherever they appear; their converters are in
-- | `Boundary.Callbacks` with the flow's. `MiniMap.nodeComponent` was the last
-- | one standing and stage 4 is what lands it.
-- |
-- | Three more are refused **by value rather than by name**:
-- | `nodeColor`, `nodeStrokeColor` and `nodeClassName` are
-- | `string | ((node) => string)` upstream, and ps-flow models only the
-- | function half. The string half is a real gap in the internals, not
-- | something this module can convert around, so a consumer who passes one
-- | gets told that rather than a minimap of undefined-coloured nodes.
module Boundary.Chrome
  ( JsBackgroundProps
  , JsControlButtonProps
  , JsControlsProps
  , JsMiniMapNodeProps
  , JsMiniMapProps
  , JsPanelProps
  , background
  , controlButton
  , controls
  , miniMap
  , miniMapNode
  , miniMapNodePropsOut
  , panel
  ) where

import Prelude

import Boundary.Callbacks
  ( JsCommandHandler
  , JsInteractiveChangeHandler
  , JsMiniMapClickHandler
  , JsMiniMapNodeClickHandler
  , JsNodeMouseHandler
  , commandHandlerIn
  , interactiveChangeHandlerIn
  , miniMapClickHandlerIn
  , miniMapNodeClickHandlerIn
  , miniMapNodeClickHandlerOut
  , nodeMouseHandlerIn
  )
import Boundary.Elements (asCssObject, fromCssObject, nodeOut)
import Boundary.Enums (backgroundVariantIn, orientationIn, panelPositionIn)
import Boundary.FitView (JsFitViewOptions, fitViewOptionsIn)
import Boundary.Undefined
  ( Undefinable
  , fromUndefinable
  , orNullable
  , requiredProp
  , toUndefinable
  )
import Boundary.Untagged (asArray, asFunction, asNumber, asString, typeName)
import Boundary.Wrapper (mkComponentWrapper)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (Nullable)
import Data.Tuple (Tuple(..))
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried (mkEffectFn1)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Additional.Background (background) as PS
import React.Additional.Controls (controls) as PS
import React.Additional.Controls.Button (controlButton) as PS
import React.Additional.MiniMap (miniMap) as PS
import React.Additional.MiniMap.Node (miniMapNode) as PS
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (ReactChildren, memo, reactComponent, reactComponentWithChildren)
import React.FFI.ForwardRef (forwardNullableRef)
import React.Portal.Panel (panel) as PS
import React.Types.Component
  ( BackgroundProps
  , ControlButtonProps
  , ControlsProps
  , MiniMapNodeProps
  , MiniMapProps
  , PanelProps
  )
import React.Types.Nodes (Node)
import Unsafe.Coerce (unsafeCoerce)

-- ────────────────────────────────────────────────────────────────────────
-- Shared
-- ────────────────────────────────────────────────────────────────────────

-- | Every message below names its component — `MiniMap.onClick`, not
-- | `onClick`. Six records meet here, `ReactFlow` has props of its own by
-- | some of the same names, and the message is the only thing that says which
-- | element the consumer has to go and look at. `Boundary.Undefined`'s
-- | `requiredProp` takes that qualified path for the same reason.

-- ────────────────────────────────────────────────────────────────────────
-- Panel
-- ────────────────────────────────────────────────────────────────────────

-- | Upstream's `PanelProps` is `HTMLAttributes<HTMLDivElement> & { position }`,
-- | and ps-flow models the four attributes its own component forwards. The
-- | rest of `HTMLAttributes` is a gap in the internals — this record cannot
-- | name what it does not know the shape of, so an unmodelled DOM attribute
-- | is dropped here as silently as it is on the PureScript surface.
type JsPanelProps =
  { position :: Undefinable String
  , className :: Undefinable String
  , style :: Undefinable Foreign
  , "aria-label" :: Undefinable String
  , "data-testid" :: Undefinable String
  , children :: ReactChildren JSX
  -- | Upstream's name for what ps-flow spells `innerRef`, and the reason this
  -- | component is a `forwardRef`. `Boundary.Undefined.orNullable` says why it
  -- | is read from the props object as well as from the forwarded argument.
  , ref :: Undefinable Foreign
  }

convertPanel :: JsPanelProps -> Nullable Foreign -> PanelProps
convertPanel p forwarded =
  { position: panelPositionIn "Panel.position" (requiredProp "Panel.position" p.position)
  , className: fromUndefinable p.className
  , style: map asCssObject (fromUndefinable p.style)
  , "aria-label": fromUndefinable p."aria-label"
  , "data-testid": fromUndefinable p."data-testid"
  , children: p.children
  , innerRef: orNullable p.ref forwarded
  }

-- | `forwardRef`, and no `memo` — which is upstream's shape and not the one
-- | the PureScript component underneath has. `React.Portal.Panel.panel` is
-- | memoized; `<Panel />` upstream is not, and the wrapper is what a
-- | JavaScript caller sees. Boundary stage 4 is where the four chrome
-- | components stopped guessing at this and started copying it.
panel :: ReactComponent JsPanelProps
panel =
  forwardNullableRef "Panel"
    \(props :: JsPanelProps) forwarded -> element PS.panel (convertPanel props forwarded)

-- ────────────────────────────────────────────────────────────────────────
-- Background
-- ────────────────────────────────────────────────────────────────────────

-- | `gap` and `offset` are `number | [number, number]` upstream, narrowed
-- | below. Everything else is a scalar with nothing to get wrong but its name.
type JsBackgroundProps =
  { id :: Undefinable String
  , color :: Undefinable String
  , bgColor :: Undefinable String
  , className :: Undefinable String
  , patternClassName :: Undefinable String
  , gap :: Undefinable Foreign
  , size :: Undefinable Number
  , offset :: Undefinable Foreign
  , lineWidth :: Undefinable Number
  , variant :: Undefinable String
  , style :: Undefinable Foreign
  }

convertBackground :: JsBackgroundProps -> BackgroundProps
convertBackground p =
  { id: fromUndefinable p.id
  , color: fromUndefinable p.color
  , bgColor: fromUndefinable p.bgColor
  , className: fromUndefinable p.className
  , patternClassName: fromUndefinable p.patternClassName
  , gap: map (numberPairIn "Background.gap") (fromUndefinable p.gap)
  , size: fromUndefinable p.size
  , offset: map (numberPairIn "Background.offset") (fromUndefinable p.offset)
  , lineWidth: fromUndefinable p.lineWidth
  , variant: map (backgroundVariantIn "Background.variant") (fromUndefinable p.variant)
  , style: map asCssObject (fromUndefinable p.style)
  }

-- | `number | [number, number]` — one value for both axes, or one each.
numberPairIn :: String -> Foreign -> Either Number (Tuple Number Number)
numberPairIn field raw = case asNumber raw of
  Just n -> Left n
  Nothing -> case asArray raw of
    Just [ x, y ] -> Right (Tuple (axis "x" x) (axis "y" y))
    _ ->
      unsafeThrow $
        "ps-flow: `" <> field <> "` must be a number or a pair of numbers, got "
          <> typeName raw
          <> "."
  where
  axis name value = case asNumber value of
    Just n -> n
    Nothing ->
      unsafeThrow $
        "ps-flow: the " <> name <> " entry of `" <> field <> "` must be a number, got "
          <> typeName value
          <> "."

-- | `memo`, because upstream's is. Stage 1's wrapper was a plain
-- | `reactComponent`, so crossing a memoized PureScript component published an
-- | un-memoized one; the same three-word fix lands on `<Controls />` and
-- | `<MiniMap />` below.
background :: ReactComponent JsBackgroundProps
background =
  unsafePerformEffect $ memo $ reactComponent "Background"
    \(props :: JsBackgroundProps) -> pure (element PS.background (convertBackground props))

-- ────────────────────────────────────────────────────────────────────────
-- Controls
-- ────────────────────────────────────────────────────────────────────────

type JsControlsProps =
  { showZoom :: Undefinable Boolean
  , showFitView :: Undefinable Boolean
  , showInteractive :: Undefinable Boolean
  , fitViewOptions :: Undefinable JsFitViewOptions
  , onZoomIn :: Undefinable JsCommandHandler
  , onZoomOut :: Undefinable JsCommandHandler
  , onFitView :: Undefinable JsCommandHandler
  , onInteractiveChange :: Undefinable JsInteractiveChangeHandler
  , position :: Undefinable String
  , children :: ReactChildren JSX
  , style :: Undefinable Foreign
  , className :: Undefinable String
  , "aria-label" :: Undefinable String
  , orientation :: Undefinable String
  }

convertControls :: JsControlsProps -> ControlsProps
convertControls p =
  { showZoom: fromUndefinable p.showZoom
  , showFitView: fromUndefinable p.showFitView
  , showInteractive: fromUndefinable p.showInteractive
  , fitViewOptions: map fitViewOptionsIn (fromUndefinable p.fitViewOptions)
  , onZoomIn: map commandHandlerIn (fromUndefinable p.onZoomIn)
  , onZoomOut: map commandHandlerIn (fromUndefinable p.onZoomOut)
  , onFitView: map commandHandlerIn (fromUndefinable p.onFitView)
  , onInteractiveChange:
      map interactiveChangeHandlerIn (fromUndefinable p.onInteractiveChange)
  , position: map (panelPositionIn "Controls.position") (fromUndefinable p.position)
  , children: p.children
  , style: map asCssObject (fromUndefinable p.style)
  , className: fromUndefinable p.className
  , "aria-label": fromUndefinable p."aria-label"
  , orientation: map (orientationIn "Controls.orientation") (fromUndefinable p.orientation)
  }

controls :: ReactComponent JsControlsProps
controls =
  unsafePerformEffect $ memo $ reactComponentWithChildren "Controls"
    \(props :: JsControlsProps) -> pure (element PS.controls (convertControls props))

-- ────────────────────────────────────────────────────────────────────────
-- MiniMap
-- ────────────────────────────────────────────────────────────────────────

-- | The node data parameter is `Foreign` here, as it is everywhere else on
-- | this surface: a JavaScript consumer's `node.data` is whatever they put in
-- | it, and the boundary hands it back unread.
type JsMiniMapProps =
  { nodeColor :: Undefinable Foreign
  , nodeStrokeColor :: Undefinable Foreign
  , nodeClassName :: Undefinable Foreign
  , nodeBorderRadius :: Undefinable Number
  , nodeStrokeWidth :: Undefinable Number
  , nodeComponent :: Undefinable (ReactComponent JsMiniMapNodeProps)
  , bgColor :: Undefinable String
  , maskColor :: Undefinable String
  , maskStrokeColor :: Undefinable String
  , maskStrokeWidth :: Undefinable Number
  , position :: Undefinable String
  , onClick :: Undefinable JsMiniMapClickHandler
  , onNodeClick :: Undefinable JsNodeMouseHandler
  , pannable :: Undefinable Boolean
  , zoomable :: Undefinable Boolean
  , "aria-label" :: Undefinable String
  , inversePan :: Undefinable Boolean
  , zoomStep :: Undefinable Number
  , offsetScale :: Undefinable Number
  , children :: ReactChildren JSX
  , style :: Undefinable Foreign
  , className :: Undefinable String
  }

convertMiniMap :: JsMiniMapProps -> MiniMapProps Foreign
convertMiniMap p =
  { nodeColor: map (nodeAttributeIn "MiniMap.nodeColor") (fromUndefinable p.nodeColor)
  , nodeStrokeColor:
      map (nodeAttributeIn "MiniMap.nodeStrokeColor") (fromUndefinable p.nodeStrokeColor)
  , nodeClassName:
      map (nodeAttributeIn "MiniMap.nodeClassName") (fromUndefinable p.nodeClassName)
  , nodeBorderRadius: fromUndefinable p.nodeBorderRadius
  , nodeStrokeWidth: fromUndefinable p.nodeStrokeWidth
  , nodeComponent: map wrapMiniMapNodeComponent (fromUndefinable p.nodeComponent)
  , bgColor: fromUndefinable p.bgColor
  , maskColor: fromUndefinable p.maskColor
  , maskStrokeColor: fromUndefinable p.maskStrokeColor
  , maskStrokeWidth: fromUndefinable p.maskStrokeWidth
  , position: map (panelPositionIn "MiniMap.position") (fromUndefinable p.position)
  , onClick: map miniMapClickHandlerIn (fromUndefinable p.onClick)
  , onNodeClick: map nodeMouseHandlerIn (fromUndefinable p.onNodeClick)
  , pannable: fromUndefinable p.pannable
  , zoomable: fromUndefinable p.zoomable
  , "aria-label": fromUndefinable p."aria-label"
  , inversePan: fromUndefinable p.inversePan
  , zoomStep: fromUndefinable p.zoomStep
  , offsetScale: fromUndefinable p.offsetScale
  , children: p.children
  , style: map asCssObject (fromUndefinable p.style)
  , className: fromUndefinable p.className
  }

-- | `string | ((node) => string)`, of which ps-flow models the function half.
-- |
-- | The function is the consumer's, so this is one of the few places on the
-- | surface where a value ps-flow produced is handed *to* the caller — the
-- | node goes out through `nodeOut`, the same converter `applyNodeChanges`
-- | returns nodes through, so what they see is upstream's shape.
-- |
-- | The string half is refused. Folding it into a constant function would be
-- | this module inventing behaviour the internals do not have, and would hide
-- | the census row that says so.
nodeAttributeIn :: String -> Foreign -> (Node Foreign -> String)
nodeAttributeIn field raw = case asFunction raw of
  Just f -> \node -> readString (f (unsafeCoerce (nodeOut node)))
  Nothing -> case asString raw of
    Just _ ->
      unsafeThrow $
        "ps-flow: `" <> field <> "` accepts upstream's function form but not its "
          <> "string form — ps-flow models this prop as a per-node function only. "
          <> "Pass `() => " <> "\"…\"" <> "` instead of the bare string."
    Nothing ->
      unsafeThrow $
        "ps-flow: `" <> field <> "` must be a function of a node, got "
          <> typeName raw
          <> "."
  where
  readString value = case asString value of
    Just s -> s
    Nothing ->
      unsafeThrow $
        "ps-flow: `" <> field <> "` returned " <> typeName value <> ", not a string."

miniMap :: ReactComponent JsMiniMapProps
miniMap =
  unsafePerformEffect $ memo $ reactComponentWithChildren "MiniMap"
    \(props :: JsMiniMapProps) -> pure (element PS.miniMap (convertMiniMap props))

-- ────────────────────────────────────────────────────────────────────────
-- ControlButton
--
-- The button `<Controls />` renders for each of its own controls, and the one
-- a consumer adds their own beside them with. Upstream's props are
-- `ButtonHTMLAttributes<HTMLButtonElement>`, of which ps-flow models the six
-- its component forwards. The rest is missing from the internals, exactly as
-- it is on `JsPanelProps` against `HTMLAttributes`: this record cannot name
-- what it does not know the shape of, so an unmodelled DOM attribute is
-- dropped here as silently as it is on the PureScript surface.
-- ────────────────────────────────────────────────────────────────────────

type JsControlButtonProps =
  { onClick :: Undefinable JsCommandHandler
  , disabled :: Undefinable Boolean
  , className :: Undefinable String
  , title :: Undefinable String
  , "aria-label" :: Undefinable String
  , style :: Undefinable Foreign
  , children :: ReactChildren JSX
  }

convertControlButton :: JsControlButtonProps -> ControlButtonProps
convertControlButton p =
  { onClick: map commandHandlerIn (fromUndefinable p.onClick)
  , disabled: fromUndefinable p.disabled
  , className: fromUndefinable p.className
  , title: fromUndefinable p.title
  , "aria-label": fromUndefinable p."aria-label"
  , style: map asCssObject (fromUndefinable p.style)
  , children: p.children
  }

-- | Not memoized, because upstream's is not — the opposite direction to
-- | `<Background />` and its two siblings above, and why the surface-parity
-- | allowlist listed this one class of divergence pointing both ways.
-- | ps-flow's own `<ControlButton />` is memoized; that is a fact about the
-- | internals, and the JS surface publishes upstream's shape.
controlButton :: ReactComponent JsControlButtonProps
controlButton =
  unsafePerformEffect $ reactComponentWithChildren "ControlButton"
    \(props :: JsControlButtonProps) ->
      pure (element PS.controlButton (convertControlButton props))

-- ────────────────────────────────────────────────────────────────────────
-- MiniMapNode
--
-- The per-node rect inside the minimap, and the only component on this
-- surface that crosses in **both** directions: a consumer can render it
-- themselves, and `MiniMap.nodeComponent` is ps-flow rendering the consumer's
-- replacement for it. So this record has a converter each way, and neither is
-- the other's inverse — `miniMapNodePropsOut` is what the wrapper below hands
-- a component ps-flow did not write.
-- ────────────────────────────────────────────────────────────────────────

type JsMiniMapNodeProps =
  { id :: Undefinable String
  , x :: Undefinable Number
  , y :: Undefinable Number
  , width :: Undefinable Number
  , height :: Undefinable Number
  , borderRadius :: Undefinable Number
  , className :: Undefinable String
  , color :: Undefinable String
  , shapeRendering :: Undefinable String
  , strokeColor :: Undefinable String
  , strokeWidth :: Undefinable Number
  , style :: Undefinable Foreign
  , selected :: Undefinable Boolean
  , onClick :: Undefinable JsMiniMapNodeClickHandler
  }

-- | Six members upstream declares required, and three ps-flow makes required
-- | that upstream does not. `className`, `shapeRendering` and `selected` have
-- | an answer a rect nobody configured can carry — the empty string and
-- | `false` — so they default rather than throwing; the six that name the
-- | rect's identity and geometry have no such answer.
convertMiniMapNode :: JsMiniMapNodeProps -> MiniMapNodeProps
convertMiniMapNode p =
  { id: requiredProp "MiniMapNode.id" p.id
  , x: requiredProp "MiniMapNode.x" p.x
  , y: requiredProp "MiniMapNode.y" p.y
  , width: requiredProp "MiniMapNode.width" p.width
  , height: requiredProp "MiniMapNode.height" p.height
  , borderRadius: requiredProp "MiniMapNode.borderRadius" p.borderRadius
  , className: fromMaybe "" (fromUndefinable p.className)
  , color: fromUndefinable p.color
  , shapeRendering: fromMaybe "" (fromUndefinable p.shapeRendering)
  , strokeColor: fromUndefinable p.strokeColor
  , strokeWidth: fromUndefinable p.strokeWidth
  , style: map asCssObject (fromUndefinable p.style)
  , selected: fromMaybe false (fromUndefinable p.selected)
  , onClick: map miniMapNodeClickHandlerIn (fromUndefinable p.onClick)
  }

miniMapNodePropsOut :: MiniMapNodeProps -> JsMiniMapNodeProps
miniMapNodePropsOut p =
  { id: toUndefinable (Just p.id)
  , x: toUndefinable (Just p.x)
  , y: toUndefinable (Just p.y)
  , width: toUndefinable (Just p.width)
  , height: toUndefinable (Just p.height)
  , borderRadius: toUndefinable (Just p.borderRadius)
  , className: toUndefinable (Just p.className)
  , color: toUndefinable p.color
  , shapeRendering: toUndefinable (Just p.shapeRendering)
  , strokeColor: toUndefinable p.strokeColor
  , strokeWidth: toUndefinable p.strokeWidth
  , style: toUndefinable (map fromCssObject p.style)
  , selected: toUndefinable (Just p.selected)
  , onClick: toUndefinable (map miniMapNodeClickHandlerOut p.onClick)
  }

-- | `MiniMap.nodeComponent`, crossing: the consumer's component wrapped so
-- | that what reaches it is `JsMiniMapNodeProps`. The third and last of the
-- | three props whose values are components the consumer wrote — `nodeTypes`
-- | in stage 1, `edgeTypes` and this one in stage 4 — and all three go through
-- | `Boundary.Wrapper`, which says why the wrapper has to be a component
-- | rather than a call.
wrapMiniMapNodeComponent
  :: ReactComponent JsMiniMapNodeProps
  -> ReactComponent MiniMapNodeProps
wrapMiniMapNodeComponent userComponent =
  mkComponentWrapper userComponent
    (mkEffectFn1 \psProps -> pure (element userComponent (miniMapNodePropsOut psProps)))

-- | `memo`, because upstream's is.
miniMapNode :: ReactComponent JsMiniMapNodeProps
miniMapNode =
  unsafePerformEffect $ memo $ reactComponent "MiniMapNode"
    \(props :: JsMiniMapNodeProps) ->
      pure (element PS.miniMapNode (convertMiniMapNode props))
