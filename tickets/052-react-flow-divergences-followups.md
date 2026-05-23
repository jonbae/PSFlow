# 052 — Divergences from tickets 041 / 042 / 043

## Context

The implementation pass for tickets [041 (GraphView)](041-react-graph-view.md),
[042 (ReactFlow)](042-react-flow-component.md), and
[043 (Providers)](043-react-providers.md) landed with six intentional
divergences from the ticket text. Each is documented in the relevant
module header on `master`; this ticket collects them in one place so
they can be tracked, prioritised, and closed independently.

None of the items below blocks the public API surface — `spago build`
and `spago test` are green, and the structural acceptance criteria for
041/042/043 are met. They're follow-ups that tighten fidelity to the
upstream TS source or remove workarounds.

## Items

### 1. Dev-time warning hooks gate on `state.debug`, not `process.env.NODE_ENV`

**TS:** `if (process.env.NODE_ENV === 'development') { … }` in
[useNodeOrEdgeTypesWarning.ts:22](../xyflow-main/packages/react/src/container/GraphView/useNodeOrEdgeTypesWarning.ts)
and [useStylesLoadedWarning.ts:11](../xyflow-main/packages/react/src/container/GraphView/useStylesLoadedWarning.ts).

**PS port:** Gates on the runtime `state.debug :: Boolean` set on the
provider — there is no `process.env.NODE_ENV` equivalent in the
PureScript output we produce, and dead-code-elimination on warning
calls is not free in PS.

**Files:**
- [src/React/Hook/NodeOrEdgeTypesWarning.purs](../src/React/Hook/NodeOrEdgeTypesWarning.purs)
- [src/React/Hook/StylesLoadedWarning.purs](../src/React/Hook/StylesLoadedWarning.purs)

**Proposed remediation:** Replace the `state.debug` check with a
compile-time flag exposed as a `foreign import isDevelopment ::
Boolean` that JS bundlers (webpack/esbuild) can constant-fold via
`define`. Users opt in via a build-time `define` on `IS_DEV` or
similar. Falls back to `true` so behaviour matches TS dev-mode
default for anyone not configuring the bundler.

### 2. `isNode` / `isEdge` live at the React layer, not in `System.Utils.Graph`

**TS:** [react/utils/general.ts:27,51](../xyflow-main/packages/react/src/utils/general.ts)
re-exports `isNodeBase` / `isEdgeBase` from
[system/utils/graph.ts:39,49](../xyflow-main/packages/system/src/utils/graph.ts).

**PS port:** The ticket text said "re-export from system layer" but
verification showed no standalone `isNodeBase` / `isEdgeBase` in
`src/System/`. The React-layer guards were added directly with a JS
sidecar. Functionally equivalent, just sited differently.

**Files:**
- [src/React/Util/General.purs](../src/React/Util/General.purs) and
  its `.js` sidecar.

**Proposed remediation:** Move the field-presence FFI into
`src/System/Utils/Graph.purs` (matching the TS file layout). Have
`React.Util.General` re-export. Add QuickCheck tests covering the
"missing `position`" and "extra `source`" boundary cases.

### 3. `ReactFlowProps.children` widened from `Maybe JSX` to `ReactChildren JSX`

**TS:** `children?: ReactNode` — a single node, or an array, or
nothing. TS doesn't distinguish a single child from an array.

**PS port (before this pass):** `children :: Maybe JSX`. This crashed
`reactComponent` ("Lacks 'children'") because React reserves the
`children` field name.

**Files:**
- [src/React/Types/Component.purs](../src/React/Types/Component.purs) —
  `ReactFlowProps` field type.
- [src/React/Container/ReactFlow.purs](../src/React/Container/ReactFlow.purs) —
  uses `reactComponentWithChildren` and `reactChildrenToArray`.

**Proposed remediation:** No revert. The current shape is the React-
idiomatic encoding: users wrap a single child via
`reactChildrenFromArray [child]`, which matches how they'd pass children
to any other built-via-`reactComponentWithChildren` PS component
(e.g., the existing `flowRenderer`, `pane`, `viewport`). Document this
prominently in `React.Container.ReactFlow`'s header and in the public
README when one lands.

### 4. `multiSelectionKeyCode` and `zoomActivationKeyCode` default to `"Control"`, not `isMacOs ? "Meta" : "Control"`

**TS:** [ReactFlow/index.tsx:73-74](../xyflow-main/packages/react/src/container/ReactFlow/index.tsx)
defaults via `isMacOs() ? 'Meta' : 'Control'`. The check happens
synchronously at render time.

**PS port:** Hard-coded to `"Control"`. The existing `System.Utils.General.isMacOs`
is `Effect Boolean`, which can't be called during render without
plumbing through a `useEffect`-resolved state slot or an
`unsafePerformEffect` call.

