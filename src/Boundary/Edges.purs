-- | The edge-side components, crossing — boundary stage 4.
-- |
-- | **Eight components and two props**, and they are the half of stage 4 the
-- | **hole register** points at most directly: `parity/system/coverage/
-- | holes.json` records the four non-default built-in edge components,
-- | `EdgeToolbar` and `EdgeTypes` as exports the corpus does not drive, and
-- | every one of them is an edge. Crossing is not driving — a hole closes when
-- | a scenario renders one, not when a wrapper exists — but a component a
-- | JavaScript caller cannot hand upstream's props to cannot be driven from the
-- | JS surface at all, which is what this module removes.
-- |
-- | ## The two directions
-- |
-- | The eight components are ordinary **inbound** crossings, the shape
-- | `Boundary.Chrome` established: React calls a component with `{}`, a
-- | PureScript record field typed `Maybe` arrives `undefined`, and the first
-- | `case` over it falls off the end of a pattern match. So every field is
-- | `Undefinable` here whatever upstream declares; the ones upstream declares
-- | required are named by `requiredProp` so an omission says which prop it was
-- | rather than crashing somewhere below, and the ones upstream *defaults* get
-- | upstream's default rather than either.
-- |
-- | `edgeTypes` is the **outbound** one, and it is why these components cross
-- | together rather than one by one wherever they live. Its values are the
-- | consumer's own components, so crossing it means converting the props
-- | record ps-flow's renderer hands *them* — `edgePropsOut` — which is the
-- | converter `Boundary.Flow` has been deferring on since stage 1. `nodeTypes`
-- | crossed then on exactly this shape
-- | (`Boundary.Elements.nodePropsOut`); this is its edge-side twin.
-- |
-- | `connectionLineComponent` is the same shape once more, and the second of
-- | `Boundary.Flow`'s two deferred props: a consumer component handed
-- | `ConnectionLineComponentProps`, converted out by `connectionLinePropsOut`.
-- | ps-flow holds it as a plain props-to-`JSX` function where upstream types it
-- | `ComponentType<Props>`, so what crosses is a component turned into that
-- | function.
-- |
-- | ## Two things the crossing actually converts
-- |
-- | Most members here are scalars with nothing to get wrong but their name.
-- | Two are not:
-- |
-- |   * `labelBgPadding` is `[number, number]` upstream and `{ x, y }` in
-- |     ps-flow (`React.Edge.Text` records why). It rides on six of the records
-- |     below, so the pair of converters is written once here.
-- |   * `sourcePosition` / `targetPosition` are `Position` members, so they
-- |     cross through `Boundary.Enums` in both directions.
-- |
-- | ## Wrapper kind
-- |
-- | Six of the eight are `memo` upstream and two are not, and the wrapper is
-- | what a JavaScript caller sees — the `memo` on the PureScript component
-- | underneath is invisible from `index.js`. So each wrapper below carries
-- | upstream's own answer and not the one the internals happen to have:
-- | `<BaseEdge />` is memoized inside ps-flow and published plain, because
-- | upstream publishes it plain.
module Boundary.Edges
  ( JsBaseEdgeProps
  , JsBezierEdgeProps
  , JsBezierPathOptions
  , JsConnectionLineComponentProps
  , JsEdgeComponentRow
  , JsEdgeProps
  , JsEdgeTextProps
  , JsEdgeToolbarProps
  , JsSimpleBezierEdgeProps
  , JsSmoothStepEdgeProps
  , JsSmoothStepPathOptions
  , JsStepEdgeProps
  , JsStepPathOptions
  , JsStraightEdgeProps
  , JsStraightEdgeRow
  , baseEdge
  , bezierEdge
  , connectionLineComponentIn
  , connectionLinePropsOut
  , edgePropsOut
  , edgeText
  , edgeToolbar
  , edgeTypesIn
  , labelBgPaddingIn
  , labelBgPaddingOut
  , simpleBezierEdge
  , smoothStepEdge
  , stepEdge
  , straightEdge
  ) where

import Prelude

import Boundary.Elements
  ( JsHandle
  , JsInternalNode
  , JsXYPosition
  , asCssObject
  , asCssStyle
  , fromCssStyle
  , handleOut
  , internalNodeOut
  )
