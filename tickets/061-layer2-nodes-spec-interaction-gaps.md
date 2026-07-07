# 061 — Layer 2: node-interaction parity gaps (nodes.spec)

## Context

Layer 2 stands up xyflow's own framework-parameterized e2e specs against a ported
fixture app. The first slice ports `generic-tests/nodes/general` and adopts
`xyflow/tests/playwright/e2e/nodes.spec.ts`:

- harness/router/fixture: `examples/react-smoke/src/Generic/{Defaults,Fixture,Flow}.purs`
  + hash routing in `examples/react-smoke/src/Example/Main.purs`
- adopted spec: `examples/react-smoke/tests/generic-nodes.spec.ts`
  (run via `npm run build:smoke` + `npm run test:smoke`)

**Result: 6 / 13 pass.** Passing: `selectable=false`, `draggable=false`,
`deletable=false`, **connecting two nodes** (drag-connect commits a new edge),
`connectable=false`, `hidden=true`. The 7 failures break down below. Two are
already tracked (ticket 060); the rest are genuine node-interaction parity bugs
the callback-only smoke tests missed.

Note: the negative tests (`*=false`) currently pass *trivially* — when the
positive interaction is broken, "nothing happens" satisfies them. They become
meaningful only once the positives below are fixed.

## Resolution (2026-06-27) — now 10 / 13 pass

Gaps **1, 2, 3, 5 resolved**. Newly green: `selecting a node by click`,
`dragging a node`, `custom drag handle works`, `deleting a node and its edges`
(and the `*=false` negatives now assert real prevention, not absence of
behavior). Remaining reds: gap 4 (`selecting multiple nodes with shift drag` —
deferred, separate Pane wiring) and gaps 6/7 (`classes`/`styles` — ticket 060).

## Resolution (2026-07-07) — now 11 / 13 pass

Gap **4 resolved** — but the cause was `fitView`, not the Pane (see finding 4).
Fix in `src/React/Hook/ResizeHandler.purs` (synchronous initial `getDimensions`
+ `|| 500` fallback, matching upstream `useResizeHandler.ts`) restored a correct
initial viewport, which then required a delete-prevention fix in
`src/React/Hook/GlobalKeyHandler.purs` (exclude `deletable == Just false`) to
keep `deletable=false prevents deletion` green. Only remaining reds: gaps 6/7
(`classes`/`styles` — ticket 060).

## Resolution (2026-07-07 #2) — now 13 / 13 pass

Gaps **6 & 7 resolved** (ticket 060, Option 1). `generic-nodes.spec.ts` is fully
green and the 11 other smoke tests stay green (full smoke suite 24/24). See
finding 6 & 7 below and ticket 060's resolution note (incl. the
`Maybe (Object String)` vs `Foreign` deviation, needed to keep `InternalNode`'s
`Eq` instance).

Gap 2 was *not* the test-only artifact it first looked like: the underlying
cause is a real missing port (see below), and the delete test (gap 3) clicks-to-
select before pressing the delete key, so gap 3 couldn't go green without it.
Gap 1 also had a second root cause beyond the planned `nodeLookup` sync. Fixes:

- `src/React/Store/Reduce.purs` — `reduceTriggerNodeChanges` now re-adopts the
  lookup (shared `adoptNodesInto` helper) in the uncontrolled branch, so
  committed drag/delete changes re-render. (gaps 1 + 3)
- `src/System/XYDrag.purs` — `updateNodes` now persists the
  `calculateNodePosition` result back into `dragItems`
  (`position`/`internals.positionAbsolute`), matching TS's mutation; without it
  every live + drag-end dispatch carried stale coordinates and the node never
  moved. (gap 1)
- `src/React/Hook/Drag.purs` + `NodeWrapper`/`NodesSelection` — wire
  `useDrag`'s `onNodeMouseDown` to `handleNodeClick` (was hardcoded `Nothing`),
  porting `useDrag.ts`. This restores `selectNodesOnDrag` selection — the only
  select path when `nodeDragThreshold == 0`. (gap 2, unblocks gap 3)
- `examples/react-smoke/src/Generic/DragHandleNode.purs` (+ `Fixture`/`Flow`) —
  port the custom node and register it via `nodeTypes`. (gap 5)

## Findings

### 1. Node drag doesn't move the rendered node  (parity bug) — RESOLVED
`reduceUpdateNodePositions` (`src/React/Store/Reduce.purs:238`) builds
`NodePositionChange`s and calls `reduceTriggerNodeChanges`, which updates
`state.nodes` (only when `hasDefaultNodes`) and fires `onNodesChange` — but it
**never updates `state.nodeLookup`**, which is what `NodeWrapper` renders from
(transform = `node.internals.positionAbsolute`). Contrast:
- `reduceSetNodes` (`:138`) re-adopts → updates `nodeLookup` (so *controlled*
  mode works: drag → onNodesChange → app setNodes → SetNodes → re-adopt → moves).
- `reduceAddSelectedNodes` (`:288`) *does* update `nodeLookup` directly.

So *uncontrolled* drag emits the change but the node stays put. Symptom:
`dragging a node` sees `transform` stuck at `translate(0px, 0px)`. The smoke
"node drag fires onNodesChange" test passed because it only checks the callback.
**Fix:** in `reduceUpdateNodePositions`, also write each drag item's
`position` + `internals.positionAbsolute` (and `dragging`) into `nodeLookup`
before/with `reduceTriggerNodeChanges` (mirrors xyflow's store `updateNodePositions`,
which mutates the internal node for smooth drag regardless of controlled state).

### 2. `nodeDragThreshold: 0` suppresses click-to-select  (parity bug) — RESOLVED

