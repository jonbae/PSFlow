# AAMF Step 2: reconcile the existing port

Prepared 2026-11-07 against PSFlow
`04fd4f246eb02d311effbf4fb1debedcbc21ba01`, `@xyflow/react` 12.11.0,
`@xyflow/system` 0.0.77, and AAMF
`7dc475d81ef9796b5b90f57a29475eaafa375753`.

**The documentation portion of Step 2 is complete.** All 171 source files
have explicit mappings into the existing port, with symbol/caller context,
dispositions, evidence limits, and bounded follow-up work. The AAMF integration
and `getViewportForBounds` pilot are specified but unimplemented. AAMF remains
analysis-only: its normal source index is uncertified, and this session does
not authorize code changes. Step 3 was not started.

## Deliverables and decision

| Artifact | Contents |
|---|---|
| [Complete mapping](AAMF_STEP2_MAPPING.md) | 127 React and 44 system files; named declarations; existing `.purs` destinations; converters/FFI; observed callers; disposition and work routing |
| [Integration contract](AAMF_STEP2_INTEGRATION.md) | Verified AAMF capabilities, missing adapter requirements, authoritative task/checkpoint handoff, target context, project preservation, and the unexecuted pilot |
| This document | Evidence profiles, individual work contracts, ownership/dependencies, accepted representation decisions, and the stop point |

Retain AAMF's diagnostic inventory as reference material and carry subsequent
port tasks through PSFlow's current workflow. Do not feed its 120 provisional
source-driven tasks directly into phase 4. The map accounts for **121 task-source
files + 32 absorbed context files + 18 re-export-only files**. None of those
counts is a missing-feature or completion count.

The integration decision is scoped to the current docs-only work. Adapter cost
has not been estimated against the remaining port work. A future AAMF execution
requires both the Step 1 certification fixes and the integration acceptance
checks; this is not a completed autonomous AAMF migration.

## Evidence and review method

Source declarations were enumerated from the pinned TypeScript AST. Each file
was assigned existing target ownership explicitly, rather than through extension
replacement. The map links the source declarations, actual PureScript modules,
boundary converters, and existing FFI. Its caller appendix preserves distinct
cross-file symbol-call observations from the Step 1 diagnostic database.
Those observations remain partial and uncertified. Known caller chains from
source inspection are recorded in the work contracts below even when SCIP did
not record them.

This is a reconciliation for deciding what to retain and what to investigate or
finish. It is **not** a branch-by-branch equivalence review of all 2,484 indexed
symbols. A file containing an implementation does not prove its mechanism; a
crossed export does not prove mounted behavior; a declared hole does not prove
either. Retained implementations stay as dependencies/context instead of being
scheduled for wholesale translation.