import Boundary.Enums
  ( alignXIn
  , alignYIn
  , connectionLineTypeOut
  , positionIn
  , positionOut
  )
import Boundary.Undefined (Undefinable, fromUndefinable, requiredProp, toUndefinable)
import Data.Maybe (Maybe, maybe)
import Boundary.Wrapper (mkComponentWrapper)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried (mkEffectFn1)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object (mapWithKey) as Object
import React.Additional.EdgeToolbar (edgeToolbar) as PS
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (ReactChildren, memo, reactComponent, reactComponentWithChildren)
import React.Edge.Base (baseEdge) as PS
import React.Edge.Bezier (bezierEdge) as PS
import React.Edge.SimpleBezier (simpleBezierEdge) as PS
import React.Edge.SmoothStep (smoothStepEdge) as PS
import React.Edge.Step (stepEdge) as PS
import React.Edge.Straight (straightEdge) as PS
import React.Edge.Text (edgeText) as PS
import React.Types.Component (EdgeToolbarProps)
import React.Types.Edges
  ( BaseEdgeProps
  , BezierEdgeProps
  , EdgeComponentRow
  , ConnectionLineComponent
  , ConnectionLineComponentProps
  , ConnectionStatus(..)
  , EdgeProps
  , EdgeTextProps
  , EdgeTypesMap
  , PathOptions
  , SimpleBezierEdgeProps
  , SmoothStepEdgeProps
  , StepEdgeProps
  , StraightEdgeProps
  )
import System.Types.Geometry (Position(..))
import Unsafe.Coerce (unsafeCoerce)

-- ────────────────────────────────────────────────────────────────────────
-- Shared
-- ────────────────────────────────────────────────────────────────────────

-- | Every message below names its component, and `Boundary.Undefined`'s
-- | `requiredProp` is written to take that qualified path: five of the records
-- | in this module declare a `sourceX`, so a bare prop name would say nothing
-- | about which element the consumer has to go and look at.

-- | `[x, y]` upstream, `{ x, y }` in ps-flow. One of the two members on these
-- | records whose representation actually differs, so it is one of the two
-- | that converts.
labelBgPaddingIn :: String -> Array Number -> { x :: Number, y :: Number }
labelBgPaddingIn field = case _ of
  [ x, y ] -> { x, y }
  _ ->
    unsafeThrow $
      "ps-flow: `" <> field <> "` must be [paddingX, paddingY]."

labelBgPaddingOut :: { x :: Number, y :: Number } -> Array Number
labelBgPaddingOut p = [ p.x, p.y ]

-- ────────────────────────────────────────────────────────────────────────
-- EdgeText
-- ────────────────────────────────────────────────────────────────────────

type JsEdgeTextProps =
  { x :: Undefinable Number
  , y :: Undefinable Number
  , label :: Undefinable String
  , labelStyle :: Undefinable Foreign
  , labelShowBg :: Undefinable Boolean
  , labelBgStyle :: Undefinable Foreign
  , labelBgPadding :: Undefinable (Array Number)
  , labelBgBorderRadius :: Undefinable Number
  }

convertEdgeText :: JsEdgeTextProps -> EdgeTextProps
convertEdgeText p =
  { x: requiredProp "EdgeText.x" p.x
  , y: requiredProp "EdgeText.y" p.y
  , label: fromUndefinable p.label
  , labelStyle: map asCssStyle (fromUndefinable p.labelStyle)
  , labelShowBg: fromUndefinable p.labelShowBg
  , labelBgStyle: map asCssStyle (fromUndefinable p.labelBgStyle)
  , labelBgPadding:
      map (labelBgPaddingIn "EdgeText.labelBgPadding") (fromUndefinable p.labelBgPadding)
  , labelBgBorderRadius: fromUndefinable p.labelBgBorderRadius
  }

edgeText :: ReactComponent JsEdgeTextProps
edgeText =
  unsafePerformEffect $ memo $ reactComponent "EdgeText"
    \(props :: JsEdgeTextProps) -> pure (element PS.edgeText (convertEdgeText props))

-- ────────────────────────────────────────────────────────────────────────
-- BaseEdge
-- ────────────────────────────────────────────────────────────────────────

