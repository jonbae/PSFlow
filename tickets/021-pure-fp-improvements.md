# 021 — Pure-FP improvements to the PureScript port

A review of the core modules ([Geometry](../src/XYFlow/Types/Geometry.purs),
[Node](../src/XYFlow/Types/Node.purs),
[General](../src/XYFlow/Utils/General.purs),
[Store](../src/XYFlow/Utils/Store.purs),
[Graph](../src/XYFlow/Utils/Graph.purs),
[XYDrag](../src/XYFlow/XYDrag.purs),
[XYDrag/Utils](../src/XYFlow/XYDrag/Utils.purs),
[Connections](../src/XYFlow/Utils/Connections.purs),
[Edges/General](../src/XYFlow/Utils/Edges/General.purs)) surfaced the
following improvements, ranked roughly by payoff.

## High payoff — structural

### 1. Use row polymorphism instead of duplicating `NodeBase` into `InternalNodeBase`

[Node.purs:44-115](../src/XYFlow/Types/Node.purs) literally repeats every
field of `NodeBase` to add `internals`, and
[Store.purs:135-163](../src/XYFlow/Utils/Store.purs) defines `toBaseLike`
to strip `internals` back off. Replace with a single row alias:

```purescript
type NodeBaseRow n = ( id :: String, position :: XYPosition, ... )
type NodeBase n = { | NodeBaseRow n }
type InternalNodeBase n = { internals :: NodeInternals | NodeBaseRow n }
```

That kills `toBaseLike`, kills the giant record literal in
[Store.purs:391-429](../src/XYFlow/Utils/Store.purs), and makes
`getNodeDimensions` row-polymorphic by construction instead of by
hand-written constraint.

### 2. Replace the `Ref`-soup state machines with `StateT`

