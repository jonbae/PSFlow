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
-- | leaves: `Position` on node props and node handles, `MarkerType` on an edge
-- | marker, `HandleType` on a node handle. The rest are inbound-only in stage
-- | 1, and an unused outbound codec is a converter nobody has been able to get
-- | wrong yet. The three that do exist are written as `case` expressions
-- | rather than as lookups in the member table below, so that a constructor
-- | added to one of those sum types fails the build instead of throwing on the
-- | first value that reaches it.
-- |
-- | The string values are upstream's verbatim. Two are worth reading twice:
-- | `ConnectionLineType.Bezier` is `"default"`, not `"bezier"`, and
-- | `MarkerType.ArrowClosed` is `"arrowclosed"`, all lowercase.
module Boundary.Enums
  ( backgroundVariantIn
  , colorModeIn
  , connectionLineTypeIn
  , connectionModeIn
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
  , selectionModeIn
  , zIndexModeIn
  ) where

import Prelude

import Data.Array (find)
import Data.Foldable (intercalate)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..), fst, snd)
import Effect.Exception.Unsafe (unsafeThrow)
import System.Types.Connection
  ( ColorMode(..)
  , ConnectionMode(..)
  , InterpolateMode(..)
  , PanOnScrollMode(..)
  , PanelPosition(..)
  , SelectionMode(..)
  , ZIndexMode(..)
  )
import React.Types.Component (BackgroundVariant(..))
-- Qualified: `Orientation`'s two constructors are spelled the same as two of
-- `PanOnScrollMode`'s, and both codecs live in this module.
import React.Types.Component (Orientation(..)) as Chrome
import System.Types.Edge (ConnectionLineType(..), MarkerType(..))
import System.Types.Geometry (Position(..))
import System.Types.Handle (HandleType(..))

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

-- | `FitViewOptions.interpolate`.
interpolateModeIn :: String -> String -> InterpolateMode
interpolateModeIn field = fromEnumString field
  [ Tuple "smooth" Smooth
  , Tuple "linear" Linear
  ]
