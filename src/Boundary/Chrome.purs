-- | The four chrome components, crossing: `<Panel />`, `<Background />`,
-- | `<Controls />` and `<MiniMap />`.
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
-- | ## What is refused, and what that costs
-- |
-- | One prop resolves here and does not cross. `MiniMap.nodeComponent` is a
-- | consumer's own component receiving `MiniMapNodeProps`, so crossing it means
-- | an outbound converter for that record — the same reason `edgeTypes` is
-- | deferred and `nodeTypes` is not.
-- |
-- | `Controls`' four handlers and `MiniMap`'s two were refused beside it until
-- | boundary stage 2, which crossed the callbacks wherever they appear; their
-- | converters are in `Boundary.Callbacks` with the flow's.
-- |
-- | Three more are refused **by value rather than by name**:
-- | `nodeColor`, `nodeStrokeColor` and `nodeClassName` are
-- | `string | ((node) => string)` upstream, and ps-flow models only the
-- | function half. The string half is a real gap in the internals, not
-- | something this module can convert around, so a consumer who passes one
-- | gets told that rather than a minimap of undefined-coloured nodes.
module Boundary.Chrome
  ( JsBackgroundProps
  , JsControlsProps
  , JsMiniMapProps
  , JsPanelProps
  , background
  , controls
  , miniMap
  , panel
  ) where

import Prelude

import Boundary.Callbacks
  ( JsCommandHandler
  , JsInteractiveChangeHandler
  , JsMiniMapClickHandler
  , JsNodeMouseHandler
  , commandHandlerIn
  , interactiveChangeHandlerIn
  , miniMapClickHandlerIn
  , nodeMouseHandlerIn
  )
import Boundary.Elements (asCssObject, nodeOut)
import Boundary.Enums (backgroundVariantIn, orientationIn, panelPositionIn)
import Boundary.Flow (JsFitViewOptions, fitViewOptionsIn)
import Boundary.Refusal (Refusal, componentProp, deferredMessage, refuseFirst)
import Boundary.Undefined (Undefinable, fromUndefinable)
import Boundary.Untagged (asArray, asFunction, asNumber, asString, typeName)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Additional.Background (background) as PS
import React.Additional.Controls (controls) as PS
import React.Additional.MiniMap (miniMap) as PS
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (ReactChildren, reactComponent, reactComponentWithChildren)
import React.Portal.Panel (panel) as PS
import React.Types.Component (BackgroundProps, ControlsProps, MiniMapProps, PanelProps)
import React.Types.Nodes (Node)
import Unsafe.Coerce (unsafeCoerce)

-- ────────────────────────────────────────────────────────────────────────
-- Shared
-- ────────────────────────────────────────────────────────────────────────

-- | Every refusal below names its component — `MiniMap.onClick`, not
-- | `onClick`. Four records meet here, `ReactFlow` has props of its own by
-- | some of the same names, and the message is the only thing that says which
-- | element the consumer has to go and look at.

-- | A prop upstream declares required. It is typed `Undefinable` here anyway,
-- | because a JavaScript caller can always omit it and TypeScript is not
-- | running — and an omission met by a pattern-match failure names nothing.
requiredProp :: forall a. String -> Undefinable a -> a
requiredProp field u = case fromUndefinable u of
  Just v -> v
  Nothing ->
    unsafeThrow $
      "ps-flow: `" <> field <> "` is required and was not supplied."

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
  }

convertPanel :: JsPanelProps -> PanelProps
convertPanel p =
  { position: panelPositionIn "Panel.position" (requiredProp "Panel.position" p.position)
  , className: fromUndefinable p.className
  , style: map asCssObject (fromUndefinable p.style)
  , "aria-label": fromUndefinable p."aria-label"
  , "data-testid": fromUndefinable p."data-testid"
  , children: p.children
  }

panel :: ReactComponent JsPanelProps
panel =
  unsafePerformEffect $ reactComponentWithChildren "Panel"
    \(props :: JsPanelProps) -> pure (element PS.panel (convertPanel props))

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

background :: ReactComponent JsBackgroundProps
background =
  unsafePerformEffect $ reactComponent "Background"
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
  unsafePerformEffect $ reactComponentWithChildren "Controls"
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
  , nodeComponent :: Undefinable Foreign
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

deferredMiniMapProps :: Array (Refusal JsMiniMapProps)
deferredMiniMapProps =
  [ componentProp "MiniMap.nodeComponent" _.nodeComponent
  ]

miniMapPropsIn :: JsMiniMapProps -> MiniMapProps Foreign
miniMapPropsIn = convertMiniMap <<< refuseFirst deferredMessage deferredMiniMapProps

convertMiniMap :: JsMiniMapProps -> MiniMapProps Foreign
convertMiniMap p =
  { nodeColor: map (nodeAttributeIn "MiniMap.nodeColor") (fromUndefinable p.nodeColor)
  , nodeStrokeColor:
      map (nodeAttributeIn "MiniMap.nodeStrokeColor") (fromUndefinable p.nodeStrokeColor)
  , nodeClassName:
      map (nodeAttributeIn "MiniMap.nodeClassName") (fromUndefinable p.nodeClassName)
  , nodeBorderRadius: fromUndefinable p.nodeBorderRadius
  , nodeStrokeWidth: fromUndefinable p.nodeStrokeWidth
  , nodeComponent: Nothing
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
  unsafePerformEffect $ reactComponentWithChildren "MiniMap"
    \(props :: JsMiniMapProps) -> pure (element PS.miniMap (miniMapPropsIn props))
