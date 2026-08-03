# 077 — Test debt: connection, handle and keyboard behavior

## Context

One of four test-debt tickets from the [071](071-version-drift-audit-12-3-to-12-11.md)
changelog sweep. Every row is `ported-ungated` — implemented in PSFlow, spot-checked
against upstream during the sweep, but exercised by no gate. See
[076](076-test-debt-drag-selection-store.md) for the shared rationale.

## Rows (13)

| PR | Change | Where it lives |
|---|---|---|
| [#5704](https://github.com/xyflow/xyflow/pull/5704) | Keep `onConnectEnd` / `isValidConnection` current during a connection | `src/React/Handle.purs` |
| [#5578](https://github.com/xyflow/xyflow/pull/5578) | Pass current pointer position to connection | `src/System/XYHandle.purs` |
| [#5635](https://github.com/xyflow/xyflow/pull/5635) | Update ongoing connection when node moves by keyboard | `src/React/Hook/MoveSelectedNodes.purs`, `src/System/XYHandle.purs` |
| [#5266](https://github.com/xyflow/xyflow/pull/5266) | Connection snapping for handles larger than `connectionRadius` | `src/System/XYHandle/Utils.purs` |
| [#5480](https://github.com/xyflow/xyflow/pull/5480) | Prevent multi-touch during a new connection | `src/System/XYHandle.purs` |
| [#5428](https://github.com/xyflow/xyflow/pull/5428) | Clicking detached handle elements starts a connection | `src/System/XYHandle/Utils.purs` |
| [#5515](https://github.com/xyflow/xyflow/pull/5515) | Fix id parsing of static handles | `src/React/Handle.purs` |
| [#5042](https://github.com/xyflow/xyflow/pull/5042) | Click connections when target sets `isConnectableStart` | `src/React/Handle.purs` |
| [#4949](https://github.com/xyflow/xyflow/pull/4949) | `useNodeConnections` returns all connected edges | `src/React/Hook/NodeConnections.purs` |
| [#5090](https://github.com/xyflow/xyflow/pull/5090) | Release key even when an input is focused | `src/React/Hook/KeyPress.purs` |
| [#5118](https://github.com/xyflow/xyflow/pull/5118) | Do not swallow key events when a button is focused | `src/React/Hook/KeyPress.purs`, `src/System/Utils/Dom.purs` |
| [#5263](https://github.com/xyflow/xyflow/pull/5263) | Multi-select key works when an input is focused | `src/React/Hook/KeyPress.purs` |
| [#4880](https://github.com/xyflow/xyflow/pull/4880) | Type check all event targets | `src/System/Utils/Dom.purs` |

## Note

The three `KeyPress` rows (#5090, #5118, #5263) plus #4880 all turn on the same
predicate — `isInputDOMNode` in `src/System/Utils/Dom.purs` — and each PR
adjusted which DOM nodes count as "input-like". They are cheap to cover
together with a focused unit test over that predicate, which is likely the
highest value-per-effort item in this ticket. Note the existing Layer 1 coverage
is only indirect (`test/Test/Main.purs:195` asserts `elementSelectionKeys`).

## Acceptance criteria

- Each row is covered by a new assertion or explicitly re-bucketed with a reason.
- `isInputDOMNode` gains direct unit coverage over the node kinds these PRs
  touched.
- Rows flip to a covered bucket in `parity/changelog-audit/verdicts.json`;
  `npm run parity:changelog` stays green.
- `spago test` and `npm run test:smoke` stay green.

## Source files

- `src/React/Handle.purs`, `src/System/XYHandle.purs`, `src/System/XYHandle/Utils.purs`
- `src/React/Hook/KeyPress.purs`, `src/React/Hook/NodeConnections.purs`
- `src/System/Utils/Dom.purs`
- `parity/changelog-audit/verdicts.json` — the rows, with per-PR notes
