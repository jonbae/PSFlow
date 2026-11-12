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
-- | The surface crossed in five stages, ordered by how detectable a mistake in
-- | each is. Anything that had not yet crossed was re-exported **unchanged** —
-- | it resolved, but its shape was still the PureScript one. The `manifest`
-- | says which is which, and is the only place that answer is written down.
-- |
-- | **Every component and every prop has now crossed.** Stage 1 landed this
-- | skeleton, the eight TS enum objects below, the converters, the three graph
-- | utilities a driver calls, the four chrome components a driver mounts and
-- | the four a custom node mounts; stage 2 landed the callback props; stage 3
-- | the imperative instance and all 21 hooks, `onInit` with them; and stage 4
-- | the components no fixture mounts, the two sub-components inside `Controls`
-- | and `MiniMap`, and the three props whose values are components the
-- | consumer wrote. The enums needed no converter at all: they are plain data
-- | on both sides, `{ Left: "left", … }` against `{ Left: "left", … }`, so
-- | there is nothing to get wrong but member names, which the record types
-- | check.
-- |
-- | **Stage 5 is complete: `passthrough` is empty.** The fourteen standalone
-- | functions left by stage 4 now have JS-native call and value conventions.
-- | Edge paths live in `Boundary.EdgePaths`; viewport, traversal, bounds,
-- | reconnection and native shape guards live in `Boundary.Utils`.
-- | Direct JS-entry regressions observe their source branches and original
-- | consumer references. Crossing is independent of full parity: the earlier
-- | change/add helpers still have consumer-object exceptions owned by #150.
-- |
-- | The converters are the rest, and they live in twenty modules beneath
-- | this one, none of them on the PureScript surface:
-- |
-- |   * `Boundary.Undefined` — `undefined`, which is what a JavaScript caller
-- |     means by a prop they did not set.
-- |   * `Boundary.Untagged` — the runtime narrowing TypeScript does at the use
-- |     site for unions like `string | string[]` and erases.
-- |   * `Boundary.Original` — the consumer's own value behind a conversion,
-- |     which a raw store read hands back as upstream's store does.
-- |   * `Boundary.Enums` — string literals in, sum-type constructors out.
-- |   * `Boundary.Elements` — `Node`, `Edge`, node props, the change objects,
-- |     `Connection`, and the shapes a handler carries back out.
-- |   * `Boundary.Callbacks` — one JS-shaped type and one converter per
-- |     handler, shared by every record below that has one.
-- |   * `Boundary.Flow` — the 124 flow props, and `ReactFlow` itself.
-- |   * `Boundary.Utils` — `applyNodeChanges`, `applyEdgeChanges` and
-- |     `addEdge`, which a controlled flow's own change handlers call, so a
-- |     driver reaches them on the first interaction; and, from stage 5,
-- |     `getViewportForBounds` and the padding it reads.
-- |   * `Boundary.Chrome` — `Panel`, `Background`, `Controls` and `MiniMap`,
-- |     which a driver mounts inside the flow, and since stage 4 the two
-- |     pieces a consumer reaches *inside* two of them, `ControlButton` and
-- |     `MiniMapNode`.
-- |   * `Boundary.Edges` — the five built-in edge components, `BaseEdge`,
-- |     `EdgeText`, `EdgeToolbar`, and the two props whose values are the
-- |     consumer's own edge-side components: `edgeTypes` and
-- |     `connectionLineComponent`.
-- |   * `Boundary.Portals` — `EdgeLabelRenderer` and `ViewportPortal`, whose
-- |     only prop is `children` and whose whole crossing is that one.
-- |   * `Boundary.Wrapper` — the one FFI shared by the three props that hold
-- |     components the consumer wrote.
-- |   * `Boundary.NodeChrome` — `Handle` and `NodeToolbar`, which a consumer's
-- |     own node component mounts one level down.
-- |   * `Boundary.Resizer` — `NodeResizer` and `NodeResizeControl`, mounted the
-- |     same way and crossed with the callbacks because their lifecycle
-- |     handlers are callback props.
-- |   * `Boundary.FitView` — `FitViewOptions` and the padding inside it, which
-- |     `ReactFlow`, `<Controls />` and `instance.fitView` all take, and which
-- |     moved out of `Boundary.Flow` when the third of those appeared.
-- |   * `Boundary.Promise` — `Aff` as a `Promise`, which is what the eleven
-- |     asynchronous methods of the instance need.
-- |   * `Boundary.SetState` — React's `SetStateAction`, shared by the two state
-- |     hooks and the instance's `setNodes`/`setEdges`.
-- |   * `Boundary.Instance` — the imperative `ReactFlowInstance`: thirty-two
-- |     members, reached from `useReactFlow` and from `onInit`.
-- |   * `Boundary.Store` — the store state in upstream's shape, with zustand's
-- |     `setState` and `subscribe`: what `useStore` and `useStoreApi` hand over.
-- |   * `Boundary.Hooks` — all 21 hooks. Two of them crossed in stage 1
-- |     (`useNodesState`, `useEdgesState`) because they touch no instance; the
-- |     rest could not, because `useReactFlow` returns one.
-- |
-- | `ReactFlow` is therefore the first *component* to cross, and `Handle` and
-- | `NodeToolbar` the last of stage 1's set: each export upstream's fixtures
-- | import crossed with the fixture that imports it. Stage 4 is the opposite
-- | selection and is why it is last: its set is everything `passthrough` still
-- | held, which no fixture imports — and the **hole** register is what says
-- | which of them the corpus does not drive. A crossing nothing mounts is
-- | exactly the one nothing would have caught, so `parity/boundary/mount.mjs`
-- | mounts all fourteen.
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
  ( module CrossedSurface
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
-- not from the PureScript surface, which still has the unconverted one. The
-- three utilities come from `Boundary.Utils` for the same reason: a driver
-- calls them with every argument at once, which a curried PureScript function
-- is not. So does `getViewportForBounds`, stage 5's first graph utility, whose
-- six arguments upstream takes in one call and whose `padding` is an untagged
-- value; `Boundary.Utils` crosses both.
import Boundary.Flow (reactFlow, reactFlowProvider) as CrossedSurface
import Boundary.Utils (addEdge, applyEdgeChanges, applyNodeChanges, getConnectedEdges, getIncomers, getNodesBounds, getOutgoers, getViewportForBounds, isEdge, isNode, reconnectEdge) as CrossedSurface

-- The four chrome components upstream's drivers mount. `Boundary.Chrome` says
-- why each needed a wrapper at all; the short version is that a JavaScript
-- caller reaches all four with no props, and a PureScript record of `Maybe`s
-- answers that with a pattern-match failure.
import Boundary.Chrome (background, controlButton, controls, miniMap, miniMapNode, panel) as CrossedSurface

-- The six edge-path helpers, stage 5's first half. A custom edge component
-- calls one on its first line, with the position strings `edgeTypes` hands
-- it, and destructures an array; `Boundary.EdgePaths` says what the raw
-- PureScript functions did with that.
import Boundary.EdgePaths
  ( getBezierEdgeCenter
  , getBezierPath
  , getEdgeCenter
  , getSimpleBezierPath
  , getSmoothStepPath
  , getStraightPath
  ) as CrossedSurface

-- The edge-side components, stage 4. `Boundary.Edges` says why they cross
-- together: `edgeTypes`' values are the consumer's own edge components, so the
-- props record ps-flow hands them had to cross too, and that record is the
-- built-in components' own.
import Boundary.Edges
  ( baseEdge
  , bezierEdge
  , edgeText
  , edgeToolbar
  , simpleBezierEdge
  , smoothStepEdge
  , stepEdge
  , straightEdge
  ) as CrossedSurface

-- The two portal targets, stage 4. `children` is the only prop either takes,
-- and it is the one prop a JavaScript caller cannot pass to an un-crossed
-- PureScript component at all.
import Boundary.Portals (edgeLabelRenderer, viewportPortal) as CrossedSurface

-- All twenty-one hooks, and with them the imperative instance: `useReactFlow`
-- returns it, so `Boundary.Hooks` is where stage 3 becomes reachable from
-- `index.js`. `useNodesState` and `useEdgesState` were already there — they
-- crossed in stage 1 because they touch no instance — and the other nineteen
-- join them here.
import Boundary.Hooks
  ( experimental_useOnEdgesChangeMiddleware
  , experimental_useOnNodesChangeMiddleware
  , useConnection
  , useEdges
  , useEdgesState
  , useHandleConnections
  , useInternalNode
  , useKeyPress
  , useNodeConnections
  , useNodeId
  , useNodes
  , useNodesData
  , useNodesInitialized
  , useNodesState
  , useOnSelectionChange
  , useOnViewportChange
  , useReactFlow
  , useStore
  , useStoreApi
  , useUpdateNodeInternals
  , useViewport
  ) as CrossedSurface

-- The two a *custom node* mounts, rather than a driver. `Boundary.NodeChrome`
-- says why they crossed last of stage 1's set: nothing but a consumer's own
-- node component mounts either, and the node-toolbar fixture is the first one
-- any gate runs.
import Boundary.NodeChrome (handle, nodeToolbar) as CrossedSurface

-- The other pair a custom node mounts, and the only two exports stage 2 adds
-- beyond the callbacks themselves. `Boundary.Resizer` says why they come
-- forward out of stage 4: their three lifecycle handlers are callback props,
-- and a callback cannot cross without the record it hangs off.
import Boundary.Resizer (nodeResizeControl, nodeResizer) as CrossedSurface

-- No value is re-exported raw from React after stage 5. The PureScript
-- surface itself stays in React; these crossings belong only to index.js.

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