[XYDrag.purs:179-218](../src/XYFlow/XYDrag.purs) holds 11 `Ref` cells in
`DragState`, and the lifecycle handlers spend most of their lines doing
`Ref.read`/`Ref.write` plumbing. The mutations are sequential, not
concurrent — there's no real reason for `Ref`. A `StateT DragState
Effect` (or a final-tagless `MonadDrag m`) lets the handlers be
pure-state transitions, and the only true `Effect` boundary is the d3
callback registration. Same diagnosis applies to
[XYHandle.purs:206-212](../src/XYFlow/XYHandle.purs) (seven `Ref`s in
one closure).

### 3. Newtype the IDs

`Map String (InternalNodeBase n)`, `Map String HandleConnection`, `Map
String NodeDragItem` all key on a bare `String`. `NodeId`, `EdgeId`,
`HandleId`, `ParentId` newtypes catch the very real bug class of
"passed an edge id where a node id was wanted" — visible already in
[Store.purs:856-859](../src/XYFlow/Utils/Store.purs) where `nodeId <>
"-" <> typeStr <> "-" <> hid` mixes three string-typed identifiers.

### 4. Phantom-tag `Handle` and `HandleType`

[Handle.purs](../src/XYFlow/Types/Handle.purs) presumably has
`HandleType = Source | Target` plus a `Handle` record carrying that as
data. Promote to `Handle :: HandleType -> Type` so connection
validation in [XYHandle.purs:460-465](../src/XYFlow/XYHandle.purs) (the
`Strict` mode check) becomes a type error instead of a runtime branch.

### 5. Extract the pure cores from the `Effect`-wrapped reducers

[Store.purs:312-351](../src/XYFlow/Utils/Store.purs)
`updateAbsolutePositions` is `Ref.read`, then a pure `Foldable.foldl`,
then `Ref.write`. Same shape in
[adoptUserNodes](../src/XYFlow/Utils/Store.purs) and
[updateConnectionLookup](../src/XYFlow/Utils/Store.purs). Splitting
`updateAbsolutePositionsPure :: NodeLookup n -> ParentLookup n ->
Options -> { nodeLookup, parentLookup }` and a thin `Ref` shell makes
them QuickCheck-able directly.

## Medium payoff — algebraic structure

### 6. `Box`/`Rect`/`Dimensions`/`XYPosition` should be newtypes with `Semigroup`/`Monoid` instances

They're type synonyms today
([Geometry.purs:27-35](../src/XYFlow/Types/Geometry.purs)), so they
can't carry instances. `getBoundsOfBoxes` is exactly the `<>` of a
bounding-box monoid; the `posInf`/`negInf` initial value in
[Graph.purs:123-127](../src/XYFlow/Utils/Graph.purs) is exactly its
`mempty`. With instances you'd write `getNodesBounds = foldMap
nodeToBox` instead of the current 12-line `foldl`.

### 7. Stop boolean-blindness in pure helpers

[General.purs:213](../src/XYFlow/Utils/General.purs)
`pointToRendererPoint p t snapToGrid grid` — that `Boolean` should be
`Maybe SnapGrid`.
[General.purs:226](../src/XYFlow/Utils/General.purs) similarly for
`partially`/`excludeNonSelectable`.
[Graph.purs:199](../src/XYFlow/Utils/Graph.purs) `getNodesInside ...
partially excludeNonSelectable` is two unnamed `Bool`s in a row — call
sites are unreadable.

### 8. `getNodeDimensions` lies about totality

[General.purs:348-365](../src/XYFlow/Utils/General.purs) defaults
missing measurements to `0.0`. Downstream code in
[Graph.purs:222-237](../src/XYFlow/Utils/Graph.purs) (`visible`) then
checks `isNothing node.internals.handleBounds` to detect "actually
unmeasured" — losing-then-recovering information. Return `Maybe
Dimensions`, force the caller to handle absence.

### 9. `parseHandles` over-uses `Maybe`

[Store.purs:472-510](../src/XYFlow/Utils/Store.purs) returns `Maybe {
source :: Maybe (Array Handle), target :: Maybe (Array Handle) }` —
three nesting levels of optionality where one would do. Empty array
means "no handles"; `Nothing` at the outer level should mean "not yet
parsed". The two inner `Maybe`s collapse to arrays.

### 10. `NodeChange` could be split

[Node.purs:240-266](../src/XYFlow/Types/Node.purs) bundles
dimension/position/selection/add/remove/replace into one ADT. Selection
changes have nothing in common with dimension changes — they share no
fields and are consumed in different code paths. Smaller types per
phase + `Either`/`These` at the boundaries reads better and lets each
phase publish its own change list type.

### 11. `SetAttributesMode` is awkward

[Node.purs:212-216](../src/XYFlow/Types/Node.purs) has four
constructors where three of them are products. `Maybe { width ::
Boolean, height :: Boolean }` (with `Nothing` = "no set") collapses the
same information without the enumeration boilerplate.

### 12. `OnError` as a callback is anti-FP

[Node.purs:279](../src/XYFlow/Types/Node.purs) bakes `Effect Unit`
reporting into pure call sites like
[Graph.purs:359](../src/XYFlow/Utils/Graph.purs). Return errors as
values (`Either Error a` or `Validation Errors a`); let the caller
decide whether to log.

## Low payoff — local cleanups

### 13. Quadratic `acc <> [x]` accumulators

[Store.purs:650-657](../src/XYFlow/Utils/Store.purs) (custom
`filterMap`), [Store.purs:505](../src/XYFlow/Utils/Store.purs),
[XYDrag/Utils.purs:170](../src/XYFlow/XYDrag/Utils.purs),
[Graph.purs:489-491](../src/XYFlow/Utils/Graph.purs),
[Edges/General.purs:178](../src/XYFlow/Utils/Edges/General.purs). Each
`acc <> [x]` rebuilds the array. Use `Array.snoc` (still O(n) but
explicit), or build a `List`, or use `mapMaybe`/`filterMap` from
`Data.Array`.

### 14. Reinventing `Data.Array` helpers

- [Store.purs:650](../src/XYFlow/Utils/Store.purs) `filterMap` =
  `Data.Array.mapMaybe`.
- [General.purs:373](../src/XYFlow/Utils/General.purs) `firstJust` =
  `Data.Foldable.oneOf` (since `Maybe` has `Plus`).
- [General.purs:376](../src/XYFlow/Utils/General.purs) `hasJust` =
  `Data.Foldable.any isJust`.
- [General.purs:404](../src/XYFlow/Utils/General.purs) `areSetsEqual =
  (==)` — delete it.

### 15. `unsafeCoerce` at the d3-event boundary

[XYDrag.purs:222-226](../src/XYFlow/XYDrag.purs). `Foreign` has
`readImpl`/`Decode` machinery; even a hand-written `Foreign -> Either
ForeignError MouseEvent` is more honest than two unsafe coerces.

### 16. `roundHalfAwayFromZero` and `roundHalfAway` are duplicated

[General.purs:206](../src/XYFlow/Utils/General.purs) (PS) and
[XYDrag.purs:242](../src/XYFlow/XYDrag.purs) (FFI). Pick one.

### 17. `isParentSelected` will loop on parent-id cycles

[XYDrag/Utils.purs:41-47](../src/XYFlow/XYDrag/Utils.purs) — comment
claims cycles are "impossible by construction" but `Map` doesn't
enforce that. Either add a `Set String` of visited ids, or validate
acyclicity at adoption time and encode it in a newtype
`AcyclicNodeLookup`.

### 18. `Set.fromFoldable` rebuilt every call

[Graph.purs:92, 109, 250, 454, 457](../src/XYFlow/Utils/Graph.purs) all
build short-lived `Set String` from `map _.id ...`. `Array.elem` on
small arrays would be faster and simpler; for the hot-path bounds
computation, cache the set on the lookup.

### 19. `calculateSnapOffset` order-dependent on `Map.toUnfoldable`

[XYDrag/Utils.purs:194-206](../src/XYFlow/XYDrag/Utils.purs) picks "the
first item" via `Array.head` of the unfolded map — that's the
lowest-key item, not the user-clicked item. The TS source likely has
insertion order. Document the divergence or thread the actual click
target.

### 20. Property tests for the pure helpers are missing

[Test/Main.purs](../test/Test/Main.purs) is a hand-written assertion
list. The pure cores are textbook QuickCheck candidates:

- `clamp x lo hi ∈ [lo,hi]`
- `boxToRect ∘ rectToBox = id`
- `getBoundsOfBoxes` associative + commutative
- `oppositePosition` involutive (already asserted manually)
- `addEdge` idempotent
- `snapPosition` fixed-point on snap-aligned input

## Recommended ordering

The biggest wins are #1 (row polymorphism), #2 (StateT), #3 (id
newtypes), and #6 (monoid for Box). Those four would noticeably change
the shape of the codebase; the rest are local.
