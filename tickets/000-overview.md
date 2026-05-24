# 000 — Project Overview: xyflow System Package → PureScript

> React layer port complete (2026-05-23) — see ticket [053](053-react-runtime-verification.md). All non-blocked smoke-test items from the runtime checklist pass against a real browser; the remaining two items (node-drag, click-connect) are gated on the `<Handle>` connection-drag wiring tracked under [052](052-react-flow-divergences-followups.md).

## Summary

This document is the root index for porting the `@xyflow/system` TypeScript package to idiomatic PureScript. The source monorepo lives at `xyflow-main/packages/system/src/`. The React-specific layer (`xyflow-main/packages/react/src/`) is not covered here — it requires a separate planning pass involving React FFI bindings and is out of scope for this phase.

The PureScript library is called `ps-flow`. Tickets are placed under `tickets/` and numbered for dependency ordering.

---

## Scope of Conversion

### Included (all 20 tickets below)
- All types from `types/` (geometry, handles, connections, nodes, edges, pan/zoom interfaces)
- All utility functions from `utils/` (general math, graph traversal, DOM helpers, edge paths, store operations, connections, toolbars, markers)
- All system controllers from `xydrag/`, `xyhandle/`, `xypanzoom/`, `xyresizer/`, `xyminimap/`
- Constants from `constants.ts`

### Excluded (React layer)
- `packages/react/src/` — React component rendering, hooks (`useReactFlow`, `useStore`, etc.), Zustand store, TSX components. These require React FFI or a completely different rendering approach (e.g. Halogen). A follow-up planning exercise is needed.

---

## Ticket Dependency Order

Execute tickets in this order. A ticket may only begin when all its prerequisites are complete.

```
001 Geometry Types                    (no prerequisites)
002 Handle Types                      (001)
003 Connection & Viewport Types       (001, 002)
004 Node Types                        (001, 002, 003)
005 Edge Types                        (001, 003)
006 PanZoom Interface Types           (001, 003)
007 Constants                         (001)
008 Utils.General                     (001, 003, 004, 007)
009 Utils.Graph                       (001, 003, 004, 005, 006, 007, 008)
010 Utils.Store                       (001, 004, 005, 006, 008, 009)
011 Utils.Dom                         (001, 002, 008)
012 Utils.Connections                 (003)
013 Utils.Edges                       (001, 002, 003, 004, 005)
014 Utils.Toolbar                     (001, 003, 004, 005)
015 Utils.ShallowNodeData             (004)
016 XYDrag                            (001, 004, 005, 008, 011)
017 XYHandle                          (001, 002, 003, 004, 006, 008, 011, 013)
018 XYPanZoom                         (001, 003, 006, 008)
019 XYResizer                         (001, 004, 008, 011, 016)
020 XYMinimap                         (001, 006, 008, 018)
```

### Parallelism opportunities
After completing tickets 001–003, several streams can proceed in parallel:
- Stream A: 004 → 009 → 010
- Stream B: 005 → 013
- Stream C: 007 → 008 → 011
- Stream D: 006 → 018 → 020
- Stream E: 012 (depends only on 003)
- Stream F: 014, 015 (thin tickets, depend on types only)
- Stream G: 016, 017, 019 (controllers — after DOM and type tickets)

---

## Proposed PureScript Module Structure

```
src/
  XYFlow/
    Types/
      Geometry.purs       (001)
      Handle.purs         (002)
      Connection.purs     (003)
      Node.purs           (004)
      Edge.purs           (005)
      PanZoom.purs        (006)
    Constants.purs        (007)
    Utils/
      General.purs        (008)
      Graph.purs          (009)
      Store.purs          (010)
      Dom.purs            (011)
      Dom.js              (FFI for 011)
      Connections.purs    (012)
      Edges.purs          (013 re-export)
      Edges/
        Straight.purs
        Bezier.purs
        SmoothStep.purs
        General.purs
        Positions.purs
      Marker.purs
      Toolbar.purs        (014)
      ShallowNodeData.purs(015)
    XYDrag.purs           (016)
    XYDrag.js             (FFI)
    XYDrag/
      Utils.purs
    XYHandle.purs         (017)
    XYHandle/
      Utils.purs
    XYPanZoom.purs        (018)
    XYPanZoom/
      EventHandler.purs
      Filter.purs
      Utils.purs
    XYPanZoom.js          (FFI)
    XYResizer.purs        (019)
    XYResizer.js          (FFI)
    XYResizer/
      Utils.purs
    XYMinimap.purs        (020)
    XYMinimap.js          (FFI)
    FFI/
      D3Drag.purs         (shared d3-drag bindings)
      D3Drag.js
      D3Zoom.purs         (shared d3-zoom bindings)
      D3Zoom.js
      D3Selection.purs    (shared d3-selection bindings)
      D3Selection.js
```