Real cause (not the "narrow artifact" first assumed): `useDrag`'s
`onNodeMouseDown` was hardcoded `Nothing`, so the `selectNodesOnDrag` selection
path never fired. With `nodeDragThreshold == 0` the wrapper's `onClick` defers to
that path entirely, so nothing selected. Fixed by wiring `onNodeMouseDown →
handleNodeClick`.
With the fixture's `nodeDragThreshold: 0` (from upstream `general.ts`),
`selecting a node by click` fails (no `selected` class). Neutralizing the
threshold makes it pass — so with threshold 0, the drag subsystem captures the
pointer on mousedown and the click→select never dispatches `AddSelectedNodes`.
xyflow handles threshold-0 click-select (a 0-distance drag is treated as a click).
**Fix:** in the node drag/click path (`src/React/Hook/Drag.purs` / `System.XYDrag`
/ NodeWrapper `onClick`), select on a zero-distance drag-stop, or don't let a
threshold-0 drag swallow the click.

### 3. Delete key doesn't remove a selected node  (parity bug) — RESOLVED
`deleting a node and its edges` fails *even after* selection works (verified with
the threshold neutralized): Node-1 is selected, `d` is pressed (fixture
`deleteKeyCode: 'd'`), but the node stays attached. The delete flow isn't
committing the removal to `nodeLookup`/`edgeLookup` (or isn't triggered).
**Fix:** trace `deleteKeyCode` → GlobalKeyHandler → delete dispatch → store
(`getNodesToDelete`/remove) and ensure the lookups update, like ticket 060/this
ticket's lookup-sync theme.

### 4. Shift-drag selection box doesn't select  (parity bug) — RESOLVED
`selecting multiple nodes with shift drag` failed: the `.react-flow__selection`
rectangle never entered the viewport. **The Pane user-selection wiring was not
the cause** — instrumenting it showed the lasso path works end-to-end (rect
commits, nodes select) for an on-screen drag. The real cause was **`fitView`
positioning the nodes off-screen**: the test starts its drag at `box.x - 150,
box.y - 25`, and `box` sat at negative screen coords (transform
`translate(-50, -155.5) scale(0.5)`), so the `pointerdown` landed off the pane.

Root cause: `src/React/Hook/ResizeHandler.purs` never did the **synchronous
initial dimension measurement** upstream's `useResizeHandler.ts` does (nor its
`|| 500` fallback). The container `width`/`height` were still ~0 when the node
ResizeObservers fired and resolved the queued initial `fitView`, so the fit ran
against a zero-size container and produced a garbage viewport. **Fix:** mirror
upstream — read `getDimensions` synchronously on mount (seeding `width`/`height`
before the fit resolves) with the `|| 500` fallback, and re-measure via the
observer.

Un-masked bug (fixed here too): with nodes now on-screen, `deletable=false
prevents deletion` began failing — the `notDeletable` node could finally be
clicked/selected, and `useGlobalKeyHandler` was removing **every** selected node
without checking `deletable`. Fixed by excluding `deletable == Just false`
nodes/edges from the removal changes (mirrors `getElementsToRemove`).

### 5. `custom drag handle works`  (missing fixture component) — RESOLVED
The `drag-handle` node uses `type: 'DragHandleNode'` with
`dragHandle: '.custom-drag-handle'`. No `DragHandleNode` component is ported, so
the node falls back to default and has no `.custom-drag-handle` element. **Fix:**
port the small `DragHandleNode` custom node into the fixture app + register it via
`nodeTypes`.

### 6 & 7. `classes get applied` / `styles get applied` — RESOLVED
Node `className` / `style` now carried (ticket 060, Option 1). Added
`className`/`style` to `NodeBaseRow`, a user-class slot to `buildNodeClassName`,
and a `base → node.style → inlineDimensions` merge in `mergedStyle`; fixture
`Node-1` sets both. `style` is `Maybe (Object String)` (not `Foreign`) so
`InternalNode` keeps its `Eq` for `useStore` memoization/tests — see ticket 060's
resolution note.

## Acceptance criteria

- `npm run build:smoke && npm run test:smoke` → `generic-nodes.spec.ts` all green
  (with 060 + this ticket's fixes), and the existing 11 smoke tests stay green.
- The negative `*=false` tests still pass once the positives do (i.e. they now
  assert real prevention, not absence of behavior).

## Source files

- `src/React/Store/Reduce.purs` — `reduceUpdateNodePositions` (238), `reduceTriggerNodeChanges` (261)
- `src/React/Hook/Drag.purs`, `src/System/XYDrag.purs` — threshold/click-vs-drag
- `src/React/Hook/GlobalKeyHandler.purs` + delete dispatch — delete flow
- `src/React/Container/Pane*` — selection rectangle
- `examples/react-smoke/tests/generic-nodes.spec.ts`, `examples/react-smoke/src/Generic/*`
- Reference: `xyflow/tests/playwright/e2e/nodes.spec.ts`, `xyflow/examples/react/src/generic-tests/nodes/**`

## Follow-up — remaining Layer 2 e2e specs

`nodes.spec` is the first of xyflow's five e2e specs. The other four are tracked
as one ticket each, ported one at a time using this ticket's recipe (sequence:
pane → edges → node-toolbar → props):

- [062](062-layer2-pane-spec.md) — `pane.spec` (pan/zoom/auto-pan; no expected source gaps)
- [063](063-layer2-edges-spec.md) — `edges.spec` (edge `className`/`style` source gaps, cf. [060](060-node-classname-style-presentational-fields.md))
- [064](064-layer2-node-toolbar-spec.md) — `node-toolbar.spec` (custom `ToolbarNode` + `NodeToolbar` data-id `.trim()` fix)
- [065](065-layer2-props-colormode-spec.md) — `props.spec` (bespoke ColorMode page, minimal)
