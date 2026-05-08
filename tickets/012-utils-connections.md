# 012 — Connection Utility Functions

## Title
Port connection map comparison and status utilities

## Source Files
- `xyflow-main/packages/system/src/utils/connections.ts`

## Target Module
`XYFlow.Utils.Connections`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `areConnectionMapsEqual :: (a?, b?) -> boolean` | `areConnectionMapsEqual :: Maybe (Map String HandleConnection) -> Maybe (Map String HandleConnection) -> Boolean` |
| `handleConnectionChange :: (a, b, cb?) -> void` | `handleConnectionChange :: Map String HandleConnection -> Map String HandleConnection -> Maybe (Array HandleConnection -> Effect Unit) -> Effect Unit` |
| `getConnectionStatus :: (isValid: boolean \| null) -> string \| null` | `getConnectionStatus :: Maybe Boolean -> Maybe ConnectionStatus` |
| `type ConnectionStatus` (synthesized) | `data ConnectionStatus = ValidConnection \| InvalidConnection` |

## Idiomatic Notes

- **`areConnectionMapsEqual`.** TS takes optional parameters (`a?`, `b?`). In PS, wrap in `Maybe`. The function is pure since it only reads the maps.
- **`handleConnectionChange`.** The TS version calls `cb` with the diff if the callback is provided. In PS, the callback is `Maybe (Array HandleConnection -> Effect Unit)`. The function returns `Effect Unit` because of the callback. If the callback is `Nothing`, the function is a no-op.
- **`getConnectionStatus`.** TS returns `null | 'valid' | 'invalid'`. In PS, `null` becomes `Nothing`, and the two string values become a `data ConnectionStatus = ValidConnection | InvalidConnection`. Return `Maybe ConnectionStatus`.
- **Map comparison.** The TS implementation checks `a.size !== b.size` and iterates keys. In PS, use `Data.Map.keys` and `Data.Set.subset` to implement this cleanly. The natural PS idiom: `Map.keys a == Map.keys b` (after converting to sets) plus equality of values at each key. Since `areConnectionMapsEqual` only checks key presence (not values), use `Map.keys a == Map.keys b`.
- **Diff computation.** `handleConnectionChange` computes the set difference `a.keys \ b.keys` and returns connections from `a` that are not in `b`. Use `Map.difference` or `Map.filterWithKey`.

## New Spago Dependencies
- `maybe`
- `ordered-collections`
- `effect`

## Prerequisite Tickets
- 003 (Connection types — `HandleConnection`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `areConnectionMapsEqual` is a pure function.
- `handleConnectionChange` returns `Effect Unit`.
- `getConnectionStatus` is total and returns `Maybe ConnectionStatus`.
- `ConnectionStatus` derives `Eq`, `Show`.