type JsBaseEdgeProps =
  { id :: Undefinable String
  , path :: Undefinable String
  , labelX :: Undefinable Number
  , labelY :: Undefinable Number
  , label :: Undefinable String
  , labelStyle :: Undefinable Foreign
  , labelShowBg :: Undefinable Boolean
  , labelBgStyle :: Undefinable Foreign
  , labelBgPadding :: Undefinable (Array Number)
  , labelBgBorderRadius :: Undefinable Number
  , style :: Undefinable Foreign
  , markerEnd :: Undefinable String
  , markerStart :: Undefinable String
  , interactionWidth :: Undefinable Number
  , className :: Undefinable String
  }

convertBaseEdge :: JsBaseEdgeProps -> BaseEdgeProps
convertBaseEdge p =
  { id: fromUndefinable p.id
  , path: requiredProp "BaseEdge.path" p.path
  , labelX: fromUndefinable p.labelX
  , labelY: fromUndefinable p.labelY
  , label: fromUndefinable p.label
  , labelStyle: map asCssStyle (fromUndefinable p.labelStyle)
  , labelShowBg: fromUndefinable p.labelShowBg
  , labelBgStyle: map asCssStyle (fromUndefinable p.labelBgStyle)
  , labelBgPadding:
      map (labelBgPaddingIn "BaseEdge.labelBgPadding") (fromUndefinable p.labelBgPadding)
  , labelBgBorderRadius: fromUndefinable p.labelBgBorderRadius
  , style: map asCssStyle (fromUndefinable p.style)
  , markerEnd: fromUndefinable p.markerEnd
  , markerStart: fromUndefinable p.markerStart
  , interactionWidth: fromUndefinable p.interactionWidth
  , className: fromUndefinable p.className
  }

-- | Not memoized, because upstream's is not. ps-flow's own `<BaseEdge />` is —
-- | it is what every built-in edge renders through, so memoizing it internally
-- | is a reasonable thing for the port to do — but that is a fact about the
-- | internals, and the JS surface publishes upstream's shape.
baseEdge :: ReactComponent JsBaseEdgeProps
baseEdge =
  unsafePerformEffect $ reactComponent "BaseEdge"
    \(props :: JsBaseEdgeProps) -> pure (element PS.baseEdge (convertBaseEdge props))

-- ────────────────────────────────────────────────────────────────────────
-- The five built-in edge components
--
-- Spelled as rows and extended, the way `React.Types.Edges` spells the
-- PureScript ones: `StraightEdge` is the variant with no use for the two
-- handle sides, the other four add them, and three of those four add one
-- `pathOptions` field apiece. Upstream writes the largest record and `Omit`s
-- from it; PureScript extends a row rather than subtracting from one, so both
-- sides here grow — and `parity/boundary/drift.mjs` expands the composition on
-- both before comparing labels.
--
-- The converters compose the same way, one step behind: a PureScript record is
-- built whole, so each layer builds the record below it and names the fields
-- that layer adds. `sharedEdgeFields` reads the seventeen, `bendingEdgeFields`
-- adds the two handle sides, and `withPathOptions` adds the one field the
-- three path-shaped variants have.
-- ────────────────────────────────────────────────────────────────────────

type JsStraightEdgeRow r =
  ( id :: Undefinable String
  , sourceX :: Undefinable Number
  , sourceY :: Undefinable Number
  , targetX :: Undefinable Number
  , targetY :: Undefinable Number
  , markerStart :: Undefinable String
  , markerEnd :: Undefinable String
  , interactionWidth :: Undefinable Number
  , style :: Undefinable Foreign
  , sourceHandleId :: Undefinable String
  , targetHandleId :: Undefinable String
  , label :: Undefinable String
  , labelStyle :: Undefinable Foreign
  , labelShowBg :: Undefinable Boolean
  , labelBgStyle :: Undefinable Foreign
  , labelBgPadding :: Undefinable (Array Number)
  , labelBgBorderRadius :: Undefinable Number
  | r
  )

type JsStraightEdgeProps = Record (JsStraightEdgeRow ())

type JsEdgeComponentRow r =
  ( sourcePosition :: Undefinable String
  , targetPosition :: Undefinable String
  | JsStraightEdgeRow r
  )