---

## TypeScript Patterns and Their PureScript Treatment

### Patterns solvable in pure PureScript (no FFI)

| TS Pattern | PS Approach |
|---|---|
| `enum X { A = 'a', B = 'b' }` | `data X = A \| B` with `Eq`, `Show`, `Bounded`, `Enum` |
| `type X = 'a' \| 'b' \| 'c'` (string union) | `data X = A \| B \| C` |
| `interface X { field?: T }` (optional field) | `field :: Maybe T` in the record |
| `type X = A & B` (intersection) | Flat record merging all fields |
| `type X = A \| B` (discriminated union) | `data X = XA A \| XB B` |
| `[T, U]` (tuple as return) | Named record `{ first :: T, second :: U }` |
| `[number, number]` (geometric pair) | `newtype` with labelled fields (e.g. `NodeOrigin`) |
| `Map<K, V>` (immutable use) | `Data.Map.Map k v` |
| `Set<T>` | `Data.Set.Set t` |
| Recursive functions | Direct PS recursion |
| `Promise<T>` | `Aff T` |
| `void` return (side effects) | `Effect Unit` |
| Optional function params | Explicit `Maybe` args or separate helper functions |
| `Partial<T>` | Record with all fields wrapped in `Maybe`, or a separate override type |
| `Required<T>` | Concrete record with no `Maybe` wrappers |
| `Omit<T, K>` | New concrete record type without those fields |
| `Pick<T, K>` | New concrete record type with only those fields |

### Patterns requiring FFI

| TS Pattern / Dependency | FFI Strategy |
|---|---|
| `d3-drag` (drag behavior) | `XYFlow.FFI.D3Drag` — wrap `drag()`, event handler attachment, filter |
| `d3-zoom` (zoom behavior) | `XYFlow.FFI.D3Zoom` — wrap `zoom()`, `scaleTo`, `scaleBy`, `translateBy`, `constrain`, `transform` |
| `d3-selection` (`select`, `pointer`) | `XYFlow.FFI.D3Selection` — wrap `select()` and `pointer()` |
| `d3-interpolate` (`interpolateZoom`, `interpolate`) | Used inside d3 zoom calls — handled within D3Zoom FFI |
| `d3-transition` (`transition`) | Side-effect import only (no PS surface needed) |
| `ZoomTransform` (d3 type) | Opaque `newtype ZoomTransform = ZoomTransform Foreign` with FFI accessors |
| `requestAnimationFrame` / `cancelAnimationFrame` | `foreign import requestAnimationFrame :: Effect Unit -> Effect Int` |
| `setTimeout` / `clearTimeout` | `foreign import setTimeout :: Effect Unit -> Int -> Effect TimeoutId` |
| DOM `getBoundingClientRect` | `web-html` package (preferred) or thin FFI |
| DOM `querySelectorAll`, `getAttribute` | `web-dom` package |
| DOM `composedPath`, `closest` | `web-events` / `web-dom` packages or thin FFI |
| DOM `window.DOMMatrixReadOnly` | Thin FFI shim |
| DOM `getComputedStyle` | Thin FFI shim |
| `navigator.userAgent` | Thin FFI shim (for `isMacOs`) |
| `document.elementFromPoint` | Thin FFI shim |

### Patterns intentionally not ported

