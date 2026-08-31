-- | String literals in, sum-type constructors out — and, for three of them,
-- | back.
-- |
-- | Upstream's enums are TS enums, which are string-valued at runtime, and its
-- | unions are string literals. A JavaScript consumer writes `'left'` or
-- | `Position.Left`, which are the same value; they never write `PosLeft`,
-- | which is not reachable from JavaScript at all. `Boundary` publishes the
-- | runtime enum objects (`position`, `markerType`, …) so `Position.Left`
-- | resolves; this module is the other half — the codec that turns the string
-- | those objects hold into the PureScript constructor the internals are
-- | written against.
-- |
-- | **A string that is not a member throws.** Upstream would fall through its
-- | `switch` and render something arbitrary; here it is a consumer error with
-- | a cheap, exact signature, and the alternative — picking a default — is the
-- | silent-`Nothing` failure this whole effort exists to remove. The message
-- | names the field, the value and the members, because a caller who typo'd
-- | `'smoothStep'` needs to see `'smoothstep'`.
-- |
-- | **Only three cross outbound**, because only three are on a value that
-- | leaves: `Position` on node props, node handles and a connection state's
-- | two sides; `MarkerType` on an edge marker; `HandleType` on a node handle
-- | and on the argument `onReconnectStart` is handed. The rest are
-- | inbound-only, and an unused outbound codec is a converter nobody has been
-- | able to get wrong yet. The three that do exist are written as `case`
-- | expressions rather than as lookups in the member table below, so that a
-- | constructor added to one of those sum types fails the build instead of
-- | throwing on the first value that reaches it.
-- |
-- | The string values are upstream's verbatim. Two are worth reading twice:
-- | `ConnectionLineType.Bezier` is `"default"`, not `"bezier"`, and
-- | `MarkerType.ArrowClosed` is `"arrowclosed"`, all lowercase.
module Boundary.Enums
  ( alignIn
  , alignXIn
  , alignYIn
  , backgroundVariantIn
  , colorModeIn
  , connectionLineTypeIn
  , connectionLineTypeOut
  , connectionModeIn
  , controlPositionIn
  , handleTypeIn
  , handleTypeOut
  , interpolateModeIn
  , markerTypeIn
  , markerTypeOut
  , orientationIn
  , panOnScrollModeIn
  , panelPositionIn
  , positionIn
  , positionOut
  , resizeControlVariantIn
  , resizeDirectionIn
  , selectionModeIn
  , zIndexModeIn
  ) where

import Prelude

import Data.Array (find)
import Data.Foldable (intercalate)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..), fst, snd)
import Effect.Exception.Unsafe (unsafeThrow)
import React.Types.Component (BackgroundVariant(..))
-- Qualified: `Orientation`'s two constructors are spelled the same as two of
-- `PanOnScrollMode`'s, and both codecs live in this module.
import React.Types.Component (Orientation(..)) as Chrome
import System.Types.Connection
  ( ColorMode(..)
  , ConnectionMode(..)
  , InterpolateMode(..)
  , PanOnScrollMode(..)
  , PanelPosition(..)
  , SelectionMode(..)
  , ZIndexMode(..)
  )
import System.Types.Edge (AlignX(..), AlignY(..), ConnectionLineType(..), MarkerType(..))
import System.Types.Geometry (Position(..))
import System.Types.Handle (HandleType(..))
import System.Types.Node (Align(..))
import System.XYResizer
  ( ControlLinePosition(..)
  , ControlPosition(..)
  , CornerPosition(..)
  , ResizeControlDirection
  , ResizeControlVariant(..)
  )
-- Qualified for the same reason `Orientation` is: `ResizeControlDirection`'s
-- two constructors are spelled `Horizontal` and `Vertical` as well.
import System.XYResizer (ResizeControlDirection(..)) as Resizer

-- | Look a string up in a member table, or throw naming the field, the value
-- | and every member. `field` is the JS-facing prop path the value arrived on
-- | (`"connectionLineType"`, `"node.sourcePosition"`), so the message points at
-- | the consumer's own source rather than at ours.
fromEnumString :: forall a. String -> Array (Tuple String a) -> String -> a
fromEnumString field members value =
  case find (\m -> fst m == value) members of
    Just m -> snd m
    Nothing ->
      unsafeThrow $
        "ps-flow: " <> show value <> " is not a valid `" <> field
          <> "`. Expected one of: "
          <> intercalate ", " (map (show <<< fst) members)
          <> "."

