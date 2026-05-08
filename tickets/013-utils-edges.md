# 013 — Edge Path Utilities

## Title
Port edge path computation: straight, bezier, smooth-step, positions, markers, general edge utilities

## Source Files
- `xyflow-main/packages/system/src/utils/edges/straight-edge.ts`
- `xyflow-main/packages/system/src/utils/edges/bezier-edge.ts`
- `xyflow-main/packages/system/src/utils/edges/smoothstep-edge.ts`
- `xyflow-main/packages/system/src/utils/edges/general.ts`
- `xyflow-main/packages/system/src/utils/edges/positions.ts`
- `xyflow-main/packages/system/src/utils/edges/index.ts`
- `xyflow-main/packages/system/src/utils/marker.ts`

## Target Modules
- `XYFlow.Utils.Edges` (re-exports sub-modules)
- `XYFlow.Utils.Edges.Straight`
- `XYFlow.Utils.Edges.Bezier`
- `XYFlow.Utils.Edges.SmoothStep`
- `XYFlow.Utils.Edges.General`
- `XYFlow.Utils.Edges.Positions`
- `XYFlow.Utils.Marker`

## Key Types / Functions

### Straight Edge (`XYFlow.Utils.Edges.Straight`)

| TypeScript | Proposed PureScript |
|---|---|
| `type GetStraightPathParams` | `type StraightPathParams = { sourceX :: Number, sourceY :: Number, targetX :: Number, targetY :: Number }` |
| `getStraightPath :: (params) -> [path, labelX, labelY, offsetX, offsetY]` | `getStraightPath :: StraightPathParams -> EdgePathResult` |

### Bezier Edge (`XYFlow.Utils.Edges.Bezier`)

| TypeScript | Proposed PureScript |
|---|---|
| `type GetBezierPathParams` | `type BezierPathParams = { sourceX :: Number, sourceY :: Number, sourcePosition :: Position, targetX :: Number, targetY :: Number, targetPosition :: Position, curvature :: Number }` |
| `getBezierEdgeCenter :: ({...8 params...}) -> [cx, cy, ox, oy]` | `getBezierEdgeCenter :: BezierControlPoints -> EdgeCenter` |
| `getBezierPath :: (params) -> [path, labelX, labelY, offsetX, offsetY]` | `getBezierPath :: BezierPathParams -> EdgePathResult` |
| `type GetControlWithCurvatureParams` | Private; inlined |

### Smooth Step Edge (`XYFlow.Utils.Edges.SmoothStep`)

| TypeScript | Proposed PureScript |
|---|---|
| `interface GetSmoothStepPathParams` | `type SmoothStepPathParams = { sourceX :: Number, sourceY :: Number, sourcePosition :: Position, targetX :: Number, targetY :: Number, targetPosition :: Position, borderRadius :: Number, centerX :: Maybe Number, centerY :: Maybe Number, offset :: Number, stepPosition :: Number }` |
| `getSmoothStepPath :: (params) -> [path, labelX, labelY, offsetX, offsetY]` | `getSmoothStepPath :: SmoothStepPathParams -> EdgePathResult` |

### General Edge Utils (`XYFlow.Utils.Edges.General`)

| TypeScript | Proposed PureScript |
|---|---|
| `getEdgeCenter :: ({sourceX, sourceY, targetX, targetY}) -> [cx, cy, ox, oy]` | `getEdgeCenter :: { sourceX :: Number, sourceY :: Number, targetX :: Number, targetY :: Number } -> EdgeCenter` |
| `type GetEdgeZIndexParams` | `type GetEdgeZIndexParams = { sourceNode :: InternalNodeBase nodeData, targetNode :: InternalNodeBase nodeData, selected :: Boolean, zIndex :: Int, elevateOnSelect :: Boolean, zIndexMode :: ZIndexMode }` |
| `getElevatedEdgeZIndex :: (params) -> number` | `getElevatedEdgeZIndex :: GetEdgeZIndexParams -> Int` |
| `isEdgeVisible :: (params) -> boolean` | `isEdgeVisible :: { sourceNode :: InternalNodeBase nodeData, targetNode :: InternalNodeBase nodeData, width :: Number, height :: Number, transform :: Transform } -> Boolean` |
| `type GetEdgeId` | `type GetEdgeId = Connection -> String` |
| `getEdgeId :: (params) -> string` | `getEdgeId :: Connection -> String` |
| `addEdge :: (edgeParams, edges, options?) -> EdgeType[]` | `addEdge :: forall edgeData. EdgeBase edgeData -> Array (EdgeBase edgeData) -> GetEdgeId -> Array (EdgeBase edgeData)` |
| `reconnectEdge :: (oldEdge, newConnection, edges, options?) -> EdgeType[]` | `reconnectEdge :: forall edgeData. EdgeBase edgeData -> Connection -> Array (EdgeBase edgeData) -> Boolean -> GetEdgeId -> Array (EdgeBase edgeData)` |
| `type AddEdgeOptions` | Collapsed into explicit parameters |
| `type ReconnectEdgeOptions` | Collapsed into explicit parameters |

