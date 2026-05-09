# 023 — Project Overview: React Layer → PureScript

## Summary

This ticket is the root index for porting `@xyflow/react` (the React component layer) to PureScript, layered on top of the already-ported system modules under `System.*` (renamed in ticket 022). The result lives at `src/React/`, mirroring `xyflow-main/packages/react/src/` file-for-file.

Tickets 024–049 cover the layer end-to-end. This ticket establishes the dependency graph, parallelism map, FFI strategy, and the public API contract.

## Public API contract: identical to upstream

The PS port's exports mirror `xyflow-main/packages/react/src/index.ts` exactly — same names, same shapes, same semantics. No additions, no removals, no renames. The only allowed differences are standard PS-idiom translations:

- TS optional argument → `Maybe`
- TS callback `(x: A) => void` → `EffectFn1 A Unit` (or `A -> Effect Unit`)
- TS `Promise<T>` → `Aff T`
- TS class instance → record of `Effect`/`Aff`-typed methods

In particular both `useStore` and `useStoreApi` are preserved verbatim. `useStoreApi()` returns `{ getState, setState, subscribe }` with the same Zustand-compatible shape that third-party node components depend on.

## Rendering target

`purescript-react-basic-hooks`. Mirrors the source 1:1 (component-per-file, hook-per-file). Keeps React as the runtime so the existing CSS files (`base.css`, `style.css`) work unchanged. Halogen was considered and rejected — too large a conceptual rewrite, no React ref/portal correspondence, and the upstream CSS targets React-emitted class names.

## Store strategy

Redux pattern, implemented natively in PureScript. No FFI to `redux` or `zustand`.

- `React.Store.Action` — `Action` ADT (~16 named constructors + `PatchState` escape hatch) and `Effect_` ADT (side-effect descriptors).
- `React.Store.Reduce` — pure `reduce :: ReactFlowState -> Action -> { state, effects }`.
- `React.Store.Shell` — thin `Effect`-typed shell: `Ref ReactFlowState`, subscription list, `dispatch` runs the reducer and performs `Effect_` values.

`useStoreApi().setState(f)` is implemented as `dispatch (PatchState f)` — the contract is preserved while the typed common case still benefits from named reducers.

## Ticket Dependency Order

```
022 Rename XYFlow → System         (prerequisite)
023 Overview (this ticket)         (no prerequisites beyond 022)
024 React Types                    (023)
025 Contexts                       (024)
026 Store (reducer + shell)        (024)
027 Hook: Store/StoreApi           (025, 026)
028 Hook: Selectors                (027)
029 Hook: Listeners                (027)
030 Hook: useReactFlow + helpers   (027, 028, 029)
031 Hook: Internal effects         (027, plus System.XYDrag from 016)
032 Built-in Edge components       (024, plus System.Utils.Edges from 013)
033 Built-in Node components       (024, 028)
034 Handle component               (027, 028, plus System.XYHandle from 017)
035 NodeWrapper                    (027, 031, 034)
036 EdgeWrapper                    (027, 031)
037 Selection overlays             (027)
038 Pane                           (027, 030)
039 Viewport + ZoomPane            (027, 030, plus System.XYPanZoom from 018)
040 Renderers                      (035, 036)
041 GraphView                      (037, 038, 039, 040)
042 ReactFlow component            (041)
043 Providers                      (025, 026)
044 Portal components              (024)
045 Background                     (024)
046 Controls                       (027, 030)
047 MiniMap                        (027, 044, plus System.XYMinimap from 020)
048 NodeResizer + Toolbars         (044, plus System.XYResizer from 019)
049 Public API + smoke test        (all above)
```

### Parallelism opportunities

After 027 lands, the following streams can proceed in parallel:
- Stream A: 028 → 030 → 042
- Stream B: 029 → 042
- Stream C: 031 → 035 / 036
- Stream D: 032 / 033 / 034 (independent)
- Stream E: 037 / 038 / 039 → 041
- Stream F: 044 → 045 / 046 / 047 / 048 (after 044 lands)
- Stream G: 043 (depends only on 025, 026 — early)

## Proposed PureScript Module Structure

