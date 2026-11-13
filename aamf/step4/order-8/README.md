# Step 4, order 8: changelog branch evidence

**Complete, 2026-11-13 UTC.** All 42 rows are in system, with zero
gate-pending rows and zero audit gaps. The final checkpoint passes all 151
scenarios, with zero self-inconsistency and zero driving divergences.
Export coverage remains 155/156 driven, with one declared hole.
[validation.json](validation.json) records the commands, counts and policy hashes.

The starting point is PSFlow commit
65ff5ab7 (the merged Step 4 order 7), against the fixed
@xyflow/react 12.11.0 and @xyflow/system 0.0.77 baseline.
The [previous 116-scenario checkpoint](before-checkpoint.tar.gz) is preserved.
The upstream changes were fetched from xyflow/xyflow through the GitHub
connector; all 42 exact patches are preserved under [upstream](upstream/).

This task owns the corpus additions, the affected port fixes, the changelog
rebucketing, the branch-evidence checks, and the report/trace refresh. It uses
PSFlow's own gates with the AAMF inventory as context; it does not run an
autonomous AAMF migration.

## What is established per row

[rows.json](rows.json) records the source change, its PureScript destination,
its original scenario assignment, the scenario now used, and its observable.
There are 42 rows and 38 distinct cited scenarios. The corpus gains 24 focused
scenarios and 11 fixture baselines, taking 116 scenarios to 151.

A passing scenario alone does not close a row.
[system-evidence.mjs](../../../parity/changelog-audit/system-evidence.mjs)
checks the specific observable in both captures of each library. The changelog
audit invokes it for every retired row. Its
[tests](../../../parity/changelog-audit/system-evidence.test.mjs)
remove each row's observable from an otherwise valid trace and require that
receipt to fail. The net still compares the two executing libraries across
all seven sections with the original normalization, regions and weakenings.

These receipt checks establish reach. The differential net establishes
equality. The scratch reversion experiments below establish that the selected
observations distinguish the relevant faults.

