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

## Covered (41 functions)

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
  (ticket 039 — the arithmetic only, no `nodeLookup` on either side);
  `getNodePositionWithOrigin`, `nodeToRect`, `nodeToBox` (Step 3 H — a user
  node over the same generators, so every dimension-fallback rung and the
  node's own origin are reached; the internal-node branch reads a
  `positionAbsolute` only a store fills); `isNode`,
  `isEdge` (ticket 039 — all 16 key combinations, the guards' whole domain,
  exhausted rather than sampled).
- **Changes** (`Test.Parity.Changes`): `applyNodeChanges`, `applyEdgeChanges`
  (ticket 039 — exact comparison, since neither does arithmetic, and order is
  the subject).
- **Adoption** (`Test.Parity.Adoption`): `adoptUserNodes` (Step 4 row 7 — two
  rounds into the same lookups, the second reusing some nodes and rebuilding
  the rest, under all three `zIndexMode`s; every internal node's position,
  `z`, `rootParentIndex` and handle bounds).
- **Handle** (`Test.Parity.Handle`): `XYHandle.isValid` (Step 4 row 7 — over a
  stand-in document and the internal nodes each side adopts, a handle larger
  than the connection radius and 400 generated drags).
- **DOM predicates** (`Test.Parity.Dom`): `isInputDOMNode`, `hasSelector`
  (Step 4 row 7 — stand-ins for every kind of event target, exhausted, a throw
  counted as an answer).
- **Selection** (`Test.React.Container.PaneSelection`): `areSetsEqual` (Step 4
  row 7 — all 256 pairs of subsets of four ids).
- **Internal nodes** (`Test.Parity.InternalNodes`): `getInternalNodesBounds`,
  `getNodesInside` (Step 4 row 9 — over the internal nodes each side adopts
  from one description, with every dimension rung, `selectable`, `dragging`,
  handle bounds or none, and positions that include `-0` and `NaN`; each
  rect member compared as `Object.is` compares it. The bounds take no filter,
  `<NodesSelection />`'s, `<MiniMap />`'s or a subset of ids. The PSFlow side
  hands `getNodesInside` the array `orderedInternalNodes` builds, under
  shuffled ids, and the ids come back compared in order. Transforms,
  `partially` and `excludeNonSelectable` are each sometimes left to
  upstream's default).

## Deferred

None. Every pure function this ticket tracked is under differential parity.

## Out of scope for Layer 1 (not pure / DOM / d3)

`getEventPosition`, `getPointerPosition`, `getDimensions`, `getHandleBounds`,
`getHostForElement`, `updateNodeInternals`, `updateAbsolutePositions`,
`updateConnectionLookup`, `calcAutoPan`.

## Acceptance

- `npm run build:oracle` then `spago test` is green (all `run<Group>Parity`
  blocks pass). Close a deferred row by surfacing it (and striking it here).
