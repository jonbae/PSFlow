-- | `<Viewport />` — the thin transform container that hosts every
-- | node, edge, and overlay layer. Mirrors
-- | `xyflow-main/packages/react/src/container/Viewport/index.tsx`.
-- |
-- | Selects `state.transform` and applies it as a CSS
-- | `translate(x,y) scale(z)` so child DOM coordinates match flow
-- | coordinates. Re-renders only when the `Transform` changes (inherits
-- | `Eq` from the newtype).
module React.Container.Viewport
  ( viewport
  , module React.Types.Component
  ) where

import Prelude

import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Basic (ReactComponent)
import React.Basic.Hooks (memo, reactChildrenToArray, reactComponentWithChildren)
import React.Basic.Hooks as React
import React.FFI.DOM (div_)
import React.Hook.Store (useStore)
import React.Types.Component (ViewportProps)
import React.Types.Store (ReactFlowState)
import System.Types.Geometry (Transform(..))
import Unsafe.Coerce (unsafeCoerce)

toForeignStyle :: forall r. Record r -> Foreign
toForeignStyle = unsafeCoerce

selectTransform :: forall n e. ReactFlowState n e -> Transform
selectTransform = _.transform

viewport :: ReactComponent ViewportProps
viewport =
  unsafePerformEffect $ memo $ reactComponentWithChildren "Viewport"
    \(props :: ViewportProps) -> React.do
      Transform t <- useStore selectTransform
      let
        transformStr =
          "translate(" <> show t.tx <> "px,"
            <> show t.ty
            <> "px) scale("
            <> show t.scale
            <> ")"

        styleObj = toForeignStyle { transform: transformStr }
      pure $
        div_
          { className: "react-flow__viewport xyflow__viewport react-flow__container"
          , style: styleObj
          }
          (reactChildrenToArray props.children)
