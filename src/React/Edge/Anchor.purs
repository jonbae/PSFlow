-- | `<EdgeAnchor />` — the invisible reconnect-handle circle drawn at
-- | each endpoint of a selected edge. Mirrors
-- | `xyflow-main/packages/react/src/components/Edges/EdgeAnchor.tsx`.
-- |
-- | Used by the (future) `EdgeUpdateAnchors` component (ticket 036). The
-- | circle is offset along the handle's axis by `radius` so the
-- | click-target sits *outside* the node, where the edge is
-- | reconnectable.
module React.Edge.Anchor
  ( EdgeAnchorProps
  , edgeAnchor
  ) where

import Prelude

import Data.Maybe (Maybe, fromMaybe)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Events (EventHandler)
import React.Basic.Hooks (reactComponent)
import React.FFI.DOM (circle_)
import System.Types.Geometry (Position(..))

type EdgeAnchorProps =
  { position :: Position
  , centerX :: Number
  , centerY :: Number
  , radius :: Maybe Number
  , onMouseDown :: EventHandler
  , onMouseEnter :: EventHandler
  , onMouseOut :: EventHandler
  , type :: String
  }

shiftX :: Number -> Number -> Position -> Number
shiftX x shift = case _ of
  PosLeft -> x - shift
  PosRight -> x + shift
  _ -> x

shiftY :: Number -> Number -> Position -> Number
shiftY y shift = case _ of
  PosTop -> y - shift
  PosBottom -> y + shift
  _ -> y

edgeAnchor :: ReactComponent EdgeAnchorProps
edgeAnchor = unsafePerformEffect $ reactComponent "EdgeAnchor" \(props :: EdgeAnchorProps) ->
  pure $
    let
      r = fromMaybe 10.0 props.radius
    in
      circle_
        { onMouseDown: props.onMouseDown
        , onMouseEnter: props.onMouseEnter
        , onMouseOut: props.onMouseOut
        , className: "react-flow__edgeupdater react-flow__edgeupdater-" <> props.type
        , cx: shiftX props.centerX r props.position
        , cy: shiftY props.centerY r props.position
        , r
        , stroke: "transparent"
        , fill: "transparent"
        }
        []