type JsSimpleBezierEdgeProps = Record (JsEdgeComponentRow ())

type JsBezierPathOptions = { curvature :: Undefinable Number }

type JsSmoothStepPathOptions =
  { offset :: Undefinable Number
  , borderRadius :: Undefinable Number
  , stepPosition :: Undefinable Number
  }

type JsStepPathOptions = { offset :: Undefinable Number }

type JsBezierEdgeProps =
  Record (JsEdgeComponentRow (pathOptions :: Undefinable JsBezierPathOptions))

type JsSmoothStepEdgeProps =
  Record (JsEdgeComponentRow (pathOptions :: Undefinable JsSmoothStepPathOptions))

type JsStepEdgeProps =
  Record (JsEdgeComponentRow (pathOptions :: Undefinable JsStepPathOptions))

-- | The seventeen members every built-in edge shares, read once. `who` is the
-- | component the value arrived on, because all five records declare a
-- | `sourceX` and a message that did not say which would send the consumer to
-- | the wrong element.
sharedEdgeFields :: String -> JsStraightEdgeProps -> StraightEdgeProps
sharedEdgeFields who p =
  { id: fromUndefinable p.id
  , sourceX: requiredProp (who <> ".sourceX") p.sourceX
  , sourceY: requiredProp (who <> ".sourceY") p.sourceY
  , targetX: requiredProp (who <> ".targetX") p.targetX
  , targetY: requiredProp (who <> ".targetY") p.targetY
  , markerStart: fromUndefinable p.markerStart
  , markerEnd: fromUndefinable p.markerEnd
  , interactionWidth: fromUndefinable p.interactionWidth
  , style: map asCssStyle (fromUndefinable p.style)
  , sourceHandleId: fromUndefinable p.sourceHandleId
  , targetHandleId: fromUndefinable p.targetHandleId
  , label: fromUndefinable p.label
  , labelStyle: map asCssStyle (fromUndefinable p.labelStyle)
  , labelShowBg: fromUndefinable p.labelShowBg
  , labelBgStyle: map asCssStyle (fromUndefinable p.labelBgStyle)
  , labelBgPadding:
      map (labelBgPaddingIn (who <> ".labelBgPadding")) (fromUndefinable p.labelBgPadding)
  , labelBgBorderRadius: fromUndefinable p.labelBgBorderRadius
  }

-- | Those seventeen plus the two handle sides — the props of every built-in
-- | edge whose path bends.
-- |
-- | The two are **defaulted, not required**, and that is upstream's answer
-- | rather than a convenience: `sourcePosition = Position.Bottom` and
-- | `targetPosition = Position.Top` are written into the parameter lists of
-- | `BezierEdge.tsx`, `SimpleBezierEdge.tsx` and `SmoothStepEdge.tsx`, so
-- | upstream's own documented example — `<BezierEdge sourceX … targetY />`
-- | with no positions — renders. ps-flow's record has no absent state for a sum
-- | type, so supplying the defaults is the crossing's job, exactly as it is for
-- | `<Handle />`'s `type` and `position` in `Boundary.NodeChrome`.
-- |
-- | The **inbound coercion is sound because the reader is a subset**: every
-- | record below extends `JsStraightEdgeRow`, and `sharedEdgeFields` reads only
-- | that row's seventeen members. Composing this way rather than transcribing
-- | nineteen fields five times is what stops a mis-wired member hiding in a
-- | copy — `parity/boundary/drift.mjs` compares the label *sets*, so it would
-- | not see `sourceX` reading `p.sourceY`.
bendingEdgeFields :: String -> JsSimpleBezierEdgeProps -> SimpleBezierEdgeProps
bendingEdgeFields who p =
  { id: shared.id
  , sourceX: shared.sourceX
  , sourceY: shared.sourceY
  , targetX: shared.targetX
  , targetY: shared.targetY
  , markerStart: shared.markerStart
  , markerEnd: shared.markerEnd
  , interactionWidth: shared.interactionWidth
  , style: shared.style
  , sourceHandleId: shared.sourceHandleId
  , targetHandleId: shared.targetHandleId
  , label: shared.label
  , labelStyle: shared.labelStyle
  , labelShowBg: shared.labelShowBg
  , labelBgStyle: shared.labelBgStyle
  , labelBgPadding: shared.labelBgPadding
  , labelBgBorderRadius: shared.labelBgBorderRadius
  , sourcePosition:
      maybe PosBottom (positionIn (who <> ".sourcePosition")) (fromUndefinable p.sourcePosition)
  , targetPosition:
      maybe PosTop (positionIn (who <> ".targetPosition")) (fromUndefinable p.targetPosition)
  }
  where
  shared = sharedEdgeFields who (unsafeCoerce p)

