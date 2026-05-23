-- | `<Background />` add-on. Renders a tiled SVG pattern (lines, dots,
-- | or cross) that pans/zooms with the viewport. Mirrors
-- | `xyflow-main/packages/react/src/additional-components/Background/Background.tsx`.
module React.Additional.Background
  ( background
  , module React.Types.Component
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Foldable (foldl)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Newtype (class Newtype)
import Data.Number (floor) as Number
import Data.Number.Format (toString) as NumberFormat
import Data.Tuple (Tuple(..))
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object as Object
import React.Basic (ReactComponent, element)
import React.Basic.Hooks (memo, reactComponent)
import React.Basic.Hooks as React
import React.Additional.Background.Patterns (dotPattern, linePattern)
import React.FFI.DOM (defs_, pattern_, rect_, svg_)
import React.Hook.Store (useStore)
import React.Types.Component (BackgroundProps, BackgroundVariant(..))
import React.Types.Store (ReactFlowState)
import System.Types.Geometry (Transform(..))
import Unsafe.Coerce (unsafeCoerce)

showN :: Number -> String
showN = NumberFormat.toString

defaultSize :: BackgroundVariant -> Number
defaultSize = case _ of
  Dots -> 1.0
  Lines -> 1.0
  Cross -> 6.0

normalisePair :: Either Number (Tuple Number Number) -> Tuple Number Number
normalisePair = case _ of
  Left n -> Tuple n n
  Right t -> t

-- | Selector slice with derived `Eq` (Transform already derives Eq).
newtype BgSlice = BgSlice { transform :: Transform, patternId :: String }

derive instance newtypeBgSlice :: Newtype BgSlice _
derive newtype instance eqBgSlice :: Eq BgSlice

selector :: forall n e. ReactFlowState n e -> BgSlice
selector s = BgSlice
  { transform: s.transform
  , patternId: "pattern-" <> s.rfId
  }

modN :: Number -> Number -> Number
modN x y = x - y * Number.floor (x / y)

toForeignStyle :: Object String -> Foreign
toForeignStyle = unsafeCoerce

containerStyle :: Object String
containerStyle = Object.fromFoldable
  [ Tuple "position" "absolute"
  , Tuple "top" "0"
  , Tuple "left" "0"
  , Tuple "width" "100%"
  , Tuple "height" "100%"
  ]

buildStyle
  :: Maybe (Object String)
  -> Maybe String
  -> Maybe String
  -> Foreign
buildStyle userStyle bgColor patternColor =
  toForeignStyle merged
  where
  base = fromMaybe Object.empty userStyle
  withContainer = foldl (\acc (Tuple k v) -> Object.insert k v acc) base
    (Object.toUnfoldable containerStyle :: Array (Tuple String String))
  withBg = case bgColor of
    Nothing -> withContainer
    Just c -> Object.insert "--xy-background-color-props" c withContainer
  merged = case patternColor of
    Nothing -> withBg
    Just c -> Object.insert "--xy-background-pattern-color-props" c withBg

background :: ReactComponent BackgroundProps
background =
  unsafePerformEffect $ memo $ reactComponent "Background"
    \(props :: BackgroundProps) -> React.do
      BgSlice slice <- useStore selector
      let
        Transform t = slice.transform
        variant = fromMaybe Dots props.variant
        patternSize = fromMaybe (defaultSize variant) props.size
        isDots = variant == Dots
        isCross = variant == Cross
        Tuple gapX gapY = normalisePair (fromMaybe (Left 20.0) props.gap)
        scaledGapXRaw = gapX * t.scale
        scaledGapYRaw = gapY * t.scale
        scaledGapX = if scaledGapXRaw == 0.0 then 1.0 else scaledGapXRaw
        scaledGapY = if scaledGapYRaw == 0.0 then 1.0 else scaledGapYRaw
        scaledSize = patternSize * t.scale
        Tuple offX offY = normalisePair (fromMaybe (Left 0.0) props.offset)
        Tuple patDimX patDimY =
          if isCross then Tuple scaledSize scaledSize
          else Tuple scaledGapX scaledGapY
        offXScaled = offX * t.scale
        offYScaled = offY * t.scale
        scaledOffX = if offXScaled == 0.0 then 1.0 + patDimX / 2.0 else offXScaled
        scaledOffY = if offYScaled == 0.0 then 1.0 + patDimY / 2.0 else offYScaled
        patternIdResolved = slice.patternId <> fromMaybe "" props.id
        userClass = fromMaybe "" props.className
        className = "react-flow__background"
          <> (if userClass == "" then "" else " " <> userClass)
        patternX = modN t.tx scaledGapX
        patternY = modN t.ty scaledGapY
        patTransform = "translate(-" <> showN scaledOffX <> ",-" <> showN scaledOffY <> ")"
        innerPattern =
          if isDots then element dotPattern
            { radius: scaledSize / 2.0
            , className: props.patternClassName
            }
          else element linePattern
            { dimensions: Tuple patDimX patDimY
            , lineWidth: props.lineWidth
            , variant
            , className: props.patternClassName
            }
      pure $ svg_
        { className
        , style: buildStyle props.style props.bgColor props.color
        , "data-testid": "rf__background"
        }
        [ defs_ {}
            [ pattern_
                { id: patternIdResolved
                , x: patternX
                , y: patternY
                , width: scaledGapX
                , height: scaledGapY
                , patternUnits: "userSpaceOnUse"
                , patternTransform: patTransform
                }
                [ innerPattern ]
            ]
        , rect_
            { x: "0"
            , y: "0"
            , width: "100%"
            , height: "100%"
            , fill: "url(#" <> patternIdResolved <> ")"
            }
            []
        ]
