-- | Pattern child components for `<Background />`. Mirrors
-- | `xyflow-main/packages/react/src/additional-components/Background/Patterns.tsx`.
module React.Additional.Background.Patterns
  ( linePattern
  , dotPattern
  ) where

import Prelude

import Data.Maybe (fromMaybe)
import Data.Number.Format (toString) as NumberFormat
import Data.Tuple (Tuple(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Hooks (reactComponent)
import React.FFI.DOM (circle_, path_)
import React.Types.Component (BackgroundVariant(..), DotPatternProps, LinePatternProps)

showN :: Number -> String
showN = NumberFormat.toString

variantClass :: BackgroundVariant -> String
variantClass = case _ of
  Lines -> "lines"
  Dots -> "dots"
  Cross -> "cross"

linePattern :: ReactComponent LinePatternProps
linePattern =
  unsafePerformEffect $ reactComponent "LinePattern"
    \(props :: LinePatternProps) ->
      let
        Tuple w h = props.dimensions
        d = "M" <> showN (w / 2.0) <> " 0 V" <> showN h
          <> " M0 " <> showN (h / 2.0) <> " H" <> showN w
        userClass = fromMaybe "" props.className
        className = "react-flow__background-pattern " <> variantClass props.variant
          <> (if userClass == "" then "" else " " <> userClass)
      in
        pure $ path_
          { strokeWidth: fromMaybe 1.0 props.lineWidth
          , d
          , className
          }
          []

dotPattern :: ReactComponent DotPatternProps
dotPattern =
  unsafePerformEffect $ reactComponent "DotPattern"
    \(props :: DotPatternProps) ->
      let
        userClass = fromMaybe "" props.className
        className = "react-flow__background-pattern dots"
          <> (if userClass == "" then "" else " " <> userClass)
      in
        pure $ circle_
          { cx: props.radius
          , cy: props.radius
          , r: props.radius
          , className
          }
          []
