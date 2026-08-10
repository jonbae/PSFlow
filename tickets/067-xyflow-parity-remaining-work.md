# 067 — xyflow feature-parity status & remaining work (consolidation)

## Bottom line

**PSFlow is functionally feature-complete against `@xyflow/react` 12.11.0 /
`@xyflow/system` 0.0.77** (the exact versions vendored under `xyflow/` and used
as the Layer 0 parity baseline). Everything below is **coverage depth and
cosmetic completeness, not missing features.**

Evidence of completeness at filing (2026-07-07):

- **Layer 0 (API surface)** — `npm run parity:surface` reports *"Missing in PSFlow:
  none — full parity"* against 12.11.0. All residual rows are allowlisted
  documented divergences (see [058](058-layer0-api-surface-gaps.md)).
- **Layer 2 (e2e)** — all 5 upstream specs ported and green: `nodes`, `pane`,
  `edges`, `node-toolbar`, `props` (`constants.ts`/`utils.ts` are helpers, not
  specs). Full smoke **52/52**; `spago test` green.
- **Components/hooks** — all 6 additional components (Background, Controls,
  EdgeToolbar, MiniMap, NodeResizer, NodeToolbar) and the upstream hook set are
  present.
- **Source hygiene** — zero `TODO`/`FIXME`/typed-hole/`unsafeCrashWith` markers
  in `src/`.

This ticket is the single index for the residual work. Each item is already
tracked in its own ticket; close a row by resolving the linked ticket and
striking it here.

## Remaining work (priority order)

### ~~1. Genuine behavioral divergence~~ — [066](066-edge-parity-followups-deferred.md) item 1 ✅ RESOLVED (2026-07-10)

The **only** item that was an actual behavior bug rather than test/polish.

- `reduceAddSelectedNodes` (`src/React/Store/Reduce.purs` ~333) now guards on
  `state.multiSelectionActive`, mirroring the edge side
  ([063](063-layer2-edges-spec.md) `reduceAddSelectedEdges`), so a meta-click
  multi-select of nodes adds to the selection instead of deselecting the
  previously-selected node. Guarded by a new `spago test` case (fails if the fix
  is reverted).

### ~~2. Test coverage~~ — [066](066-edge-parity-followups-deferred.md) item 2 ✅ RESOLVED (2026-07-10)

`test/Test/React/Store/Reduce.purs` now has unit coverage for the node
multi-select fix plus two of the three 063 edge fixes:

1. `reduceTriggerEdgeChanges` uncontrolled `edgeLookup`/`connectionLookup`
   rebuild (`Reduce.purs` ~304) — covered (`EdgeRemoveChange` drops from lookup).
2. `reduceAddSelectedEdges` `multiSelectionActive` branch (`Reduce.purs` ~356) —
   covered (select-reaches-lookup + keep-prior-selection).
3. `EdgeWrapper` `isSelectable` form (`EdgeWrapper.purs` ~343) — stays covered by
   e2e only (render concern, no reducer-test home).

### 3. Differential-parity depth — [059](059-layer1-behavioral-parity-coverage.md)

Four pure node-bounds functions are **implemented and exercised end-to-end by
Layer 2**, but not yet under the Layer 1 oracle differential harness:
`getInternalNodesBounds`, `getNodesInside`, `nodeToRect`/`nodeToBox`,
`getNodePositionWithOrigin`. Deferred because each needs richer oracle
translation (`NodeLookup` / `InternalNodeBase`). This tightens numeric-parity
confidence; it does not add a feature.

`getViewportForBounds` came under the harness with ticket 030 and
`getNodesBounds` with ticket 039; both are struck from 059's deferred table.

### 4. API-surface cosmetics — [058](058-layer0-api-surface-gaps.md)

Allowlisted, so `parity:surface` stays green. Completeness only.

- **Group A (~14 symbols)** exist in the code but are not re-exported through the
  `src/React.purs` barrel (e.g. `NodeProps`, `BackgroundVariant`, `NodeHandle`,
  `MiniMapNode(s)`, `FitViewParams`, the `Get*PathParams` aliases). Mostly
  one-line re-export additions.
