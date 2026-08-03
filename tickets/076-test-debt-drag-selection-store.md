# 076 — Test debt: drag, selection and store-updater behavior

## Context

One of four test-debt tickets from the [071](071-version-drift-audit-12-3-to-12-11.md)
changelog sweep. Every row here is bucketed `ported-ungated`: the behavior **is**
implemented in PSFlow and was spot-checked against upstream during the sweep, but
**no gate exercises it**. If any of these regressed, all suites would stay green.

That is the same failure mode ticket 069 hit — behavior that no test touches
drifts silently — so these are tracked rather than assumed safe. The distinction
from [073](073-xyresizer-drag-lifecycle-scaffold.md) /
[075](075-custom-default-node-type-fallback.md) matters: those are *known wrong*.
These are *believed right and unverified*.

Grouped by subsystem, not by PR, so `src/` context is reused across a batch.

## Rows (16)

| PR | Change | Where it lives |
|---|---|---|
| [#5803](https://github.com/xyflow/xyflow/pull/5803) | Reset node drag state when drag is aborted | `src/System/XYDrag.purs:194,209,305,346,349,378` |
| [#5052](https://github.com/xyflow/xyflow/pull/5052) | Error when dragging an uninitialized node | `src/System/XYDrag.purs` |
| [#5450](https://github.com/xyflow/xyflow/pull/5450) | Call `onNodeDrag` while autopan is ongoing | `src/System/XYDrag.purs:350-352` |
| [#5684](https://github.com/xyflow/xyflow/pull/5684) | Consolidate drag handler effects in `useDrag` | `src/React/Hook/Drag.purs` |
| [#5682](https://github.com/xyflow/xyflow/pull/5682) | No unnecessary updates when `selectNodesOnDrag = false` | `src/System/XYDrag.purs`, `src/React/Hook/Drag.purs` |
| [#5550](https://github.com/xyflow/xyflow/pull/5550) | Prevent child nodes of different parents overlapping | `src/System/XYDrag/Utils.purs:36-55,86` |
| [#5043](https://github.com/xyflow/xyflow/pull/5043) | Use current `expandParent` value during drag | `src/System/Types/Node.purs:77,139` |
| [#4846](https://github.com/xyflow/xyflow/pull/4846) | `expandParent` with immer / immutable helpers | pure-FP path, structurally satisfied |
| [#5551](https://github.com/xyflow/xyflow/pull/5551) | Allow starting a selection above a node | `src/React/Container/Pane.purs` |
| [#5593](https://github.com/xyflow/xyflow/pull/5593) | Reset selection box when user selects a node | `src/React/Component/UserSelection.purs` |
| [#5727](https://github.com/xyflow/xyflow/pull/5727) | Clear visual selection when zero nodes remain selected | `src/React/Container/Pane.purs:293-295` |
| [#4929](https://github.com/xyflow/xyflow/pull/4929) | Selection accounts for selectability of connected edges | `src/System/Utils/Store.purs` |
| [#4862](https://github.com/xyflow/xyflow/pull/4862) | Prevent default scrolling on arrow-key move | `src/React/Hook/MoveSelectedNodes.purs` |
| [#5769](https://github.com/xyflow/xyflow/pull/5769) | `useEffect` for StoreUpdater | `src/React/Provider/StoreUpdater.purs:5-8,45` |
| [#5733](https://github.com/xyflow/xyflow/pull/5733) | Reorder StoreUpdater before GraphView, layout effects | `src/React/Container/ReactFlow.purs:203,272` |
| [#5368](https://github.com/xyflow/xyflow/pull/5368) | Cleanup store updater | `src/React/Provider/StoreUpdater.purs` |

## Note on the StoreUpdater rows

`src/React/Provider/StoreUpdater.purs:5-8` documents a deliberate structural
divergence: upstream uses a single `useEffect` over `fieldsToTrack.map(...)`,
PSFlow uses one `useEffect` per tracked prop. #5769 and #5733 are both about
*effect ordering and timing*, which is exactly what that divergence could
perturb. These two deserve scrutiny before being assumed correct — they are the
highest-risk rows in this ticket.

## Acceptance criteria

- Each row is either covered by a new assertion or explicitly re-bucketed with
  the reason it cannot be gated.
- The StoreUpdater ordering rows are verified against upstream semantics, not
  just assumed from the fidelity note.
- Rows flip from `ported-ungated` to a covered bucket in
  `parity/changelog-audit/verdicts.json`; `npm run parity:changelog` stays green.
- `spago test` and `npm run test:smoke` stay green.

## Source files

- `src/System/XYDrag.purs`, `src/System/XYDrag/Utils.purs`
- `src/React/Hook/Drag.purs`, `src/React/Hook/MoveSelectedNodes.purs`
- `src/React/Container/Pane.purs`, `src/React/Component/UserSelection.purs`
- `src/React/Provider/StoreUpdater.purs`, `src/React/Container/ReactFlow.purs`
- `parity/changelog-audit/verdicts.json` — the rows, with per-PR notes