See the plan at `~/.claude/plans/read-xyflow-main-packages-react-convert-hazy-reddy.md` for the full tree. Top-level layout:

```
src/React/
  Types.purs / Types/...
  Context/
  Store/
  Hook/
  Edge/
  Node/
  Handle.purs
  Component/
  Container/
  Provider.purs / Provider/
  Portal/
  Additional/
  FFI/
```

## React Patterns and their PureScript Treatment

### Pure-PS (no FFI)

| TS Pattern | PS Approach |
|---|---|
| Functional component | `Component props` from `react-basic-hooks` via `mkComponent` |
| `useMemo(fn, deps)` | `useMemo deps fn` from `react-basic-hooks` |
| `useCallback(fn, deps)` | `useCallback deps fn` |
| `useState<T>(init)` | `useState init` returning `Tuple T (T -> Effect Unit)` |
| `useReducer` | `useReducer` (used inside store hooks if needed) |
| `useRef<T>(null)` | `useRef Nothing` returning `Ref (Maybe T)` |
| Custom hook | `Hook` newtype + `coerceHook` |
| `React.memo(C)` | `memo` from `react-basic-hooks` |
| Conditional rendering | PS `if`/pattern match returning `JSX` |
| `props.children` | `JSX` field on the props record |

### Requires FFI

| TS Pattern | FFI Strategy |
|---|---|
| `forwardRef` | `React.FFI.React.forwardRef` — thin wrapper |
| `displayName` | Set on the FFI side; not exposed to PS |
| `createPortal` | `React.Portal.FFI.createPortal :: JSX -> Node -> JSX` |
| `cloneElement` | Avoid; restructure to avoid where possible |
| `ResizeObserver` | `React.FFI.ResizeObserver` (or `web-resize-observer` dep) |
| `classcat` (`cc`) | Either keep as JS lib via FFI or inline the trivial conditional-class logic in PS |
| Zustand `createWithEqualityFn` | NOT used — replaced by `React.Store.Shell` |
| Zustand `useStore`/`useStoreApi` | NOT used — re-implemented in `React.Hook.Store` against the PS store |

### Intentionally not ported

| TS Feature | Reason |
|---|---|
| `process.env.NODE_ENV` warnings | Replaced by explicit `debug :: Boolean` field on the store |
| `displayName` strings (per-component) | Set inside FFI helper only |
| `fixedForwardRef` (TS-only generics workaround) | Use `React.FFI.React.forwardRef`; PS generics handle the original problem |
| `Partial<ReactFlowProps>` | Concrete prop record with `Maybe` fields |
| `React.PropsWithChildren` | Add `children :: JSX` to the prop record |
| Zustand's `shallow` equality | Replaced by deriving `Eq` on selector return records |

## Complete Spago Dependency Additions

In addition to those listed in `000-overview.md`:

| Package | First needed in ticket | Reason |
|---|---|---|
| `react-basic` | 024 | Core React types (`JSX`, `ReactElement`) |
| `react-basic-hooks` | 024 | Hooks API + `mkComponent`, `useState`, `useEffect`, etc. |
| `react-basic-dom` | 032 | DOM/SVG element constructors for built-in components |
| `web-resize-observer` (or thin FFI) | 031 | `useNodeObserver` |
| `unsafe-reference` | 027 | Reference-equality fast path for selectors (optional) |

## Key Design Decisions

1. **Public API mirrors xyflow exactly.** No renames, no additions, no behaviour drift. PS-idiom translations only.
2. **Store internals are pure functions.** All 16 named action methods become Action constructors handled by a pure reducer. `useStoreApi().setState` survives only as a `PatchState` escape-hatch action.
3. **One module per source file.** A reviewer reading both repos side-by-side should see line-for-line correspondence.
4. **No re-implementing system functionality.** All graph/geometry/drag/zoom/handle/resizer/minimap logic is imported from `System.*`.
5. **React stays as the runtime.** Existing CSS, JS interop, and consumer code keep working.
6. **`forwardRef`, `memo`, `createPortal` are FFI'd in one place.** `React.FFI.React` is the only module that imports React directly outside the store and the per-component definitions provided by `react-basic-hooks`.
