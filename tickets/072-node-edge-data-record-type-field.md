# 072 — Realign `Node.nodeType` / `Edge.edgeType` with upstream's `type`

## Context

The `Node` and `Edge` *data* records call upstream's `type` field `nodeType` /
`edgeType`:

- `src/System/Types/Node.purs` — `NodeBaseRow.nodeType`
- `src/System/Types/Edge.purs` — `EdgeBase.edgeType`

Until [071](071-version-drift-audit-12-3-to-12-11.md) both files justified this
with a false claim: that `type` is a PureScript keyword and therefore unusable
as a record label. It is not. `src/React/Types/Nodes.purs` has declared
`type :: String` on `NodeProps` all along, and 071 §5 added `type :: Maybe String`
to `EdgeProps` for the same reason. Those comments now state the real rationale —
internal consistency with the `nodeTypes` / `edgeTypes` lookup maps the field
indexes into — and point here.

So the *props* records (the JS-facing component boundary) now match upstream
exactly, while the *data* records still diverge. That asymmetry is deliberate and
currently harmless, but it is the last place where a PSFlow field name silently
differs from the object shape that actually crosses into JS.

## Why this is not a rename

A blind rename would be wrong. These records are the PureScript-facing API that
user code constructs, and `nodeType` / `edgeType` read better in PureScript than
a bare `type` next to `nodeTypes`. The point is not to give up the PS-facing
name; it is to stop that name leaking into the JS-facing object.

The intended shape is a **marshalling layer**: PureScript-facing names stay
`nodeType` / `edgeType`, and the JS-facing objects say `type`. This pairs
naturally with [070](070-typescript-declaration-surface.md), which has to
describe the JS-facing shape anyway to emit `.d.ts` — the two want the same
single source of truth for "what does this field look like on each side".

## Scope

- A conversion boundary for `NodeBase` / `EdgeBase` mirroring what
  `mkNodeProps` / `mkEdgeProps` already do for the props records.
- Every site that builds a node/edge object destined for JS, including
  `placeholderEdge` (`src/React/Component/EdgeWrapper.purs`), which currently
  keeps `edgeType` correctly *because* it is a data record.
- Pair with 070 so the `.d.ts` surface and the marshalling layer agree.

## Acceptance criteria

- The JS-facing node/edge objects carry `type`; PureScript-facing records keep
  `nodeType` / `edgeType`.
- The rationale comments in `System/Types/Node.purs` and `System/Types/Edge.purs`
  are updated to describe the marshalling boundary rather than pointing here.
- `npm run parity:api`, `spago test` and `npm run test:smoke` stay green.

## Source files

- `src/System/Types/Node.purs`, `src/System/Types/Edge.purs`
- `src/React/Types/Nodes.purs`, `src/React/Types/Edges.purs` (the already-aligned
  props records — the model to follow)
- [070](070-typescript-declaration-surface.md) — pair with this
- [071](071-version-drift-audit-12-3-to-12-11.md) §5 — the `EdgeProps` precedent
