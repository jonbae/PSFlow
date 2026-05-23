-- | `<ControlButton />` — the styled `<button>` rendered for each
-- | built-in control (zoom in/out, fit view, lock) and available to
-- | consumers wanting to add their own buttons inside `<Controls />`.
-- | Mirrors `xyflow-main/.../Controls/ControlButton.tsx`.
module React.Additional.Controls.Button
  ( controlButton
  ) where

import Prelude

import Data.Foldable (for_)
import Data.Maybe (fromMaybe)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Events (handler_)
import React.Basic.Hooks (memo, reactChildrenToArray, reactComponentWithChildren)
import React.FFI.DOM (button_, opt)
import React.Types.Component (ControlButtonProps)

controlButton :: ReactComponent ControlButtonProps
controlButton =
  unsafePerformEffect $ memo $ reactComponentWithChildren "ControlButton"
    \(props :: ControlButtonProps) ->
      let
        userClass = fromMaybe "" props.className
        className = "react-flow__controls-button"
          <> (if userClass == "" then "" else " " <> userClass)
        onClickHandler = handler_ (for_ props.onClick identity)
      in
        pure $ button_
          { type: "button"
          , className
          , onClick: onClickHandler
          , disabled: opt props.disabled
          , title: opt props.title
          , "aria-label": opt props."aria-label"
          , style: opt props.style
          }
          (reactChildrenToArray props.children)
