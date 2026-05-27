# 055 — Decide the fate of unused `EdgeId` and `HandleId` newtypes

## Context

Ticket [050 #1](050-pure-fp-followups.md) called for four id newtypes:
`NodeId`, `EdgeId`, `HandleId`, `ParentId`. The implementation pass
(Phase 4 of the 050 follow-up) created all four in
[`src/System/Types/Ids.purs`](../src/System/Types/Ids.purs) but only
propagated `NodeId` and `ParentId` through the codebase. `EdgeId` and
`HandleId` are currently **defined but unused** — dead newtypes that
no value in the system has the type of.

This ticket weighs whether to:

- **A.** Propagate `EdgeId` and `HandleId` through the codebase (the
  original 050 #1 scope), or
- **B.** Delete them from `Ids.purs`, leaving only `NodeId` and
  `ParentId`.

## What the partial flip already buys us

The headline benefit of 050 #1 — preventing "wrong kind of id passed
to wrong lookup" — is **already secured by `NodeId` alone**.

After Phase 4:

- `NodeLookup :: Map NodeId _`, `ParentLookup :: Map ParentId (Map NodeId _)`.
- `EdgeBase.source / .target :: NodeId`,
  `Handle.nodeId :: NodeId`,
  `Connection.source / .target :: NodeId`.
- All node-id action payloads and lookup signatures carry `NodeId`.

So:

- `Map.lookup edge.source nodeLookup` typechecks (both `NodeId`).
- `Map.lookup edge.id nodeLookup` does **not** typecheck (edge.id is
  String, lookup key is NodeId) — the bug class is closed.
- Mixing an edge id with a node id at any function boundary is a
  compile-time error today, even though `EdgeId` is bare `String`.

The only ambiguity left is *within* the String space — e.g.,
accidentally swapping two String-typed fields that are *both* edge
ids, or confusing `edge.id` with `Handle.id` or a CSS-class string.
That class of bug is small and not what the original ticket framed as
the motivation.

## Pros of deleting `EdgeId` and `HandleId` (option B)

### Carrying cost

- They're currently exported from `System.Types.Ids` but referenced
  nowhere. Dead symbols are a maintenance smell — every reader has to
  ask "why are these here, am I supposed to use them?"

### Avoided downstream cost if we keep them

If we keep them around as future scaffolding, every new feature that
touches edges or handles has to decide whether to wrap with the
newtype or not — and the inconsistency between "EdgeId is a real
newtype but not used yet" and "actually flip it later" creates
churn. Choosing one direction now is cheaper.

### Public-API noise

`EdgeProps` and `NodeProps` (React-layer user-facing prop types)
already need `unwrap` at the boundary for `NodeId`. Adding
`unwrap edge.id` and `unwrap (Just <$> handle.id)` to those boundary
sites for very little compile-time gain is friction the user will
notice.

### Test fixture cost

Every test that constructs an edge would gain `EdgeId "e1"` wrapping.
Every test that constructs a handle with an id would gain
`HandleId "out"`. ~15 fixture sites across `test/Test/Main.purs`,
`test/Test/System/Utils/Store.purs`,
`test/Test/React/Store/Reduce.purs`, etc.

### The "wrong kind of String" risk is already mitigated

If you mistype `edge.id` as `handle.id` or vice versa, the rest of
the surrounding code shape almost always catches it (different
record types, different functions take them). The newtype catches a
narrower set of confusions than NodeId did, where the underlying
risk was real `Map String _` ambiguity.

## Pros of propagating `EdgeId` and `HandleId` (option A)

### Symmetric, principled type story

"Every identifier kind in the domain has its own newtype" is
defensible as a design principle. `NodeId`/`ParentId` already exist;
having `EdgeId`/`HandleId` keeps the family complete. A reader who
knows about `NodeId` will reach for `EdgeId` instinctively.

### Catches a small class of bugs `NodeId` doesn't

- Passing an edge id to a function that wants a node id of a *parent
  edge* (hypothetical — not in the codebase today).
- Mixing `Handle.id` with `Edge.sourceHandle` (both `Maybe String`).
  These fields are conceptually different roles even though both are
  String — the newtype would make swapping them a type error.
- A future `EdgeLookup` indexed differently from today would benefit
  from typed keys.

### Documents intent

Reading `edgeId :: EdgeId` answers "what kind of id is this?"
without needing to look at the field name or surrounding context.
With `String` you have to read the variable name.

### Cheaper now than later

Propagating `EdgeId` after the React surface has grown is more
expensive than doing it while the cascade is fresh. If we're going
to do it at all, the cost-curve favours doing it now.

### Tests already touch most edge fixtures

The 050 #1 Phase 4 cascade already touched every node fixture in
the test suite. Adding `EdgeId` wrapping to the same fixtures is
incremental, not net-new.

## Estimated cost of option A

Based on the Phase 4 NodeId cascade as a calibration:

| Item | Estimate |
|---|---|
| `EdgeBase.id`, `EdgeChange` payload ids, `EdgeLookup` key flip | 10–15 files |
| `EdgeProps.id` boundary unwrap (React-layer) | 1 file |
| Public `getEdge` / `updateEdge` / `deleteElements` boundary wraps | 1–2 files (`React.Hook.ReactFlow`) |
| Test fixtures (`mkEdge`, `sampleEdge`, `freshEdge`) | 4–5 files |
| `Handle.id` / `NodeHandle.id` to `Maybe HandleId` | 5–10 files |
| `EdgeBase.sourceHandle` / `.targetHandle` to `Maybe HandleId` | 3–5 files |
| Composite-key string-concat unwraps (`addConnectionToLookup` site) | 1 file |

Roughly **20–30 files**, ~half the size of the NodeId cascade.

## Estimated cost of option B

Delete the two `newtype` blocks and their derived instances from
[`src/System/Types/Ids.purs`](../src/System/Types/Ids.purs). Remove
them from the export list. No other file changes (they're unused).

**1 file**, ~20 lines.

## Recommendation

**Option B (delete) is the right default** unless you have a concrete
case in mind where `EdgeId`-vs-`String` or `HandleId`-vs-`String`
confusion has caused (or is likely to cause) a real bug. The 80% of
the type-safety value came from `NodeId`; the marginal 5–10% from
`EdgeId`/`HandleId` is not worth the ~20–30 file cascade and the
permanent boundary-unwrap noise in user-facing React prop types.

If you ever later add a function or feature where mixing edge ids
with arbitrary strings (logging keys, DOM data attributes, CSS class
strings) becomes a real risk, **adding `EdgeId` then** is no harder
than adding it now — the change is fully mechanical and the cascade
is the same size whether done today or in six months.

## Acceptance criteria (option B)

- `src/System/Types/Ids.purs` no longer defines `EdgeId` or
  `HandleId`. Export list updated.
- `spago build` passes with zero warnings.
- Grep for `EdgeId` / `HandleId` across the repo returns zero hits
  (modulo this ticket, ticket 050, and any commit-message references).

## Acceptance criteria (option A)

- `EdgeBase.id :: EdgeId`, `EdgeChange` payload `id` fields `:: EdgeId`,
  `EdgeLookup :: Map EdgeId _`.
- `Handle.id :: Maybe HandleId`, `NodeHandle.id :: Maybe HandleId`,
  `EdgeBase.sourceHandle / .targetHandle :: Maybe HandleId`.
- Composite-key concatenation sites in
  [`System/Utils/Store.purs`](../src/System/Utils/Store.purs)
  unwrap `HandleId` at the string boundary.
- React-layer `EdgeProps.id` / `EdgeProps.sourceHandleId` /
  `.targetHandleId` unwrap at the boundary (keep `String` for
  consumer-facing prop types).
- Test fixtures use `EdgeId "..."` / `HandleId "..."` constructors.
- `spago build` clean, `spago test` green.

## Prerequisite tickets

- 050 (Phase 4 — `NodeId`/`ParentId` propagation must be in place
  first; this ticket is the optional fourth quadrant).
