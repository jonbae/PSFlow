# 054 — TS public-API symbols missing from the PS port

## Context

Ticket [049](049-react-public-api.md) wired up `src/React.purs` as the
public-API barrel mirroring
[`xyflow-main/packages/react/src/index.ts`](../xyflow-main/packages/react/src/index.ts).
Most of the TS export list maps to existing PS modules from tickets
023–048. A small number of TS symbols have **no PS equivalent yet** —
either because the porting ticket that owned them deferred the work, or
because the TS construct (e.g. a type-level overload set) doesn't have
a natural PS shape.

`src/React.purs` deliberately *omits* these symbols rather than
inline-commenting them. This ticket is the single source of truth for
what's still missing — close it when the table is empty and 049's
"API contract" checkbox can be ticked.

## Missing symbols

| TS symbol | TS source | PS owner ticket | Suggested PS module | Notes |
|-----------|-----------|-----------------|---------------------|-------|
| `SetCenter` (callback type) | [index.ts:115](../xyflow-main/packages/react/src/index.ts) | 024 (React Types) | `React.Types.Instance` | Lives inside the `ViewportHelperFunctions` record but not exposed as a standalone alias. Trivial one-line `type SetCenter = …`. |
| `SetViewport` (callback type) | [index.ts:116](../xyflow-main/packages/react/src/index.ts) | 024 | `React.Types.Instance` | Same shape concern as `SetCenter`. |
| `FitBounds` (callback type) | [index.ts:117](../xyflow-main/packages/react/src/index.ts) | 024 | `React.Types.Instance` | Same shape concern. |
| `EdgeMarkerType` *constructor parity* | [index.ts:50](../xyflow-main/packages/react/src/index.ts) | 005 | `System.Types.Edge` | The PS port uses a different discriminator — TS exports both a `type` and `enum`. Re-exporting the PS constructor is fine; an audit is needed to confirm no field difference. |
| `ConnectionInProgress` *named type* | [index.ts:110](../xyflow-main/packages/react/src/index.ts) | 003 | `System.Types.Connection` | PS calls it `ConnectionInProgressData`. Add a `type ConnectionInProgress = ConnectionInProgressData` alias so the TS name appears verbatim. |
| `NoConnection` *named type* | [index.ts:111](../xyflow-main/packages/react/src/index.ts) | 003 | `System.Types.Connection` | TS treats it as a separate type; PS uses the nullary constructor of `ConnectionState`. Decide whether to add a `type NoConnection = Unit` alias for surface parity or document the divergence. |

## Verification (per row)

When a row is closed:
- Add the symbol to the relevant `import … as ReExportSystem*` /
  `import … as ReExportReactTypes` block in `src/React.purs`.
- Rebuild: `spago build` should still be green and the symbol should
  appear in `output/React/index.js`.
- Add a one-line re-export in `index.js` (the JS shim) for any value
  symbol; type-only additions need no JS-shim change.
- Strike the row from the table above.

## Acceptance Criteria

- Table above is empty.
- `src/React.purs` exports every name listed in
  `xyflow-main/packages/react/src/index.ts` (modulo the documented
  divergences in the `React.purs` module header).
- The "API contract" checkbox in
  [tickets/049-react-public-api.md](049-react-public-api.md) is
  ticked.

## Source Files

- [tickets/049-react-public-api.md](049-react-public-api.md)
- [src/React.purs](../src/React.purs)
- [index.js](../index.js)
- [xyflow-main/packages/react/src/index.ts](../xyflow-main/packages/react/src/index.ts)
