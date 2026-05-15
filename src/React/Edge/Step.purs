-- | `<StepEdge />` — orthogonal edge with *square* corners (smooth-step
-- | with `borderRadius = 0`). Reuses
-- | `React.Edge.SmoothStep.mkSmoothStepEdge`. Mirrors
-- | `xyflow-main/packages/react/src/components/Edges/StepEdge.tsx`.
module React.Edge.Step
  ( stepEdge
  , stepEdgeInternal
  ) where

import Data.Maybe (Maybe(..))
import React.Basic (ReactComponent)
import React.Edge.SmoothStep (mkSmoothStepEdge)
import React.Types.Edges (SmoothStepEdgeProps, StepEdgeProps)
import Unsafe.Coerce (unsafeCoerce)

-- | StepEdge shares all input fields with SmoothStepEdge — the only
-- | behavioural difference is the forced `borderRadius = 0`. Coerce the
-- | prop record so we can share the factory.
stepEdge :: ReactComponent StepEdgeProps
stepEdge = unsafeCoerce
  ( mkSmoothStepEdge
      { isInternal: false, forcedBorderRadius: Just 0.0, name: "StepEdge" }
      :: ReactComponent SmoothStepEdgeProps
  )

stepEdgeInternal :: ReactComponent StepEdgeProps
stepEdgeInternal = unsafeCoerce
  ( mkSmoothStepEdge
      { isInternal: true, forcedBorderRadius: Just 0.0, name: "StepEdgeInternal" }
      :: ReactComponent SmoothStepEdgeProps
  )