- **Group B (~7 symbols)** are upstream-only type aliases with no PS model
  (`BuiltInNode`, `BuiltInEdge`, `ConnectionLineComponent`,
  `EdgeComponentWithPathOptions`, `GetMiniMapNodeAttribute`, `ResizeControlProps`,
  `ResizeControlLineProps`). Decide per-row: model or document as intentional
  divergence.

### ~~5. Numeric edge case~~ — [057](057-snapposition-negative-half-rounding.md) ✅ RESOLVED (2026-08-03)

`roundHalfAwayFromZero` → `roundHalfUp`, matching JS `Math.round` across the
full signed domain. Fixed at both call sites — `snapPosition` and `XYDrag`'s
multi-drag snap offset. Layer 1 now runs `snapPosition` (and
`pointToRendererPoint` *with* a grid) over the full domain, plus a dedicated
half-multiple generator so the tie-break is hit on every draw rather than ~1%
of them. Deterministic unit assertions in `Test/Main.purs` back it up.

### ~~6. `NodeProps` prop-member gap~~ — [069](069-nodeprops-prop-member-gap.md) ✅ RESOLVED (2026-08-03)

All 8 members now reach custom node components: `React.Types.Nodes` gained
`width`/`height`/`parentId`/`selectable`/`deletable`/`draggable` and the
`xPos`/`yPos` → `positionAbsoluteX`/`positionAbsoluteY` rename, and
`mkNodeProps` threads them (it already received `selectable`/`draggable` and
discarded them). `parity:surface` reports *NodeProps* 0 missing / 0 extra.

Because the Layer 0 prop-member diff is informational rather than a gate — which
is how this drift survived from 12.3.5 — the fix is guarded by e2e:
`examples/react-smoke/tests/node-props.spec.ts` (PSFlow-specific, not an
upstream port) asserts every threaded field off a probe node component at
`#/examples/node-props`. Confirmed to fail under a reverted `selectable` and
under `positionAbsoluteX` wired to raw `position`.

### ~~7. Behavioral-drift audit 12.3.5→12.11~~ — [071](071-version-drift-audit-12-3-to-12-11.md) ✅ RESOLVED (2026-08-03)

Port floor is 12.3.5; both the surface gate and the Layer 1 numeric tests
baseline at the vendored 12.11.0 / 0.0.77 (the oracle bundles from `xyflow/`,
not `node_modules`).

