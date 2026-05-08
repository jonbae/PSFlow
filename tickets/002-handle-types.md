# 002 — Handle Types

## Title
Port handle and connection types

## Source Files
- `xyflow-main/packages/system/src/types/handles.ts`

## Target Module
`XYFlow.Types.Handle`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `type HandleType = 'source' \| 'target'` | `data HandleType = Source \| Target` |
| `type Handle = { id?: string \| null; nodeId: string; x: number; y: number; position: Position; type: HandleType; width: number; height: number }` | `type Handle = { id :: Maybe String, nodeId :: String, x :: Number, y :: Number, position :: Position, handleType :: HandleType, width :: Number, height :: Number }` |
| `type HandleProps = { type, position, isConnectable?, isConnectableStart?, isConnectableEnd?, isValidConnection?, id? }` | `type HandleProps = { handleType :: HandleType, position :: Position, isConnectable :: Boolean, isConnectableStart :: Boolean, isConnectableEnd :: Boolean, isValidConnection :: Maybe IsValidConnection, id :: Maybe String }` |

## Idiomatic Notes

- **`HandleType` string union.** TS `'source' | 'target'` becomes `data HandleType = Source | Target`. Derive `Eq`, `Show`.
- **`Handle.id?: string | null`.** Both optional (`?`) and explicitly nullable (`null`) collapse to `Maybe String` in PS. The distinction between "not provided" and "provided as null" does not carry semantic weight here — the TS code treats both as absent.
- **`HandleProps.isConnectable`, etc.** Optional boolean fields with a documented default of `true` should be collapsed to non-optional `Boolean` fields at the PS type level, with a `defaultHandleProps` record for construction. Consumers should pass the full props record; the default record handles the `?` ergonomics.
- **`isValidConnection?: IsValidConnection`.** This becomes `Maybe IsValidConnection` where `IsValidConnection` is ported in ticket 003. The callback itself has type `EdgeBase | Connection -> Boolean`, which will be an `Effect`-free pure function.
- **Field name `type` conflicts with a PS keyword.** Rename to `handleType` throughout. Document this divergence from the TS API.

## New Spago Dependencies
- `maybe` (for `Maybe String`)

## Prerequisite Tickets
- 001 (for `Position`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `Handle` record can be constructed and pattern-matched.
- `HandleType` derives `Eq` and `Show`.
- The word `type` does not appear as a record field label in any exported PS type.
