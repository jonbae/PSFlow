-- | `<Panel />` — the nine-position overlay div used by Controls,
-- | MiniMap, Attribution, and any user-supplied UI panel. Mirrors
-- | `xyflow-main/packages/react/src/components/Panel/index.tsx`.
-- |
-- | Despite living under `React.Portal.*` (where it's grouped with the
-- | true portal components), Panel is not a React portal — it is a
-- | regular `<div>` with absolute positioning. The grouping comes from
-- | the TS source, where Panel sits next to EdgeLabelRenderer and
-- | ViewportPortal as one of the "overlay primitives".
module React.Portal.Panel
  ( panel
  , panelPositionClasses
  ) where

import Prelude

import Data.Maybe (fromMaybe)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Hooks (memo, reactChildrenToArray, reactComponentWithChildren)
import React.FFI.DOM (div_, opt)
import React.Types.Component (PanelProps)
import System.Types.Connection (PanelPosition(..))

panelPositionClasses :: PanelPosition -> String
panelPositionClasses = case _ of
  TopLeft -> "top left"
  TopCenter -> "top center"
  TopRight -> "top right"
  BottomLeft -> "bottom left"
  BottomCenter -> "bottom center"
  BottomRight -> "bottom right"
  CenterLeft -> "center left"
  CenterRight -> "center right"

panel :: ReactComponent PanelProps
panel =
  unsafePerformEffect $ memo $ reactComponentWithChildren "Panel"
    \(props :: PanelProps) ->
      let
        userClass = fromMaybe "" props.className
        className = "react-flow__panel " <> panelPositionClasses props.position
          <> (if userClass == "" then "" else " " <> userClass)
      in
        pure $ div_
          { className
          , style: opt props.style
          , "aria-label": opt props."aria-label"
          , "data-testid": opt props."data-testid"
          -- Straight through, `null` included: React reads a null ref as no
          -- ref, which is exactly what the caller who passed none meant.
          , ref: props.innerRef
          }
          (reactChildrenToArray props.children)
