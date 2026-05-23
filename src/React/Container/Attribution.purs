-- | `<Attribution />` — the small "React Flow" link panel in the bottom
-- | corner. Suppressed via `proOptions.hideAttribution`. Mirrors
-- | `xyflow-main/packages/react/src/components/Attribution/index.tsx`.
-- |
-- | **PS divergence: inline panel positioning.** The TS source delegates
-- | to `<Panel position={...}>`. The `<Panel>` component itself lands in
-- | a later ticket (045); we inline its positioning logic here as a
-- | `panelPositionClasses` helper since Attribution is the only consumer
-- | at this stage.
module React.Container.Attribution
  ( attribution
  ) where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactComponent)
import React.Basic.Hooks (reactComponent)
import React.FFI.DOM (div_, textContent)
import React.Types.Component (AttributionProps)
import System.Types.Connection
  ( PanelPosition(..)
  )

-- | Render a single `<a>` child without pulling in another FFI binding —
-- | we don't already expose `<a>` from `React.FFI.DOM`, and adding it
-- | for one call site isn't justified. Use a local FFI.
foreign import a_ :: forall p. Record p -> Array JSX -> JSX

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

attribution :: ReactComponent AttributionProps
attribution =
  unsafePerformEffect $ reactComponent "Attribution" \(props :: AttributionProps) ->
    let
      hidden = case props.proOptions of
        Just po -> po.hideAttribution
        Nothing -> false
    in
      if hidden then pure mempty
      else
        let
          pos = fromMaybe BottomRight props.position
          className = "react-flow__panel react-flow__attribution "
            <> panelPositionClasses pos
        in
          pure $ div_
            { className
            , "data-message":
                "Please only hide this attribution when you are subscribed to React Flow Pro: https://pro.reactflow.dev"
            }
            [ a_
                { href: "https://reactflow.dev"
                , target: "_blank"
                , rel: "noopener noreferrer"
                , "aria-label": "React Flow attribution"
                }
                [ textContent "React Flow" ]
            ]

