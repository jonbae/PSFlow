-- | The `<EdgeText />` helper. Renders the label group used inside
-- | `<BaseEdge />`. Mirrors
-- | `xyflow-main/packages/react/src/components/Edges/EdgeText.tsx`.
-- |
-- | Differences from TS:
-- |   * Bbox measurement is omitted — the TS source measures the rendered
-- |     `<text>` via `getBBox()` after mount to size the background
-- |     `<rect>`. Replicating that requires a `useRef`/`useEffect` cycle
-- |     against an SVG node, which we keep out of this initial port. The
-- |     rect is sized off `labelBgPadding` only; this is visually close
-- |     enough for static labels and matches the TS branch when bbox
-- |     measurement has not yet run (bbox = `{0,0}`).
-- |   * `labelBgPadding` here is `{ x, y }` (matching the existing
-- |     `EdgeTextProps` scaffold) rather than TS's `[number, number]`.
module React.Edge.Text
  ( edgeText
  ) where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactComponent)
import React.Basic.Hooks (reactComponent)
import React.FFI.DOM (g_, opt, rect_, text_, textContent)
import React.Types.Edges (EdgeTextProps)

defaultPadding :: { x :: Number, y :: Number }
defaultPadding = { x: 2.0, y: 4.0 }

edgeText :: ReactComponent EdgeTextProps
edgeText = unsafePerformEffect $ reactComponent "EdgeText" \(props :: EdgeTextProps) ->
  pure case props.label of
    Nothing -> mempty
    Just lbl ->
      let
        pad = fromMaybe defaultPadding props.labelBgPadding
        showBg = fromMaybe true props.labelShowBg
        bgRadius = fromMaybe 2.0 props.labelBgBorderRadius
        transform =
          "translate("
            <> show props.x
            <> " "
            <> show props.y
            <> ")"
        bg :: JSX
        bg
          | showBg = rect_
              { x: -pad.x
              , y: -pad.y
              , width: 2.0 * pad.x
              , height: 2.0 * pad.y
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
          , dy: "0.3em"
          , style: opt props.labelStyle
          }
          [ textContent lbl ]
      in
        g_
          { transform
          , className: "react-flow__edge-textwrapper"
          , visibility: "visible"
          }
          [ bg, labelText ]
