# 033 — Built-in node components

## Title
Port the built-in node components: `DefaultNode`, `InputNode`, `OutputNode`, `GroupNode`, plus the `handleNodeClick` util used by `NodeWrapper`.

## Source Files
- `xyflow-main/packages/react/src/components/Nodes/DefaultNode.tsx`
- `xyflow-main/packages/react/src/components/Nodes/InputNode.tsx`
- `xyflow-main/packages/react/src/components/Nodes/OutputNode.tsx`
- `xyflow-main/packages/react/src/components/Nodes/GroupNode.tsx`
- `xyflow-main/packages/react/src/components/Nodes/utils.ts` (`handleNodeClick`, related helpers)

## Target Modules
- `React.Node.Default`
- `React.Node.Input`
- `React.Node.Output`
- `React.Node.Group`
- `React.Node.Util`

## Key Components / Functions

| TS | PS |
|---|---|
| `DefaultNode: React.FC<NodeProps>` | `defaultNode :: Component NodeProps` |
| `InputNode` | `inputNode :: Component NodeProps` |
| `OutputNode` | `outputNode :: Component NodeProps` |
| `GroupNode` | `groupNode :: Component NodeProps` |
| `handleNodeClick(...)` | `handleNodeClick :: HandleNodeClickArgs -> Effect Unit` |

### Component shapes

Each built-in node renders:
- `DefaultNode`: a div with `Handle` source on bottom, `Handle` target on top, `data.label` as text content.
- `InputNode`: source-only (no target handle).
- `OutputNode`: target-only.
- `GroupNode`: empty container (no handles, no label) — for grouping/parent nodes.

```purescript
type NodeProps =
  { id :: String
  , data :: Foreign     -- user-defined data; type-erased here
  , selected :: Boolean
  , type :: String
  , isConnectable :: Boolean
  , xPos :: Number
  , yPos :: Number
  , zIndex :: Number
  , dragging :: Boolean
  , targetPosition :: Maybe Position
  , sourcePosition :: Maybe Position
  , dragHandle :: Maybe String
  }

defaultNode :: Component NodeProps
```

### `handleNodeClick`

Pure dispatcher invoked by `NodeWrapper` (ticket 035). Argument record:
```purescript
type HandleNodeClickArgs =
  { id :: String
  , store :: StoreApi
  , unselect :: Boolean
  , nodeRef :: Ref (Maybe HTMLDivElement)
  }

handleNodeClick :: HandleNodeClickArgs -> Effect Unit
```

Reads `s.elementsSelectable`, `s.multiSelectionActive`, `s.elevateNodesOnSelect`, then:
- Adds the node to the selected set (single or multi).
- Optionally focuses the DOM node via `nodeRef`.
- Triggers `AddSelectedNodes` action.

## Idiomatic Notes

- **Default `Position` is `Bottom`/`Top`.** TS defaults: `targetPosition = Position.Top`, `sourcePosition = Position.Bottom`. The default-handles built-in nodes use these unless props override.
- **`Handle` is the connection-point component (ticket 034).** Built-in nodes import it. Don't define a duplicate.
- **`data.label` is `Foreign`.** The user puts whatever data they want; built-ins read `.label` via `Foreign` decoding. If decoding fails (no `label` field), render nothing.
- **No `memo` on these.** Match the TS source — internal node types are not memoised; the surrounding `NodeWrapper` handles stability.
- **`handleNodeClick` is pure-effect.** Reads from store, dispatches an action. Called inside a React event handler.
- **`builtinNodeTypes` registry.** TS exports a record `{ default: DefaultNode, input: InputNode, output: OutputNode, group: GroupNode }` from `NodeWrapper/utils.tsx`. Mirror as `React.Component.NodeWrapper.Util.builtinNodeTypes :: Object (Component NodeProps)`. Keep in `NodeWrapper`'s util module since that's where it's consumed (ticket 035).

## New Spago Dependencies
- None new beyond ticket 032

## Prerequisite Tickets
- 022 (rename)
- 024 (prop types)
- 027 (`useStoreApi` for `handleNodeClick`)
- 034 (`Handle` — but this ticket and 034 can be developed in parallel as long as there's a forward declaration; co-ordinate landing)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- All 4 built-in components plus `handleNodeClick` are exported.
- Each built-in renders the correct handle configuration:
  - `DefaultNode`: source + target.
  - `InputNode`: source only.
  - `OutputNode`: target only.
  - `GroupNode`: no handles, no label.
- `handleNodeClick` correctly toggles selection in the store under multi-select and single-select modes.