### Positions (`XYFlow.Utils.Edges.Positions`)

| TypeScript | Proposed PureScript |
|---|---|
| `getEdgePosition :: (params) -> EdgePosition \| null` | `getEdgePosition :: GetEdgePositionParams -> Maybe EdgePosition` |
| `getHandlePosition :: (node, handle?, fallbackPosition?, center?) -> XYPosition` | `getHandlePosition :: InternalNodeBase nodeData -> Maybe Handle -> Position -> Boolean -> XYPosition` |
| `type GetEdgePositionParams` | `type GetEdgePositionParams = { id :: String, sourceNode :: InternalNodeBase nodeData, sourceHandle :: Maybe String, targetNode :: InternalNodeBase nodeData, targetHandle :: Maybe String, connectionMode :: ConnectionMode, onError :: Maybe OnError }` |

### Marker (`XYFlow.Utils.Marker`)

| TypeScript | Proposed PureScript |
|---|---|
| `getMarkerId :: (marker?, id?) -> string` | `getMarkerId :: Maybe EdgeMarkerType -> Maybe String -> String` |
| `createMarkerIds :: (edges, {id?, defaultColor?, ...}) -> MarkerProps[]` | `createMarkerIds :: Array (EdgeBase edgeData) -> MarkerConfig -> Array MarkerProps` |
| `type MarkerConfig` (synthesized) | `type MarkerConfig = { id :: Maybe String, defaultColor :: Maybe String, defaultMarkerStart :: Maybe EdgeMarkerType, defaultMarkerEnd :: Maybe EdgeMarkerType }` |

## Idiomatic Notes

- **Tuple returns in path functions.** Every TS path function returns `[path: string, labelX, labelY, offsetX, offsetY]`. Tuples-as-unnamed-multiple-returns are an anti-pattern in PS. Use a record:
  ```purescript
  type EdgePathResult =
    { path :: String
    , labelX :: Number
    , labelY :: Number
    , offsetX :: Number
    , offsetY :: Number
    }
  ```
  Similarly, `getBezierEdgeCenter` returns `[cx, cy, ox, oy]` — use:
  ```purescript
  type EdgeCenter = { centerX :: Number, centerY :: Number, offsetX :: Number, offsetY :: Number }
  ```
- **`getBezierEdgeCenter` 8-parameter form.** The TS function takes an object with 8 fields. Create an explicit record type `BezierControlPoints` for the input.
- **`getSmoothStepPath` optional `centerX`/`centerY`.** These optional overrides become `Maybe Number` in the params record. The function computes them if absent.
- **`addEdge` / `reconnectEdge` options objects.** The TS options have two fields each. Collapse these into explicit Boolean/function parameters rather than options records, as the options are simple.
- **`addEdge` `devWarn`.** The TS function calls `devWarn('006', ...)` on invalid input and returns the original edges array. In PS, make this behavior explicit: `addEdge` returns `Either String (Array (EdgeBase edgeData))` — `Left errMsg` if source or target is empty, `Right newEdges` otherwise. Callers can `fromRight edges` to silently discard errors or handle them explicitly.
- **`getEdgePosition` returns `null`.** In PS, return `Maybe EdgePosition`.
- **`getHandlePosition` null handle.** TS accepts `null` for handle and falls back to node dimensions. In PS, accept `Maybe Handle`.
- **Private helpers** (`getControlWithCurvature`, `calculateControlOffset`, `getPoints`, `getBend`, `getDirection`, `getNodesWithinDistance`, `distance`, `toHandleBounds`, `getHandle` (positions local), `connectionExists`). All should be unexported local functions.

## New Spago Dependencies
- `either`
- `maybe`
- `ordered-collections`

## Prerequisite Tickets
- 001 (Geometry)
- 002 (Handle)
- 003 (Connection)
- 004 (Node types)
- 005 (Edge types)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- Path functions return `EdgePathResult` records (not tuples).
- `getEdgePosition` returns `Maybe EdgePosition`.
- `addEdge` returns `Either String (Array (EdgeBase edgeData))`.
- Property tests: `getStraightPath` produces the correct midpoint label position for a horizontal edge.
- `getMarkerId` produces stable, deterministic IDs for the same `EdgeMarker` input.
