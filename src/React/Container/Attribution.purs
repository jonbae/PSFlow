-- | `<Attribution />` — the small "React Flow" link panel in the bottom
-- | corner. Suppressed via `proOptions.hideAttribution`. Mirrors
-- | `xyflow-main/packages/react/src/components/Attribution/index.tsx`.
module React.Container.Attribution
  ( attribution
  ) where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (null)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (reactChildrenFromArray, reactComponent)
import React.FFI.DOM (span_, textContent)
import React.Portal.Panel (panel)
import React.Types.Component (AttributionProps)
import System.Types.Connection (PanelPosition(..))

-- | Render a single `<a>` child without pulling in another FFI binding —
-- | we don't already expose `<a>` from `React.FFI.DOM`, and adding it
-- | for one call site isn't justified. Use a local FFI.
foreign import a_ :: forall p. Record p -> Array JSX -> JSX

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
          link = a_
            { href: "https://reactflow.dev"
            , target: "_blank"
            , rel: "noopener noreferrer"
            , "aria-label": "React Flow attribution"
            }
            [ textContent "React Flow" ]
          messageWrap = span_
            { "data-message":
                "Please only hide this attribution when you are subscribed to React Flow Pro: https://pro.reactflow.dev"
            }
            [ link ]
        in
          pure $ element panel
            { position: pos
            , className: Just "react-flow__attribution"
            , style: Nothing
            , "aria-label": Nothing
            , "data-testid": Nothing
            , children: reactChildrenFromArray [ messageWrap ]
            , innerRef: null
            }
