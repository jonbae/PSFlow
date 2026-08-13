-- | The `<EdgeText />` helper. Renders the measured label group used inside
-- | `<BaseEdge />`, mirroring
-- | `xyflow-main/packages/react/src/components/Edges/EdgeText.tsx`.
-- |
-- | `labelBgPadding` remains `{ x, y }` (matching PSFlow's existing
-- | `EdgeTextProps` scaffold) rather than TS's `[number, number]`.
module React.Edge.Text
  ( edgeText
  ) where

import Prelude

import Data.Foldable (for_)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (Nullable, toMaybe, toNullable)
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Basic (JSX, ReactComponent)
import React.Basic.Hooks (reactComponent, readRef, useEffect, useRef, useState)
import React.Basic.Hooks as React
import React.FFI.DOM (g_, opt, rect_, text_, textContent)
import React.Types.Edges (EdgeTextProps)

defaultPadding :: { x :: Number, y :: Number }
defaultPadding = { x: 2.0, y: 4.0 }

type TextBBox =
  { x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  }

initialBBox :: TextBBox
initialBBox = { x: 1.0, y: 0.0, width: 0.0, height: 0.0 }

foreign import measureText :: Foreign -> Effect TextBBox

edgeText :: ReactComponent EdgeTextProps
edgeText = unsafePerformEffect $ reactComponent "EdgeText" \(props :: EdgeTextProps) -> React.do
  bbox /\ setBBox <- useState initialBBox
  textRef <- useRef (toNullable Nothing :: Nullable Foreign)

  useEffect props.label do
    mText <- toMaybe <$> readRef textRef
    for_ mText \text -> do
      measured <- measureText text
      setBBox (const measured)
    pure (pure unit)

  pure case props.label of
    Nothing -> mempty
    Just lbl ->
      let
        pad = fromMaybe defaultPadding props.labelBgPadding
        showBg = fromMaybe true props.labelShowBg
        bgRadius = fromMaybe 2.0 props.labelBgBorderRadius
        transform =
          "translate("
            <> show (props.x - bbox.width / 2.0)
            <> " "
            <> show (props.y - bbox.height / 2.0)
            <> ")"
        bg :: JSX
        bg
          | showBg = rect_
              { x: -pad.x
              , y: -pad.y
              , width: bbox.width + 2.0 * pad.x
              , height: bbox.height + 2.0 * pad.y
              , className: "react-flow__edge-textbg"
              , style: opt props.labelBgStyle
              , rx: bgRadius
              , ry: bgRadius
              }
              []
          | otherwise = mempty
        labelText :: JSX
        labelText = text_
          { className: "react-flow__edge-text"
          , y: bbox.height / 2.0
          , dy: "0.3em"
          , ref: textRef
          , style: opt props.labelStyle
          }
          [ textContent lbl ]
      in
        g_
          { transform
          , className: "react-flow__edge-textwrapper"
          , visibility: if bbox.width == 0.0 then "hidden" else "visible"
          }
          [ bg, labelText ]