-- ────────────────────────────────────────────────────────────────────────
-- Position — `@xyflow/system`, on `Node.sourcePosition`/`targetPosition`,
-- `Handle.position`, and the node props a custom component receives.
-- ────────────────────────────────────────────────────────────────────────

positionIn :: String -> String -> Position
positionIn field = fromEnumString field
  [ Tuple "left" PosLeft
  , Tuple "top" PosTop
  , Tuple "right" PosRight
  , Tuple "bottom" PosBottom
  ]

positionOut :: Position -> String
positionOut = case _ of
  PosLeft -> "left"
  PosTop -> "top"
  PosRight -> "right"
  PosBottom -> "bottom"

-- ────────────────────────────────────────────────────────────────────────
-- MarkerType — the `type` field of an `EdgeMarker`.
-- ────────────────────────────────────────────────────────────────────────

markerTypeIn :: String -> String -> MarkerType
markerTypeIn field = fromEnumString field
  [ Tuple "arrow" Arrow
  , Tuple "arrowclosed" ArrowClosed
  ]

markerTypeOut :: MarkerType -> String
markerTypeOut = case _ of
  Arrow -> "arrow"
  ArrowClosed -> "arrowclosed"

-- ────────────────────────────────────────────────────────────────────────
-- HandleType — on a node handle, and the string half of
-- `DefaultEdgeOptions.reconnectable`'s `boolean | HandleType`.
-- ────────────────────────────────────────────────────────────────────────

handleTypeIn :: String -> String -> HandleType
handleTypeIn field = fromEnumString field
  [ Tuple "source" Source
  , Tuple "target" Target
  ]

handleTypeOut :: HandleType -> String
handleTypeOut = case _ of
  Source -> "source"
  Target -> "target"

-- ────────────────────────────────────────────────────────────────────────
-- Inbound only — nothing in stage 1 hands one of these back out.
-- ────────────────────────────────────────────────────────────────────────

connectionModeIn :: String -> String -> ConnectionMode
connectionModeIn field = fromEnumString field
  [ Tuple "strict" Strict
  , Tuple "loose" Loose
  ]

connectionLineTypeIn :: String -> String -> ConnectionLineType
connectionLineTypeIn field = fromEnumString field
  [ Tuple "default" BezierLine
  , Tuple "straight" StraightLine
  , Tuple "step" StepLine
  , Tuple "smoothstep" SmoothStepLine
  , Tuple "simplebezier" SimpleBezierLine
  ]

-- | The way back out, which boundary stage 4 is the first thing to need:
-- | `connectionLineComponent` hands a consumer's own component the type the
-- | flow is drawing with. `Bezier` is `"default"` in this direction too.
connectionLineTypeOut :: ConnectionLineType -> String
connectionLineTypeOut = case _ of
  BezierLine -> "default"
  StraightLine -> "straight"
  StepLine -> "step"
  SmoothStepLine -> "smoothstep"
  SimpleBezierLine -> "simplebezier"

panOnScrollModeIn :: String -> String -> PanOnScrollMode
panOnScrollModeIn field = fromEnumString field
  [ Tuple "free" Free
  , Tuple "vertical" Vertical
  , Tuple "horizontal" Horizontal
  ]

selectionModeIn :: String -> String -> SelectionMode
selectionModeIn field = fromEnumString field
  [ Tuple "partial" Partial
  , Tuple "full" Full
  ]

-- | A string union upstream rather than an enum, so there is no runtime object
-- | for it and a consumer always writes the literal.
panelPositionIn :: String -> String -> PanelPosition
panelPositionIn field = fromEnumString field
  [ Tuple "top-left" TopLeft
  , Tuple "top-center" TopCenter
  , Tuple "top-right" TopRight
  , Tuple "bottom-left" BottomLeft
  , Tuple "bottom-center" BottomCenter
  , Tuple "bottom-right" BottomRight
  , Tuple "center-left" CenterLeft
  , Tuple "center-right" CenterRight
  ]

