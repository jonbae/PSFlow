# 015 — Shallow Node Data Equality

## Title
Port shallow node data equality check

## Source Files
- `xyflow-main/packages/system/src/utils/shallow-node-data.ts`

## Target Module
`XYFlow.Utils.ShallowNodeData`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `shallowNodeData :: (a, b) -> boolean` | `shallowNodeData :: forall nodeData. Eq nodeData => Array (NodeSummary nodeData) -> Array (NodeSummary nodeData) -> Boolean` |
| `type NodeData = Pick<NodeBase, 'id' \| 'type' \| 'data'>` | `type NodeSummary nodeData = { id :: String, nodeType :: Maybe String, data :: nodeData }` |

## Idiomatic Notes

- **`Object.is` reference equality for `data`.** The TS implementation checks `Object.is(_a[i].data, _b[i].data)` — reference (pointer) identity, not structural equality. This optimization exists because React re-renders are triggered by reference changes. PS has no reference equality. Use structural equality (`==`) via the `Eq` constraint instead. This changes the semantics slightly — it will return `true` for structurally identical objects that are different references. This is the correct PS-idiomatic behavior and is semantically stronger (fewer spurious false results). Document this divergence.
- **Null handling.** TS accepts `NodeData | NodeData[] | null`. In PS, use `Maybe (Array (NodeSummary nodeData))` — the `null` case becomes `Nothing`.
- **Single vs array.** TS accepts either a single `NodeData` or an array. In PS, require an `Array` always. Provide a convenience wrapper `shallowNodeDataSingle :: NodeSummary nodeData -> NodeSummary nodeData -> Boolean` for the single-node comparison case.
- **The function is pure** — no effects.

## New Spago Dependencies
- `maybe`

## Prerequisite Tickets
- 004 (Node types — for `NodeBase` shape reference)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `shallowNodeData` is a pure function with an `Eq nodeData` constraint.
- Tests verify: empty arrays return `true`, arrays of different lengths return `false`, arrays with matching data return `true`, arrays with differing data return `false`.
