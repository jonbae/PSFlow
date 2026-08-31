# 079 — Test debt: MiniMap, Controls, Panel, Background and CSS behavior

> **Fates decided.** [Fate of the 57 test-debt rows under the
> net](https://github.com/jonbae/PSFlow/issues/21) assigned every row in this
> ticket a disposition — see `tickets/080-test-debt-dispositions.md`. Read that
> before writing any test here; most of these rows are covered by a shared
> scenario rather than a per-row assertion, and the acceptance criteria below
> are superseded by it. The research notes in this ticket still stand.


## Context

One of four test-debt tickets from the [071](071-version-drift-audit-12-3-to-12-11.md)
changelog sweep. Every row is `ported-ungated` — implemented in PSFlow, spot-checked
against upstream during the sweep, but exercised by no gate. See
[076](076-test-debt-drag-selection-store.md) for the shared rationale.

## Rows (15)

| PR | Change | Where it lives |
|---|---|---|
| [#5546](https://github.com/xyflow/xyflow/pull/5546) | Do not crash MiniMap if all nodes are hidden | `src/React/Additional/MiniMap.purs:91` |
| [#5692](https://github.com/xyflow/xyflow/pull/5692) | Handle undefined node in MiniMap | `src/React/Additional/MiniMap/Nodes.purs:54` |
| [#5139](https://github.com/xyflow/xyflow/pull/5139) | `rgba` instead of `rgb` for MiniMap mask color | `src/React/Additional/MiniMap.purs:138-141` |
| [#5153](https://github.com/xyflow/xyflow/pull/5153) | Separators on horizontal control buttons | `src/React/Additional/Controls.purs` |
| [#5252](https://github.com/xyflow/xyflow/pull/5252) | Center panel correctly for top/bottom-center | `src/React/Portal/Panel.purs:28-34` |
| [#5362](https://github.com/xyflow/xyflow/pull/5362) | Remove Panel pointer events while a selection is dragged | `src/React/Portal/Panel.purs` |
| [#4826](https://github.com/xyflow/xyflow/pull/4826) | Forward ref of the div inside Panel | `src/React/FFI/ForwardRef.purs` (Panel does not use it) |
| [#5259](https://github.com/xyflow/xyflow/pull/5259) | Fix background-color CSS variable fallback | `src/React/Additional/Background.purs:87,90` |
| [#5512](https://github.com/xyflow/xyflow/pull/5512) | Prevent native page zoom pinch-zooming a `nowheel` node | `src/System/XYPanZoom/Filter.purs` |
| [#5148](https://github.com/xyflow/xyflow/pull/5148) | Prevent browser zoom for pinch gestures on `nowheel` | same guard, system side |
| [#5638](https://github.com/xyflow/xyflow/pull/5638) | `touch-action: none` for mobile selection box | stylesheet-only |
| [#5455](https://github.com/xyflow/xyflow/pull/5455) | Fix warning when wrapper has `display: none` | `src/React/Hook/StylesLoadedWarning.purs` |
| [#5472](https://github.com/xyflow/xyflow/pull/5472) | Remove `dangerouslySetInnerHTML` from `domAttributes` | see [074](074-node-edge-domattributes-ariarole.md) |
| [#4844](https://github.com/xyflow/xyflow/pull/4844) | Custom `data-testid` for the ReactFlow component | `src/React/Container/ReactFlow.purs` |
| [#4855](https://github.com/xyflow/xyflow/pull/4855) | Pass `path` element attributes to `BaseEdge` | `src/React/Edge/Base.purs` |

## Notes

**#5472 is not really test debt** — it is listed here because PSFlow cannot
spread `domAttributes` at all, so the vulnerability it removes does not exist.
The real work is in [074](074-node-edge-domattributes-ariarole.md); implement
the spread with the exclusion already in place. Re-bucket this row when 074
lands, rather than covering it here.

**#5638 (`touch-action`) and the CSS-variable rows (#5259, #5139)** turn on
stylesheet behavior. PSFlow ships no CSS of its own and relies on the upstream
stylesheet, so these are arguably `n/a` rather than test debt. Decide that
explicitly and re-bucket — the sweep deliberately left them as gaps rather than
quietly claiming coverage PSFlow does not have.

**#4826 (Panel `forwardRef`)** is a genuine, already-documented deferral: both
`NodeWrapper.purs:28` and `EdgeWrapper.purs:25` note that `forwardRef` to the
inner element is deferred generally. It may belong with those as one
`forwardRef` ticket rather than here.

> **Settled, and the reading above was half wrong.** It did become one ticket,
> [#27](https://github.com/jonbae/PSFlow/issues/27), and the row is now
> `surface`. But only `Panel`, `Handle` and `ReactFlow` were ever missing a
> `forwardRef`. The two wrapper notes this paragraph cites were describing a
> deferral that upstream does not have either — neither `NodeWrapper` nor
> `EdgeWrapper` is a `forwardRef` there, both being internal components nothing
> hands a ref to. What was actually missing was the ref each one holds *for
> itself*, and the `blur()` calls that drop focus from a node or edge the user
> has just deselected. Both notes have been replaced with what the elements
> now do.

## Acceptance criteria

- Each row is covered, re-bucketed to `n/a` with a stated reason, or moved to the
  ticket that actually owns it (#5472 → 074; possibly #4826 → a `forwardRef`
  ticket).
- Rows flip out of `ported-ungated` in `parity/changelog-audit/verdicts.json`;
  `npm run parity:changelog` stays green.
- `spago test` and `npm run test:smoke` stay green.

## Source files

- `src/React/Additional/{MiniMap,Controls,Background}.purs`, `src/React/Additional/MiniMap/Nodes.purs`
- `src/React/Portal/Panel.purs`, `src/React/Edge/Base.purs`
- `src/System/XYPanZoom/Filter.purs`, `src/React/Hook/StylesLoadedWarning.purs`
- `parity/changelog-audit/verdicts.json` — the rows, with per-PR notes
