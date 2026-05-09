# 029 — Hooks: Listener registration

## Title
Port the listener-registration hooks: `useOnViewportChange`, `useOnSelectionChange`, `useOnInitHandler`. Each registers an `Effect`-typed callback in the store and de-registers on unmount.

## Source Files
- `xyflow-main/packages/react/src/hooks/useOnViewportChange.ts`
- `xyflow-main/packages/react/src/hooks/useOnSelectionChange.ts`
- `xyflow-main/packages/react/src/hooks/useOnInitHandler.ts`

## Target Module
`React.Hook.Listeners`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `UseOnViewportChangeOptions = { onStart?, onChange?, onEnd? }` | `type UseOnViewportChangeOptions = { onStart :: Maybe (Viewport -> Effect Unit), onChange :: Maybe (Viewport -> Effect Unit), onEnd :: Maybe (Viewport -> Effect Unit) }` |
| `useOnViewportChange(opts)` | `useOnViewportChange :: UseOnViewportChangeOptions -> Hook _ Unit` |
| `UseOnSelectionChangeOptions = { onChange? }` | `type UseOnSelectionChangeOptions = { onChange :: Maybe (OnSelectionChangeParams -> Effect Unit) }` |
| `useOnSelectionChange(opts)` | `useOnSelectionChange :: UseOnSelectionChangeOptions -> Hook _ Unit` |
| `useOnInitHandler(onInit)` | `useOnInitHandler :: Maybe (ReactFlowInstance -> Effect Unit) -> Hook _ Unit` |

## Idiomatic Notes

- **Pattern: `useEffect` registers, returns cleanup.** Each hook does:
  1. Read store via `useStoreApi`.
  2. In `useEffect [callbacks]`, push the callback into the store's listener slot.
  3. Return an `Effect Unit` cleanup that pulls the callback back out.
- **`onSelectionChange` accumulates handlers.** TS uses `state.onSelectionChangeHandlers: Array<Callback>`. The action `AddSelectionChangeHandler cb` appends; `RemoveSelectionChangeHandler cb` pulls by reference equality. Use a newtyped `HandlerKey` (an `Int` from a counter) so removal is reliable.
- **`onViewportChange` slots are singular.** TS overwrites `state.onViewportChangeStart` etc. PS does the same — the `Action` constructor sets the field; cleanup sets it back to `Nothing`.
- **`useOnInitHandler` fires once.** Reads `state.viewportInitialized`; when it flips to `true`, fires `onInit` exactly once with the `ReactFlowInstance` from `useReactFlow`. Subsequent transitions are ignored. This requires a `Ref Boolean` (`hasFired`) inside the hook.
- **No callback comparison.** Don't try to dedupe by reference — let the user pass stable callbacks (memoised via `useCallback`).
- **`Effect Unit` cleanup discipline.** `useEffect` from `react-basic-hooks` expects a cleanup; return one even if it's `pure unit`.

## New Spago Dependencies
- None beyond ticket 027

## Prerequisite Tickets
- 027 (`useStoreApi`)
- 026 (the `Action` constructors `AddOnViewportChange*`, `RemoveOnViewportChange*`, `AddSelectionChangeHandler`, etc.)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- All three hooks follow the register-on-mount, deregister-on-unmount pattern.
- `useOnInitHandler` fires exactly once across the lifetime of the component, even if `viewportInitialized` transitions multiple times.
- `useOnSelectionChange` allows multiple components to subscribe simultaneously.
