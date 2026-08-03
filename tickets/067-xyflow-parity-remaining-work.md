# 067 — xyflow feature-parity status & remaining work (consolidation)

## Bottom line

**PSFlow is functionally feature-complete against `@xyflow/react` 12.11.0 /
`@xyflow/system` 0.0.77** (the exact versions vendored under `xyflow/` and used
as the Layer 0 parity baseline). Everything below is **coverage depth and
cosmetic completeness, not missing features.**

Evidence of completeness at filing (2026-07-07):

- **Layer 0 (API surface)** — `npm run parity:api` reports *"Missing in PSFlow:
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

Six pure node-bounds/viewport functions are **implemented and exercised
end-to-end by Layer 2**, but not yet under the Layer 1 oracle differential
harness: `getNodesBounds`, `getInternalNodesBounds`, `getNodesInside`,
`getViewportForBounds`, `nodeToRect`/`nodeToBox`, `getNodePositionWithOrigin`.
Deferred because each needs richer oracle translation (measured dims / origin /
`NodeLookup` / `InternalNodeBase`). This tightens numeric-parity confidence; it
does not add a feature.

### 4. API-surface cosmetics — [058](058-layer0-api-surface-gaps.md)

Allowlisted, so `parity:api` stays green. Completeness only.

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
discarded them). `parity:api` reports *NodeProps* 0 missing / 0 extra.

Because the Layer 0 prop-member diff is informational rather than a gate — which
is how this drift survived from 12.3.5 — the fix is guarded by e2e:
`examples/react-smoke/tests/node-props.spec.ts` (PSFlow-specific, not an
upstream port) asserts every threaded field off a probe node component at
`#/examples/node-props`. Confirmed to fail under a reverted `selectable` and
under `positionAbsoluteX` wired to raw `position`.

### 7. Behavioral-drift audit 12.3.5→12.11 — [071](071-version-drift-audit-12-3-to-12-11.md)

Port floor is 12.3.5; surface is gated at 12.11.0 and numeric behavior tested
at 12.10.2. Bounded sweep of changelog entries not covered by Layer 1 or the 5
e2e specs. Item 6 is the first instance it would catch (now fixed). A second
candidate is already visible in the Layer 0 report: *Edge* props still show 1
missing member — upstream's `type` vs PSFlow's `edgeType`.

### 8. TypeScript declaration surface — [070](070-typescript-declaration-surface.md)

No `.d.ts`; TS consumers get `any` for the public surface. Largest drop-in item
but purely additive and partly generatable from the Layer 0 parity artifacts.
Depends on item 6.

## Recommendation

- For **"true parity"**: every known behavioral divergence is now closed — items
  1–2 (node multi-select + unit coverage, 2026-07-10), item 6 (`NodeProps`,
  2026-08-03) and item 5 (`snapPosition` rounding, 2026-08-03). The remaining
  rows 3, 4, 7 and 8 are tracked precisely *because* they are intentional,
  non-blocking gaps; decide per-row whether they are worth closing.
- For **"can I claim parity"**: effectively already yes — the objective gate
  (Layer 0 diff against 12.11.0) is green and every remaining item is documented
  and allowlisted.

## Acceptance criteria

- This ticket stays accurate as the parity index: each row is either resolved
  (and struck, with its linked ticket closed) or remains a documented,
  allowlisted divergence.
- `npm run parity:api` (Layer 0) and `spago test` / `npm run test:smoke` stay
  green as rows are closed.

## Source files / references

- [066](066-edge-parity-followups-deferred.md) — behavioral divergence + unit
  coverage (items 1–2)
- [059](059-layer1-behavioral-parity-coverage.md) — Layer 1 deferred functions
  (item 3)
- [058](058-layer0-api-surface-gaps.md) — Layer 0 surface gaps (item 4)
- [057](057-snapposition-negative-half-rounding.md) — snapPosition rounding
  (item 5)
- `parity/layer0-api/report.md` — generated full-parity snapshot
- Vendored upstream baseline: `xyflow/packages/react` 12.11.0 /
  `xyflow/packages/system` 0.0.77
