-- | Shared utilities for the per-edge wrapper component. Mirrors
-- | `xyflow-main/packages/react/src/components/EdgeWrapper/utils.ts`.
-- |
-- |   * `builtinEdgeTypes` — registry of the five built-in edge-type
-- |     keys (`default`, `straight`, `step`, `smoothstep`,
-- |     `simplebezier`) pointing at the `*Internal` variants. The
-- |     internal variants suppress their `id` so the wrapper can supply
-- |     the canonical `data-id` attribute itself.
-- |   * `nullPosition` — the "no endpoints resolved" sentinel returned
-- |     by `selectEdgePosition` when source/target nodes are missing or
-- |     unmeasured. Carries `zIndex` so the wrapper can still render the
-- |     `<svg>` shell consistently.
-- |   * `EdgePositionSlice` — the `useStore` projection shape used by
-- |     the wrapper to track position changes with structural `Eq`.
module React.Component.EdgeWrapper.Util
  ( builtinEdgeTypes
  , nullPosition
  , EdgePositionSlice
  ) where

import Data.Maybe (Maybe(..))
import Data.Tuple.Nested ((/\))
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object (fromFoldable) as Object
import React.Basic (ReactComponent)
import React.Edge.Bezier (bezierEdgeInternal)
import React.Edge.SimpleBezier (simpleBezierEdgeInternal)
import React.Edge.SmoothStep (smoothStepEdgeInternal)
import React.Edge.Step (stepEdgeInternal)
import React.Edge.Straight (straightEdgeInternal)
import React.Types.Edges (EdgeProps)
import System.Types.Geometry (Position)
import Unsafe.Coerce (unsafeCoerce)

-- | TS `{ default, straight, step, smoothstep, simplebezier }`.
-- |
-- | The per-variant `ReactComponent BezierEdgeProps`/
-- | `StraightEdgeProps`/etc. records are uniformised to
-- | `ReactComponent (EdgeProps Foreign)` via `unsafeCoerce` for the
-- | registry. The wrapper passes the same uniform `EdgeProps` record
-- | to whichever variant resolves, and React forwards untouched the
-- | fields the variant cares about. Same trick used in
-- | `React.Component.NodeWrapper.Util.builtinNodeTypes`.
builtinEdgeTypes :: Object (ReactComponent (EdgeProps Foreign))
builtinEdgeTypes = Object.fromFoldable
  [ "default" /\ unsafeCoerce bezierEdgeInternal
  , "straight" /\ unsafeCoerce straightEdgeInternal
  , "step" /\ unsafeCoerce stepEdgeInternal
  , "smoothstep" /\ unsafeCoerce smoothStepEdgeInternal
  , "simplebezier" /\ unsafeCoerce simpleBezierEdgeInternal
  ]

-- | `useStore` projection shape for the edge's endpoint coordinates and
-- | elevated z-index. All fields have structural `Eq`, so the selector
-- | wakes the wrapper component only when one of these primitives
-- | actually changes — matching TS's `shallow`-equality contract.
type EdgePositionSlice =
  { zIndex :: Int
  , sourceX :: Maybe Number
  , sourceY :: Maybe Number
  , targetX :: Maybe Number
  , targetY :: Maybe Number
  , sourcePosition :: Maybe Position
  , targetPosition :: Maybe Position
  }

-- | The "no endpoints" sentinel. `zIndex` is overwritten by the caller
-- | when an edge-level z-index is known even though the nodes haven't
-- | yet been measured.
nullPosition :: EdgePositionSlice
nullPosition =
  { zIndex: 0
  , sourceX: Nothing
  , sourceY: Nothing
  , targetX: Nothing
  , targetY: Nothing
  , sourcePosition: Nothing
  , targetPosition: Nothing
  }