| Upstream PR | Changed branch and port | Scenario(s) and observable |
|---|---|---|
| [4844](upstream/4844.diff) | Consumer data-testid overrides the wrapper default. [ReactFlow.purs](../../../src/React/Container/ReactFlow.purs) | flow-custom-testid. Resolved custom-id action and DOM data-testid. |
| [4855](upstream/4855.diff) | Forward SVG path attributes outside BaseEdge’s named props. [Base.purs](../../../src/React/Edge/Base.purs) | custom-edge-baseedge-path. Resolved custom path attribute and SVG DOM. |
| [4862](upstream/4862.diff) | Prevent the arrow-key browser default in both node and selection handlers. [NodeWrapper.purs](../../../src/React/Component/NodeWrapper.purs) | arrow-key-selected-node, debt-selection-keyboard. consumerKey.defaultPrevented with node position changes. |
| [4949](upstream/4949.diff) | Connection keys include both endpoints, avoiding per-handle collisions. [Store.purs](../../../src/System/Utils/Store.purs) | probe-node-connections. Hub DOM renders all five incident edges, including both directions. |
| [4991](upstream/4991.diff) | Reset wrapper scrolling on focus before forwarding onScroll. [ReactFlow.purs](../../../src/React/Container/ReactFlow.purs) | debt-focus-wrapper-scroll. wrapperScroll callback and settled scroll offsets are both zero. |
| [5012](upstream/5012.diff) | Read the snapToGrid default from the store and honor an explicit snapGrid. [ViewportHelper.purs](../../../src/React/Hook/ViewportHelper.purs) | viewport-helpers-with-options. Settled inherited, disabled and custom-grid screenToFlowPosition answers. |
| [5042](upstream/5042.diff) | An existing click connection may end on a handle that cannot start one. [Handle.purs](../../../src/React/Handle.purs) | debt-click-connect-end-only. onConnect after clicking target without connectablestart. |
| [5043](upstream/5043.diff) | Read expandParent and parentId from the current node, not the drag snapshot. [Reduce.purs](../../../src/React/Store/Reduce.purs) | debt-live-expand-parent. Mid-gesture expandParent replacement followed by further position changes. |
| [5052](upstream/5052.diff) | Report error015 when calculating an uninitialized node’s drag position. [Graph.purs](../../../src/System/Utils/Graph.purs) | drag-unmeasured-node. onError callback with code 015 and original error message. |
| [5120](upstream/5120.diff) | Perform initial fit even without an imperative fitView resolver. [Shell.purs](../../../src/React/Store/Shell.purs) | fitview-onnodeschange-variants. Initial onMove fit precedes the first imperative call on an uncontrolled flow. |
| [5127](upstream/5127.diff) | Queue a frame refit when the diff is empty and the consumer ignores changes. [Batch.purs](../../../src/React/Provider/Batch.purs) | debt-fitview-ignored-changes. fitView settles true and moves viewport with a consumer that returns early. |
| [5132](upstream/5132.diff) | Queue the no-change frame refit even with no onNodesChange callback. [Batch.purs](../../../src/React/Provider/Batch.purs) | debt-fitview-absent-handler. fitView settles true; fixture literally omits the observed callback. |
| [5139](upstream/5139.diff) | Use rgba for the default minimap mask custom property. [build.mjs](../../../distribution/build.mjs) | debt-css-defaults. getComputedStyle preserves the raw rgba default and rendered fill. |
| [5148](upstream/5148.diff) | Prevent a ctrl-wheel default above nowheel in the zoom-on-scroll handler. [EventHandler.purs](../../../src/System/XYPanZoom/EventHandler.purs) | debt-ctrl-wheel-nowheel. consumerWheel records ctrlKey and defaultPrevented. |
| [5153](upstream/5153.diff) | Horizontal controls use right borders, except the last button. [build.mjs](../../../distribution/build.mjs) | debt-css-defaults. Computed right/bottom border widths for every horizontal button. |
| [5249](upstream/5249.diff) | Fire onNodesChange after an uncontrolled imperative node mutation. [Batch.purs](../../../src/React/Provider/Batch.purs) | uncontrolled-update-node. replace/add receipts alongside updated uncontrolled nodes. |
| [5252](upstream/5252.diff) | Center panels with the additional margin compensation on both axes. [build.mjs](../../../distribution/build.mjs) | debt-css-defaults. Computed matrix transforms for top/bottom/left/right center panels. |
| [5259](upstream/5259.diff) | Give the explicit background prop priority over the general CSS variable. [build.mjs](../../../distribution/build.mjs) | debt-css-defaults. Computed background color with both candidates set. |
| [5362](upstream/5362.diff) | Remove inline pointerEvents; the selection ancestor’s CSS owns it. [Panel.purs](../../../src/React/Portal/Panel.purs) | debt-css-selection. Panel has no inline pointer-events and the nested panel computes none. |
| [5368](upstream/5368.diff) | Merge ariaLabelConfig without overwriting the merge through the generic branch. [StoreUpdater.purs](../../../src/React/Provider/StoreUpdater.purs) | debt-store-effect-timing. Partial config changes retain all default labels in the public store. |
| [5428](upstream/5428.diff) | Resolve the starting handle type from currentTarget, not elementFromPoint. [XYHandle.purs](../../../src/System/XYHandle.purs) | debt-detached-handle. Connection starts through a detached nested handle child. |
| [5450](upstream/5450.diff) | Retain the last drag event for autopan’s node-drag callback. [XYDrag.purs](../../../src/System/XYDrag.purs) | drag-node-autopan. More onNodeDrag callbacks than manual pointer moves. |
| [5455](upstream/5455.diff) | Skip measuring an invisible wrapper before size/error handling. [ResizeHandler.purs](../../../src/React/Hook/ResizeHandler.purs) | mount-in-display-none. Hidden wrapper retains the visible store dimensions and emits no error004. |
| [5480](upstream/5480.diff) | Ignore partial touchend while a finger remains; suppress connection-time touch pan. [XYHandle.purs](../../../src/System/XYHandle.purs) | debt-connection-partial-touch-end. Driving includes a partial touchend; final connection is still in progress. |
| [5512](upstream/5512.diff) | Prevent a ctrl-wheel default above nowheel in the pan-on-scroll handler. [EventHandler.purs](../../../src/System/XYPanZoom/EventHandler.purs) | debt-ctrl-wheel-nowheel-pan-on-scroll. consumerWheel records ctrlKey and defaultPrevented with panOnScroll enabled. |
| [5546](upstream/5546.diff) | Return finite zero bounds when the filter rejects every node. [Graph.purs](../../../src/System/Utils/Graph.purs) | minimap-all-nodes-hidden. A finite MiniMap viewBox over existing nodes that are all hidden. |
| [5547](upstream/5547.diff) | End a started pan even if its viewport never changed. [EventHandler.purs](../../../src/System/XYPanZoom/EventHandler.purs) | debt-pan-without-movement. Start/end callbacks for the final press/release with no intervening move. |
| [5551](upstream/5551.diff) | Capture pointerdown over a node to begin box selection. [Pane.purs](../../../src/React/Container/Pane.purs) | selection-box-from-node. Node-targeted pointerdown produces onSelectionStart and onSelectionEnd. |
| [5578](upstream/5578.diff) | Update the raw pointer even while snapped to the same handle. [XYHandle.purs](../../../src/System/XYHandle.purs) | debt-connection-pointer. Consumer connection has a raw pointer distinct from its snapped endpoint. |
| [5593](upstream/5593.diff) | Delay selection reset until movement; keep box state clear on a node click. [Pane.purs](../../../src/React/Container/Pane.purs) | debt-selection-click-node. A real box selection followed by node click leaves no group rectangle. |
| [5635](upstream/5635.diff) | Refresh the connection origin after moving its source node by keyboard. [XYHandle.purs](../../../src/System/XYHandle.purs) | debt-keyboard-connection-origin. Connection origin matches the moved source handle, including a later pointer move. |
| [5638](upstream/5638.diff) | Apply touch-action:none to the pane. [build.mjs](../../../distribution/build.mjs) | selection-box-touch, debt-css-defaults. Touch selection input and the computed pane touch-action. |
| [5682](upstream/5682.diff) | Skip deselection changes for already-unselected nodes and edges. [Reduce.purs](../../../src/React/Store/Reduce.purs) | drag-node-no-select-on-drag. Position changes occur without any select changes in the exact callback log. |
| [5684](upstream/5684.diff) | Rebind drag when nodeClickDistance changes, while retaining programmatic selection dragging. [Drag.purs](../../../src/React/Hook/Drag.purs) | debt-programmatic-selection-drag. Selected nodes added programmatically move as a group; a short node drag after the click-distance prop change retains its native onNodeClick. |
| [5692](upstream/5692.diff) | Skip a node whose lookup entry vanishes during a minimap render. [Nodes.purs](../../../src/React/Additional/MiniMap/Nodes.purs) | debt-minimap-missing-node. A synchronous missing-entry render and restoration complete without a page error. |
| [5704](upstream/5704.diff) | Read validation and onConnectEnd from the live store during a connection. [Handle.purs](../../../src/React/Handle.purs) | debt-live-connection-handlers. Replacement validator rejects and replacement end handler receives the final state. |
| [5722](upstream/5722.diff) | Expose snapGrid in the screenToFlowPosition options contract. [Instance.purs](../../../src/Boundary/Instance.purs) | viewport-helpers-with-options. Custom-grid answer differs from store-grid and unsnapped answers; declaration is packaged too. |
| [5723](upstream/5723.diff) | Pass the whole options record to scaleBy and scaleTo. [ViewportHelper.purs](../../../src/React/Hook/ViewportHelper.purs) | debt-viewport-option-interpolation. Frame-by-frame onMove sequence for zoomIn, zoomOut and zoomTo with linear interpolation. |
| [5727](upstream/5727.diff) | Clear nodesSelectionActive when SetNodes removes the last selected node. [Reduce.purs](../../../src/React/Store/Reduce.purs) | debt-selection-cleared-by-nodes. No group rectangle and store nodesSelectionActive false after imperative deselection. |
| [5733](upstream/5733.diff) | Mount StoreUpdater before GraphView when a persistent provider’s flow remounts. [ReactFlow.purs](../../../src/React/Container/ReactFlow.purs) | debt-store-remount. GraphView custom-node passive effects read four nodes and four lookup entries on both mounts of a persistent-provider flow. |
| [5769](upstream/5769.diff) | Use passive effects, preserving a consumer layout effect’s pre-update store read. [StoreUpdater.purs](../../../src/React/Provider/StoreUpdater.purs) | debt-store-effect-timing. Changed layout effect reads old minZoom; changed passive effect reads the new value. |
| [5803](upstream/5803.diff) | Emit dragging:false on an aborted drag’s end. [XYDrag.purs](../../../src/System/XYDrag.purs) | debt-abort-touch-drag. Multitouch abort has final position-change callbacks with dragging false. |