-- | One of the three bending variants that also takes a `pathOptions` record,
-- | built by record *update* on the variant that does not.
-- |
-- | The coercion is sound for the reason `React.Edge.Step`'s is: the target
-- | record differs from `SimpleBezierEdgeProps` by exactly the field the update
-- | then writes, so nothing is left reading a label that is not there.
withPathOptions
  :: forall o
   . SimpleBezierEdgeProps
  -> Maybe o
  -> Record (EdgeComponentRow (pathOptions :: Maybe o))
withPathOptions shared options =
  (unsafeCoerce shared :: Record (EdgeComponentRow (pathOptions :: Maybe o)))
    { pathOptions = options }

convertStraightEdge :: JsStraightEdgeProps -> StraightEdgeProps
convertStraightEdge = sharedEdgeFields "StraightEdge"

convertSimpleBezierEdge :: JsSimpleBezierEdgeProps -> SimpleBezierEdgeProps
convertSimpleBezierEdge = bendingEdgeFields "SimpleBezierEdge"

convertBezierEdge :: JsBezierEdgeProps -> BezierEdgeProps
convertBezierEdge p =
  withPathOptions (bendingEdgeFields "BezierEdge" (unsafeCoerce p)) $
    map (\o -> { curvature: fromUndefinable o.curvature }) (fromUndefinable p.pathOptions)

convertSmoothStepEdge :: JsSmoothStepEdgeProps -> SmoothStepEdgeProps
convertSmoothStepEdge p =
  withPathOptions (bendingEdgeFields "SmoothStepEdge" (unsafeCoerce p)) $
    map
      ( \o ->
          { offset: fromUndefinable o.offset
          , borderRadius: fromUndefinable o.borderRadius
          , stepPosition: fromUndefinable o.stepPosition
          }
      )
      (fromUndefinable p.pathOptions)

convertStepEdge :: JsStepEdgeProps -> StepEdgeProps
convertStepEdge p =
  withPathOptions (bendingEdgeFields "StepEdge" (unsafeCoerce p)) $
    map (\o -> { offset: fromUndefinable o.offset }) (fromUndefinable p.pathOptions)

-- ────────────────────────────────────────────────────────────────────────

straightEdge :: ReactComponent JsStraightEdgeProps
straightEdge =
  unsafePerformEffect $ memo $ reactComponent "StraightEdge"
    \(props :: JsStraightEdgeProps) ->
      pure (element PS.straightEdge (convertStraightEdge props))

simpleBezierEdge :: ReactComponent JsSimpleBezierEdgeProps
simpleBezierEdge =
  unsafePerformEffect $ memo $ reactComponent "SimpleBezierEdge"
    \(props :: JsSimpleBezierEdgeProps) ->
      pure (element PS.simpleBezierEdge (convertSimpleBezierEdge props))

bezierEdge :: ReactComponent JsBezierEdgeProps
bezierEdge =
  unsafePerformEffect $ memo $ reactComponent "BezierEdge"
    \(props :: JsBezierEdgeProps) ->
      pure (element PS.bezierEdge (convertBezierEdge props))

smoothStepEdge :: ReactComponent JsSmoothStepEdgeProps
smoothStepEdge =
  unsafePerformEffect $ memo $ reactComponent "SmoothStepEdge"
    \(props :: JsSmoothStepEdgeProps) ->
      pure (element PS.smoothStepEdge (convertSmoothStepEdge props))

stepEdge :: ReactComponent JsStepEdgeProps
stepEdge =
  unsafePerformEffect $ memo $ reactComponent "StepEdge"
    \(props :: JsStepEdgeProps) ->
      pure (element PS.stepEdge (convertStepEdge props))

