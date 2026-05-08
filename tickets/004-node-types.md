# 004 — Node Types

## Title
Port node data structures: NodeBase, InternalNodeBase, NodeDragItem, NodeProps, change types

## Source Files
- `xyflow-main/packages/system/src/types/nodes.ts`
- `xyflow-main/packages/system/src/types/changes.ts` (node-change portion)

## Target Module
`XYFlow.Types.Node`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `type NodeBase<NodeData, NodeType>` | `type NodeBase nodeData = { id :: String, position :: XYPosition, data :: nodeData, sourcePosition :: Maybe Position, targetPosition :: Maybe Position, hidden :: Boolean, selected :: Boolean, dragging :: Boolean, draggable :: Maybe Boolean, selectable :: Maybe Boolean, connectable :: Maybe Boolean, deletable :: Maybe Boolean, dragHandle :: Maybe String, width :: Maybe Number, height :: Maybe Number, initialWidth :: Maybe Number, initialHeight :: Maybe Number, parentId :: Maybe String, zIndex :: Maybe Int, extent :: Maybe NodeExtent, expandParent :: Boolean, ariaLabel :: Maybe String, origin :: Maybe NodeOrigin, handles :: Maybe (Array NodeHandle), measured :: { width :: Maybe Number, height :: Maybe Number }, nodeType :: Maybe String }` |
| `type InternalNodeBase<NodeType>` | `type InternalNodeBase nodeData = { id :: String, ...(all NodeBase fields), internals :: NodeInternals }` |
| `type NodeInternals` (synthesized from `InternalNodeBase`) | `type NodeInternals = { positionAbsolute :: XYPosition, z :: Number, rootParentIndex :: Maybe Int, handleBounds :: Maybe NodeHandleBounds, bounds :: Maybe NodeBounds }` |
| `type NodeHandleBounds = { source: Handle[] \| null; target: Handle[] \| null }` | `type NodeHandleBounds = { source :: Maybe (Array Handle), target :: Maybe (Array Handle) }` |
| `type NodeBounds = XYPosition & { width: number \| null; height: number \| null }` | `type NodeBounds = { x :: Number, y :: Number, width :: Maybe Number, height :: Maybe Number }` |
| `type NodeDragItem` | `type NodeDragItem = { id :: String, position :: XYPosition, distance :: XYPosition, measured :: { width :: Number, height :: Number }, internals :: { positionAbsolute :: XYPosition }, extent :: Maybe NodeExtent, parentId :: Maybe String, origin :: Maybe NodeOrigin, expandParent :: Boolean, dragging :: Boolean }` |
| `type NodeProps<NodeType>` | `type NodeProps nodeData = { id :: String, data :: nodeData, width :: Maybe Number, height :: Maybe Number, sourcePosition :: Maybe Position, targetPosition :: Maybe Position, dragHandle :: Maybe String, parentId :: Maybe String, nodeType :: String, dragging :: Boolean, zIndex :: Int, selectable :: Boolean, deletable :: Boolean, selected :: Boolean, draggable :: Boolean, isConnectable :: Boolean, positionAbsoluteX :: Number, positionAbsoluteY :: Number }` |
| `type NodeHandle = Omit<Optional<Handle, 'width' \| 'height'>, 'nodeId'>` | `type NodeHandle = { id :: Maybe String, x :: Number, y :: Number, position :: Position, handleType :: HandleType, width :: Maybe Number, height :: Maybe Number }` |
| `type NodeOrigin = [number, number]` | Defined in ticket 001; re-exported here |
| `type NodeExtent = 'parent' \| CoordinateExtent \| null` | `data NodeExtent = ParentExtent \| CoordExtent CoordinateExtent` |
| `type NodeLookup nodeData` | `type NodeLookup nodeData = Map String (InternalNodeBase nodeData)` |
| `type ParentLookup nodeData` | `type ParentLookup nodeData = Map String (Map String (InternalNodeBase nodeData))` |
| `type Align = 'center' \| 'start' \| 'end'` | `data Align = AlignCenter \| AlignStart \| AlignEnd` |
| **Change types:** | |
| `type NodeDimensionChange` | `data NodeChange nodeData = NodeDimensionChange { id :: String, dimensions :: Maybe Dimensions, resizing :: Boolean, setAttributes :: SetAttributesMode } \| NodePositionChange { id :: String, position :: Maybe XYPosition, positionAbsolute :: Maybe XYPosition, dragging :: Boolean } \| NodeSelectionChange { id :: String, selected :: Boolean } \| NodeRemoveChange { id :: String } \| NodeAddChange { item :: NodeBase nodeData, index :: Maybe Int } \| NodeReplaceChange { id :: String, item :: NodeBase nodeData }` |
| `type SetAttributesMode = boolean \| 'width' \| 'height'` | `data SetAttributesMode = SetBoth \| SetWidth \| SetHeight \| NoSetAttributes` |

## Idiomatic Notes

- **`NodeBase` generic.** TS `NodeBase<NodeData, NodeType>` has two type parameters: a `data` payload and a node `type` tag string. In PS, the type tag is represented as `Maybe String` in the record (not a phantom type) — keeping it at the value level is appropriate because node types are user-defined runtime strings, not compile-time-checked constructors.
- **Conditional type in `NodeBase`.** The TS definition uses a conditional type `undefined extends NodeType ? { type?: string } : { type: string }` to make the `type` field required when the type param is concrete. PS does not need this complexity; `nodeType :: Maybe String` covers both cases honestly.
- **`InternalNodeBase` extends `NodeBase`.** In PS, the internal node is a flat record (not an extension) to avoid row-polymorphism complexity. The `internals` sub-record holds the extra data. When displaying, PS functions that expect a `NodeBase`-shaped record can use row polymorphism: `forall r. { id :: String, position :: XYPosition | r } -> ...`.
- **`NodeExtent = 'parent' | CoordinateExtent | null`.** This is a tagged union — in PS: `data NodeExtent = ParentExtent | CoordExtent CoordinateExtent`. The `null` case is represented by `Maybe NodeExtent` at the field level.
- **`NodeChange` discriminated union.** Six change types with different payloads. Port as a single `data NodeChange nodeData` with six constructors. The `type` string field disappears — the constructor IS the tag.
- **`SetAttributes` field.** TS type `boolean | 'width' | 'height'` is a 4-value type; use `data SetAttributesMode = SetBothDimensions | SetWidthOnly | SetHeightOnly | NoSetAttributes` to make intent explicit.
- **Optional boolean node flags** (`draggable?`, `selectable?`, `connectable?`, `deletable?`). These tri-state values (true / false / unset/inherit) must be `Maybe Boolean`. Do NOT collapse to `Boolean` — the "unset" state means "inherit from the store default."
- **`userNode` backpointer** in `NodeInternals`. This is a reference-equality optimization in the TS code. In PS there is no reference equality. Omit `userNode` from `NodeInternals`; functions that need the original user node should accept it as a separate parameter.

## New Spago Dependencies
- `maybe`
- `ordered-collections`

## Prerequisite Tickets
- 001 (Geometry)
- 002 (Handle)
- 003 (Connection)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `NodeChange nodeData` matches exhaustively on all six constructors.
- `NodeExtent` ADT is exported with `ParentExtent` and `CoordExtent` constructors.
- `InternalNodeBase nodeData` is a concrete record type (not a type alias to a union or open row).
- `NodeLookup` and `ParentLookup` are exported as type aliases.
