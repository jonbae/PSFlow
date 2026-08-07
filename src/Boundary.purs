-- | The **boundary module** — ps-flow's JS surface, in PureScript.
-- |
-- | `index.js` is the door the audience comes through, and until now it
-- | re-exported the `React` barrel raw, so idiomatic PureScript representations
-- | reached JavaScript untranslated. This module is where the crossing happens.
-- | Written in PureScript against the real types, so every conversion is
-- | compiler-checked; `index.js` becomes a bare re-export of the compiled
-- | output, doing nothing but restore the PascalCase names PureScript's grammar
-- | forbids at the value level.
-- |
-- | Two audiences, unchanged by this module:
-- |
-- |   * **PureScript users** keep importing `React`. That surface is not
-- |     touched here — no signature in it changes, and nothing below the
-- |     barrel knows this module exists.
-- |   * **JavaScript users** get `index.js`, which is this module renamed.
-- |
-- | ## Staging
-- |
-- | The surface crosses in four stages, ordered by how detectable a mistake in
-- | each is. Everything that has not yet crossed is re-exported **unchanged** — it
-- | resolves, but its shape is still the PureScript one. The `manifest` says
-- | which is which, and is the only place that answer is written down.
-- |
-- | What has landed so far is this skeleton, the eight TS enum objects below,
-- | and the converters. The enums needed no converter at all — they are plain
-- | data on both sides, `{ Left: "left", … }` against `{ Left: "left", … }`, so
-- | there is nothing to get wrong but member names, which the record types
-- | check.
-- |
-- | The converters are the rest, and they live in four modules beneath this
-- | one, none of them on the PureScript surface:
-- |
-- |   * `Boundary.Undefined` — `undefined`, which is what a JavaScript caller
-- |     means by a prop they did not set.
-- |   * `Boundary.Untagged` — the runtime narrowing TypeScript does at the use
-- |     site for unions like `string | string[]` and erases.
-- |   * `Boundary.Enums` — string literals in, sum-type constructors out.
-- |   * `Boundary.Elements` — `Node`, `Edge`, node props, the change objects
-- |     and `Connection`.
-- |   * `Boundary.Flow` — the 124 flow props, and `ReactFlow` itself.
-- |
-- | `ReactFlow` is therefore the first *component* to cross. The twelve other
-- | exports upstream's fixtures import cross with their fixtures.
-- |
-- | The enums are not a consumer nit. `Position` and `MarkerType` were not on
-- | the JS surface at all, and two of upstream's five test fixtures import
-- | them — an ESM import of a name that does not exist is a link error, so
-- | those fixtures could not load against ps-flow at all.
-- |
-- | The objects are frozen. Upstream's are TS enum objects, which are not, but a
-- | consumer mutating a shared enum is a bug in every case and PureScript's own
-- | reasoning assumes these are immutable.
module Boundary
  ( module PublicSurface
  , module CrossedSurface
  , BackgroundVariantEnum
  , ConnectionLineTypeEnum
  , ConnectionModeEnum
  , MarkerTypeEnum
  , PanOnScrollModeEnum
  , PositionEnum
  , ResizeControlVariantEnum
  , SelectionModeEnum
  , backgroundVariant
  , connectionLineType
  , connectionMode
  , markerType
  , panOnScrollMode
  , position
  , resizeControlVariant
  , selectionMode
  , Manifest
  , manifest
  ) where

-- The exports that have crossed. `reactFlow` is the JS-facing component from
-- `Boundary.Flow`, which converts a JavaScript props object and renders
-- `React.Container.ReactFlow`'s component with it — so it comes from there and
-- not from the PureScript surface, which still has the unconverted one.
import Boundary.Flow (reactFlow) as CrossedSurface

-- The other 59 symbols of the public surface, passing through raw. Ordered to
-- mirror `xyflow/packages/react/src/index.ts`, as `index.js` is, so future
-- audits stay mechanical.
import React
  ( -- Components
    reactFlowWithRef
  , handle
  , edgeText
  , straightEdge
  , stepEdge
  , bezierEdge
  , simpleBezierEdge
  , smoothStepEdge
  , baseEdge
  , reactFlowProvider
  , panel
  , edgeLabelRenderer
  , viewportPortal
  -- Hooks
  , useReactFlow
  , useUpdateNodeInternals
  , useNodes
  , useEdges
  , useViewport
  , useKeyPress
  , useNodesState
  , useEdgesState
  , useStore
  , useStoreApi
  , useOnViewportChange
  , useOnSelectionChange
  , useNodesInitialized
  , useHandleConnections
  , useNodeConnections
  , useNodesData
  , useConnection
  , useInternalNode
  , useNodeId
  , experimental_useOnNodesChangeMiddleware
  , experimental_useOnEdgesChangeMiddleware
  -- Utilities
  , applyNodeChanges
  , applyEdgeChanges
  , isNode
  , isEdge
  -- System functions
  , getBezierEdgeCenter
  , getBezierPath
  , getEdgeCenter
  , getSmoothStepPath
  , getStraightPath
  , getViewportForBounds
  , getNodesBounds
  , getIncomers
  , getOutgoers
  , addEdge
  , reconnectEdge
  , getConnectedEdges
  , getSimpleBezierPath
  -- Additional components
  , background
  , controls
  , controlButton
  , miniMap
  , nodeToolbar
  , nodeResizer
  , nodeResizeControl
  , edgeToolbar
  ) as PublicSurface