-- ────────────────────────────────────────────────────────────────────────
-- EdgeToolbar
-- ────────────────────────────────────────────────────────────────────────

type JsEdgeToolbarProps =
  { edgeId :: Undefinable String
  , x :: Undefinable Number
  , y :: Undefinable Number
  , isVisible :: Undefinable Boolean
  , alignX :: Undefinable String
  , alignY :: Undefinable String
  , style :: Undefinable Foreign
  , className :: Undefinable String
  , children :: ReactChildren JSX
  }

convertEdgeToolbar :: JsEdgeToolbarProps -> EdgeToolbarProps
convertEdgeToolbar p =
  { edgeId: requiredProp "EdgeToolbar.edgeId" p.edgeId
  , x: requiredProp "EdgeToolbar.x" p.x
  , y: requiredProp "EdgeToolbar.y" p.y
  , isVisible: fromUndefinable p.isVisible
  , alignX: map (alignXIn "EdgeToolbar.alignX") (fromUndefinable p.alignX)
  , alignY: map (alignYIn "EdgeToolbar.alignY") (fromUndefinable p.alignY)
  , style: map asCssObject (fromUndefinable p.style)
  , className: fromUndefinable p.className
  , children: p.children
  }

edgeToolbar :: ReactComponent JsEdgeToolbarProps
edgeToolbar =
  unsafePerformEffect $ reactComponentWithChildren "EdgeToolbar"
    \(props :: JsEdgeToolbarProps) -> pure (element PS.edgeToolbar (convertEdgeToolbar props))

-- ────────────────────────────────────────────────────────────────────────
-- `edgeTypes`, and the props a consumer's own edge component receives
-- ────────────────────────────────────────────────────────────────────────

-- | What a custom edge component is handed. The mirror of
-- | `Boundary.Elements.JsNodeProps`, one element kind along, and the reason
-- | `edgeTypes` could not cross with `nodeTypes` in stage 1.
type JsEdgeProps =
  { id :: String
  , type :: Undefinable String
  , animated :: Boolean
  , data :: Undefinable Foreign
  , style :: Undefinable Foreign
  , selected :: Boolean
  , source :: String
  , target :: String
  , selectable :: Undefinable Boolean
  , deletable :: Undefinable Boolean
  , sourceX :: Number
  , sourceY :: Number
  , targetX :: Number
  , targetY :: Number
  , sourcePosition :: String
  , targetPosition :: String
  , label :: Undefinable String
  , labelStyle :: Undefinable Foreign
  , labelShowBg :: Undefinable Boolean
  , labelBgStyle :: Undefinable Foreign
  , labelBgPadding :: Undefinable (Array Number)
  , labelBgBorderRadius :: Undefinable Number
  , sourceHandleId :: Undefinable String
  , targetHandleId :: Undefinable String
  , markerStart :: Undefinable String
  , markerEnd :: Undefinable String
  , pathOptions :: Undefinable Foreign
  , interactionWidth :: Undefinable Number
  }

edgePropsOut :: EdgeProps Foreign -> JsEdgeProps
edgePropsOut p =
  { id: p.id
  , type: toUndefinable p.type
  , animated: p.animated
  , data: toUndefinable p.data
  , style: toUndefinable (map fromCssStyle p.style)
  , selected: p.selected
  , source: p.source
  , target: p.target
  , selectable: toUndefinable p.selectable
  , deletable: toUndefinable p.deletable
  , sourceX: p.sourceX
  , sourceY: p.sourceY
  , targetX: p.targetX
  , targetY: p.targetY
  , sourcePosition: positionOut p.sourcePosition
  , targetPosition: positionOut p.targetPosition
  , label: toUndefinable p.label
  , labelStyle: toUndefinable (map fromCssStyle p.labelStyle)
  , labelShowBg: toUndefinable p.labelShowBg
  , labelBgStyle: toUndefinable (map fromCssStyle p.labelBgStyle)
  , labelBgPadding: toUndefinable (map labelBgPaddingOut p.labelBgPadding)
  , labelBgBorderRadius: toUndefinable p.labelBgBorderRadius
  , sourceHandleId: toUndefinable p.sourceHandleId
  , targetHandleId: toUndefinable p.targetHandleId
  , markerStart: toUndefinable p.markerStart
  , markerEnd: toUndefinable p.markerEnd
  , pathOptions: toUndefinable (map pathOptionsOut p.pathOptions)
  , interactionWidth: toUndefinable p.interactionWidth
  }

