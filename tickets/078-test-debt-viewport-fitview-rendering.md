# 078 — Test debt: viewport, fitView and render-path behavior

## Context

One of four test-debt tickets from the [071](071-version-drift-audit-12-3-to-12-11.md)
changelog sweep. Every row is `ported-ungated` — implemented in PSFlow, spot-checked
against upstream during the sweep, but exercised by no gate. See
[076](076-test-debt-drag-selection-store.md) for the shared rationale.

## Rows (13)

| PR | Change | Where it lives |
|---|---|---|
| [#5276](https://github.com/xyflow/xyflow/pull/5276) | `ease` / `interpolate` on all viewport-altering functions | `src/React/Hook/ViewportHelper.purs:96-97,124`; `src/System/XYPanZoom.purs:249,287,305` |
| [#5723](https://github.com/xyflow/xyflow/pull/5723) | Pass options to viewport helper functions correctly | `src/React/Hook/ViewportHelper.purs` |
| [#5722](https://github.com/xyflow/xyflow/pull/5722) | `snapGrid` in `screenToFlowPosition` options | `src/React/Hook/ViewportHelper.purs` |
| [#5012](https://github.com/xyflow/xyflow/pull/5012) | `snapGrid` option + `snapToGrid` default false | same path as #5722 |
| [#5547](https://github.com/xyflow/xyflow/pull/5547) | Always call `onMoveEnd` when `onMoveStart` was called | `src/System/XYPanZoom/EventHandler.purs` |
| [#5132](https://github.com/xyflow/xyflow/pull/5132) | `fitView` when `onNodesChange` is undefined | `src/React/Hook/ViewportHelper.purs`, `src/System/Utils/Graph.purs` |
| [#5127](https://github.com/xyflow/xyflow/pull/5127) | `fitView` when `onNodesChange` returns early | same path as #5132 |
| [#5120](https://github.com/xyflow/xyflow/pull/5120) | `fitView` for uncontrolled flows | `src/React/Hook/NodesEdgesState.purs` |
| [#5249](https://github.com/xyflow/xyflow/pull/5249) | `onNodesChange` for uncontrolled flows using `updateNode` | `src/React/Hook/ReactFlow.purs` |
| [#4991](https://github.com/xyflow/xyflow/pull/4991) | Fix viewport shifting on node focus | `src/React/Component/NodeWrapper.purs` |
| [#5629](https://github.com/xyflow/xyflow/pull/5629) | Prevent unnecessary re-render in `FlowRenderer` | `src/React/Container/FlowRenderer.purs` |
| [#5497](https://github.com/xyflow/xyflow/pull/5497) | Skip eager node render when dimensions/handles predefined | `src/React/Container/NodeRenderer.purs` |
| [#4875](https://github.com/xyflow/xyflow/pull/4875) | Prevent unnecessary edge rerenders when resizing | `src/React/Container/EdgeRenderer.purs` |

## Notes

**`ease` / `interpolate` (#5276)** is the row most worth attention.
`src/System/XYPanZoom.purs:237` states outright that "d3-zoom's interpolate APIs
aren't exercised in the test harness" — the options are threaded through but
their effect is unobserved end to end.

**The four render-path rows** (#5629, #5497, #4875, and #5192 already bucketed
`unit`) are all *performance* changes upstream. They are correctness-neutral by
intent, so they are the lowest-priority rows here; the cost of gating render
counts is high relative to the risk. Consider closing them as accepted
non-coverage rather than building render-count assertions.

**The three `fitView` rows** (#5132, #5127, #5120) share one code path and one
fixture would likely cover all three.

## Acceptance criteria

- Each row is covered by a new assertion or explicitly re-bucketed with a reason;
  the render-path rows may legitimately close as accepted non-coverage.
- `ease` / `interpolate` gain end-to-end observation, or the fidelity note at
  `XYPanZoom.purs:237` is upgraded to a documented, allowlisted limit.
- Rows flip to a covered bucket in `parity/changelog-audit/verdicts.json`;
  `npm run parity:changelog` stays green.
- `spago test` and `npm run test:smoke` stay green.

## Source files

- `src/React/Hook/ViewportHelper.purs`, `src/System/XYPanZoom.purs`,
  `src/System/XYPanZoom/EventHandler.purs`
- `src/System/Utils/Graph.purs`, `src/React/Hook/NodesEdgesState.purs`
- `src/React/Container/{FlowRenderer,NodeRenderer,EdgeRenderer}.purs`
- `parity/changelog-audit/verdicts.json` — the rows, with per-PR notes
