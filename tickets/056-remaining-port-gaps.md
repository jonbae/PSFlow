# 056 — Smoke-test follow-ups after Handle wiring

## Context

The Handle-wiring commit (the change that landed alongside this ticket) closed item 4 of the earlier draft of this ticket — the connection-state visual-class flags (`connectingfrom`, `connectingto`, `clickconnecting`, `valid`, the gated `connectionindicator`) — by subscribing `src/React/Handle.purs` to `state.connection` and `state.connectionClickStartHandle` and threading the seven booleans into `buildClassName`.

A re-audit of `xyflow-main/packages/react/src` against `src/React` confirmed every upstream module has a PS port — `EdgeToolbar`, `EdgeLabelRenderer`, `ViewportPortal`, `BatchProvider`, all `Edges` variants, all `Nodes` variants, etc. The structural port is feature-complete. What remains are the smoke-test wirings that the Handle change unblocks and a couple of nit follow-ups carried forward from ticket 052.

## Items

### 1. Un-skip "click-connect creates an edge"

[smoke.spec.ts:107](../examples/react-smoke/tests/smoke.spec.ts) is currently `test.skip(...)`. Replace with a real body now that `src/React/Handle.purs` implements click-connect:

- Set `connectOnClick: Just true` in [Example/Main.purs](../examples/react-smoke/src/Example/Main.purs)'s `reactFlowProps`.
- Wire an `onConnect` callback (or set `defaultEdges` / `hasDefaultEdges` via the provider) so the resulting edge actually shows up in the DOM. Without one of those, `onConnectExtended` calls back but the store's `edges` array doesn't change.
- Playwright body: click the source handle of `n1` (`.react-flow__handle[data-nodeid="n1"][data-handlepos="right"]`), then the target handle of `n2`, assert `.react-flow__edge` count went from 1 to 2.

### 2. Un-skip "node drag fires onNodesChange"

[smoke.spec.ts:104](../examples/react-smoke/tests/smoke.spec.ts) is currently `test.skip(...)`. The "blocked by Handle wiring" comment is misleading — node drag flows through `System.XYDrag`, not `System.XYHandle`. Two-step fix:

- Add an `onNodesChange` callback in [Example/Main.purs](../examples/react-smoke/src/Example/Main.purs) that writes the change array to `window.__lastNodeChanges` (a small FFI).
- Playwright body: drag node `n1` by (50, 50), assert `window.__lastNodeChanges` contains a `position` change for `n1` with a non-zero delta.

If after wiring the example app the test still fails, the assumption that node drag is independent of Handle wiring is wrong — investigate at that point.

### 3. Optional: "connection-state classes flip during drag"

Adds coverage for the new visual-class flags that the Handle wiring brought in.

- Start a drag from `n1`'s source handle, hover partway between nodes, assert the source handle has class `connectingfrom` and target candidates have `connectionindicator`.
- Release on `n2`'s target handle, assert the resulting edge.

Lower priority than items 1 and 2 — those exercise the same wiring at a coarser granularity.

## Files touched (when all items close)

- `examples/react-smoke/tests/smoke.spec.ts` — un-skip and replace bodies; optionally one new test.
- `examples/react-smoke/src/Example/Main.purs` — add `onNodesChange` + `onConnect` capture and `connectOnClick: Just true`.
- Possibly a small JS sidecar to expose `window.__lastNodeChanges` for Playwright (or use `page.evaluate` to subscribe via a React effect).

## Acceptance criteria

- `purs compile` (project equivalent of `spago build`) stays green with zero warnings.
- All currently-passing smoke tests stay green.
- Items 1 and 2 turn red `test.skip` → green `test`.
- No regressions in the existing 7 smoke tests (two-nodes-one-edge, Background, MiniMap click, Controls zoom, wheel zoom, background pan, no console errors).

## Prerequisite tickets

- The Handle-wiring commit. Without it, both items remain blocked.

## Notes

After this ticket closes, the only known gaps that aren't behind tickets are:

- The five open items in ticket [052](052-react-flow-divergences-followups.md) (dev-time warning hook, `isNode`/`isEdge` siting, `multiSelectionKeyCode` macOS default, `outerRef`, focus-scroll-reset).
- The type-alias gaps in ticket [054](054-react-public-api-missing-symbols.md).
- The decision in ticket [055](055-edgeid-handleid-newtype-decision.md).

None of those blocks a working flow; they're polish.
