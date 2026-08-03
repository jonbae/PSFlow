# 070 — TypeScript declaration surface (`.d.ts`)

## Context

PSFlow ships no `.d.ts`. `index.js` re-exports the compiled PureScript under
TS-identical PascalCase names, but a TypeScript consumer importing `ps-flow` gets
`any` for every symbol. Since rich types are a large part of `@xyflow/react`'s
value, a TS shop cannot treat PSFlow as a drop-in without them. This is the
largest remaining item for literal drop-in consumption; it is purely additive
(no PS source change) and partially generatable from artifacts we already have.

## Leverage

Layer 0 already **guarantees the export-name set matches upstream by
construction** (`npm run parity:api` → 0 missing), and the extractor emits the
full upstream type inventory: `parity/layer0-api/upstream.json` holds all 142
type exports + prop members, pulled via the TS compiler API from the vendored
`@xyflow/react` 12.11.0 / `@xyflow/system` 0.0.77.

So the surface splits cleanly:

- **Structurally identical (majority)** — re-export upstream's own published
  `.d.ts` types under the PSFlow export names. Names line up because Layer 0
  enforces it.
- **PS-idiom divergences (~35 rows, the allowlist in
  `parity/layer0-api/allowlist.json`)** — hand-author these; a blind copy of
  upstream's `.d.ts` would **over-promise**. Key cases:
  - `NodeChange` / `EdgeChange` are single ADTs in PS, not N standalone change
    types (`NodeAddChange`, `EdgeRemoveChange`, …). Model as a discriminated
    union; do not export the phantom per-constructor types as structural types.
  - `ConnectionState` / `NoConnection` — nullary constructor, not a standalone
    type.
  - `Maybe T` optional record fields → `T | undefined` (or optional members).
  - Renames: `ControlsProps`←`ControlProps`, `EdgeTypesMap`←`EdgeTypes`,
    `NodeTypesMap`←`NodeTypes`.

## Approach (proposed)

1. Add a `types/ps-flow.d.ts`, point `package.json#types` at it.
2. Generate the identical-surface rows from `upstream.json` (re-export or inline).
3. Hand-author the allowlisted divergent rows.
4. Extend `parity:api` (or add a `parity:types` step) with a `tsc --noEmit`
   type-check of a fixture that imports the public surface, so the `.d.ts` cannot
   silently drift from `index.js`.

Depends on [069](069-nodeprops-prop-member-gap.md): author `NodeProps` in the
`.d.ts` only after its record gap is closed, or the declaration will encode the
wrong shape.

## Acceptance Criteria

- A TS fixture importing every symbol from `ps-flow` type-checks under
  `tsc --noEmit` with no `any`-fallback for the public surface.
- The divergent ~35 rows are modelled faithfully (ADT unions, `NoConnection`,
  renames) — not copied verbatim from upstream.
- A parity step fails if a `.d.ts` export drifts from the `index.js` value
  surface.

## Source Files

- [index.js](../index.js) — the value surface the `.d.ts` must mirror
- [parity/layer0-api/upstream.json] — extracted upstream type inventory (generated)
- [parity/layer0-api/allowlist.json](../parity/layer0-api/allowlist.json) — the
  divergent rows to hand-author
- [src/React.purs](../src/React.purs) — PS-side type re-export barrel / divergence
  header
- [069](069-nodeprops-prop-member-gap.md) — prerequisite for the `NodeProps` decl