| TS Feature | Reason Omitted |
|---|---|
| `process.env.NODE_ENV` checks | Replaced by explicit `isDev :: Boolean` parameter |
| `Object.is` reference equality | PS has no reference equality; structural `Eq` used instead (documented divergence) |
| `DistributivePick<T, K>` utility type | TS compiler workaround; not needed in PS |
| `Optional<T, K>` utility type | Replace with concrete record types at each use site |
| `any` / `unknown` in public API | Replaced by concrete types or type variables with constraints |
| React hooks and component types | Out of scope (React layer) |
| Zustand store types | Out of scope (React layer) |
| CSS styles (`base.css`, `style.css`) | Not a PureScript concern |
| `console.warn` / `console.error` in pure functions | Moved to `Effect` callbacks or caller responsibility |

---

## Complete Spago Dependency List

The following packages must be added to `spago.yaml` across the full port. The existing project already has `console`, `effect`, `foldable-traversable`, `lists`, `prelude`.

| Package | First needed in ticket |
|---|---|
| `maybe` | 002 |
| `either` | 003 |
| `ordered-collections` | 003 (for `Map`, `Set`) |
| `aff` | 006 |
| `refs` | 010 |
| `foreign` | 006 (for opaque d3 types) |
| `web-events` | 006 |
| `web-html` | 006 |
| `web-dom` | 011 |
| `effect-uncurried` | 011 |
| `arrays` | 001 (already a transitive dep; add explicitly) |
| `tuples` | Used in `Tuple` if needed (minor) |
| `strings` | Marker ID generation (013) |
| `integers` | For `Int` round-trip utilities |
| `math` | For `Math.sqrt`, `Math.pow`, `Math.round` (pure in PS) |
| `control` | ST monad for local mutable state in handlers |
| `newtype` | For `newtype` deriving |
| `generics-rep` | For deriving `Bounded`/`Enum` on ADTs |

> Note: `math` operations (`Math.sqrt`, `Math.pow`, `Math.min`, `Math.max`, `Math.abs`, `Math.round`, `Math.ceil`, `Math.floor`) are available from `Data.Number` in the `numbers` package in PureScript, or directly from the `Prelude`'s `Semiring`/`Ring` instances. Verify which package version provides `Data.Number` at registry version 76.2.1.

---

## Key Design Decisions

1. **All TS tuples used as geometric pairs become `newtype`-wrapped records.** `Transform`, `CoordinateExtent`, `NodeOrigin`, `SnapGrid` — all get labelled fields. This is the most important safety decision in the port.

2. **`NodeChange` and `EdgeChange` are ADTs, not tagged records.** The TS `type: 'dimensions' | 'position' | ...` discriminant field is replaced by constructors. No stringly-typed dispatch.

3. **`ConnectionState` is an ADT.** `NoConnection | ConnectionInProgress data` instead of `{ inProgress: boolean, ... }`. Pattern matching replaces all `if (state.inProgress)` checks.

4. **Mutable store operations use `Ref`.** `adoptUserNodes`, `updateNodeInternals`, `updateConnectionLookup` take `Ref (Map ...)` parameters rather than mutating in-place.

5. **DOM functions are `Effect`.** Every function that reads from the DOM is typed as `Effect a`, making the boundary explicit.

6. **Async operations are `Aff`.** All `Promise<T>` return types become `Aff T`. No fire-and-forget implicit promises.

7. **`PanZoomInstance` is a record of functions.** The TS interface becomes a plain PS record whose fields are `Effect`- or `Aff`-typed functions. This is the standard PS "service object" pattern.

8. **d3 types are opaque.** `D3ZoomBehavior`, `D3Selection`, `ZoomTransform` are newtypes over `Foreign`. They do not expose their fields to PS code; accessors are provided via thin FFI.

9. **No type guards.** TS `isEdgeBase`, `isNodeBase`, `isInternalNodeBase` runtime guards are eliminated. PS's type system enforces structure statically.

10. **Error-returning functions over throwing.** Any TS function that could throw (e.g. due to missing map entries) becomes a total `Maybe`-returning function in PS.

---

> Note (2026-05): the system port directory was renamed `src/XYFlow/` → `src/System/` in ticket 022 to match `xyflow-main/packages/system/`. Module paths in tickets 001–021 read `XYFlow.*` for historical accuracy; on disk they are `System.*`.