All **180 in-range PRs** are bucketed in `parity/changelog-audit/verdicts.json`:
113 covered, 66 silent gaps, 1 n/a. Genuine divergence was low, as predicted —
the lasting output is the gate. `npm run parity:changelog` now fails on any PR
without a verdict, which is what catches the *next* version bump, and the Layer 0
prop diff **gates** instead of merely printing (item 6's failure mode).
`EdgeProps.edgeType` → `type` landed here, taking all three prop records to 0/0.

The 66 gaps are split across rows 9–13 below. Two are known-wrong behavior; the
rest is test debt — behavior believed correct but unverified.

### 9. Node/Edge data-record `type` field — [072](072-node-edge-data-record-type-field.md)

The props records now match upstream's `type`; the `Node`/`Edge` *data* records
still say `nodeType`/`edgeType`. Wants a marshalling layer, so pair with item 8
(070), which needs the same JS-facing shape to emit `.d.ts`. The old "PureScript
keyword" rationale was false and has been corrected in both files.

### 10. `XYResizer` drag lifecycle is a scaffold — [073](073-xyresizer-drag-lifecycle-scaffold.md)

**Known wrong.** `onStart`/`onDrag`/`onEnd` are typed scaffolds: `onDrag` emits
literal zeros, `onEnd` fires unconditionally with `initResizeParams`, and the
`prevValues`/`resizeDetected` refs are allocated but never written. Blocks 5
in-range PRs. Predates the audit range — the sweep just made it visible.

### 11. Custom `default` node-type fallback — [075](075-custom-default-node-type-fallback.md)

**Known wrong.** An unknown node type falls back to `builtinNodeTypes.default`,
ignoring a user-supplied `default` in `nodeTypes`; upstream checks the user map
first. One-line fix, ticketed rather than fixed inline because gating it needs a
new fixture *and* route.

### 12. `domAttributes` / `ariaRole` on nodes and edges — [074](074-node-edge-domattributes-ariarole.md)

Not carried on `NodeBase`/`EdgeBase`; already documented in both wrappers.
`edge.reconnectable` belongs to the same cluster. Note these are invisible to the
Layer 0 prop diff, which covers only the three *props* records — a real blind
spot in the current gate.

### 13. Test debt from the sweep — [076](076-test-debt-drag-selection-store.md), [077](077-test-debt-connection-handle-keyboard.md), [078](078-test-debt-viewport-fitview-rendering.md), [079](079-test-debt-component-chrome.md)

57 rows where behavior **is** ported and was spot-checked against upstream, but
no gate exercises it — so a regression would keep every suite green. Split by
subsystem: drag/selection/store (16), connection/handle/keyboard (13),
viewport/fitView/render (13), component chrome (15). Highest-risk rows are called
out in each ticket; some chrome rows may legitimately re-bucket to `n/a`.

### 8. TypeScript declaration surface — [070](070-typescript-declaration-surface.md)

No `.d.ts`; TS consumers get `any` for the public surface. Largest drop-in item
but purely additive and partly generatable from the Layer 0 parity artifacts.
Depends on item 6.

## Recommendation

- For **"true parity"**: two known behavioral divergences are now open, both
  found by the 071 sweep and neither previously visible — the `XYResizer`
  lifecycle scaffold (item 10) and the custom `default` node-type fallback
  (item 11). Everything else is intentional or unverified-but-believed-correct.
  Earlier rows closed: items 1–2 (2026-07-10), items 5–6 (2026-08-03), item 7
  (2026-08-03).
- For **"can I claim parity"**: yes for the surface, with a caveat worth stating
  plainly. The Layer 0 diff against 12.11.0 is green and now *gates* the prop
  members too, and all 180 changelog PRs are bucketed. But the gate is name-only
  (types and arity are not compared), it does not cover the `Node`/`Edge` data
  records at all (item 12), and 57 ported behaviors have no test exercising them
  (item 13). "Parity is gated" is true; "parity is proven" is not.
- **Bumping the baseline** is now one procedure, documented in the README parity
  section: update `xyflow/`, re-pin the exact devDependencies, rebuild the
  oracle, then run `parity:surface` and `parity:changelog` together. The changelog
  audit will fail on every PR the bump introduces until each is bucketed.

## Acceptance criteria

- This ticket stays accurate as the parity index: each row is either resolved
  (and struck, with its linked ticket closed) or remains a documented,
  allowlisted divergence.
- `npm run parity:surface` (Layer 0) and `spago test` / `npm run test:smoke` stay
  green as rows are closed.

## Source files / references

- [066](066-edge-parity-followups-deferred.md) — behavioral divergence + unit
  coverage (items 1–2)
- [059](059-layer1-behavioral-parity-coverage.md) — Layer 1 deferred functions
  (item 3)
- [058](058-layer0-api-surface-gaps.md) — Layer 0 surface gaps (item 4)
- [057](057-snapposition-negative-half-rounding.md) — snapPosition rounding
  (item 5)
- [071](071-version-drift-audit-12-3-to-12-11.md) — changelog drift audit
  (item 7, resolved); spawned [072](072-node-edge-data-record-type-field.md),
  [073](073-xyresizer-drag-lifecycle-scaffold.md),
  [074](074-node-edge-domattributes-ariarole.md),
  [075](075-custom-default-node-type-fallback.md),
  [076](076-test-debt-drag-selection-store.md),
  [077](077-test-debt-connection-handle-keyboard.md),
  [078](078-test-debt-viewport-fitview-rendering.md),
  [079](079-test-debt-component-chrome.md) (items 9–13)
- `parity/surface/report.md` — generated full-parity snapshot
- `parity/changelog-audit/report.md` — the 180-PR drift audit; its
  `verdicts.json` is the per-PR record, cross-linked to the tickets above
- Vendored upstream baseline: `xyflow/packages/react` 12.11.0 /
  `xyflow/packages/system` 0.0.77
