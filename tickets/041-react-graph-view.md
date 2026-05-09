# 041 — GraphView

## Title
Port the `GraphView` orchestrator. Composes the `Pane`, `Viewport`/`ZoomPane`, renderers, and dev-time warning hooks. Sits between `ReactFlow` (top-level) and the rendering layer.

## Source Files
- `xyflow-main/packages/react/src/container/GraphView/index.tsx`
- `xyflow-main/packages/react/src/container/GraphView/useNodeOrEdgeTypesWarning.ts`
- `xyflow-main/packages/react/src/container/GraphView/useStylesLoadedWarning.ts`

## Target Module
`React.Container.GraphView`

## Key Types / Functions

```purescript
graphView :: Component GraphViewProps
```

`GraphViewProps` is a large pass-through record — most fields come from `ReactFlowProps` and are forwarded to `ZoomPane`, `Pane`, the renderers, and the connection line. Defined in `React.Types.Component`.

## Behaviour

1. Calls `useNodeOrEdgeTypesWarning(nodeTypes)` and `useNodeOrEdgeTypesWarning(edgeTypes)` — dev-time warning if a `nodeTypes`/`edgeTypes` record reference changes between renders.
2. Calls `useStylesLoadedWarning()` — dev-time warning if `react-flow__container` styles aren't loaded.
3. Renders:
   ```
   <FlowRenderer ...>
     <ZoomPane ...>
       <Pane ...>
         <Viewport>
           <NodeRenderer />
           <ConnectionLine />
           <NodesSelection />
           <UserSelection />
         </Viewport>
       </Pane>
     </ZoomPane>
   </FlowRenderer>
   ```
   (Exact structure mirrors the TS source — `EdgeRenderer` is inside `FlowRenderer`, not inside `Viewport`, since edges live in the SVG layer.)

## Idiomatic Notes

- **Dev-time warnings.** TS uses `process.env.NODE_ENV === 'development'`. PS uses the `state.debug :: Boolean` flag set on the store at provider time. Document divergence.
- **No own state.** Pure pass-through component.
- **Children fan out.** Most rendering decisions are in the children. This module is structure.
- **`useNodeOrEdgeTypesWarning` is a one-shot warning per mount.** Use a `Ref Boolean` to ensure it doesn't re-warn on every render.

## New Spago Dependencies
- None new

## Prerequisite Tickets
- 022, 024
- 037 (overlays)
- 038 (Pane)
- 039 (Viewport, ZoomPane)
- 040 (renderers)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `graphView` mounts the full container hierarchy.
- Dev-time warnings fire correctly when `state.debug` is true and conditions are met.
- All props on `ReactFlowProps` reach the appropriate child component without manual prop-drilling glue.
