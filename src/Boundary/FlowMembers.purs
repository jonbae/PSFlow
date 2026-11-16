-- | The two converters `Boundary.Flow` shares with `Boundary.Store`, which
-- | reads the same members off the store state: `ariaLabelConfig` and
-- | `panOnDrag`. They live here so that `Boundary.Flow` can read the store's
-- | JavaScript view without the two modules importing each other.
module Boundary.FlowMembers
  ( JsAriaLabelConfig
  , ariaLabelConfigIn
  , panOnDragIn
  ) where

import Prelude

import Boundary.Undefined (Undefinable, fromUndefinable)
import Boundary.Untagged (asArray, asBoolean, asNumber, typeName)
import Data.Array.NonEmpty (fromArray) as NEA
import Data.Int (round) as Int
import Data.Maybe (Maybe(..))
import Effect.Exception.Unsafe (unsafeThrow)
import Foreign (Foreign)
import System.Constants (AriaLabelConfigOverride)
import System.Types.PanZoom (PanOnDrag(..))

-- | Upstream keys this record by dotted path — `'node.a11yDescription.default'`
-- | — and PureScript renamed them to camelCase identifiers. Nothing else on
-- | this surface renames a key that a consumer writes as a literal, so this is
-- | the one place where getting the crossing wrong is invisible: every key
-- | would simply miss, and every label would silently stay at its default.
type JsAriaLabelConfig =
  { "node.a11yDescription.default" :: Undefinable String
  , "node.a11yDescription.keyboardDisabled" :: Undefinable String
  , "node.a11yDescription.ariaLiveMessage" ::
      Undefinable ({ direction :: String, x :: Number, y :: Number } -> String)
  , "edge.a11yDescription.default" :: Undefinable String
  , "controls.ariaLabel" :: Undefinable String
  , "controls.zoomIn.ariaLabel" :: Undefinable String
  , "controls.zoomOut.ariaLabel" :: Undefinable String
  , "controls.fitView.ariaLabel" :: Undefinable String
  , "controls.interactive.ariaLabel" :: Undefinable String
  , "minimap.ariaLabel" :: Undefinable String
  , "handle.ariaLabel" :: Undefinable String
  }

-- | `boolean | number[]` — `true` pans on every button, an array names the
-- | mouse buttons that pan, and an empty array names none, which is `false`.
panOnDragIn :: Foreign -> PanOnDrag
panOnDragIn raw = case asBoolean raw of
  Just true -> PanAlways
  Just false -> NoPan
  Nothing -> case asArray raw of
    Just buttons ->
      case NEA.fromArray (map readButton buttons) of
        Just nea -> PanOnButtons nea
        Nothing -> NoPan
    Nothing ->
      unsafeThrow $
        "ps-flow: `panOnDrag` must be a boolean or an array of mouse-button "
          <> "numbers, got "
          <> typeName raw
          <> "."
  where
  readButton b = case asNumber b of
    Just n -> Int.round n
    Nothing ->
      unsafeThrow $
        "ps-flow: every entry of `panOnDrag` must be a mouse-button number, got "
          <> typeName b
          <> "."

ariaLabelConfigIn :: JsAriaLabelConfig -> AriaLabelConfigOverride
ariaLabelConfigIn c =
  { nodeA11yDescriptionDefault: fromUndefinable c."node.a11yDescription.default"
  , nodeA11yDescriptionKeyboardDisabled:
      fromUndefinable c."node.a11yDescription.keyboardDisabled"
  , nodeA11yDescriptionAriaLiveMessage:
      fromUndefinable c."node.a11yDescription.ariaLiveMessage"
  , edgeA11yDescriptionDefault: fromUndefinable c."edge.a11yDescription.default"
  , controlsAriaLabel: fromUndefinable c."controls.ariaLabel"
  , controlsZoomInAriaLabel: fromUndefinable c."controls.zoomIn.ariaLabel"
  , controlsZoomOutAriaLabel: fromUndefinable c."controls.zoomOut.ariaLabel"
  , controlsFitViewAriaLabel: fromUndefinable c."controls.fitView.ariaLabel"
  , controlsInteractiveAriaLabel: fromUndefinable c."controls.interactive.ariaLabel"
  , minimapAriaLabel: fromUndefinable c."minimap.ariaLabel"
  , handleAriaLabel: fromUndefinable c."handle.ariaLabel"
  }
