# 073 — `XYResizer` drag lifecycle is a typed scaffold

## Context

Found by the [071](071-version-drift-audit-12-3-to-12-11.md) changelog sweep.
Five in-range upstream PRs land in `not-ported` for one shared reason: the
`XYResizer` drag lifecycle was never wired up.

`src/System/XYResizer.purs:301-338` carries three handlers whose own header
comment calls them "typed scaffolds":

```purescript
onDrag _params _state upd ev = case upd.onResize of
  Just cb -> cb (ResizeDragEvent (toForeign ev))
    { x: 0.0, y: 0.0, width: 0.0, height: 0.0, direction: { dx: 0, dy: 0 } }
  Nothing -> pure unit

onEnd _params _state upd ev = case upd.onResizeEnd of
  Just cb -> cb (ResizeDragEvent (toForeign ev)) initResizeParams
  Nothing -> pure unit
```

`onDrag` emits literal zeros. `onEnd` passes `initResizeParams` (also zeros).
All three ignore their `_state` parameter, so the `ResizerState` fields that
exist for exactly this purpose are never read:

- `prevValues :: Ref ResizeParams` (`:232`) — allocated, never written or read.
- `resizeDetected :: Ref Boolean` (`:234,266`) — allocated at `false`, never
  written.

The math is not missing — `System.XYResizer.Utils.getDimensionsAfterResize`
exists. It is simply never called from the lifecycle.

**This predates the 12.3.5→12.11.0 range.** It is not version drift; the sweep
just made it visible by asking what these five PRs would need in order to be
observable.

## The five in-range PRs this blocks

| PR | Upstream change | Why it cannot land today |
|---|---|---|
| [#5509](https://github.com/xyflow/xyflow/pull/5509) | Prevent calling `onResizeEnd` if the node was not resized | Upstream guards on `resizeDetected`; PSFlow calls unconditionally |
| [#5147](https://github.com/xyflow/xyflow/pull/5147) | Pass dimensions to the final resize change event | Upstream passes `{ ...prevValues }`; PSFlow passes zeros |
| [#5528](https://github.com/xyflow/xyflow/pull/5528) | Let `NodeResizer` props change during an ongoing resize | No ongoing-resize state to observe |
| [#5784](https://github.com/xyflow/xyflow/pull/5784) | Fix node resizing possible beyond absolute extents | Extent clamping is unreachable |
| [#5326](https://github.com/xyflow/xyflow/pull/5326) | Prevent `NodeResizer` controls becoming too small when zooming out | Control auto-scaling exists (`src/React/Additional/NodeResizer/Control.purs:83`) but the lifecycle it feeds is inert |

Upstream reference: `xyflow/packages/system/src/xyresizer/XYResizer.ts` —
`resizeDetected` at `:139`, the `.on('end')` guard, and `prevValues` maintenance
through the drag.

## Scope

Wire the lifecycle: thread `ResizerState` through `onStart`/`onDrag`/`onEnd`,
maintain `prevValues` and `resizeDetected`, and call
`getDimensionsAfterResize`. Then the five PRs above become assertions rather
than separate work.

This is deliberately **not** an inline fix under 071's triage rule: it is
multi-file, needs the Utils math wired in, and needs a new example route +
fixture + spec to be gated at all.

## Acceptance criteria

- `onResizeEnd` fires only when a resize actually occurred, and receives the
  final dimensions.
- Extent clamping applies during resize (#5784).
- A Layer 2 spec drives a real resize and asserts the emitted dimensions;
  reverting the `resizeDetected` guard fails it.
- `npm run parity:surface`, `spago test`, `npm run test:smoke` stay green.
- The five rows above flip from `not-ported` to a covered bucket in
  `parity/changelog-audit/verdicts.json`.

## Source files

- `src/System/XYResizer.purs:227-267` (state), `:301-338` (the scaffolds)
- `src/System/XYResizer/Utils.purs` — `getDimensionsAfterResize`
- `src/React/Additional/NodeResizer.purs`, `src/React/Additional/NodeResizer/Control.purs`
- `xyflow/packages/system/src/xyresizer/XYResizer.ts` — upstream reference