**Files:**
- [src/React/Container/ReactFlow.purs](../src/React/Container/ReactFlow.purs) —
  the `defaultMultiSelKey` binding.

**Proposed remediation:** Wrap `isMacOs` in a module-level
`unsafePerformEffect` so the value is computed once at module load.
Same trick as `infiniteExtent` constants. Then default to
`if isMacOs then SingleKey "Meta" else SingleKey "Control"`. Safe
because `navigator.userAgent` doesn't change between page loads.

### 5. `fixedForwardRef` and outer-div `ref` not exposed

**TS:** `export default fixedForwardRef(ReactFlow)` —
[ReactFlow/index.tsx:349](../xyflow-main/packages/react/src/container/ReactFlow/index.tsx).
TS only needs `fixedForwardRef` to work around a generics-variance
issue specific to TypeScript. Ticket 042's "Idiomatic Notes" explicitly
OKs skipping this.

**PS port:** `reactFlow` is exported directly. Users cannot attach a
`Ref` to the outer `<div>`.

**Files:**
- [src/React/Container/ReactFlow.purs](../src/React/Container/ReactFlow.purs).

**Proposed remediation:** Add an explicit `outerRef :: Maybe (Ref
HTMLDivElement)` field to `ReactFlowProps` and pass it through to
`div_` via the existing `React.FFI.ForwardRef.forwardRef` helper. Or
add a wrapper component `reactFlowWithRef` for callers that need it.

### 6. `wrapperOnScroll` focus-scroll-reset omitted

**TS:** [ReactFlow/index.tsx:161-167](../xyflow-main/packages/react/src/container/ReactFlow/index.tsx)
installs a scroll handler that immediately scrolls the outer div back
to `(0, 0)` whenever the browser's tab-focus logic scrolls a focused
node into view. Without this, focusing a node outside the viewport
scrolls the wrapper instead of moving the flow's transform.

**PS port:** Skipped — not in the acceptance criteria for 042 and
required a careful `React.UIEvent` handler decision.

**Files:**
- [src/React/Container/ReactFlow.purs](../src/React/Container/ReactFlow.purs).

**Proposed remediation:** Add a `useCallback`-equivalent stable
handler that does
`e.currentTarget.scrollTo({ top: 0, left: 0, behavior: 'instant' })`
then forwards to `props.onScroll`. Add `onScroll :: Maybe (UIEvent ->
Effect Unit)` to `ReactFlowProps` (currently absent). Need a small FFI
for `scrollTo`.

### 7. `StoreUpdater`'s `previousFields` ref replaced by per-effect identity gating

**TS:** [StoreUpdater/index.tsx:138-167](../xyflow-main/packages/react/src/components/StoreUpdater/index.tsx)
maintains a `useRef<Partial<StoreUpdaterProps>>` and compares
`fieldValue === previousFieldValue` before dispatching. The full TS
effect dep array is `fieldsToTrack.map(f => props[f])` — one effect
with N deps.

**PS port:** N effects, each with a single-element `UnsafeReference
prop.field` dep. React's per-call identity check gives the same gate.

**Files:**
- [src/React/Provider/StoreUpdater.purs](../src/React/Provider/StoreUpdater.purs).

**Proposed remediation:** Leave as-is — the PS approach is cleaner
and behaviourally identical. Document the design decision in the
module header (it already is). Close this item without code change.

## Files touched (when all items close)

- `src/React/Hook/NodeOrEdgeTypesWarning.purs`
- `src/React/Hook/StylesLoadedWarning.purs`
- `src/React/Util/General.purs` (move to `src/System/Utils/Graph.purs`
  with React-side re-export)
- `src/React/Container/ReactFlow.purs` (items 4, 5, 6)
- `src/React/Types/Component.purs` (items 5, 6 add optional fields)
- `src/System/Utils/Graph.purs` (item 2 receives moved guards)

## Acceptance criteria

For items 1, 2, 4, 5, 6 (code changes):
- `spago build` and `spago test` pass with zero warnings after each
  item lands.
- The relevant module header comment for each divergence is removed
  (it no longer diverges) or updated to reference the new behaviour.
- For item 5 (`outerRef`), include a smoke test demonstrating that a
  `Ref` passed via `ReactFlowProps` reaches the outer `<div>`.

For items 3 and 7 (intentional, no code change):
- Update the module header comments to clarify the design choice was
  deliberate, not a workaround.
- Close the item with a commit message that references this ticket.

## Prerequisite tickets

- 041, 042, 043 — the implementation pass that introduced these
  divergences.

## Notes

These items can land independently in any order. None requires
coordinated changes across modules.
