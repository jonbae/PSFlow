-- | `<Viewport />` — the thin transform container that hosts every
-- | node, edge, and overlay layer. Mirrors
-- | `xyflow/packages/react/src/container/Viewport/index.tsx`.
-- |
-- | Selects `state.transform` and applies it as a CSS
-- | `translate(x,y) scale(z)` so child DOM coordinates match flow
-- | coordinates. Re-renders only when the `Transform` changes (inherits
-- | `Eq` from the newtype).
module React.Container.Viewport
  ( viewport
  , viewportTransform
  , module React.Types.Component
  ) where

import Prelude

import Data.Number.Format (toString) as NumberFormat
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

-- | TS `translate(${transform[0]}px,${transform[1]}px) scale(${transform[2]})`.
viewportTransform :: Transform -> String
viewportTransform (Transform t) =
  "translate(" <> NumberFormat.toString t.tx <> "px,"
    <> NumberFormat.toString t.ty
    <> "px) scale("
    <> NumberFormat.toString t.scale
    <> ")"

viewport :: ReactComponent ViewportProps
viewport =
  unsafePerformEffect $ memo $ reactComponentWithChildren "Viewport"
    \(props :: ViewportProps) -> React.do
      transform <- useStore selectTransform
      let
        styleObj = toForeignStyle { transform: viewportTransform transform }
      pure $
        div_
          { className: "react-flow__viewport xyflow__viewport react-flow__container"
          , style: styleObj
          }
          (reactChildrenToArray props.children)
