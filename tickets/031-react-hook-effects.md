# 031 — Hooks: Internal effect hooks

## Title
Port the internal effect-handling hooks: `useDrag`, `useMoveSelectedNodes`, `useNodeObserver`, `useResizeHandler`, `useViewportSync`, `useGlobalKeyHandler`, `useKeyPress`, `useColorModeClass`, `useIsomorphicLayoutEffect`, plus the experimental middleware hooks.

## Source Files
- `xyflow-main/packages/react/src/hooks/useDrag.ts`
- `xyflow-main/packages/react/src/hooks/useMoveSelectedNodes.ts`
- `xyflow-main/packages/react/src/components/NodeWrapper/useNodeObserver.ts`
- `xyflow-main/packages/react/src/hooks/useResizeHandler.ts`
- `xyflow-main/packages/react/src/hooks/useViewportSync.ts`
- `xyflow-main/packages/react/src/hooks/useGlobalKeyHandler.ts`
- `xyflow-main/packages/react/src/hooks/useKeyPress.ts`
- `xyflow-main/packages/react/src/hooks/useColorModeClass.ts`
- `xyflow-main/packages/react/src/hooks/useIsomorphicLayoutEffect.ts`
- `xyflow-main/packages/react/src/hooks/useOnNodesChangeMiddleware.ts`
- `xyflow-main/packages/react/src/hooks/useOnEdgesChangeMiddleware.ts`

## Target Modules
One module per hook under `React.Hook.*` — see plan-file structure.

## Key Functions

| Hook | Signature |
|---|---|
| `useDrag` | `UseDragOptions -> Hook _ Boolean` (returns `dragging` flag) |
| `useMoveSelectedNodes` | `Hook _ (XYPosition -> Number -> Effect Unit)` (returns the move function) |
| `useNodeObserver` | `UseNodeObserverParams -> Hook _ Unit` |
| `useResizeHandler` | `Ref (Maybe HTMLDivElement) -> Hook _ Unit` |
| `useViewportSync` | `Maybe Viewport -> Hook _ Unit` |
| `useGlobalKeyHandler` | `UseGlobalKeyHandlerOptions -> Hook _ Unit` |
| `useKeyPress` | `KeyCode -> Maybe UseKeyPressOptions -> Hook _ Boolean` |
| `useColorModeClass` | `Maybe ColorMode -> Hook _ (Maybe ColorModeClass)` |
| `useIsomorphicLayoutEffect` | (helper, not a hook itself — see notes) |
| `experimental_useOnNodesChangeMiddleware` | `(NodeChange -> Effect (Maybe NodeChange)) -> Hook _ Unit` |
| `experimental_useOnEdgesChangeMiddleware` | `(EdgeChange -> Effect (Maybe EdgeChange)) -> Hook _ Unit` |

### `useDrag`

The biggest hook in this ticket. Wires `System.XYDrag` (ticket 016) into a React component lifecycle:

1. On mount, call `createXYDrag` to allocate a drag controller.
2. On `useEffect [dependencies]`, call `controller.update(params)` with the current drag config.
3. On unmount, call `controller.destroy`.

Returns the `dragging :: Boolean` flag from a local `useState`.

### `useNodeObserver`

Wraps `ResizeObserver`. On mount:
1. Create a `ResizeObserver` whose callback dispatches `UpdateNodeInternals` with measurements for the observed node IDs.
2. Observe the wrapper element via the passed `Ref`.
3. On unmount, disconnect.

`ResizeObserver` is a browser API — wrap via FFI in `React.FFI.ResizeObserver` (or use the `web-resize-observer` package if available at the registry version).

### `useKeyPress`

Polls `document` for keydown/keyup. Maintains a `Ref Boolean`. Returns the boolean. Uses `System.Utils.Dom.isMacOs` (ticket 011) for the modifier-key normalisation. Match the TS source's behaviour for `KeyCode` arrays (any-of-list match) and `actInsideInputWithModifier` option.

### `useGlobalKeyHandler`

Composes multiple `useKeyPress` calls (delete, multi-select, pan-activation) and dispatches the corresponding store actions. Each key produces an action (`TriggerDeleteSelected`, `SetMultiSelectionActive`, etc.).

### `useColorModeClass`

Reads the current `ColorMode` from props (defaulting to `system`). When `system`, listens to `prefers-color-scheme` via `matchMedia`. Returns `Maybe ColorModeClass`. The `matchMedia` listener cleanup runs on unmount. Use a thin FFI helper for `matchMedia`.

### `useIsomorphicLayoutEffect`

```purescript
useIsomorphicLayoutEffect :: forall deps. EffectFn1 deps Unit -> deps -> Effect Unit
```

The TS helper picks `useLayoutEffect` on the client and `useEffect` on the server (via `typeof window !== 'undefined'`). PS port: a helper that selects the effect via FFI based on a `hasWindow :: Effect Boolean` check — but in practice PS rarely runs in SSR, so this can collapse to `useLayoutEffect` with a comment about the divergence.

### Middleware hooks

`experimental_useOnNodesChangeMiddleware` registers an interceptor in the store's `onNodesChangeMiddlewareMap`. The shell (ticket 026) consults this map before dispatching `TriggerNodeChanges`; each registered fn can drop or transform a change. Use a `MiddlewareKey` newtype (`Int` from a per-mount counter) for unique registration.

## Idiomatic Notes

- **`useDrag` pulls from `System.XYDrag`.** Do not reimplement drag logic. The hook's only job is lifecycle wiring.
- **`ResizeObserver` is an FFI shim.** One module: `React.FFI.ResizeObserver` exposing `createResizeObserver`, `observe`, `unobserve`, `disconnect`. Single-use across this ticket and ticket 040 (`NodeRenderer`).
- **`document.addEventListener` is `Effect`.** Wrap in `web-events` or a thin FFI. Cleanup unsubscribes.
- **`matchMedia` is an FFI shim.** One function: `prefersDarkMode :: Effect (Effect (Boolean -> Effect Unit) -> Effect (Effect Unit))` (returns a subscribe fn that returns a cleanup). Verbose but honest.
- **Each hook returns its cleanup.** `useEffect` from `react-basic-hooks` requires this; don't forget the `pure (pure unit)` no-op.
- **`useDrag` re-runs the `update` call on dep change without re-creating the controller.** The TS source uses `useEffect([deps])` to call `update`; the constructor runs only once via `useMemo`.

## New Spago Dependencies
- `web-events` (already in system layer)
- `web-html` (for `Window`, `Document`)
- One of `web-resize-observer` or hand-rolled `React.FFI.ResizeObserver`

## Prerequisite Tickets
- 027 (`useStore`, `useStoreApi`)
- 026 (Action constructors)
- System tickets 011 (Dom utils — `isMacOs`, `isInputDOMNode`), 016 (XYDrag), 008 (General — `calcAutoPan`, `snapPosition`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- All 11 hooks listed exist with the proposed signatures.
- `useDrag` correctly initialises and tears down a drag controller across mount/unmount.
- `useNodeObserver` triggers `UpdateNodeInternals` actions on resize.
- `useKeyPress` returns `true` while the key is held and `false` otherwise.
- `useColorModeClass` updates when system color mode changes (requires manual browser test).
- Middleware hooks register and de-register cleanly with unique keys.
