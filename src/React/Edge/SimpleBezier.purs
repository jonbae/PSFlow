-- | `<SimpleBezierEdge />` — simple-bezier edge (control points use the
-- | midpoint instead of weighted curvature). Wraps
-- | `System.Utils.Edges.SimpleBezier.getSimpleBezierPath`. Mirrors
-- | `xyflow-main/packages/react/src/components/Edges/SimpleBezierEdge.tsx`.
-- |
-- | Re-exports `getSimpleBezierPath` from `System.Utils.Edges.SimpleBezier`
-- | because the TS source also exports it publicly. Public consumers
-- | will be able to import it from `React.purs` once ticket 049 lands.
module React.Edge.SimpleBezier
  ( simpleBezierEdge
  , simpleBezierEdgeInternal
  , module ReexportSimpleBezier
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent, element)
import React.Basic.Hooks (memo, reactComponent)
import React.Edge.Base (baseEdge)
import React.Types.Edges (SimpleBezierEdgeProps)
import System.Utils.Edges.SimpleBezier (getSimpleBezierPath)
import System.Utils.Edges.SimpleBezier (getSimpleBezierPath) as ReexportSimpleBezier

mkSimpleBezierEdge :: { isInternal :: Boolean } -> ReactComponent SimpleBezierEdgeProps
mkSimpleBezierEdge cfg =
  unsafePerformEffect $ memo $ reactComponent name \(props :: SimpleBezierEdgeProps) ->
    pure $
      let
        result = getSimpleBezierPath
          { sourceX: props.sourceX
          , sourceY: props.sourceY
          , sourcePosition: props.sourcePosition
          , targetX: props.targetX
          , targetY: props.targetY
          , targetPosition: props.targetPosition
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
  name = if cfg.isInternal then "SimpleBezierEdgeInternal" else "SimpleBezierEdge"

simpleBezierEdge :: ReactComponent SimpleBezierEdgeProps
simpleBezierEdge = mkSimpleBezierEdge { isInternal: false }

simpleBezierEdgeInternal :: ReactComponent SimpleBezierEdgeProps
simpleBezierEdgeInternal = mkSimpleBezierEdge { isInternal: true }
