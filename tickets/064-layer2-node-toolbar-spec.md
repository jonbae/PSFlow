# 064 — Layer 2: node-toolbar.spec (toolbar positioning + default visibility)

## Context

Layer 2 e2e port (recipe: ticket [061](061-layer2-nodes-spec-interaction-gaps.md)).
Only 2 tests, but this is the only remaining generic fixture with a **custom node
type**, and it needs one **confirmed one-line source fix**.

Upstream spec: `xyflow/tests/playwright/e2e/node-toolbar.spec.ts` (2 tests).
Route `#/tests/generic/node-toolbar/general`. Fixture `node-toolbar/general.ts`
+ custom `node-toolbar/components/ToolbarNode.tsx`. `ToolbarNode` renders
`<NodeToolbar isVisible position align>` (3 buttons) + label + source/target
`Handle`s. 13 nodes: 1 `default-node` (toolbar shown only when selected) + 12
position×align permutations (`toolbarVisible:true`); 1 edge.
`nodeTypes: { ToolbarNode }`.

## Resolution (2026-07-07) — 2 / 2 pass, one-line source fix as predicted

Went exactly as scoped — the confirmed one-line source fix plus the custom
component port, no surprises:

- **Source fix** — `src/React/Additional/NodeToolbar.purs`: wrapped the `data-id`
  `foldl` in `String.trim` (mirrors upstream's `.reduce(…, '').trim()`), so the
  spec's exact-match `[data-id="node-start-top"]` resolves. Toolbar Layer-1 parity
  (`spago test`) stays green — the trim only touches the `data-id` string, not the
  `getNodeToolbarTransform` math.
- **New component** — `examples/react-smoke/src/Generic/ToolbarNode.purs`: renders
  `<NodeToolbar isVisible position align>` (3 buttons) + a left `Target` / right
  `Source` `Handle` (all from the public `React` barrel), reading a `ToolbarData`
  record off the opaque `NodeProps Foreign` via `unsafeCoerce`. The PS `Position` /
  `Align` ADTs round-trip fine (fixture stores the actual PS values; component
  coerces them back — same runtime rep).
- **Fixture** — `Generic.Fixture` gained `nodeToolbarGeneral` (1 `default-node`
  with `toolbarVisible`/`toolbarAlign` = `Nothing` for selection-driven visibility
  + 12 position×align permutations built via `Array.concatMap` + 1 edge) and a
  route arm. `mkToolbarNode` stashes the richer `data` under the `Node Unit` `data`
  field (typed `Unit`, runtime a record — the store treats `data` opaquely), so no
  change to the `Fixture` type was needed.

Full smoke 50/50; `spago test` green (incl. toolbar parity).

## Tests (2)

- `all toolbars are positioned correctly` — for each of 12 permutations, assert
  the toolbar box sits on the correct side of the node box and aligns
  start/center/end. Locates toolbars via exact-match `[data-id="node-start-top"]`
  etc.
- `toolbar default behaviour` — `default-node`'s toolbar is absent until the node
  is clicked, then attached (selection-driven visibility).

## Work

- **Source fix (confirmed):** `src/React/Additional/NodeToolbar.purs` builds the
  toolbar `data-id` via `foldl (\acc n -> acc <> unwrap n.id <> " ") ""` →
  trailing space (`"node-start-top "`). Upstream `.trim()`s it
  (`packages/react/src/additional-components/NodeToolbar/NodeToolbar.tsx:136`).
  The spec's exact-match `[data-id="node-start-top"]` won't match until trimmed.
  One-line fix.
- **New custom component:** port `ToolbarNode` into
  `examples/react-smoke/src/Generic/ToolbarNode.purs`, modeled on
  `Generic/DragHandleNode.purs`. It reads `data.toolbarVisible /
  toolbarPosition / toolbarAlign` and renders `NodeToolbar` (from the public
  `React` barrel) + two `Handle`s. This makes node `data` **non-`Unit`**: the
  generic `baseNode` is `Node Unit`, so this fixture carries a richer/coerced
  data payload (follow `DragHandleNode`'s `NodeProps Foreign` approach). Register
  via `nodeTypes` (coerced `Object`, as in `Fixture.purs` ~121–124).
- Add the `nodeToolbarGeneral` fixture + `fixtureForRoute` arm; adopt the spec as
  `examples/react-smoke/tests/generic-node-toolbar.spec.ts` with the three infra
  edits.

## Feature status

`NodeToolbar` exists (`src/React/Additional/NodeToolbar.purs`, isVisible/position/
align/offset, selection-based default visibility ~113–120) with its portal
(`NodeToolbar/Portal.purs`). Transform math exists and is under Layer-1 parity
(`src/System/Utils/Toolbar.purs` `getNodeToolbarTransform`, align
start/center/end → 0/0.5/1.0). `Handle` exists (`src/React/Handle.purs`). So once
the data-id is trimmed and the custom node is ported, positioning should be
correct. Verify the PS `Position`/`Align` ADT encoding matches what a PS
`ToolbarNode` passes to `NodeToolbar`.

## Acceptance criteria

- `npm run build:smoke && npm run test:smoke -- --grep "node-toolbar"` → both green.
- Full `npm run test:smoke` stays green.
- If `NodeToolbar` output is under Layer-1 parity, re-run `spago test`.

## Source files

- New: `examples/react-smoke/tests/generic-node-toolbar.spec.ts`,
  `examples/react-smoke/src/Generic/ToolbarNode.purs`
- Edit (fixture): `examples/react-smoke/src/Generic/Fixture.purs`
- Edit (source fix): `src/React/Additional/NodeToolbar.purs` (data-id `.trim()`)
- Reference: `xyflow/tests/playwright/e2e/node-toolbar.spec.ts`,
  `xyflow/examples/react/src/generic-tests/node-toolbar/{general.ts,components/ToolbarNode.tsx}`