The governing rules are [PORTING.md](PORTING.md), [CONTEXT.md](CONTEXT.md), and
[README.md](README.md#the-five-gates). Existing tests and committed reports
were read, not executed or refreshed. Their names below identify what they can
observe, with no new claim that they currently pass. In particular, the old
system and surface reports remain snapshots.

| Map profiles | Existing evidence and its precise limit |
|---|---|
| E01: exports/re-exports | [Manifest](src/Boundary.js), [JS entry](index.js), [surface extraction](parity/surface/extract-psflow.mjs): binding ownership, value shape and selected calls. Not a proof of each implementation body. The 18 re-export-only files remain indexed context. |
| E02: type/shape contracts | [Boundary drift check](parity/boundary/drift.mjs), [mount checks](parity/boundary/mount.mjs), [shape allowlist](parity/surface/allowlist.json): named members and selected conversion behavior. Type aliases alone cannot prove omission, reference identity, callback timing or all union cases. |
| E03: geometry | [Geometry properties](test/Test/Parity/Geometry.purs): direct PureScript values for bounds, coordinates and padding, including positive-dimension fit-view inputs. [Surface fixture](parity/surface/behavior.mjs) observes one six-argument JS viewport call. Neither covers every malformed/omitted direct-call padding argument. |
| E04: graph | [Graph properties](test/Test/Parity/Graph.purs): graph/bounds values. Surface fixtures call the JS graph utilities and guards, but the raw curried exports remain transitional. |
| E05: edge/marker/toolbar math | [Edges](test/Test/Parity/Edges.purs), [Marker](test/Test/Parity/Marker.purs), [Toolbar](test/Test/Parity/Toolbar.purs): pure return values. They do not mount every edge component or toolbar. |
| E06: changes | [Change properties](test/Test/Parity/Changes.purs) observe modeled value changes. [Issue 150](https://github.com/jonbae/PSFlow/issues/150) and surface exceptions explicitly record the unproved/broken consumer-object preservation contract. |
| E07: internals/store | [Store utilities](test/Test/System/Utils/Store.purs), [merge internals](test/Test/React/Store/MergeNodeInternals.purs), [update positions](test/Test/React/Store/UpdateNodePositions.purs), and API/hook traces observe selected state results. They do not establish original `internals.userNode` reference preservation. |
| E08: resize | [Resize utilities](src/System/XYResizer/Utils.purs) exist; [lifecycle](src/System/XYResizer.purs) ignores its state and emits initial/zero callback values. [Hole register](parity/system/coverage/holes.json) declares the absent resizer fixture/callback witnesses. Mountability does not establish resizing. |
| E09: store/selectors | [Internal store proxy](test/Test/React/Hook/Store.purs) exercises subscription semantics and server snapshots. [Connection projection](test/Test/React/Hook/ConnectionTo.purs) covers coordinate conversion. JS `useStore`/`useStoreApi` still throw; internal tests do not satisfy that public contract or all selector identity cases. |
| E10: listeners | Static source comparison finds timer/dependency and slot lifecycle differences. Existing hook probes can observe an installed callback, but do not prove removal/replacement/unmount semantics or the `onInit` timer. W08 supplies the missing local-proxy contracts. |
| E11/E12: rendering/store/drag | Focused [PureScript test modules](test/Test/React), [drag proxies](test/Test/System/XYDrag.purs), and scenarios such as `drag-node-reports-changes`, `drag-node-autopan`, `arrow-key-selected-node`, and `pane-click-keeps-selection-when-not-selectable` observe selected DOM/callback/state mechanisms. Stored self-inconsistency must be remeasured before treating differences as fix tasks. |
| E13: viewport | [Event handlers](test/Test/System/XYPanZoom/EventHandler.purs), [source events](test/Test/System/XYPanZoom/SourceEvents.purs), [viewport sync](test/Test/React/Hook/ViewportSync.purs), plus `viewport-helpers-with-options`, `pan-after-controlled-viewport-change` and `ctrl-wheel-pinches-with-panonscroll` observe timing/options and event provenance. They do not establish all gesture paths. |
| E14: connections | [Handle proxy](test/Test/System/XYHandle.purs), [final connection](test/Test/System/FinalConnectionState.purs), [connection ordering](test/Test/System/Utils/ConnectionOrder.purs), and `connect-handle-to-handle` observe validation, connection states/order and callbacks. PR195 is still open for null side bounds. |
| E15: chrome | Focused background offset/pattern, MiniMap/mask and NodeToolbar portal proxies under [test/Test/React/Additional](test/Test/React/Additional), plus the chrome scenarios, observe selected geometry, DOM and defaults. Icon ownership is shared in one module. |
| E16: mounted holes | [Coverage report](parity/system/coverage.md) and [hole reasons](parity/system/coverage/holes.json) distinguish a missing mounted witness from missing code. Add fixtures before claiming those components' behavior. |
| E17: default edges | [Refusal table](src/Boundary/Flow.purs) names 13 unsupported `defaultEdgeOptions` fields. No corpus fixture sets the options. A separate edge field or pure path function does not prove the flow defaults work. |
| E18: ambient declarations | `custom.d.ts` supplies TypeScript CSS/SVG declarations. It needs no runtime PureScript body; this accepts no visual or behavior difference. |

## Current issue/PR coordination

GitHub was checked read-only on 2026-11-07 using the repository's
[tracker convention](.claude/issue-tracker.md):

- [Issue 150](https://github.com/jonbae/PSFlow/issues/150) remains open. Its
  prerequisite [PR151](https://github.com/jonbae/PSFlow/pull/151) merged on
  2026-10-16; do not treat that historical blocker as still pending.
- [PR194](https://github.com/jonbae/PSFlow/pull/194) remains open for arrow-key
  aria-live messages; [PR195](https://github.com/jonbae/PSFlow/pull/195) remains
  open for null handle-side bounds. Read their final disposition before W11
  or any work touching those mechanisms.
- [Issue 111](https://github.com/jonbae/PSFlow/issues/111) owns a genuine
  multi-node selection drag witness; [issue 108](https://github.com/jonbae/PSFlow/issues/108)
  owns a pan refusal beyond `translateExtent`. Keep those evidence tasks
  separate from the already implemented controller code.
- [Issue 93](https://github.com/jonbae/PSFlow/issues/93) remains the destination
  and backlog index. The new static findings below have **not** been published
  as issues, and the old `tickets/` documents remain reference material.

## Bounded follow-up work contracts

These cards define future implementation/evidence work; no card was executed.
Each card names one observable gap. A broad source-file mapping does not grant
permission to change all of its targets. Use the card's allowed outputs, with
all other mapped files read-only. Proposed new test files are labeled **new**.
Split any card further if implementing it requires unrelated behavior changes.

### W00 — establish current evidence for retained units

- **Disposition:** reuse; add evidence only where the baseline demonstrates a gap.
- **Source/callers:** all E01/E05/E15 units remain existing dependencies. Public
  calls enter through `index.js`/Boundary; edges call path helpers, controls use
  viewport helpers, chrome reads selectors and store state.
- **Observable gap:** the committed reports do not describe a freshly built
  copy of this exact checkout. No new feature gap is inferred from that alone.
- **Allowed outputs:** only artifacts regenerated by the README commands:
  `oracle/index.js`, driver bundles under `parity/driver/dist/`,
  `parity/surface/upstream.json`, `parity/surface/psflow.json`,
  `parity/surface/report.md`, `parity/system/traces/`,
  `parity/system/report.md`, and `parity/system/coverage.md`.
- **Acceptance/dependencies:** check PR194/195, build first, run the five gates
  in README order and `parity:boundary`; record exact revisions and command
  outcomes. Preserve both captures for unstable scenarios. Do not broaden an
  allowlist/region or count failed scenarios as independent missing features.
  This is Step 3's baseline work, not a build performed during Step 2.

### W01 — cross the JS viewport function (first pilot)

- **Disposition:** finish conversion; retain core geometry unchanged.
- **Source/callers:** system `utils/general.ts::getViewportForBounds` plus
  `parsePadding`, `parsePaddings`, `calculateAppliedPaddings`; callers are system
  `utils/graph.ts::fitViewport`, React `store/initialState.ts::getInitialState`
  and `hooks/useViewportHelper.ts`. The public JS call has six parameters and
  no padding default; defaults such as `0.1` belong to callers.
- **Target/FFI:** `System.Utils.General` already implements the math.
  `Boundary.Utils`, `Boundary.purs` and the manifest own the new crossing;
  inspect `Boundary.FitView.paddingIn` before reusing its option-field parser.
- **Observable gap:** a single uncurried JS call currently yields the next
  function rather than a viewport. **Allowed outputs and acceptance:** use the
  complete [pilot specification](AAMF_STEP2_INTEGRATION.md#pilot-specification-cross-getviewportforbounds).
  It limits code output to `src/Boundary/Utils.purs`, `src/Boundary.purs`,
  `src/Boundary.js`, with named evidence outputs. Numeric, pixel, percent and
  directional padding, clamps, omission and invalid values require comparison
  against upstream. Retire only this export's two exceptions. Seven other
  passthrough exports remain; stage 4 stays recorded.
- **Dependencies:** W00 and an implementation scope; for AAMF execution also
  certified phase 0/1, the adapter, target-context and resume acceptance checks.

### W02 — cross one remaining graph utility at a time

- **Disposition:** finish conversion. Reuse existing graph/edge math.
- **Source/callers:** system `utils/graph.ts::{getConnectedEdges,getIncomers,
  getOutgoers,getNodesBounds,isNodeBase,isEdgeBase}`; React `utils/general.ts`
  exposes guards as `isNode`/`isEdge`. Reconnection flows through React
  `utils/edges.ts` into system `utils/edges/general.ts::reconnectEdge`; consumers
  call the public functions and connection callbacks. Inspect `useReactFlow`
  queries and edge updater callers for representation/identity expectations.
- **Target/FFI:** retain `System.Utils.Graph`, `System.Utils.Edges.General`,
  `React.Util.General`; use existing `Boundary.Elements` for represented shapes
  only when identity/key contracts permit it.
- **Observable gap:** the JS surface still owns these seven names as raw
  passthroughs. Guard calls happen to agree in current surface fixtures, which
  is evidence to preserve rather than justification for a blind wrapper.
- **Allowed outputs:** `src/Boundary/Utils.purs`, `src/Boundary.purs`,
  `src/Boundary.js`, `parity/boundary/mount.mjs`, named matching entries only in
  `parity/surface/allowlist.json`, and surface-generated artifacts. Any FFI
  addition or element converter change requires a narrower reviewed task scope.
- **Acceptance/dependencies:** after W01, select one export per task; assert
  direct JS arguments, optional-argument branches, exact return shape and
  appropriate original-element references. A local JS-entry comparison must
  fail before the crossing and pass after. Function parity, surface and
  boundary checks pass. Coordinate reconnection with W03 before editing its
  implementation. Set stage 5 only after all eight passthroughs are crossed.

### W03 — preserve consumer objects in change helpers

- **Disposition:** fix behavior, owned by issue 150.
- **Source/callers:** React `utils/changes.ts::applyChanges`, `applyChange`,
  `applyNodeChanges`, `applyEdgeChanges`; system `utils/edges/general.ts::addEdge`.
  Controlled change handlers and `useNodesEdgesState` call these; BatchProvider
  and the store reuse the change mechanism internally.
- **Target/FFI:** retain `React.Store.Changes` as value logic. The current
  `Boundary.Utils` inbound/outbound typed round-trip erases extra keys and
  allocates fresh results. Platform object/identity operations may use the
  existing `Boundary/Utils.js` seam; business decisions stay in PureScript.
- **Observable gap:** untouched elements lose original identity; copied/added
  elements lose custom and explicitly present `undefined` keys.
- **Allowed outputs:** `src/Boundary/Utils.purs`, `src/Boundary/Utils.js`,
  **new** `test/Test/Boundary/ConsumerObjects.purs` and paired `.js`, its
  registration in `test/Test/Main.purs`, and only the three issue-owned
  return-value entries in `parity/surface/allowlist.json`. Do not edit the
  core change reducer unless a separately demonstrated defect requires it.
- **Acceptance/dependencies:** W00; a local proxy reaches no-op, changed,
  add/replace/remove, and custom/present-undefined cases. Untouched references
  survive; changed copies preserve keys; added edges preserve keys and error/
  duplicate behavior. Watch the proxy fail before the fix. Retire the three
  exceptions and pass surface/boundary/function checks. Coordinate the chosen
  provenance representation with W04 and serialize W01/W02/W03 on shared files.

### W04 — retain `internals.userNode` provenance

- **Disposition:** fix behavior.
- **Source/callers:** system `utils/store.ts::adoptUserNodes`,
  `updateNodeInternals`, and `types/nodes.ts::InternalNodeBase`; callers are React
  store node adoption, `useReactFlow` internal-node queries and `useInternalNode`.
- **Target/FFI:** `System.Types.Node.NodeInternals` and
  `Boundary.Elements.JsNodeInternals` explicitly omit `userNode`. Retain the
  original consumer reference through adoption and conversion, with an explicit
  representation that also respects PureScript consumers.
- **Observable gap:** `getInternalNode(id).internals.userNode` cannot return the
  original consumer object because the model has no place for it.
- **Allowed outputs:** `src/System/Types/Node.purs`,
  `src/System/Utils/Store.purs`, `src/Boundary/Elements.purs`,
  `src/Boundary/Instance.purs`, `src/Boundary/Hooks.purs`,
  `src/React/Store/InitialState.purs`, `src/React/Store/Reduce.purs`,
  **new** `test/Test/Boundary/UserNode.purs` and paired `.js`, and its registration
  in `test/Test/Main.purs`. Expand scope explicitly if the representation needs
  a different ownership seam; do not scatter compensating copies.
- **Acceptance/dependencies:** W00; agree representation with W03 first. A proxy
  compares references for initial adoption, unchanged re-adoption and replacement
  by a different same-id object, through JS instance and hook results. Verify
  custom keys and store update behavior; pass relevant store tests plus surface
  and boundary checks. An equivalent newly built record does not satisfy it.

### W05 — wire resize state into the existing math

- **Disposition:** fix behavior.
- **Source/callers:** system `xyresizer/XYResizer.ts` start/drag/end closures,
  `nodeToChildExtent`, `utils.ts::getDimensionsAfterResize`; React
  `NodeResizeControl.tsx::ResizeControl` creates the controller and dispatches
  changes. `NodeResizer` mounts several controls; callbacks cross through
  `Boundary.Resizer`.
- **Target/FFI:** `System.XYResizer`, `System.XYResizer.Utils`,
  `React.Additional.NodeResizer.Control`; retain d3/platform seams already in
  `System.FFI.D3Drag`, `System.FFI.D3Selection`, `System.XYResizer.js`.
- **Observable gap:** start/end report initial values and drag reports zero
  geometry while `_params` and `_state` are ignored.
- **Allowed outputs:** `src/System/XYResizer.purs`,
  `src/System/XYResizer/Utils.purs`, `src/React/Additional/NodeResizer/Control.purs`,
  **new** `test/Test/System/XYResizer.purs` and paired `.js`, and its registration
  in `test/Test/Main.purs`. A mounted fixture/scenario is a separate W12 task.
- **Acceptance/dependencies:** W00; fake pointer/d3 input reproduces nonzero
  resize and evolving start/previous values, min/max, aspect and direction
  constraints, `shouldResize` veto, parent/child changes, callback ordering and
  teardown. Prove each branch against upstream before claiming it. Keep math in
  PureScript. No zero-valued placeholder may satisfy the proxy.

### W06 — provide the JS store surface

- **Disposition:** finish conversion; retain the internal subscription machinery.
- **Source/callers:** React `hooks/useStore.ts::{useStore,useStoreApi}`,
  `types/store.ts`, `store/index.ts`. Public consumer selectors/actions are the
  missing audience; existing internal hooks are not a substitute.
- **Target/FFI:** `React.Hook.Store` and `React.Store.Shell` already supply
  internal subscriptions; `Boundary.Hooks` deliberately throws for both JS
  exports because internal state/actions have no public converter.
- **Observable gap:** calling either public hook refuses instead of exposing
  the zustand-compatible state/API shape.
- **Allowed outputs:** `src/Boundary/Hooks.purs`, `src/Boundary/Hooks.js`,
  **new** `src/Boundary/Store.purs` (converter owner), `src/React/Store/Shell.purs`,
  `src/React/Types/Store.purs`, `parity/boundary/mount.mjs`, **new**
  `test/Test/Boundary/Store.purs` and paired `.js`, and its registration in
  `test/Test/Main.purs`. New platform FFI needs an explicit scoped addition.
- **Acceptance/dependencies:** W00 and the W03/W04 identity representation.
  Enumerate upstream's actual state/actions, define stable API identity, callable
  getters/setters/subscriptions and selected equality, and prove subscribe/
  unsubscribe and server snapshots. Test direct JS consumers and preserve all
  existing internal hook behavior. Remove only the two named refusal assertions
  after replacing them with behavioral checks; manifest presence is not success.

### W07 — carry default edge options through to rendering

- **Disposition:** fix behavior.
- **Source/callers:** React `types/edges.ts::DefaultEdgeOptions`,
  `EdgeWrapper`'s merge of store defaults with edge values, and `EdgeText`/
  `BaseEdge` rendering. `ReactFlow` → `StoreUpdater` seeds defaults.
- **Target/FFI:** `React.Types.Edges.DefaultEdgeOptions`, `Boundary.Flow`,
  `React.Component.EdgeWrapper`, `System.Types.Edge`, `Boundary.Elements`.
- **Observable gap:** `type`, `markerStart`, `markerEnd`, `style`, `className`,
  `label`, `labelStyle`, `labelShowBg`, `labelBgStyle`, `labelBgPadding`,
  `labelBgBorderRadius`, `ariaRole` and `domAttributes` are explicitly refused.
- **Allowed outputs:** `src/React/Types/Edges.purs`, `src/System/Types/Edge.purs`,
  `src/Boundary/Flow.purs`, `src/Boundary/Elements.purs`,
  `src/React/Component/EdgeWrapper.purs`, `src/React/Edge/Base.purs`,
  `src/React/Edge/Text.purs`, `src/Boundary/Edges.purs`,
  **new** `test/Test/Boundary/DefaultEdgeOptions.purs` and paired `.js`, its
  registration in `test/Test/Main.purs`, and `parity/boundary/mount.mjs`.
  Split into one field family per task; avoid a single broad rewrite.
- **Acceptance/dependencies:** W00, coordinated W04 element representation.
  A node/edge mount proxy observes each selected field on an edge with no
  override and confirms explicit per-edge values win. Retire only that family's
  refusal after the data reaches its actual renderer. W12 separately adds the
  mounted corpus witness; accepting the input alone is insufficient.

### W08 — translate listener lifecycle literally (two tasks)

The [listener port](src/React/Hook/Listeners.purs) records two deliberate
differences that conflict with the current porting contract. They are static
findings; no local failure or published issue was produced in this session.

| Task | Source/caller and observed difference | Allowed outputs and acceptance |
|---|---|---|
| W08a: `onInit` scheduling | [Upstream hook](xyflow/packages/react/src/hooks/useOnInitHandler.ts), called by GraphView, schedules `setTimeout(..., 1)` and depends on `onInit` plus readiness. The port calls inside the effect and keys it only on readiness. | `src/React/Hook/Listeners.purs`; **new** `test/Test/React/Hook/OnInitTiming.purs` and paired `.js`; registration in `test/Test/Main.purs`. Fake-clock proxy must show no call before the timer, exactly one scheduled invocation when eligible, correct instance, and a handler added after readiness. Match captured upstream behavior on unmount rather than invent cleanup. |
| W08b: viewport slots | [Upstream hook](xyflow/packages/react/src/hooks/useOnViewportChange.ts) independently writes each slot including `undefined`, with no cleanup. [Port reducers](src/React/Store/Reduce.purs) preserve a slot for `Nothing` and conditionally clear it on cleanup. | `src/React/Hook/Listeners.purs`, `src/React/Store/Reduce.purs`, `src/React/Store/Action.purs`; **new** `test/Test/React/Hook/ViewportListeners.purs` and paired `.js`; registration in `test/Test/Main.purs`; existing listener tests only where they explicitly assert this differing contract. A proxy compares installation, callback replacement/removal, a second partial-options hook and unmount, without clearing or retaining anything upstream would not. |

Both depend on W00, preserve existing JS converters, and need a failing-before/
passing-after local proxy plus boundary checks. W12's `OnInit` witness is
separate: enabling the callback in the driver alone cannot prove timer order.

### W09 — compare selector results by upstream's equality

- **Disposition:** add evidence first; fix only the demonstrated mismatch.
- **Source/callers:** system `utils/shallow-node-data.ts::shallowNodeData` uses
  `Object.is(data)`; React `useNodesData` uses it to select projections.
  `useNodes`, `useEdges`, `useInternalNode`, `useConnection` and toolbar selectors
  also depend on reference-sensitive comparison or explicit equality functions.
- **Target/FFI:** `System.Utils.ShallowNodeData` and `React.Hook.Selectors`
  explicitly use structural `Eq`; `Boundary.Hooks` chooses the JS overloads.
- **Observable gap:** an equal-valued new data object may be treated as
  unchanged; internal-node identity/array projection and selector overloads
  also need direct comparison. Do not infer a failing JS hook solely from its
  internal docstring.
- **Allowed first-task outputs:** **new**
  `test/Test/React/Hook/SelectorIdentity.purs` and paired `.js`, and registration
  in `test/Test/Main.purs`. After a failing probe, separately scope fixes to
  `src/System/Utils/ShallowNodeData.purs`, `src/React/Hook/Selectors.purs`,
  `src/Boundary/Hooks.purs` and existing object/identity FFI as needed.
- **Acceptance/dependencies:** W00; use same-reference, equal-valued new
  reference, changed reference, null, scalar and array cases against upstream;
  observe returned projection and render/effect count. Preserve the internal
  store's proven synchronous subscription/server-snapshot behavior. An old
  “optimization” docstring is not an accepted behavior difference.

### W10 — audit remaining type and boundary contracts by field

- **Disposition:** add evidence. No blanket type rewrite is queued.
- **Source/callers:** E02 declarations and their actual components/hooks/store
  readers; examples include `NodeBase.type`, optional flags, number-valued
  z-indices, `IsValidConnection` union inputs and callback/event arguments.
- **Target:** the exact type modules and converters named in the map.
- **Observable gap:** source/member presence alone cannot certify optionality,
  untagged unions, key presence, numeric domain or field spelling. Some source
  comments are stale: current node `hidden`, `selected`, `dragging`,
  `expandParent` and edge `animated` are already optional in code. Do not reopen
  their older Boolean migration based on PORTING.md's historical example.
- **Allowed first-task outputs:** **new** `AAMF_TYPE_CONTRACT_REVIEW.md`, naming
  one field and its callers at a time. Any future code card must then list the
  precise type, converter, reader and local proxy files it will touch.
- **Acceptance/dependencies:** W00; compare each relevant guard/default/absence
  branch and JS input/output shape, with an oracle call or a falsifying local
  proxy. Route already demonstrated gaps to W03/W04/W07, rather than creating
  overlapping generic type tasks. No new permanent exception is accepted here.

### W11 — remeasure the existing interactive mechanisms

- **Disposition:** add evidence; preserve code until a cause is demonstrated.
- **Source/callers:** XYDrag/XYHandle/XYPanZoom and their React hooks/containers,
  provider/store actions, selection, DOM and event handlers in E11–E14.
- **Observable gap:** old traces contain self-inconsistent drag/keyboard
  scenarios and cannot identify which current mechanism still differs.
- **Allowed outputs:** initially W00's capture/report artifacts only. For
  [issue 108](https://github.com/jonbae/PSFlow/issues/108),
  `parity/system/corpus/hole-closing.mjs` may gain a scoped pan-refusal scenario
  using an existing extent fixture. For [issue 111](https://github.com/jonbae/PSFlow/issues/111),
  the same corpus file may gain a multi-selected-node drag scenario using an
  existing fixture. Any driver gesture change needs its own explicit scope.
- **Acceptance/dependencies:** W00; account for PR194/195 first. Compare both
  captures before interpreting cross-side differences. The issue 108 witness
  must actually reach a pan that cannot move; issue 111 must drag multiple
  selected nodes and record the selection-drag callbacks. A reduced callback
  set or relaxed tolerance does not establish faithful scheduling.

### W12 — add one absent mounted witness per task

- **Disposition:** add evidence, using the current hole register.
- **Source/callers:** portal content, non-default edge components, EdgeToolbar,
  custom edge types, default edges, resize callbacks, reconnect and `onInit`.
- **Observable gap:** an export is crossed or has pure math tests but no
  corpus observation of the mounted mechanism. The eight/six counts in old
  tickets are not an inventory for these tasks.
- **Allowed outputs:** one **new** fixture under `parity/system/fixtures/`
  with its exact name chosen in the individual card; that scenario's entry in
  `parity/system/corpus/hole-closing.mjs`, required registry entries,
  `parity/system/coverage/holes.json` only for witnesses actually driven, and
  W00's generated traces/report/coverage artifacts. An `OnInit` task additionally
  names `parity/driver/callbacks.mjs`; a gesture addition must name its driver
  implementation/tests in a separate concrete card before execution.
- **Acceptance/dependencies:** W00; select only one hole/family with an existing
  witness in `coverage/witnesses.json`. Render content inside a portal rather
  than merely observing GraphView's empty container; explicitly register each
  edge variant; observe callbacks with their real arguments/order. Resizing
  depends on W05, defaults on W07, reconnection on W02, and `onInit` timing on
  W08a. Do not remove a hole because a fixture was merely written.

## Ownership and dependency rules

The map's target modules are read context. **Only a selected card's permitted
outputs are write ownership.** The following overlaps add dependencies even
when AAMF's source graph claims independence:

| Shared output | Serialize these prospective writers |
|---|---|
| `Boundary.Utils`, `Boundary.purs`, manifest | W01 → individual W02 crossings; W03 coordinates on `Boundary.Utils` |
| `Boundary.Elements` / element models | W04 and each W07 field family; coordinate W03's identity representation before either starts |
| `Boundary.Hooks` | W04, W06 and any W09 fix |
| `React.Store.Reduce` / action model | W04, W08b, and any separately diagnosed store fix |
| `React.Hook.Listeners` | W08a and W08b |
| `test/Test/Main.purs` | All cards registering a proxy; this is real ownership even if implementation modules differ |
| Boundary mount checks, surface allowlist and generated surface files | W01, W02, W03, W06 and W07 as their named evidence requires |
| Corpus/registry/hole register and generated traces | W11 evidence additions and each W12 fixture task |

Use one implementation task at a time initially. A future adapter must put
canonical, complete output paths into AAMF's `targetFiles`; its existing
per-task scheduling can then detect overlap. Keep read-only source dependency
context, including the system/react type cycles, pan/zoom cycle and flow
container cycle from Step 1. Do not turn retained dependencies into fabricated
“completed migration” tasks.

The recommended next implementation sequence is W00, then W01 as one bounded
pilot. Choose later cards from the refreshed evidence; W03's confirmed identity
gap and W05's explicit resize scaffold do not justify a wholesale rewrite of
their dependency modules. AAMF runtime execution remains gated by
[the integration contract](AAMF_STEP2_INTEGRATION.md).

## Accepted differences and stop point

- **D01: representation/layout.** Many source files may share one PureScript
  module, and one source file may map to several modules. ADTs/newtypes and
  `.purs` paths may differ internally only where JS-observable mechanism stays
  intact. This accepts no callback, shape, timing or DOM difference.
- **D02: ambient declarations.** TypeScript's CSS/SVG declarations need no
  separate runtime translation. Preserve styles/assets and loader behavior.
- Existing permanent surface exceptions retain their written reasons. No new
  system region or surface exception was added. Commented divergences such as
  structural identity comparison or removed timers are pending work/evidence,
  not newly accepted differences.

The normal AAMF pipeline still has no certified phase 0/1 result. No adapter,
target PureScript symbol index, authoritative reconciled runtime graph or pilot
has been implemented or verified. Those are explicit uncompleted execution
prerequisites, not missing documentation to conceal.

Only Markdown documentation changed. No implementation, tests, fixtures,
packages, AAMF source, checkpoints, issue/PR state, baseline, builds or parity
artifacts changed. Step 3 was not started.
