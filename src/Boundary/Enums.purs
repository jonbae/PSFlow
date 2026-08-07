-- | String literals in, sum-type constructors out — and back.
-- |
-- | Upstream's enums are TS enums, which are string-valued at runtime, and its
-- | unions are string literals. A JavaScript consumer writes `'left'` or
-- | `Position.Left`, which are the same value; they never write
-- | `PosLeft`, which is not reachable from JavaScript at all. `Boundary`
-- | publishes the runtime enum objects (`position`, `markerType`, …) so
-- | `Position.Left` resolves; this module is the other half — the codec that
-- | turns the string those objects hold into the PureScript constructor the
-- | internals are written against, and back out again.
-- |
-- | **A string that is not a member throws.** Upstream would fall through its
-- | `switch` and render something arbitrary; here it is a consumer error with
-- | a cheap, exact signature, and the alternative — picking a default — is the
-- | silent-`Nothing` failure this whole effort exists to remove. The message
-- | names the field, the value and the members, because a caller who typo'd
-- | `'smoothStep'` needs to see `'smoothstep'`.
-- |
-- | The string values are upstream's verbatim. Two are worth reading twice:
-- | `ConnectionLineType.Bezier` is `"default"`, not `"bezier"`, and
-- | `MarkerType.ArrowClosed` is `"arrowclosed"`, all lowercase.
module Boundary.Enums
  ( fromEnumString
  , colorModeIn
  , colorModeOut
  , connectionLineTypeIn
  , connectionLineTypeOut
  , connectionModeIn
  , connectionModeOut
  , handleTypeIn
  , handleTypeOut
  , interpolateModeIn
  , interpolateModeOut
  , markerTypeIn
  , markerTypeOut
  , panOnScrollModeIn
  , panOnScrollModeOut
  , panelPositionIn
  , panelPositionOut
  , positionIn
  , positionOut
  , selectionModeIn
  , selectionModeOut
  , zIndexModeIn
  , zIndexModeOut
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

-- | The outbound half. Total by construction: the constructor list is closed,
-- | so the compiler catches a member added upstream and mirrored into the sum
-- | type but forgotten here.
toEnumString :: forall a. Eq a => Array (Tuple String a) -> a -> String
toEnumString members value =
  case find (\m -> snd m == value) members of
    Just m -> fst m
    Nothing ->
      -- Unreachable while the table below names every constructor, which the
      -- inbound direction's `case` exhaustiveness check enforces.
      unsafeThrow "ps-flow: internal error — enum member missing from its table."

-- ────────────────────────────────────────────────────────────────────────
-- Position — `@xyflow/system`, on `Node.sourcePosition`/`targetPosition`,
-- `Handle.position`, and the node props a custom component receives.
-- ────────────────────────────────────────────────────────────────────────

positionMembers :: Array (Tuple String Position)
positionMembers =
  [ Tuple "left" PosLeft
  , Tuple "top" PosTop
  , Tuple "right" PosRight
  , Tuple "bottom" PosBottom
  ]

positionIn :: String -> String -> Position
positionIn field = fromEnumString field positionMembers

positionOut :: Position -> String
positionOut = toEnumString positionMembers

-- ────────────────────────────────────────────────────────────────────────
-- MarkerType — the `type` field of an `EdgeMarker`.
-- ────────────────────────────────────────────────────────────────────────

markerTypeMembers :: Array (Tuple String MarkerType)
markerTypeMembers =
  [ Tuple "arrow" Arrow
  , Tuple "arrowclosed" ArrowClosed
  ]

markerTypeIn :: String -> String -> MarkerType
markerTypeIn field = fromEnumString field markerTypeMembers

markerTypeOut :: MarkerType -> String
markerTypeOut = toEnumString markerTypeMembers

-- ────────────────────────────────────────────────────────────────────────
-- ConnectionMode
-- ────────────────────────────────────────────────────────────────────────

connectionModeMembers :: Array (Tuple String ConnectionMode)
connectionModeMembers =
  [ Tuple "strict" Strict
  , Tuple "loose" Loose
  ]

connectionModeIn :: String -> String -> ConnectionMode
connectionModeIn field = fromEnumString field connectionModeMembers

connectionModeOut :: ConnectionMode -> String
connectionModeOut = toEnumString connectionModeMembers

-- ────────────────────────────────────────────────────────────────────────
-- ConnectionLineType. `Bezier` is `"default"`, and that is upstream's, not a
-- transcription slip.
-- ────────────────────────────────────────────────────────────────────────

connectionLineTypeMembers :: Array (Tuple String ConnectionLineType)
connectionLineTypeMembers =
  [ Tuple "default" BezierLine
  , Tuple "straight" StraightLine
  , Tuple "step" StepLine
  , Tuple "smoothstep" SmoothStepLine
  , Tuple "simplebezier" SimpleBezierLine
  ]

connectionLineTypeIn :: String -> String -> ConnectionLineType
connectionLineTypeIn field = fromEnumString field connectionLineTypeMembers

connectionLineTypeOut :: ConnectionLineType -> String
connectionLineTypeOut = toEnumString connectionLineTypeMembers

-- ────────────────────────────────────────────────────────────────────────
-- PanOnScrollMode
-- ────────────────────────────────────────────────────────────────────────

panOnScrollModeMembers :: Array (Tuple String PanOnScrollMode)
panOnScrollModeMembers =
  [ Tuple "free" Free
  , Tuple "vertical" Vertical
  , Tuple "horizontal" Horizontal
  ]

panOnScrollModeIn :: String -> String -> PanOnScrollMode
panOnScrollModeIn field = fromEnumString field panOnScrollModeMembers

panOnScrollModeOut :: PanOnScrollMode -> String
panOnScrollModeOut = toEnumString panOnScrollModeMembers

-- ────────────────────────────────────────────────────────────────────────
-- SelectionMode
-- ────────────────────────────────────────────────────────────────────────

selectionModeMembers :: Array (Tuple String SelectionMode)
selectionModeMembers =
  [ Tuple "partial" Partial
  , Tuple "full" Full
  ]

selectionModeIn :: String -> String -> SelectionMode
selectionModeIn field = fromEnumString field selectionModeMembers

selectionModeOut :: SelectionMode -> String
selectionModeOut = toEnumString selectionModeMembers

-- ────────────────────────────────────────────────────────────────────────
-- PanelPosition — a string union upstream, not an enum, so there is no
-- runtime object for it and a consumer always writes the literal.
-- ────────────────────────────────────────────────────────────────────────

panelPositionMembers :: Array (Tuple String PanelPosition)
panelPositionMembers =
  [ Tuple "top-left" TopLeft
  , Tuple "top-center" TopCenter
  , Tuple "top-right" TopRight
  , Tuple "bottom-left" BottomLeft
  , Tuple "bottom-center" BottomCenter
  , Tuple "bottom-right" BottomRight
  , Tuple "center-left" CenterLeft
  , Tuple "center-right" CenterRight
  ]

panelPositionIn :: String -> String -> PanelPosition
panelPositionIn field = fromEnumString field panelPositionMembers

panelPositionOut :: PanelPosition -> String
panelPositionOut = toEnumString panelPositionMembers

-- ────────────────────────────────────────────────────────────────────────
-- ColorMode
-- ────────────────────────────────────────────────────────────────────────

colorModeMembers :: Array (Tuple String ColorMode)
colorModeMembers =
  [ Tuple "light" LightMode
  , Tuple "dark" DarkMode
  , Tuple "system" SystemMode
  ]

colorModeIn :: String -> String -> ColorMode
colorModeIn field = fromEnumString field colorModeMembers

colorModeOut :: ColorMode -> String
colorModeOut = toEnumString colorModeMembers

-- ────────────────────────────────────────────────────────────────────────
-- ZIndexMode
-- ────────────────────────────────────────────────────────────────────────

zIndexModeMembers :: Array (Tuple String ZIndexMode)
zIndexModeMembers =
  [ Tuple "auto" ZAuto
  , Tuple "basic" ZBasic
  , Tuple "manual" ZManual
  ]

zIndexModeIn :: String -> String -> ZIndexMode
zIndexModeIn field = fromEnumString field zIndexModeMembers

zIndexModeOut :: ZIndexMode -> String
zIndexModeOut = toEnumString zIndexModeMembers

-- ────────────────────────────────────────────────────────────────────────
-- InterpolateMode — `FitViewOptions.interpolate`.
-- ────────────────────────────────────────────────────────────────────────

interpolateModeMembers :: Array (Tuple String InterpolateMode)
interpolateModeMembers =
  [ Tuple "smooth" Smooth
  , Tuple "linear" Linear
  ]

interpolateModeIn :: String -> String -> InterpolateMode
interpolateModeIn field = fromEnumString field interpolateModeMembers

interpolateModeOut :: InterpolateMode -> String
interpolateModeOut = toEnumString interpolateModeMembers

-- ────────────────────────────────────────────────────────────────────────
-- HandleType — the string half of `Edge.reconnectable`'s
-- `boolean | HandleType`.
-- ────────────────────────────────────────────────────────────────────────

handleTypeMembers :: Array (Tuple String HandleType)
handleTypeMembers =
  [ Tuple "source" Source
  , Tuple "target" Target
  ]

handleTypeIn :: String -> String -> HandleType
handleTypeIn field = fromEnumString field handleTypeMembers

handleTypeOut :: HandleType -> String
handleTypeOut = toEnumString handleTypeMembers
