-- | `<StepEdge />` — orthogonal edge with *square* corners (smooth-step
-- | with `borderRadius = 0`). Reuses `React.Edge.SmoothStep.mkSmoothStepEdge`.
-- | Mirrors `xyflow-main/packages/react/src/components/Edges/StepEdge.tsx`.
-- |
-- | The two records differ in exactly one member. `StepEdgeProps`'
-- | `pathOptions` is `{ offset }` and `SmoothStepEdgeProps`' is
-- | `{ offset, borderRadius, stepPosition }`, so handing the factory a step
-- | edge's props unchanged hands it a record missing two labels — and the
-- | factory reads both, which in PureScript is a `Maybe` bind on `undefined`
-- | rather than a default. Upstream does the same widening explicitly
-- | (`pathOptions={{ borderRadius: 0, offset: props.pathOptions?.offset }}`),
-- | and `widen` below is that line: the coercion is sound only because the
-- | update that follows it replaces the one field whose type differs.
module React.Edge.Step
  ( stepEdge
  , stepEdgeInternal
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent, element)
import React.Basic.Hooks (memo, reactComponent)
import React.Edge.SmoothStep (mkSmoothStepEdge)
import React.Types.Edges (SmoothStepEdgeProps, StepEdgeProps)
import Unsafe.Coerce (unsafeCoerce)

-- | A step edge's props as a smooth-step edge's. `borderRadius` is 0 — that is
-- | the whole difference between the two variants — and `stepPosition` is
-- | absent so the factory's own default applies, which is what upstream leaves
-- | `undefined` for.
widen :: StepEdgeProps -> SmoothStepEdgeProps
widen p = (unsafeCoerce p :: SmoothStepEdgeProps)
  { pathOptions = Just
      { offset: p.pathOptions >>= _.offset
      , borderRadius: Just 0.0
      , stepPosition: Nothing
      }
  }

mkStepEdge :: { isInternal :: Boolean, name :: String } -> ReactComponent StepEdgeProps
mkStepEdge cfg =
  let
    -- Built once, outside the render function: a component allocated per
    -- render is a new type on every pass, and React unmounts and remounts the
    -- subtree under one.
    inner :: ReactComponent SmoothStepEdgeProps
    inner = mkSmoothStepEdge
      { isInternal: cfg.isInternal
      , forcedBorderRadius: Just 0.0
      -- Its own name, not the step edge's: the React tree upstream builds is
      -- `StepEdge` rendering `SmoothStepEdge`, and two nested components
      -- answering to one name is a devtools tree nobody can read.
      , name: if cfg.isInternal then "SmoothStepEdgeInternal" else "SmoothStepEdge"
      }
  in
    unsafePerformEffect $ memo $ reactComponent cfg.name
      \(props :: StepEdgeProps) -> pure (element inner (widen props))

stepEdge :: ReactComponent StepEdgeProps
stepEdge = mkStepEdge { isInternal: false, name: "StepEdge" }

stepEdgeInternal :: ReactComponent StepEdgeProps
stepEdgeInternal = mkStepEdge { isInternal: true, name: "StepEdgeInternal" }
