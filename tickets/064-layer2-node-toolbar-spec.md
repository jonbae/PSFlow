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
