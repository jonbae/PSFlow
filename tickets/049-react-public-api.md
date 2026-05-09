# 049 — Public API + smoke-test verification

## Title
Define the top-level `React` module that re-exports the public surface, plus a smoke-test example app that mounts a `<ReactFlow>` end-to-end. This is the verification gate for the React port.

## Source Files
- `xyflow-main/packages/react/src/index.ts` (the canonical export list)
- `xyflow-main/packages/react/src/additional-components/index.ts` (re-exported via `export *`)
- `xyflow-main/packages/react/src/types/index.ts` (re-exported via `export *`)

## Target Modules
- `React` — top-level public re-export module
- `Example.Main` — smoke-test app

## Public API

The `React` module mirrors `xyflow-main/packages/react/src/index.ts` exactly. Re-exports:

### Components
- `reactFlow` (as `ReactFlow`) — ticket 042
- `reactFlowProvider` (as `ReactFlowProvider`) — ticket 043
- `handle` (as `Handle`) — ticket 034
- `panel` (as `Panel`) — ticket 044
- `edgeLabelRenderer` (as `EdgeLabelRenderer`) — ticket 044
- `viewportPortal` (as `ViewportPortal`) — ticket 044
- `baseEdge` (as `BaseEdge`) — ticket 032
- `straightEdge` (as `StraightEdge`) — ticket 032
- `bezierEdge` (as `BezierEdge`) — ticket 032
- `simpleBezierEdge` (as `SimpleBezierEdge`) — ticket 032
- `stepEdge` (as `StepEdge`) — ticket 032
- `smoothStepEdge` (as `SmoothStepEdge`) — ticket 032
- `edgeText` (as `EdgeText`) — ticket 032

### Hooks
- `useReactFlow`, `useStore`, `useStoreApi`, `useNodes`, `useEdges`, `useViewport`, `useConnection`, `useNodesData`, `useInternalNode`, `useNodesInitialized`, `useHandleConnections`, `useNodeConnections`, `useNodesEdgesState` (as both `useNodesState` and `useEdgesState`)
- `useUpdateNodeInternals`
- `useKeyPress`
- `useOnViewportChange` + `UseOnViewportChangeOptions` type
- `useOnSelectionChange` + `UseOnSelectionChangeOptions` type
- `useNodeId`
- `experimental_useOnNodesChangeMiddleware`, `experimental_useOnEdgesChangeMiddleware`

### Utilities
- `applyNodeChanges`, `applyEdgeChanges`, `isNode`, `isEdge`
- `getSimpleBezierPath` (ticket 032)

### System re-exports
Mirror the exact list from TS lines 43–143:
- Types: `Align`, `SmoothStepPathOptions`, `BezierPathOptions`, `EdgeMarker`, `EdgeMarkerType`, `OnMove*`, `Connection`, `OnConnect*`, `Viewport`, `SnapGrid`, `ViewportHelperFunctionOptions`, `SetCenterOptions`, `FitBoundsOptions`, `PanelPosition`, `ProOptions`, `SelectionRect`, `OnError`, `NodeOrigin`, `OnSelectionDrag`, `XYPosition`, `XYZPosition`, `Dimensions`, `Rect`, `Box`, `Transform`, `CoordinateExtent`, `ColorMode`, `ColorModeClass`, `HandleType`, `ShouldResize`, `OnResize*`, `ControlPosition`, `ControlLinePosition`, `ResizeParams*`, `ResizeDragEvent`, `NodeChange`, `Node*Change` (5 sub-types), `EdgeChange`, `Edge*Change` (4 sub-types), `KeyCode`, `ConnectionState`, `FinalConnectionState`, `ConnectionInProgress`, `NoConnection`, `NodeConnection`, `OnReconnect`, `AriaLabelConfig`, `SetCenter`, `SetViewport`, `FitBounds`, `HandleConnection`, `ZIndexMode`, `Handle`
- Enums: `ConnectionLineType`, `MarkerType`, `ConnectionMode`, `Position`, `PanOnScrollMode`, `SelectionMode`, `ResizeControlVariant`
- Functions: `getBezierEdgeCenter`, `getBezierPath`, `getEdgeCenter`, `getSmoothStepPath`, `getStraightPath`, `getViewportForBounds`, `getNodesBounds`, `getIncomers`, `getOutgoers`, `addEdge`, `reconnectEdge`, `getConnectedEdges`

