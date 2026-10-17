-- | `<Panel />` — the nine-position overlay div used by Controls,
-- | MiniMap, Attribution, and any user-supplied UI panel. Mirrors
-- | `xyflow/packages/react/src/components/Panel/index.tsx`.
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
        -- Upstream's `cc(['react-flow__panel', className, ...positionClasses])`:
        -- the caller's class goes before the position, and an empty one is
        -- skipped.
        userClass = fromMaybe "" props.className
        className = "react-flow__panel"
          <> (if userClass == "" then "" else " " <> userClass)
          <> " "
          <> panelPositionClasses props.position
      in
        pure $ div_
          { className
          , style: opt props.style
          , "aria-label": opt props."aria-label"
          , "data-testid": opt props."data-testid"
          , "data-message": opt props."data-message"
          -- Straight through, `null` included: React reads a null ref as no
          -- ref, which is exactly what the caller who passed none meant.
          , ref: props.innerRef
          }
          (reactChildrenToArray props.children)
