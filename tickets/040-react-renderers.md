# 040 — Renderers: NodeRenderer, EdgeRenderer, FlowRenderer, MarkerDefinitions, MarkerSymbols

## Title
Port the rendering containers that map over the visible node/edge IDs and produce wrapped instances. Plus the SVG marker definitions used for arrowheads.

## Source Files
- `xyflow-main/packages/react/src/container/NodeRenderer/index.tsx`
- `xyflow-main/packages/react/src/container/NodeRenderer/useResizeObserver.ts`
- `xyflow-main/packages/react/src/container/EdgeRenderer/index.tsx`
- `xyflow-main/packages/react/src/container/EdgeRenderer/MarkerDefinitions.tsx`
- `xyflow-main/packages/react/src/container/EdgeRenderer/MarkerSymbols.tsx`
- `xyflow-main/packages/react/src/container/FlowRenderer/index.tsx`
- (`useVisibleNodeIds.ts`, `useVisibleEdgeIds.ts` from `hooks/`)

## Target Modules
- `React.Container.NodeRenderer`
- `React.Container.EdgeRenderer`
- `React.Container.FlowRenderer`
- `React.Container.MarkerDefinitions`
- `React.Container.MarkerSymbols`
- `React.Hook.VisibleIds` — for `useVisibleNodeIds` and `useVisibleEdgeIds`

## Key Components

```purescript
nodeRenderer :: Component NodeRendererProps
edgeRenderer :: Component EdgeRendererProps
flowRenderer :: Component FlowRendererProps
markerDefinitions :: Component MarkerDefinitionsProps
markerSymbols :: Component MarkerSymbolsProps

useVisibleNodeIds :: Boolean -> Hook _ (Array String)   -- arg: onlyRenderVisibleElements
useVisibleEdgeIds :: Boolean -> Hook _ (Array String)
```

## Behaviour

### `NodeRenderer`

1. Calls `useVisibleNodeIds onlyRenderVisible` to get the IDs to render.
2. Creates a shared `ResizeObserver` (one per `NodeRenderer` instance) and passes it down to each `NodeWrapper` so node measurements share one observer.
3. Maps over IDs, rendering one `NodeWrapper` per node.

### `EdgeRenderer`

1. Calls `useVisibleEdgeIds onlyRenderVisible`.
2. Renders an SVG `<svg>` containing `<MarkerDefinitions>` (the arrowhead defs) and a `<g>` of `EdgeWrapper`s.

### `FlowRenderer`

The SVG canvas wrapper. Hosts the `EdgeRenderer` and the `ConnectionLine` overlay. Mostly a structural container.

### `MarkerDefinitions` / `MarkerSymbols`

Generates `<defs>` with one `<marker>` per unique edge marker config in the store. Marker IDs are derived via `System.Utils.Marker.createMarkerIds` (ticket 013).

### `useVisibleNodeIds` / `useVisibleEdgeIds`

Pure selectors. When `onlyRenderVisibleElements` is true, filter by intersection with the viewport rect (`getNodesInside` / `getEdgesInside` from `System.Utils.Graph`). When false, return all IDs.

## Idiomatic Notes

- **Single `ResizeObserver` per renderer.** TS uses `useResizeObserver` to allocate one and threads it via prop. PS does the same.
- **Marker IDs match TS exactly.** `${rfId}-${markerType}-${color}`. Use `System.Utils.Marker.createMarkerIds`.
- **`MarkerSymbols` renders one `<symbol>` per `MarkerType` value.** `Arrow`, `ArrowClosed`. Pure SVG.
- **No `memo` on these containers.** They re-render on store updates by design.
- **`useVisibleNodeIds` returns a stable array reference when content unchanged.** Use `useMemo` over the dependent slice plus an `Eq (Array String)` check.

## New Spago Dependencies
- None new

## Prerequisite Tickets
- 022, 024
- 027 (`useStore`)
- 035 (NodeWrapper)
- 036 (EdgeWrapper)
- System tickets 009 (Graph), 013 (Marker)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `nodeRenderer` mounts one `NodeWrapper` per visible node ID.
- `edgeRenderer` mounts one `EdgeWrapper` per visible edge ID.
- `markerDefinitions` produces a `<defs>` block whose IDs are referenced by `markerStart`/`markerEnd` on edges.
- `useVisibleNodeIds true` returns only nodes intersecting the viewport rect.
- One `ResizeObserver` is allocated per `nodeRenderer` instance and passed down.
