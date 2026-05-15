-- | `<StraightEdge />` — straight-line edge. Wraps
-- | `System.Utils.Edges.Straight.getStraightPath`. Mirrors
-- | `xyflow-main/packages/react/src/components/Edges/StraightEdge.tsx`.
module React.Edge.Straight
  ( straightEdge
  , straightEdgeInternal
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent, element)
import React.Basic.Hooks (memo, reactComponent)
import React.Edge.Base (baseEdge)
import React.Types.Edges (StraightEdgeProps)
import System.Utils.Edges.Straight (getStraightPath)

mkStraightEdge :: { isInternal :: Boolean } -> ReactComponent StraightEdgeProps
mkStraightEdge cfg =
  unsafePerformEffect $ memo $ reactComponent name \(props :: StraightEdgeProps) ->
    pure $
      let
        result = getStraightPath
          { sourceX: props.sourceX
          , sourceY: props.sourceY
          , targetX: props.targetX
          , targetY: props.targetY
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
  name = if cfg.isInternal then "StraightEdgeInternal" else "StraightEdge"

straightEdge :: ReactComponent StraightEdgeProps
straightEdge = mkStraightEdge { isInternal: false }

straightEdgeInternal :: ReactComponent StraightEdgeProps
straightEdgeInternal = mkStraightEdge { isInternal: true }