colorModeIn :: String -> String -> ColorMode
colorModeIn field = fromEnumString field
  [ Tuple "light" LightMode
  , Tuple "dark" DarkMode
  , Tuple "system" SystemMode
  ]

zIndexModeIn :: String -> String -> ZIndexMode
zIndexModeIn field = fromEnumString field
  [ Tuple "auto" ZAuto
  , Tuple "basic" ZBasic
  , Tuple "manual" ZManual
  ]

-- | `BackgroundVariant` — a TS enum, and the one that lives in
-- | `@xyflow/react` rather than `@xyflow/system`. `Boundary` publishes its
-- | runtime object; this is the codec for the string that object holds.
backgroundVariantIn :: String -> String -> BackgroundVariant
backgroundVariantIn field = fromEnumString field
  [ Tuple "lines" Lines
  , Tuple "dots" Dots
  , Tuple "cross" Cross
  ]

-- | `Controls.orientation`. A string union upstream, with no runtime object.
orientationIn :: String -> String -> Chrome.Orientation
orientationIn field = fromEnumString field
  [ Tuple "horizontal" Chrome.Horizontal
  , Tuple "vertical" Chrome.Vertical
  ]

-- | `NodeToolbar.align`. A string union upstream, with no runtime object —
-- | which is why upstream's own fixture writes the bare `'start'`.
alignIn :: String -> String -> Align
alignIn field = fromEnumString field
  [ Tuple "center" AlignCenter
  , Tuple "start" AlignStart
  , Tuple "end" AlignEnd
  ]

-- | `<EdgeToolbar alignX>` / `<EdgeToolbar alignY>`. Two axes and two string
-- | unions, deliberately not `alignIn`'s: the node toolbar aligns along one
-- | axis with `start`/`center`/`end`, and the edge toolbar names its ends by
-- | the side they are on. Sharing a codec between them would accept `"start"`
-- | for `alignX`, which upstream's `alignXToPercent` has no entry for.
alignXIn :: String -> String -> AlignX
alignXIn field = fromEnumString field
  [ Tuple "left" AlignXLeft
  , Tuple "center" AlignXCenter
  , Tuple "right" AlignXRight
  ]

alignYIn :: String -> String -> AlignY
alignYIn field = fromEnumString field
  [ Tuple "top" AlignYTop
  , Tuple "center" AlignYCenter
  , Tuple "bottom" AlignYBottom
  ]

-- | `FitViewOptions.interpolate`.
interpolateModeIn :: String -> String -> InterpolateMode
interpolateModeIn field = fromEnumString field
  [ Tuple "smooth" Smooth
  , Tuple "linear" Linear
  ]

-- | `<NodeResizeControl position>`. Upstream is one flat string union of eight
-- | members; ps-flow nests it as a line or a corner, so the flattening is this
-- | table and there is nothing else to it.
controlPositionIn :: String -> String -> ControlPosition
controlPositionIn field = fromEnumString field
  [ Tuple "top" (ControlLine LineTop)
  , Tuple "right" (ControlLine LineRight)
  , Tuple "bottom" (ControlLine LineBottom)
  , Tuple "left" (ControlLine LineLeft)
  , Tuple "top-left" (ControlCorner CornerTopLeft)
  , Tuple "top-right" (ControlCorner CornerTopRight)
  , Tuple "bottom-left" (ControlCorner CornerBottomLeft)
  , Tuple "bottom-right" (ControlCorner CornerBottomRight)
  ]

-- | `<NodeResizeControl variant>`. A TS enum, whose runtime object `Boundary`
-- | already publishes as `ResizeControlVariant`.
resizeControlVariantIn :: String -> String -> ResizeControlVariant
resizeControlVariantIn field = fromEnumString field
  [ Tuple "line" LineVariant
  , Tuple "handle" HandleVariant
  ]

-- | `<NodeResizeControl resizeDirection>`. A string union with no runtime
-- | object, and spelled the same as `Controls.orientation`'s two members
-- | without being it — which is why the constructors are qualified.
resizeDirectionIn :: String -> String -> ResizeControlDirection
resizeDirectionIn field = fromEnumString field
  [ Tuple "horizontal" Resizer.Horizontal
  , Tuple "vertical" Resizer.Vertical
  ]
