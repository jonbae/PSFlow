-- | `<SmoothStepEdge />` — orthogonal edge with rounded corners. Wraps
-- | `System.Utils.Edges.SmoothStep.getSmoothStepPath`. Mirrors
-- | `xyflow-main/packages/react/src/components/Edges/SmoothStepEdge.tsx`.
-- |
-- | `borderRadius`, `offset`, `stepPosition` come from `pathOptions`;
-- | defaults match the TS source (`borderRadius = 5`, `offset = 20`,
-- | `stepPosition = 0.5`).
module React.Edge.SmoothStep
  ( smoothStepEdge
  , smoothStepEdgeInternal
  , mkSmoothStepEdge
  ) where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent, element)
import React.Basic.Hooks (memo, reactComponent)
import React.Edge.Base (baseEdge)
import React.Types.Edges (SmoothStepEdgeProps)
import System.Utils.Edges.SmoothStep (getSmoothStepPath)

-- | Internal factory exported for `React.Edge.Step` to reuse with
-- | `borderRadius = 0`.
mkSmoothStepEdge
  :: { isInternal :: Boolean, forcedBorderRadius :: Maybe Number, name :: String }
  -> ReactComponent SmoothStepEdgeProps
mkSmoothStepEdge cfg =
  unsafePerformEffect $ memo $ reactComponent cfg.name \(props :: SmoothStepEdgeProps) ->
    pure $
      let
        borderRadius = case cfg.forcedBorderRadius of
          Just r -> r
          Nothing -> fromMaybe 5.0 (props.pathOptions >>= _.borderRadius)
        offset = fromMaybe 20.0 (props.pathOptions >>= _.offset)
        stepPosition = fromMaybe 0.5 (props.pathOptions >>= _.stepPosition)
        result = getSmoothStepPath
          { sourceX: props.sourceX
          , sourceY: props.sourceY
          , sourcePosition: props.sourcePosition
          , targetX: props.targetX
          , targetY: props.targetY
          , targetPosition: props.targetPosition
          , borderRadius
          , centerX: Nothing
          , centerY: Nothing
          , offset
          , stepPosition
          }
        _id = if cfg.isInternal then Nothing else props.id
      in
        element baseEdge
          { id: _id
          , path: result.path
          , labelX: Just result.labelX
          , labelY: Just result.labelY
          , label: props.label
          , labelStyle: props.labelStyle
          , labelShowBg: props.labelShowBg
          , labelBgStyle: props.labelBgStyle
          , labelBgPadding: props.labelBgPadding
          , labelBgBorderRadius: props.labelBgBorderRadius
          , style: props.style
          , markerEnd: props.markerEnd
          , markerStart: props.markerStart
          , interactionWidth: props.interactionWidth
          , className: Nothing
          }

smoothStepEdge :: ReactComponent SmoothStepEdgeProps
smoothStepEdge = mkSmoothStepEdge
  { isInternal: false, forcedBorderRadius: Nothing, name: "SmoothStepEdge" }

smoothStepEdgeInternal :: ReactComponent SmoothStepEdgeProps
smoothStepEdgeInternal = mkSmoothStepEdge
  { isInternal: true, forcedBorderRadius: Nothing, name: "SmoothStepEdgeInternal" }
