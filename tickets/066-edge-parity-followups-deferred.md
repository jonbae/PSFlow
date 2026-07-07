# 066 — Deferred parity follow-ups from the Layer 2 edges work

## Context

Ticket [063](063-layer2-edges-spec.md) (edges.spec) uncovered three edge parity
bugs and fixed all three (uncontrolled `edgeLookup` rebuild, `multiSelectionActive`
branch, `isSelectable` inversion) — `generic-edges.spec.ts` is 16/16 and the full
smoke suite is 52/52. This ticket **defers** two real-but-non-blocking items that
surfaced during that work. Both are optional: the Layer 2 e2e series is
functionally complete without them.

## Item 1 — `reduceAddSelectedNodes` is missing the `multiSelectionActive` branch (latent parity bug)

`src/React/Store/Reduce.purs` `reduceAddSelectedNodes` (~line 333) unconditionally
does the "replace" selection path (`getNodeSelectionChanges … selectedSet true`,
deselecting every other node). It never checks `state.multiSelectionActive`, so a
**meta-click multi-select of nodes deselects the previously-selected node** instead
of adding to the selection.

This is the exact symmetric bug to the edge one fixed in 063: TS's
`addSelectedNodes` has an early `multiSelectionActive` branch (see upstream
`packages/react/src/store/index.ts:296-307`) that just marks the new nodes selected
and returns, leaving existing node selection intact and edges untouched. The edge
side now mirrors this (`reduceAddSelectedEdges`, `Reduce.purs:356`); the node side
does not.

**Why deferred / low urgency:** no test exercises it. Upstream `nodes.spec.ts` has
no node meta-click multi-select case (only the shift-drag lasso, which passes a
single `AddSelectedNodes` call with *all* ids at once, so the missing branch
doesn't bite). It was left out of 063 deliberately to avoid touching the passing
node path (`generic-nodes.spec.ts` 13/13) for an untested divergence.

**Fix (~5 lines):** guard `reduceAddSelectedNodes` on `state.multiSelectionActive`,
mirroring `reduceAddSelectedEdges` — when active, emit
`NodeSelectionChange { id, selected: true }` for the given ids via
`reduceTriggerNodeChanges` and return, leaving edges/other nodes alone.

**Verification:** re-run the full smoke suite (`generic-nodes.spec.ts` must stay
13/13). Optionally add a `Test/React/Store/Reduce.purs` case (see Item 2) and/or a
node meta-click e2e case to lock it in.

## Item 2 — no unit coverage for the three edge fixes

The three 063 fixes are validated **only** by the e2e smoke suite
(`generic-edges.spec.ts`), not by `spago test`:

1. `reduceTriggerEdgeChanges` (`Reduce.purs:304`) — uncontrolled `edgeLookup` /
   `connectionLookup` rebuild.
2. `reduceAddSelectedEdges` (`Reduce.purs:356`) — the `multiSelectionActive` branch.
3. `EdgeWrapper` `isSelectable` (`EdgeWrapper.purs:343`) — the
   `edge.selectable || (elementsSelectable && isNothing edge.selectable)` form.

`test/Test/React/Store/Reduce.purs` already exercises the reducers with
`sampleEdge`/`freshEdge`, so it's the natural home. Suggested cases:

- After `AddSelectedEdges [id]` (with `hasDefaultEdges = true` and
  `multiSelectionActive = false`), `state.edgeLookup[id].selected == true` (guards
  the DOM-sync fix; would have caught the original "select never reaches the DOM"
  bug).
- With `multiSelectionActive = true`, `AddSelectedEdges [id2]` keeps a
  previously-selected `id1` selected (guards Item-1-style behavior on the edge side).
- `TriggerEdgeChanges [EdgeRemoveChange { id }]` drops `id` from `edgeLookup`.

Add the analogous node case if Item 1 is done.

## Acceptance criteria

- Item 1: `reduceAddSelectedNodes` honors `multiSelectionActive`; full smoke suite
  stays green (esp. `generic-nodes.spec.ts` 13/13).
- Item 2: new `spago test` cases cover the edge (and node, if Item 1 landed)
  selection/lookup-sync paths; `spago test` stays green.

## Source files

- `src/React/Store/Reduce.purs` — `reduceAddSelectedNodes` (333),
  `reduceAddSelectedEdges` (356, reference), `reduceTriggerEdgeChanges` (304)
- `src/React/Component/EdgeWrapper.purs` — `isSelectable` (343, reference)
- `test/Test/React/Store/Reduce.purs` — new cases
- Reference: upstream `packages/react/src/store/index.ts:296-319`
  (`addSelectedNodes` / `addSelectedEdges`), ticket [063](063-layer2-edges-spec.md)
