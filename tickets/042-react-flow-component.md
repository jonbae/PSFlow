# 042 — ReactFlow component

## Title
Port the public `ReactFlow` component — the top-level entry point. Wraps everything in a provider, mounts `GraphView`, applies dev-time `A11yDescriptions` and `Attribution`. ~150-LoC TS source with ~100 props.

## Source Files
- `xyflow-main/packages/react/src/container/ReactFlow/index.tsx`
- `xyflow-main/packages/react/src/container/ReactFlow/Wrapper.tsx`
- `xyflow-main/packages/react/src/container/ReactFlow/init-values.ts`
- `xyflow-main/packages/react/src/components/A11yDescriptions/index.tsx`
- `xyflow-main/packages/react/src/components/Attribution/index.tsx`
- `xyflow-main/packages/react/src/utils/general.ts` (`fixedForwardRef`, `isNode`, `isEdge`)

## Target Modules
- `React.Container.ReactFlow`
- `React.Container.Wrapper`
- `React.Container.InitValues`
- `React.Container.A11yDescriptions`
- `React.Container.Attribution`
- `React.Util.General` — `isNode`, `isEdge` (re-export from system layer where appropriate)

## Key Types / Functions

```purescript
reactFlow :: forall nodeData edgeData. Component (ReactFlowProps nodeData edgeData)
```

`ReactFlowProps` is the largest record in the codebase — see ticket 024 for the full field list. ~100 fields covering nodes/edges, callbacks, viewport config, style/className, accessibility, default-prop-overrides, etc.

```purescript
defaultViewport :: Viewport            -- { x: 0, y: 0, zoom: 1 }
defaultNodeOrigin :: NodeOrigin        -- mkNodeOrigin 0.0 0.0
```

```purescript
a11yDescriptions :: Component A11yDescriptionsProps
attribution :: Component AttributionProps
```

## Behaviour

1. `Wrapper` (mounts a `<ReactFlowProvider>` if not already inside one). The TS source wraps in a check that detects an outer provider via context — preserve.
2. Inside the provider, render `<GraphView>` with all the prop forwarding.
3. Render `<A11yDescriptions>` (ARIA live region for selection announcements).
4. Render `<Attribution>` ("React Flow" link in bottom-right; suppressed via `proOptions.hideAttribution`).
5. Render `<SelectionListener>` (ticket 043).
6. Render `<StoreUpdater>` (ticket 043) which syncs ReactFlowProps into the store on every render.

## Idiomatic Notes

- **`fixedForwardRef`.** TS-only generics workaround. Use `React.FFI.React.forwardRef` directly; PS doesn't have the variance issue that `fixedForwardRef` solves.
- **Default values.** TS scatters `= defaultValue` in destructuring. PS centralises in `init-values.ts` and applies via `Maybe`-fallback at the call site (or via a helper that takes a `Partial`-style record and fills defaults).
- **`isNode` and `isEdge` already exist in system layer.** Re-export — don't reimplement.
- **`A11yDescriptions`** outputs a `<div role="region">` plus a `<div aria-live="polite">` updated by `state.ariaLiveMessage`.
- **`Attribution` is a small panel.** Renders a link to `https://reactflow.dev` unless `hideAttribution` is set in `proOptions`. Pure conditional render.
- **Wrapper detects existing provider.** Reads `useContext storeContext`; if present, passes through; otherwise wraps in `<ReactFlowProvider>`. Match TS.

## New Spago Dependencies
- None new

## Prerequisite Tickets
- 022, 024
- 041 (GraphView)
- 043 (Providers — but the *check for outer provider* in `Wrapper` requires context from 025 only; provider mounting waits on 043. Coordinate landing order)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `reactFlow` accepts all ~100 fields of `ReactFlowProps` and forwards correctly.
- `Wrapper` detects an outer `<ReactFlowProvider>` and skips re-wrapping.
- Default viewport is `{ x: 0, y: 0, zoom: 1 }`.
- `Attribution` is suppressed when `hideAttribution` is true.
- `A11yDescriptions` renders the ARIA structures expected by upstream a11y tests.