## Corrections found during the review

The historical assignments often described a nearby behavior. The new
witnesses supply the actual stimulus:

- expandParent changes while the pointer is held; growing a parent with a
  constant flag cannot distinguish a cached flag from the current one.
- A keyboard connection moves its source node, then moves the pointer again.
  The original scenario moved another node.
- An aborted drag receives a second touch and then ends. Escape does not set
  XYDrag's abort flag at this baseline.
- Both nowheel paths receive a cancelable Control-wheel event. Pan-on-scroll
  uses a separate activation key, so Control does not select the zoom handler.
  A consumer records defaultPrevented directly.
- One fitView fixture ignores onNodesChange and another leaves it literally
  absent. The old uncontrolled fixture could not reach either controlled
  no-change queue branch.
- StoreUpdater receives partial ariaLabelConfig changes; consumer layout and
  passive effects record their pre/post-update store reads. Remount readers
  live inside GraphView, as the upstream regression does, within a persistent
  provider.
- The missing MiniMap node is rendered synchronously while its lookup entry
  is absent, then the entry is restored before the settled snapshot. This
  reaches the selector guard without leaving unrelated instance queries in
  an inconsistent store.
- A programmatic selection is dragged, then nodeClickDistance changes and a
  short drag must retain its native click.

The review fixed missing or incomplete port behavior:

