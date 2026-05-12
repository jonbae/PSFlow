# 050 — Pure-FP follow-ups deferred from ticket 021

Ticket [021](021-pure-fp-improvements.md) listed 20 improvements. The
implementation pass landed most of them across these commits on `master`
and on the per-unit worktree branches:

- `354d510` — #4 (Handle phantom-typed wrappers)
- `f1d2846` — #13/#15/#16/#17/#19 (XYDrag small items)
- `8801a63` — #6 foundation (BoundingBox newtype)
- `f379f82` — #6 consumer / #7 / #9 / #13 (Store + Graph)
- `c36773f` — #1 (row polymorphism) and #11 (SetAttributesMode → Maybe)
- worktree-only: Unit 4 (General utils #7/#8/#13/#14/#16), Unit 7 (XYHandle
  StateT #2-Handle), Unit 8 (Edges #13), Unit 9 (#20 QuickCheck)

The items below were deliberately not landed in that pass — each is a
single coherent cascade that's better done as its own change.

## High payoff

### 1. Newtype IDs (021 #3)

[Store.purs:856-859](../src/XYFlow/Utils/Store.purs) still concatenates
`nodeId <> "-" <> typeStr <> "-" <> hid` over bare `String`. Every
`Map String _` keyed on a node id, edge id, handle id, or parent id is
also a bare `String` — so the type system can't distinguish "wrong-shape
id passed here".

```purescript
newtype NodeId   = NodeId String
newtype EdgeId   = EdgeId String
newtype HandleId = HandleId String
newtype ParentId = ParentId String
```

Derive `Eq`/`Ord`/`Show`/`Newtype` for all four. Then propagate:

- `NodeBase.id :: NodeId`, `NodeBase.parentId :: Maybe ParentId`,
  `EdgeBase.id :: EdgeId`, `Handle.nodeId :: NodeId`, `Handle.id :: Maybe HandleId`.
- `NodeLookup nodeData :: Map NodeId (InternalNodeBase nodeData)`,
  `ParentLookup` similarly.
- `unwrap` at the string-concat sites in `Store.purs` and the `gh` data-id
  selector in `XYHandle.purs:485-495`.

The cascade touches every `Map.lookup`, every `e.source` / `e.target`
comparison, and every test fixture. Worth it for catching the mixed-id
class of bugs at compile time.

### 2. Split `NodeChange` (021 #10)

[Node.purs:225-251](../src/XYFlow/Types/Node.purs) still bundles
dimension/position/selection/add/remove/replace into one ADT. Selection
changes have nothing in common with dimension changes, and the consumers
in [Store.purs](../src/XYFlow/Utils/Store.purs) `applyNodeChanges`-style
reducers branch on the constructor anyway.

Replace with per-phase types:

```purescript
data NodeDimensionChange  = NodeDimensionChange { id :: NodeId, dimensions :: Maybe Dimensions, resizing :: Boolean, setAttributes :: SetAttributesMode }
data NodePositionChange   = NodePositionChange { id :: NodeId, position :: Maybe XYPosition, positionAbsolute :: Maybe XYPosition, dragging :: Boolean }
data NodeSelectionChange  = NodeSelectionChange { id :: NodeId, selected :: Boolean }
data NodeStructuralChange n
  = NodeRemove { id :: NodeId }
  | NodeAdd { item :: NodeBase n, index :: Maybe Int }
  | NodeReplace { id :: NodeId, item :: NodeBase n }
```

Each phase publishes its own change-list type; reducers that handle a
specific phase take that phase's type and can't be passed the wrong
shape. The pattern-match exhaustiveness check becomes meaningful instead
of "must handle six cases that are unrelated".

`EdgeChange` deserves the same treatment.

### 3. OnError as values (021 #12)

[Graph.purs:359](../src/XYFlow/Utils/Graph.purs) `calculateNodePosition`
currently takes `onError :: Maybe OnError` (a `String -> String -> Effect
Unit` callback). The function is otherwise pure but bakes `Effect`
reporting into its API.

Define a `NodeError` ADT (constructors covering the cases enumerated in
[Constants.purs](../src/XYFlow/Constants.purs) `errorMessages`) and have
`calculateNodePosition` return `Either NodeError { position,
positionAbsolute }`. Callers (`XYDrag.purs`, `XYResizer/Utils.purs`,
`XYPanZoom/EventHandler.purs`) decide whether to log via `OnError` at
their own boundary.

`OnError` itself can stay as a callback alias — but pure paths shouldn't
take one as a parameter.

## Medium payoff

### 4. Extract pure cores from store reducers (021 #5)

[Store.purs:312-351](../src/XYFlow/Utils/Store.purs)
`updateAbsolutePositions`, `adoptUserNodes`, and `updateConnectionLookup`
each have the shape `Ref.read → pure fold → Ref.write`. Split each into
two:

```purescript
updateAbsolutePositionsPure
  :: NodeLookup n -> ParentLookup n -> UpdateNodesOptions n
  -> { nodeLookup :: NodeLookup n, parentLookup :: ParentLookup n }

updateAbsolutePositions
  :: Ref (NodeLookup n) -> Ref (ParentLookup n) -> UpdateNodesOptions n
  -> Effect Unit
updateAbsolutePositions nlR plR opts = do
  nl <- Ref.read nlR
  pl <- Ref.read plR
  let r = updateAbsolutePositionsPure nl pl opts
  Ref.write r.nodeLookup nlR
  Ref.write r.parentLookup plR
```

The `*Pure` half is QuickCheck-able directly (round-trip properties,
idempotence on already-clamped positions, etc.); the `Effect` shell stays
the boundary.

### 5. XYDrag StateT migration (021 #2 — Drag half)

[XYDrag.purs:179-218](../src/XYFlow/XYDrag.purs) still holds 11 `Ref`
cells in `DragState`. The XYHandle StateT migration is already done on
worktree branch `worktree-agent-a99cadfa2a914c533` (commit `b6282e6`) —
follow the same shape: collapse `DragState` to a plain record, lift the
six lifecycle handlers (`onStart`, `onDragHandler`, `onEnd`, `startDrag`,
`autoPan`, `updateNodes`) to `StateT DragState Effect`, wrap at the d3
callback boundary with a single outer `Ref DragState` and `runOnRef`.

The public exports (`createXYDrag`, `XYDragInstance`,
`XYDragParams`/`DragUpdateParams`) don't change.

### 6. Thread phantom-typed handles through `NodeHandleBounds` and edges (021 #4 follow-up)

`SourceHandle`/`TargetHandle` newtypes are exported from
[Handle.purs](../src/XYFlow/Types/Handle.purs) but only used at the
strict-mode validation site. The full benefit lands when:

- `NodeHandleBounds = { source :: Array SourceHandle, target :: Array TargetHandle }`
- `parseHandles` and `toHandleBounds` produce typed arrays.
- `Edges/Positions.purs:getEdgePosition` takes typed source/target lists.
- `XYHandle/Utils.purs:getHandle` returns typed handles by side.

Then the runtime `hType == Source` checks in `XYHandle.purs:460-465` and
the value-level dispatch in [XYHandle/Utils.purs:155-157](../src/XYFlow/XYHandle/Utils.purs)
become impossible to call with the wrong side.

### 7. Eliminate the 26-field record literal in `adoptUserNodes`

[Store.purs:367-404](../src/XYFlow/Utils/Store.purs) (post-row-poly) still
spells out every `NodeBaseRow` field by hand to construct an
`InternalNodeBase` from a `userNodeWithDefaults` plus `internals`. There's
no in-language shorthand without `Record.union` from
[`purescript-record`](https://pursuit.purescript.org/packages/purescript-record).

Add `record` to `spago.yaml` dependencies, then:

```purescript
internalNode = Record.union userNodeWithDefaults { internals: ... }
```

## Low payoff / no action

### 8. `Set.fromFoldable` caching (021 #18) — non-issue

The five sites named in 021 #18 (`Graph.purs:92, 109, 250, 454, 457`)
build the `Set` **once per call**, not per loop iteration. The original
ticket's "rebuilt every call" framing was a misreading of "rebuilt per
function invocation" as if it were per-iteration. No action needed unless
profiling shows hot-path cost.

## Recommended ordering

1. **#1 newtype IDs** first — every other follow-up benefits from typed
   ids (the split-NodeChange constructors, the typed-handle propagation,
   the pure-core signatures).
2. **#2 split NodeChange** — depends on #1 for `NodeId` in payloads.
3. **#3 OnError as values** — independent; can land any time.
4. **#4 pure cores** — depends on the final `NodeChange` shape.
5. **#5 XYDrag StateT** — independent; unblocks parity-grade QuickCheck
   on the drag handlers.
6. **#6 typed handles end-to-end** — independent of the others.
7. **#7 record-union spread** — purely cosmetic; do last (or skip).
