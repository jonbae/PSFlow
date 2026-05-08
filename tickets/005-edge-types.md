# 005 — Edge Types

## Title
Port edge data structures: EdgeBase, markers, path options, edge changes

## Source Files
- `xyflow-main/packages/system/src/types/edges.ts`
- `xyflow-main/packages/system/src/types/changes.ts` (edge-change portion)

## Target Module
`XYFlow.Types.Edge`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `type EdgeBase<EdgeData, EdgeType>` | `type EdgeBase edgeData = { id :: String, edgeType :: Maybe String, source :: String, target :: String, sourceHandle :: Maybe String, targetHandle :: Maybe String, animated :: Boolean, hidden :: Boolean, deletable :: Maybe Boolean, selectable :: Maybe Boolean, data :: Maybe edgeData, selected :: Boolean, markerStart :: Maybe EdgeMarkerType, markerEnd :: Maybe EdgeMarkerType, zIndex :: Maybe Int, ariaLabel :: Maybe String, interactionWidth :: Maybe Number }` |
| `enum ConnectionLineType { Bezier, Straight, Step, SmoothStep, SimpleBezier }` | `data ConnectionLineType = BezierLine \| StraightLine \| StepLine \| SmoothStepLine \| SimpleBezierLine` |
| `enum MarkerType { Arrow, ArrowClosed }` | `data MarkerType = Arrow \| ArrowClosed` |
| `type EdgeMarker = { type, color?, width?, height?, markerUnits?, orient?, strokeWidth? }` | `type EdgeMarker = { markerType :: MarkerType, color :: Maybe String, width :: Maybe Number, height :: Maybe Number, markerUnits :: Maybe String, orient :: Maybe String, strokeWidth :: Maybe Number }` |
| `type EdgeMarkerType = string \| EdgeMarker` | `data EdgeMarkerType = NamedMarker String \| CustomMarker EdgeMarker` |
| `type MarkerProps = EdgeMarker & { id: string }` | `type MarkerProps = { id :: String, markerType :: MarkerType, color :: Maybe String, width :: Maybe Number, height :: Maybe Number, markerUnits :: Maybe String, orient :: Maybe String, strokeWidth :: Maybe Number }` |
| `type EdgePosition = { sourceX, sourceY, targetX, targetY, sourcePosition, targetPosition }` | `type EdgePosition = { sourceX :: Number, sourceY :: Number, targetX :: Number, targetY :: Number, sourcePosition :: Position, targetPosition :: Position }` |
| `type EdgeLookup edgeData` | `type EdgeLookup edgeData = Map String (EdgeBase edgeData)` |
| `type SmoothStepPathOptions` | `type SmoothStepPathOptions = { offset :: Maybe Number, borderRadius :: Maybe Number, stepPosition :: Maybe Number }` |
| `type StepPathOptions` | `type StepPathOptions = { offset :: Maybe Number }` |
| `type BezierPathOptions` | `type BezierPathOptions = { curvature :: Maybe Number }` |
| `type EdgeToolbarBaseProps` | `type EdgeToolbarBaseProps = { x :: Number, y :: Number, isVisible :: Boolean, alignX :: AlignX, alignY :: AlignY }` |
| `type AlignX = 'left' \| 'center' \| 'right'` | `data AlignX = AlignXLeft \| AlignXCenter \| AlignXRight` |
| `type AlignY = 'top' \| 'center' \| 'bottom'` | `data AlignY = AlignYTop \| AlignYCenter \| AlignYBottom` |
| **Change types:** | |
| `type EdgeChange<EdgeType>` | `data EdgeChange edgeData = EdgeSelectionChange { id :: String, selected :: Boolean } \| EdgeRemoveChange { id :: String } \| EdgeAddChange { item :: EdgeBase edgeData, index :: Maybe Int } \| EdgeReplaceChange { id :: String, item :: EdgeBase edgeData }` |

## Idiomatic Notes

- **`EdgeBase.type` field.** Renamed to `edgeType` to avoid PS keyword clash; document the divergence.
- **`EdgeMarker.type` field.** Renamed to `markerType`.
- **`EdgeMarkerType = string | EdgeMarker`.** This is an untagged union used as a marker reference. Model as `data EdgeMarkerType = NamedMarker String | CustomMarker EdgeMarker`. The `NamedMarker` case corresponds to built-in marker references; `CustomMarker` carries the full configuration object.
- **`EdgeBase.deletable?`, `selectable?`, `animated?`, `hidden?`, `selected?`.** Apply the same tri-state rule as nodes: booleans that can be absent (meaning "inherit default") remain `Maybe Boolean`. Only `animated`, `hidden`, and `selected` have clear default values of `false` and can be plain `Boolean`. `deletable` and `selectable` must stay `Maybe Boolean`.
- **`EdgeChange` union.** TS reuses `NodeSelectionChange` and `NodeRemoveChange` for edges. In PS, duplicate the constructors inside `EdgeChange edgeData` rather than sharing — the structural sharing is a TS DRY trick that fights PS's nominal sum types.
- **`DefaultEdgeOptionsBase`.** This is `Omit<EdgeType, ...>` used in framework-specific layers only. Do not port it in this ticket; it is a React-layer concern.
- **`AlignX`, `AlignY`.** The TS file uses inline string literals. Extract them as separate ADTs shared between `EdgeToolbarBaseProps` and later toolbar utility functions.

## New Spago Dependencies
- `maybe`
- `ordered-collections`

## Prerequisite Tickets
- 001 (Geometry — for `Position`)
- 003 (Connection — for reference)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `EdgeChange edgeData` is exhaustively matchable on all four constructors.
- `EdgeMarkerType` covers both string-reference and object cases.
- `MarkerType` and `ConnectionLineType` derive `Eq`, `Show`, `Bounded`, `Enum`.
- `EdgeLookup edgeData` is exported as a type alias.
