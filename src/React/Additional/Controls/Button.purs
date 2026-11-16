-- | `<ControlButton />` — the styled `<button>` rendered for each
-- | built-in control (zoom in/out, fit view, lock) and available to
-- | consumers wanting to add their own buttons inside `<Controls />`.
-- | Mirrors `xyflow/.../Controls/ControlButton.tsx`.
module React.Additional.Controls.Button
  ( controlButton
  ) where

import Prelude

import Data.Maybe (fromMaybe)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Hooks (memo, reactChildrenToArray, reactComponentWithChildren)
import Foreign (unsafeToForeign)
import React.FFI.DOM (button_, opt, spreadOver)
import React.Types.Component (ControlButtonProps)

controlButton :: ReactComponent ControlButtonProps
controlButton =
  unsafePerformEffect $ memo $ reactComponentWithChildren "ControlButton"
    \(props :: ControlButtonProps) ->
      let
        userClass = fromMaybe "" props.className
        className = "react-flow__controls-button"
          <> (if userClass == "" then "" else " " <> userClass)
      in
        -- TS `<button type="button" className={…} {...rest}>`: the rest
        -- comes last, so a consumer's own `type` replaces `"button"`.
        pure $ button_
          ( spreadOver (map unsafeToForeign props.restAttributes)
              { type: "button"
              , className
              , onClick: opt props.onClick
              , disabled: opt props.disabled
              , title: opt props.title
              , "aria-label": opt props."aria-label"
              , style: opt props.style
              }
          )
          (reactChildrenToArray props.children)