### Additional components
Re-export `* from './additional-components'`:
- `background` (`Background`)
- `controls`, `controlButton` (`Controls`, `ControlButton`)
- `miniMap` (`MiniMap`)
- `nodeToolbar` (`NodeToolbar`)
- `nodeResizer`, `nodeResizeControl` (`NodeResizer`, `NodeResizeControl`)
- `edgeToolbar` (`EdgeToolbar`)
- All their prop types

### Types
Re-export `* from './types'`.

## Smoke-test app

`Example.Main`: mounts a `<ReactFlow>` with two nodes and one edge.

```purescript
module Example.Main where

import Prelude
import Effect (Effect)
import React.Basic.DOM (render)
import Web.HTML (window)
import Web.HTML.Window (document)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.DOM.NonElementParentNode (getElementById)
import Data.Maybe (Maybe(..))
import React (reactFlow, miniMap, controls, background, reactFlowProvider)
-- ... etc

main :: Effect Unit
main = do
  doc <- window >>= document <#> HTMLDocument.toNonElementParentNode
  mEl <- getElementById "app" doc
  case mEl of
    Just el ->
      render el $ reactFlowProvider {} $
        reactFlow
          { nodes: [...]
          , edges: [...]
          , defaultViewport: { x: 0.0, y: 0.0, zoom: 1.0 }
          , children: ...
          }
    Nothing -> pure unit
```

The example's HTML loads `react-flow/dist/style.css` so styling matches the upstream.

## Verification Checklist (the gate for "port complete")

Build:
- [ ] `spago build` passes with zero warnings on the entire repo.
- [ ] `spago test` passes — system property tests + new React reducer tests.
- [ ] `spago bundle-app -m Example.Main --to dist/example.js` produces a working bundle.

Runtime (manual, browser):
- [ ] Open the example HTML page.
- [ ] Two nodes render at their configured positions.
- [ ] One edge renders connecting the two nodes.
- [ ] Pan: dragging the background moves the viewport.
- [ ] Zoom: mouse wheel zooms the viewport.
- [ ] Node drag: clicking and dragging a node moves it; `onNodesChange` fires.
- [ ] Selection: clicking a node selects it; `onSelectionChange` fires.
- [ ] MiniMap: appears in the bottom-right; reflects current viewport rectangle; clicking pans the main viewport.
- [ ] Background: dotted grid renders behind everything.
- [ ] Controls: zoom-in, zoom-out, fit-view, lock buttons render and work.
- [ ] No `console.error`s during the session.
- [ ] No React strict-mode double-mount issues.
- [ ] Upstream CSS files (`base.css`, `style.css`) apply cleanly without manual class-name patching.

API contract:
- [ ] Every exported name from `xyflow-main/packages/react/src/index.ts` is re-exported from `React.purs` (modulo PS-idiom translations: TS `useNodesState` becomes a destructured pair from `useNodesEdgesState`).
- [ ] `useStore`, `useStoreApi` signatures are functionally equivalent to upstream (selector + optional Eq instance).
- [ ] `useReactFlow` returns a record with every method listed in `ReactFlowInstance` (ticket 024).

## New Spago Dependencies
- None new — all already added by earlier tickets

## Prerequisite Tickets
- All of 022–048

## Acceptance Criteria
- The verification checklist above passes end-to-end.
- `tickets/000-overview.md` is amended with a "React layer port complete (2026-…)" note.
- The example app is committed under `examples/react-smoke/`.
