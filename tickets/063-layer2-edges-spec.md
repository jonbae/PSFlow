# 063 — Layer 2: edges.spec (edge properties + selection/delete)

## Context

Layer 2 e2e port (recipe: ticket [061](061-layer2-nodes-spec-interaction-gaps.md)).
This ports the largest of the four remaining upstream specs and is expected to
surface **two genuine source gaps** — the same shape as ticket
[060](060-node-classname-style-presentational-fields.md)'s node work, but for
edges.

Upstream spec: `xyflow/tests/playwright/e2e/edges.spec.ts` (16 tests). Route
`#/tests/generic/edges/general`. Fixture `edges/general.ts` is **data-only** (no
custom components): 14 nodes (incl. a subflow parent `12` with children `12-a`,
`12-b`) and 12 edges, each exercising one edge prop. Flow-prop overrides:
`fitView, multiSelectionKeyCode:'s', deleteKeyCode:'d'`.

## Tests (16)

- `selection > selecting an edge by click` — click `[data-id="edge-with-class"]`, `.selected`.
- `selection > selecting multiple edges by meta-click` — click, hold `s`, click, both `.selected`.
- `properties > classes get applied` — `[data-id="edge-with-class"]` has class `edge-class-test`. **(source gap)**
- `properties > styles get applied` — `[data-id="edge-with-style"] .react-flow__edge-path` CSS `stroke: rgb(255,0,0)`. **(source gap)**
- `properties > hidden=true hides edge` — `#hidden-edge` not visible.
- `properties > animated=true add "animated" class` — `[data-id="animated-edge"]` `.animated`.
- `properties > selectable=false prevents selecting of edges` — stays unselected.
- `properties > deleting edges is possible` — select, press `d`, detached.
- `properties > deletable=false prevents deleting of edges` — stays attached.
- `properties > zIndex sets z-index of edge svgs` — SVG of `[data-id="z-index"]` CSS `z-index: 3141592`.
- `properties > aria-lable is working` — `[data-id="aria-label"]` attr `aria-label=aria-label-test`.
- `properties > interactionWidth is working` — click 21px off `interaction-width` still selects.
- `properties > marker-start, marker-end set markers` — path has `marker-start="url('#1__type=arrowclosed')"`, `marker-end="url('#1__type=arrow')"`.
- `properties > z-index` — SVG of `edge-with-class` CSS `z-index: 0`.
- `properties > sub flow: normal node to child node, z-index` — SVG of `subflow-edge` CSS `z-index: 1`.
- `properties > sub flow: child node to child node, z-index` — SVG of `subflow-edge-2` CSS `z-index: 1`.

## Source gaps to fix (mirror ticket 060's node className/style)

- **Edge `className`** — `src/System/Types/Edge.purs` `EdgeBase` has no
  `className`; the `<g>` class in `src/React/Component/EdgeWrapper.purs`
  (`buildEdgeClassName`, ~229–249; applied ~397–405) is built from flags only,
  whereas upstream does `cc([..., edge.className])`. Add `className` to
  `EdgeBase`, render it on the `<g>`, add the slot to `baseEdge` in `Fixture.purs`.
  → unblocks `classes get applied`.
- **Edge `style`** — `EdgeBase` has no `style`, and `mkEdgeProps` hardcodes
  `style: Nothing` (`EdgeWrapper.purs` ~272). The leaf `src/React/Edge/Base.purs`
  (~39, `style: opt props.style`) already accepts a path `style`, so the bottom
  plumbing exists — thread a fixture `style` through `EdgeBase` → `mkEdgeProps`.
  → unblocks `styles get applied`.
- Model edge `style` as `Maybe (Object String)` (as node style did in 060), not
  `Foreign`, to preserve the edge's `Eq` for memoization/tests.

## Feature status — everything else exists

Selection (`AddSelectedEdges`), delete, markers, `animated`, `zIndex`,
`ariaLabel`, `interactionWidth`, subflow z-index all present in
`EdgeWrapper.purs` / `EdgeBase` (`src/System/Types/Edge.purs` lines ~34–52).
Marker id format `<rfId>__type=arrow[closed]` from `src/System/Utils/Marker.purs`
`getMarkerId` — verify the default `rfId="1"` so ids read `1__type=arrow`.
`hidden` edge returns `mempty` (`EdgeWrapper.purs` ~392) so `#hidden-edge` is
absent → `not.toBeVisible()` passes. Edge `label` is absent from `EdgeBase`, but
**no test asserts label text** — drop labels.

## Acceptance criteria

- `npm run build:smoke && npm run test:smoke -- --grep edges` → all 16 green.
- Full `npm run test:smoke` stays green.
- If the new edge `className`/`style` land on a surfaced public type, re-run
  `npm run parity:api` (Layer 0) and keep it green.

## Source files

- New: `examples/react-smoke/tests/generic-edges.spec.ts`
- Edit (fixture): `examples/react-smoke/src/Generic/{Fixture,Flow}.purs`
- Edit (source gaps): `src/System/Types/Edge.purs`, `src/React/Component/EdgeWrapper.purs`
- Reference: `xyflow/tests/playwright/e2e/edges.spec.ts`,
  `xyflow/examples/react/src/generic-tests/edges/general.ts`,
  ticket [060](060-node-classname-style-presentational-fields.md) (node className/style precedent)