- SetNodes now clears the group selection when no selected node remains.
- An aborted drag emits dragging:false at its end.
- Active connections read the current global validator and end handler.
  Reconnect anchors use the same live reads. XYHandle reads the current node
  lookup on every move, preserving upstream's mutable-Map behavior with the
  port's persistent Map.
- Handle children cross the boundary and render, permitting detached handle
  content to supply the hit target.
- The wrapper forwards its synthetic scroll event after resetting scroll.
- ResizeHandler skips an invisible container, reports error004 for a visible
  zero-size container, and installs upstream's window resize listener.

Rows 5455, 5704, 5727 and 5803 are marked misfiled: the specific changed branch
had been filed as ported but was absent. Their historical debt labels remain.

## Styles and the type-only row

5139, 5153, 5252, 5259 and 5638 changed stylesheets. The package uses upstream's
pinned stylesheets, and parity:package checks their bytes against the exact
files the driver loads. The added consumer samples computed styles, including
the raw default mask custom property, all horizontal button borders, both
panel-centering axes, competing background variable/prop values, and pane
touch-action. A panel nested in the selection pane exercises its pointer-events
rule; sibling panels also retain the expected absence of inline pointer-events.

5722 changed the public options type; its runtime behavior was already added
by 5012. The settled query witness supplies a distinct custom grid and also
reads the inherited and explicitly disabled cases. The
[packed TypeScript consumer](../../../distribution/consumer/consumer.tsx)
now calls screenToFlowPosition with snapGrid and no snapToGrid, under both
module-resolution modes.

## Reversion receipts

[probe.mjs](probe.mjs) runs only in a copy marked .order8-probe-scratch.
It records each exact source mutation and the original source hash, rebuilds
PureScript, uses [capture.mjs](capture.mjs) with the real net harness and fixed
comparison policy in Linux, and restores the source in a finally block.

The first batch has nine rejected reverts. The next batch has eight rejected
faults and one surviving exploratory disabled-dependency mutation. That
survivor is retained in its original summary. The strengthened click-distance
witness has its own probe; the timing probe independently changes passive
effects to layout effects so that a reordered StoreUpdater cannot mask it.

Nineteen specific fault experiments reject their broken port: seventeen by
trace differences and two by API noncompletion. The additional exploratory
disabled-dependency mutation survived; it prompted the stronger click-distance
stimulus and is retained rather than counted as a rejection.

