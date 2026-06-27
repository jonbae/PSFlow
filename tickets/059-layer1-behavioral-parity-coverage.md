# 059 — Layer 1 behavioral-parity coverage

## Context

Layer 1 (`oracle/` + `test/Test/Parity/`) runs the same input through PSFlow and
the vendored upstream JS ("oracle", `@psflow/oracle`) and asserts the results
match within epsilon. This ticket tracks which pure functions are under live
differential parity and which remain deferred.

Mechanism (per function): add the symbol to the `entry` list in
`oracle/esbuild.mjs` (then `npm run build:oracle`), add a `…Impl` foreign import +
typed wrapper in `test/Test/Oracle.purs`/`.js`, add a QuickCheck property in a
`test/Test/Parity/<Group>.purs` module using the `test/Test/Parity/Util.purs`
comparators, and call `run<Group>Parity` from `test/Test/Main.purs`.

## Covered (23 functions)

- **Edges** (`Test.Parity.Edges`): `getEdgeCenter`, `getBezierEdgeCenter`,
  `getStraightPath`, `getBezierPath`, `getSimpleBezierPath`, `getSmoothStepPath`.
- **Geometry** (`Test.Parity.Geometry`): `clamp`, `getBoundsOfBoxes`, `rectToBox`,
  `boxToRect`, `getBoundsOfRects`, `getOverlappingArea`, `snapPosition`
  (non-negative domain — ticket 057), `clampPosition`, `pointToRendererPoint`
  (no snap), `rendererPointToPoint`.
- **Toolbar** (`Test.Parity.Toolbar`): `getNodeToolbarTransform`,
  `getEdgeToolbarTransform` (CSS-transform strings, tokenized compare).
- **Marker** (`Test.Parity.Marker`): `getMarkerId` (named + custom; numeric
  fields integer-valued so `Number.toString`/`${n}` agree).
- **Connections** (`Test.Parity.Connections`): `getConnectionStatus`.
- **Graph traversal** (`Test.Parity.Graph`): `getOutgoers`, `getIncomers`,
  `getConnectedEdges` (id-set comparison over a random graph).

## Deferred (Layer-1 gaps — exercised behaviorally by Layer 2)

Need richer oracle translation (node dimensions / origin / `internals` /
`NodeLookup`) for modest incremental value, since these are filter/bounds math
that Layer 2's real flows exercise end to end:

| Function | Why deferred |
|----------|--------------|
| `getNodePositionWithOrigin` | needs `getNodeDimensions` + origin shape |
| `nodeToRect` / `nodeToBox` | needs measured dims + origin |
| `getNodesBounds` | needs node dims + optional `NodeLookup` translation |
| `getInternalNodesBounds` | needs full `InternalNodeBase` set |
| `getNodesInside` | needs internal nodes + viewport rect |
| `getViewportForBounds` | needs bounds + viewport/zoom math + clamping |

## Out of scope for Layer 1 (not pure / DOM / d3)

`getEventPosition`, `getPointerPosition`, `getDimensions`, `getHandleBounds`,
`getHostForElement`, `isInputDOMNode`, `adoptUserNodes`, `updateNodeInternals`,
`updateAbsolutePositions`, `updateConnectionLookup`, `calcAutoPan`.

## Acceptance

- `npm run build:oracle` then `spago test` is green (all `run<Group>Parity`
  blocks pass). Close a deferred row by surfacing it (and striking it here).
