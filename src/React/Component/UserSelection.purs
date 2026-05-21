-- | `<UserSelection />` — the user's drag-selection lasso rectangle.
-- | Mirrors `xyflow-main/packages/react/src/components/UserSelection/index.tsx`.
-- |
-- | Renders a positioned `<div>` while
-- | `state.userSelectionActive && state.userSelectionRect` are both set;
-- | otherwise the component returns `mempty`.
module React.Component.UserSelection
  ( userSelection
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Number.Format (toString) as NumberFormat
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Basic (ReactComponent)
import React.Basic.Hooks (memo, reactComponent)
import React.Basic.Hooks as React
import React.FFI.DOM (div_)
import React.Hook.Store (useStore)
import React.Types.Component (UserSelectionProps)
import React.Types.Store (ReactFlowState)
import System.Types.Connection (SelectionRect)
import Unsafe.Coerce (unsafeCoerce)

type UserSelectionSlice =
  { active :: Boolean
  , rect :: Maybe SelectionRect
  }

selectSlice :: forall n e. ReactFlowState n e -> UserSelectionSlice
selectSlice s =
  { active: s.userSelectionActive
  , rect: s.userSelectionRect
  }

toForeignStyle :: forall r. Record r -> Foreign
toForeignStyle = unsafeCoerce

showN :: Number -> String
showN = NumberFormat.toString

userSelection :: ReactComponent UserSelectionProps
userSelection =
  unsafePerformEffect $ memo $ reactComponent "UserSelection"
    \(_ :: UserSelectionProps) -> React.do
      slice <- useStore selectSlice
      pure $ case slice.active, slice.rect of
        true, Just r ->
          div_
            { className: "react-flow__selection react-flow__container"
            , style: toForeignStyle
                { width: r.width
                , height: r.height
                , transform:
                    "translate(" <> showN r.x <> "px, " <> showN r.y <> "px)"
                }
            }
            []
        _, _ -> mempty