-- | `Object.freeze`. The enum objects are built above it in PureScript so the
-- | record type checks their members; this only stops a consumer writing to one.
foreign import freeze :: forall r. Record r -> Record r

-- ────────────────────────────────────────────────────────────────────────
-- The eight enum objects (stage 1)
--
-- Upstream models these as TS enums, which are a runtime object *and* a type.
-- PSFlow models the type half as a PureScript sum type (`Position`,
-- `MarkerType`, …, reachable from `React`); these records are the runtime half,
-- and they are what a JS caller writing `Position.Left` reaches. The string
-- values are upstream's, verbatim — including `ConnectionLineType.Bezier`,
-- which is `"default"` and not `"bezier"`.
--
-- Nothing here converts. Turning these strings into the PureScript
-- constructors, and back, is a stage-1 *converter* and lands with the props
-- conversion, not here.
-- ────────────────────────────────────────────────────────────────────────

type PositionEnum =
  { "Left" :: String
  , "Top" :: String
  , "Right" :: String
  , "Bottom" :: String
  }

-- | Upstream `Position` — `@xyflow/system`.
position :: PositionEnum
position = freeze
  { "Left": "left"
  , "Top": "top"
  , "Right": "right"
  , "Bottom": "bottom"
  }

type MarkerTypeEnum =
  { "Arrow" :: String
  , "ArrowClosed" :: String
  }

-- | Upstream `MarkerType` — `@xyflow/system`.
markerType :: MarkerTypeEnum
markerType = freeze
  { "Arrow": "arrow"
  , "ArrowClosed": "arrowclosed"
  }

type ConnectionModeEnum =
  { "Strict" :: String
  , "Loose" :: String
  }

-- | Upstream `ConnectionMode` — `@xyflow/system`.
connectionMode :: ConnectionModeEnum
connectionMode = freeze
  { "Strict": "strict"
  , "Loose": "loose"
  }

type ConnectionLineTypeEnum =
  { "Bezier" :: String
  , "Straight" :: String
  , "Step" :: String
  , "SmoothStep" :: String
  , "SimpleBezier" :: String
  }

-- | Upstream `ConnectionLineType` — `@xyflow/system`.
connectionLineType :: ConnectionLineTypeEnum
connectionLineType = freeze
  { "Bezier": "default"
  , "Straight": "straight"
  , "Step": "step"
  , "SmoothStep": "smoothstep"
  , "SimpleBezier": "simplebezier"
  }

type PanOnScrollModeEnum =
  { "Free" :: String
  , "Vertical" :: String
  , "Horizontal" :: String
  }

-- | Upstream `PanOnScrollMode` — `@xyflow/system`.
panOnScrollMode :: PanOnScrollModeEnum
panOnScrollMode = freeze
  { "Free": "free"
  , "Vertical": "vertical"
  , "Horizontal": "horizontal"
  }

type SelectionModeEnum =
  { "Partial" :: String
  , "Full" :: String
  }

-- | Upstream `SelectionMode` — `@xyflow/system`.
selectionMode :: SelectionModeEnum
selectionMode = freeze
  { "Partial": "partial"
  , "Full": "full"
  }

type ResizeControlVariantEnum =
  { "Line" :: String
  , "Handle" :: String
  }

-- | Upstream `ResizeControlVariant` — `@xyflow/system`.
resizeControlVariant :: ResizeControlVariantEnum
resizeControlVariant = freeze
  { "Line": "line"
  , "Handle": "handle"
  }

type BackgroundVariantEnum =
  { "Lines" :: String
  , "Dots" :: String
  , "Cross" :: String
  }

-- | Upstream `BackgroundVariant` — `@xyflow/react`, not `@xyflow/system`.
backgroundVariant :: BackgroundVariantEnum
backgroundVariant = freeze
  { "Lines": "lines"
  , "Dots": "dots"
  , "Cross": "cross"
  }

-- ────────────────────────────────────────────────────────────────────────
-- The manifest
-- ────────────────────────────────────────────────────────────────────────

-- | What has crossed, and what is still passing through raw.
-- |
-- | `crossed` and `passthrough` together name every export on the JS surface,
-- | so a gate can scope itself to the crossed set without a hand-maintained
-- | list of its own, and grows with the staging rather than being rewritten by
-- | it. Defined in `Boundary.js` as dependency-free data: a gate reads it by
-- | importing that file directly, with no build step.
type Manifest =
  { stage :: Int
  , crossed :: Array String
  , passthrough :: Array String
  }

foreign import manifest :: Manifest
