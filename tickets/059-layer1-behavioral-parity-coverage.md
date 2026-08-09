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
comparators, and call `run<Group>Parity` from `test/Test/Main.purs`. Then record
the `L1` claim in `parity/census/classification.json` and regenerate the census —
its build fails an `L1` claim the oracle bundle does not back.

Every property is accompanied by a **falsification probe** — a comparison the
same machinery must report red, feeding one side a deliberately wrong input.
A green differential result on its own is equally what a comparator that
inspects nothing would produce; the probe is what makes the green mean
something. `Test.Parity.Util`'s `falsify` runs one.

## Covered (31 functions)

- **Edges** (`Test.Parity.Edges`): `getEdgeCenter`, `getBezierEdgeCenter`,
  `getStraightPath`, `getBezierPath`, `getSimpleBezierPath`, `getSmoothStepPath`,
  `addEdge`, `reconnectEdge` (ticket 039 — the resulting edges in order plus the
  refusal channel, upstream's `onError` against PSFlow's `Left`).
- **Geometry** (`Test.Parity.Geometry`): `clamp`, `getBoundsOfBoxes`, `rectToBox`,
  `boxToRect`, `getBoundsOfRects`, `getOverlappingArea`, `snapPosition`
  (full signed domain, plus a dedicated exact-half-multiple generator — ticket
  057), `clampPosition`, `pointToRendererPoint` (with and without a snap grid),
  `rendererPointToPoint`, `getViewportForBounds` (ticket 030).
- **Toolbar** (`Test.Parity.Toolbar`): `getNodeToolbarTransform`,
  `getEdgeToolbarTransform` (CSS-transform strings, tokenized compare).
- **Marker** (`Test.Parity.Marker`): `getMarkerId` (named + custom; numeric
  fields integer-valued so `Number.toString`/`${n}` agree).
- **Connections** (`Test.Parity.Connections`): `getConnectionStatus`.
- **Graph** (`Test.Parity.Graph`): `getOutgoers`, `getIncomers`,
  `getConnectedEdges` (id-set comparison over a random graph); `getNodesBounds`
  (ticket 039 — the arithmetic only, no `nodeLookup` on either side); `isNode`,
  `isEdge` (ticket 039 — all 16 key combinations, the guards' whole domain,
  exhausted rather than sampled).
- **Changes** (`Test.Parity.Changes`): `applyNodeChanges`, `applyEdgeChanges`
  (ticket 039 — exact comparison, since neither does arithmetic, and order is
  the subject).

## Deferred (Layer-1 gaps — exercised behaviorally by Layer 2)

Need richer oracle translation (node `internals` / `NodeLookup`) for modest
incremental value, since these are filter/bounds math that Layer 2's real flows
exercise end to end:

| Function | Why deferred |
|----------|--------------|
| `getNodePositionWithOrigin` | needs `getNodeDimensions` + origin shape |
| `nodeToRect` / `nodeToBox` | needs measured dims + origin |
| `getInternalNodesBounds` | needs full `InternalNodeBase` set |
| `getNodesInside` | needs internal nodes + viewport rect |

## Out of scope for Layer 1 (not pure / DOM / d3)

`getEventPosition`, `getPointerPosition`, `getDimensions`, `getHandleBounds`,
`getHostForElement`, `isInputDOMNode`, `adoptUserNodes`, `updateNodeInternals`,
`updateAbsolutePositions`, `updateConnectionLookup`, `calcAutoPan`.

## Acceptance

- `npm run build:oracle` then `spago test` is green (all `run<Group>Parity`
  blocks pass). Close a deferred row by surfacing it (and striking it here).