| Receipt | Outcome |
|---|---|
| [First reversion batch](probes/summary.json), [reports](probes/reports/), [raw traces](probes/traces.tar.gz) | 9/9 rejected |
| [Second, exploratory batch](probes-branches/summary.json), [reports](probes-branches/reports/), [raw traces](probes-branches/traces.tar.gz) | 8 rejected, 1 surviving control |
| [Click-distance reversion](probes-drag-distance/summary.json), [report](probes-drag-distance/reports/debt-programmatic-selection-drag.md), [raw traces](probes-drag-distance/traces.tar.gz) | rejected |
| [Effect-timing reversion](probes-timing/summary.json), [report](probes-timing/reports/debt-store-effect-timing.md), [raw traces](probes-timing/traces.tar.gz) | rejected |
| [Restored-port strong witnesses](green/results.json), [raw traces](green/traces.tar.gz) | both pass, each reproduced twice on both sides |

The final reproduction script keeps the eight strict branch probes in its
branches group and runs click-distance independently; the exploratory disabled
mutation is preserved only in the original batch receipt.
An empty-diff fitView fault fails by exceeding the harness's existing
200-frame completion ceiling; it is recorded as an API noncompletion, not as
a successful trace comparison.

## Final checkpoint

The [full Linux wave](logs/full-wave.log) captured and passed all 151 scenarios.
The reversion review strengthened the remount and drag witnesses while that
wave was running. After it finished, the [owned refresh](logs/owned-refresh.log)
rebuilt the two bundles and recaptured the 24 focused scenarios plus the three
affected fixture baselines. All 27 passed. A
[full stored-trace comparison](logs/final-compare.log) then passed all 151 again.
The canonical traces are under [parity/system/traces](../../../parity/system/traces/).

All 42 branch receipts pass on both sides and both captures. The audit's 96
tests pass, including 42 positive branch checks and 42 counterexamples that
remove those observables. The
[changelog audit](../../../parity/changelog-audit/report.md) now has 175 covered
rows, zero gaps, three accepted rows and two with no analogue. The four cheap
gates, boundary checks/tests, harness/coverage/comparison tests and package
checks pass; their counts are in validation.json.

The comparator, normalization rules, regions and weakenings are unchanged.

## Reproduce

Use PureScript 0.15.16, Spago 1.0.4 and the committed dependency locks.
The recorded host uses Node 22.18.0. Browser captures use the locked
Playwright 1.60.0 Noble image through parity/system/linux.mjs: Node 24.15.0,
Chromium 148.0.7778.96 on Linux x64. The exact image digest is in validation.json.

```sh
spago build
npm run build:oracle
npm run parity:surface
spago test
npm run test:conformance
npm run test:smoke
npm run parity:boundary
npm run test:boundary
node parity/system/linux.mjs npm run parity:system
npm run test:audit
npm run parity:changelog
npm run build:package
npm run parity:package
```

For probes, prepare a disposable copy with its own source and output. Reusing
only dependency directories is safe; sharing output would invalidate a
reversion experiment. The script requires a marker before it will write.
The scratch path is a command argument; no path in these scripts is tied to the
original temporary workspace.

```sh
order8_scratch=$(mktemp -d /tmp/psflow-order8-probes.XXXXXX)
cp -R src test parity xyflow output node_modules package.json package-lock.json index.js spago.yaml spago.lock "$order8_scratch/"
ln -s "$PWD/.spago" "$order8_scratch/.spago"
mkdir -p "$order8_scratch/aamf/step4/order-8"
cp aamf/step4/order-8/capture.mjs "$order8_scratch/aamf/step4/order-8/"
touch "$order8_scratch/.order8-probe-scratch"
node aamf/step4/order-8/probe.mjs "$order8_scratch"
node aamf/step4/order-8/probe.mjs "$order8_scratch" branches
node aamf/step4/order-8/probe.mjs "$order8_scratch" drag-distance
node aamf/step4/order-8/probe.mjs "$order8_scratch" timing
```

For a focused green receipt, the first argument to capture.mjs is an output
directory, followed by explicit corpus IDs. With no IDs it captures the 24
order-eight scenarios. It rebuilds both driver bundles; compile PureScript
before calling it. Its results never stand in for the final full-corpus gate.