-- | `PathOptions` is opaque on the generic props record — upstream's is a
-- | union of the three per-variant option records — so it crosses as the plain
-- | object it already is. A consumer reading `pathOptions.offset` gets what
-- | ps-flow was handed, unread.
pathOptionsOut :: PathOptions -> Foreign
pathOptionsOut = unsafeCoerce

-- | `edgeTypes` is `nodeTypes`' twin: the values are consumer code ps-flow
-- | calls, so crossing it wraps every component in the map rather than
-- | converting data. The map is an ordinary object at runtime on both sides —
-- | `EdgeTypesMap` is opaque in PureScript precisely so the renderer can treat
-- | it as one — so the wrapping is a `mapWithKey` and a coercion back.
edgeTypesIn :: Object (ReactComponent JsEdgeProps) -> EdgeTypesMap
edgeTypesIn types =
  unsafeCoerce (Object.mapWithKey (\_ c -> wrapEdgeComponent c) types)

wrapEdgeComponent
  :: ReactComponent JsEdgeProps
  -> ReactComponent (EdgeProps Foreign)
wrapEdgeComponent userComponent =
  mkComponentWrapper userComponent
    (mkEffectFn1 \psProps -> pure (element userComponent (edgePropsOut psProps)))

-- ────────────────────────────────────────────────────────────────────────
-- `connectionLineComponent`
-- ────────────────────────────────────────────────────────────────────────

-- | What the consumer's connection-line component is handed while a
-- | connection is being drawn. Outbound in every member — ps-flow builds all
-- | of it — so nothing here is `Undefinable` for the caller's sake; the three
-- | that are, are upstream's own optional members.
type JsConnectionLineComponentProps =
  { connectionLineStyle :: Undefinable Foreign
  , connectionLineType :: String
  , fromNode :: JsInternalNode
  , fromHandle :: JsHandle
  , fromX :: Number
  , fromY :: Number
  , toX :: Number
  , toY :: Number
  , fromPosition :: String
  , toPosition :: String
  , connectionStatus :: Undefinable String
  , toNode :: Undefinable JsInternalNode
  , toHandle :: Undefinable JsHandle
  , pointer :: JsXYPosition
  }

connectionLinePropsOut :: ConnectionLineComponentProps Foreign -> JsConnectionLineComponentProps
connectionLinePropsOut p =
  { connectionLineStyle: toUndefinable (map fromCssStyle p.connectionLineStyle)
  , connectionLineType: connectionLineTypeOut p.connectionLineType
  , fromNode: internalNodeOut p.fromNode
  , fromHandle: handleOut p.fromHandle
  , fromX: p.fromX
  , fromY: p.fromY
  , toX: p.toX
  , toY: p.toY
  , fromPosition: positionOut p.fromPosition
  , toPosition: positionOut p.toPosition
  , connectionStatus: toUndefinable (map connectionStatusOut p.connectionStatus)
  , toNode: toUndefinable (map internalNodeOut p.toNode)
  , toHandle: toUndefinable (map handleOut p.toHandle)
  , pointer: p.pointer
  }

-- | Upstream's `'valid' | 'invalid' | null`. ps-flow's `Show` instance already
-- | spells the two members; this is the crossing, where it can be read beside
-- | the record that carries it.
connectionStatusOut :: ConnectionStatus -> String
connectionStatusOut = case _ of
  ConnectionValid -> "valid"
  ConnectionInvalid -> "invalid"

-- | Upstream types `connectionLineComponent` as `ComponentType<Props>` and
-- | renders it as one; ps-flow holds a plain props-to-`JSX` function, which is
-- | the shape `ReactFlowProps.connectionLineComponent` has always had. So what
-- | crosses is a React component turned into that function, with its props
-- | converted on the way in.
connectionLineComponentIn
  :: ReactComponent JsConnectionLineComponentProps
  -> ConnectionLineComponent Foreign
connectionLineComponentIn userComponent =
  \psProps -> element userComponent (connectionLinePropsOut psProps)
