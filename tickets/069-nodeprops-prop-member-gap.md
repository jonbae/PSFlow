# 069 — `NodeProps` prop-member gap (custom-node component contract)

## ✅ RESOLVED (2026-08-03)

All three acceptance criteria met.

1. **The record** — `src/React/Types/Nodes.purs` gained `width`, `height`,
   `parentId`, `selectable`, `deletable`, `draggable` and renamed `xPos`/`yPos` →
   `positionAbsoluteX`/`positionAbsoluteY`. `mkNodeProps`
   (`src/React/Component/NodeWrapper.purs`) stopped discarding its `selectable`/
   `draggable` parameters and threads all eight values through. No new logic.
   `npm run parity:surface` now reports `props missing: … Node=0` (was 8 missing +
   2 extra).

2. **Suites stay green** — `spago test` green; `npm run test:smoke` 54/54 (the
   52-test baseline plus the two new cases).

3. **The guard** — `examples/react-smoke/tests/node-props.spec.ts`, backed by
   `examples/react-smoke/src/Example/NodePropsProbe.purs` on route
   `#/examples/node-props`. A probe node component renders every threaded field
   as a `data-*` attribute; two nodes cover both branches of NodeWrapper's flag
   resolution:

   - `probe-parent` (100, 200) leaves `selectable`/`draggable`/`deletable` at
     `Nothing`, so they default from `elementsSelectable`/`nodesDraggable`/
     `fromMaybe true` → all `"true"`.
   - `probe-child` (50, 25) sets all three to `Just false` explicitly, carries
     `parentId`, and — because its parent is off-origin — has
     `positionAbsolute` (150, 225) ≠ its own `position` (50, 25). That gap is
     what makes the renamed fields testable rather than vacuous.

   Both reverts were checked: hard-coding `selectable: true` fails the spec, and
   wiring `positionAbsoluteX` to `node.position.x` fails it too.

   The probe is deliberately **PSFlow-specific and isolated** — its own module,
   route and spec file — because `tests/generic-*.spec.ts` and `src/Generic/*`
   are faithful ports of upstream's e2e suite and a PSFlow-only assertion there
   would break that invariant. Same shape as `Example.ColorMode`. The one
   mechanical change to ported code is exporting `baseNode` from
   `Generic.Fixture`, which no fixture's semantics depend on.

Out of scope, noted for [071](071-version-drift-audit-12-3-to-12-11.md): the
Layer 0 report still shows *Edge* props 1 missing — upstream's `type` vs PSFlow's
`edgeType`.

## Context

Layer 0's prop-member diff (`parity/surface/report.md` → *NodeProps*) reports
**8 members missing** on the props object PSFlow passes into a user's custom node
component, plus a rename PSFlow has not tracked. This is distinct from
[058](058-layer0-api-surface-gaps.md) Group A, which only tracks re-exporting the
`NodeProps` *type* through the React barrel — this ticket is about the *runtime
record being incomplete*, so custom-node authors cannot read fields upstream
guarantees.

Upstream contract (`xyflow/packages/system/src/types/nodes.ts` `NodeProps`,
12.11.0):

```
Pick<NodeBase, 'id'|'data'|'width'|'height'|'sourcePosition'|'targetPosition'|'dragHandle'|'parentId'>
& Required<Pick<NodeBase, 'type'|'dragging'|'zIndex'|'selectable'|'deletable'|'selected'|'draggable'>>
& { isConnectable, positionAbsoluteX, positionAbsoluteY }
```

PSFlow record (`src/React/Types/Nodes.purs:43`) currently has: `id`, `data`,
`selected`, `type`, `isConnectable`, `xPos`, `yPos`, `zIndex`, `dragging`,
`targetPosition`, `sourcePosition`, `dragHandle`.

### The gap

| Missing / renamed | Upstream | Notes |
|---|---|---|
| `width` | `Pick<NodeBase>` | optional (`Maybe Number`) |
| `height` | `Pick<NodeBase>` | optional (`Maybe Number`) |
| `parentId` | `Pick<NodeBase>` | optional (`Maybe String`) |
| `selectable` | `Required` | already computed at the call site (see below) |
| `deletable` | `Required` | pull from `node` |
| `draggable` | `Required` | already computed at the call site (see below) |
| `positionAbsoluteX` | renamed | PSFlow still exports `xPos` |
| `positionAbsoluteY` | renamed | PSFlow still exports `yPos` |

The `xPos`/`yPos` → `positionAbsoluteX`/`positionAbsoluteY` rename is 12.3.5→12.11
upstream drift the port never picked up. It is a concrete instance of the drift
audited in [071](071-version-drift-audit-12-3-to-12-11.md).

## Why it's low-effort

`mkNodeProps` (`src/React/Component/NodeWrapper.purs:294`) **already receives**
`_selectable` and `_draggable` as parameters and discards them (underscore-
prefixed); only `_connectable` is placed in the record. `NodeBase` already carries
`width`/`height`/`parentId`/`deletable`. So the change is:

1. `src/React/Types/Nodes.purs:43` — add the 6 fields, rename `xPos`/`yPos` →
   `positionAbsoluteX`/`positionAbsoluteY`.
2. `src/React/Component/NodeWrapper.purs:294` — stop discarding `_selectable`/
   `_draggable`, add them plus `deletable`/`width`/`height`/`parentId` to the
   record, rename the two position fields.
3. Any internal read of `props.xPos`/`props.yPos` (built-in nodes) follows the
   rename.

No new logic — wiring existing values through.

## Acceptance Criteria

- `parity/surface/report.md` *NodeProps* section shows **0 missing**, and the
  `xPos`/`yPos` extras are gone (or the extras list is empty).
- `spago test` and `npm run test:smoke` stay green.
- A smoke/e2e assertion reads at least one newly-threaded field (e.g. a custom
  node observing `selectable` / `width`) so the wiring is guarded against regress.

## Source Files

- [src/React/Types/Nodes.purs](../src/React/Types/Nodes.purs) — the record (`:43`)
- [src/React/Component/NodeWrapper.purs](../src/React/Component/NodeWrapper.purs)
  — `mkNodeProps` (`:289`)
- [parity/surface/report.md](../parity/surface/report.md) — prop-member diff
- [058](058-layer0-api-surface-gaps.md) — the *type*-export side (Group A)
- [071](071-version-drift-audit-12-3-to-12-11.md) — broader drift this is part of
