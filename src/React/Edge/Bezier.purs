-- | `<BezierEdge />` — cubic-bezier edge. Wraps
-- | `System.Utils.Edges.Bezier.getBezierPath`. Mirrors
-- | `xyflow-main/packages/react/src/components/Edges/BezierEdge.tsx`.
-- |
-- | Defaults: `sourcePosition = PosBottom`, `targetPosition = PosTop`,
-- | applied below since PS records have no field-default syntax.
module React.Edge.Bezier
  ( bezierEdge
  , bezierEdgeInternal
  ) where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent, element)
import React.Basic.Hooks (memo, reactComponent)
import React.Edge.Base (baseEdge)
import React.Types.Edges (BezierEdgeProps)
import System.Utils.Edges.Bezier (getBezierPath)

mkBezierEdge :: { isInternal :: Boolean } -> ReactComponent BezierEdgeProps
mkBezierEdge cfg =
  unsafePerformEffect $ memo $ reactComponent name \(props :: BezierEdgeProps) ->
    pure $
      let
        curvature = fromMaybe 0.25 (props.pathOptions >>= _.curvature)
        result = getBezierPath
          { sourceX: props.sourceX
          , sourceY: props.sourceY
          , sourcePosition: props.sourcePosition
          , targetX: props.targetX
          , targetY: props.targetY
          , targetPosition: props.targetPosition
          , curvature
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
  where
  name = if cfg.isInternal then "BezierEdgeInternal" else "BezierEdge"

bezierEdge :: ReactComponent BezierEdgeProps
bezierEdge = mkBezierEdge { isInternal: false }

bezierEdgeInternal :: ReactComponent BezierEdgeProps
bezierEdgeInternal = mkBezierEdge { isInternal: true }
