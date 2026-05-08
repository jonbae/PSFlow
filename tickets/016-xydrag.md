# 016 — XYDrag

## Title
Port the node drag controller: XYDrag factory function and drag utilities

## Source Files
- `xyflow-main/packages/system/src/xydrag/XYDrag.ts`
- `xyflow-main/packages/system/src/xydrag/utils.ts`
- `xyflow-main/packages/system/src/xydrag/index.ts`

## Target Module
`XYFlow.XYDrag`
`XYFlow.XYDrag.Utils`

## Key Types / Functions

### `XYFlow.XYDrag`

| TypeScript | Proposed PureScript |
|---|---|
| `type XYDragInstance = { update :: DragUpdateParams -> void; destroy :: () -> void }` | `type XYDragInstance = { update :: DragUpdateParams -> Effect Unit, destroy :: Effect Unit }` |
| `type DragUpdateParams = { noDragClassName?, handleSelector?, isSelectable?, nodeId?, domNode, nodeClickDistance? }` | `type DragUpdateParams = { noDragClassName :: Maybe String, handleSelector :: Maybe String, isSelectable :: Boolean, nodeId :: Maybe String, domNode :: Element, nodeClickDistance :: Number }` |
| `type StoreItems` (internal) | `type DragStoreItems nodeData = { nodes :: Array (NodeBase nodeData), nodeLookup :: NodeLookup nodeData, edges :: Array (EdgeBase edgeData), ... }` |
| `type XYDragParams` | `type XYDragParams nodeData = { getStoreItems :: Effect (DragStoreItems nodeData), onDragStart :: Maybe OnDrag, onDrag :: Maybe OnDrag, onDragStop :: Maybe OnDrag, onNodeMouseDown :: Maybe (String -> Effect Unit) }` |
| `type OnDrag` | `type OnDrag nodeData = MouseEvent -> Map String NodeDragItem -> NodeBase nodeData -> Array (NodeBase nodeData) -> Effect Unit` |
| `XYDrag :: XYDragParams -> XYDragInstance` | `createXYDrag :: forall nodeData edgeData. XYDragParams nodeData edgeData -> Effect XYDragInstance` |

### `XYFlow.XYDrag.Utils`

| TypeScript | Proposed PureScript |
|---|---|
| `isParentSelected :: (node, nodeLookup) -> boolean` | `isParentSelected :: forall nodeData. NodeBase nodeData -> NodeLookup nodeData -> Boolean` |
| `hasSelector :: (target, selector, domNode) -> boolean` | `hasSelector :: Element -> String -> Element -> Effect Boolean` |
| `getDragItems :: (nodeLookup, nodesDraggable, mousePos, nodeId?) -> Map<string, NodeDragItem>` | `getDragItems :: forall nodeData. NodeLookup nodeData -> Boolean -> XYPosition -> Maybe String -> Map String NodeDragItem` |
| `getEventHandlerParams :: ({nodeId?, dragItems, nodeLookup, dragging?}) -> [NodeBase, NodeBase[]]` | `getEventHandlerParams :: forall nodeData. Maybe String -> Map String NodeDragItem -> NodeLookup nodeData -> Boolean -> { currentNode :: NodeBase nodeData, allNodes :: Array (NodeBase nodeData) }` |
| `calculateSnapOffset :: ({dragItems, snapGrid, x, y}) -> XYPosition \| null` | `calculateSnapOffset :: Map String NodeDragItem -> SnapGrid -> Number -> Number -> Maybe XYPosition` |

## Idiomatic Notes

- **`XYDrag` as a factory function returning a mutable controller.** The TS function captures mutable state in a closure (`lastPos`, `autoPanId`, `dragItems`, etc.) and returns an object with `update` and `destroy` methods that mutate this state. In PS, model this as `createXYDrag :: ... -> Effect XYDragInstance`. The constructor returns `Effect XYDragInstance` because creating the controller allocates the internal `Ref` state cells.
- **Internal mutable state.** The TS closure variables (`lastPos`, `autoPanId`, `dragItems`, `autoPanStarted`, `mousePosition`, `containerBounds`, `dragStarted`, `d3Selection`, `abortDrag`, `nodePositionsChanged`, `dragEvent`) become `Ref` values inside the `Effect XYDragInstance` constructor body.
- **`requestAnimationFrame` for `autoPan`.** The `autoPan` function inside XYDrag uses `requestAnimationFrame` / `cancelAnimationFrame`. These are browser APIs. Wrap them via FFI:
  ```purescript
  foreign import requestAnimationFrame :: Effect Unit -> Effect Int
  foreign import cancelAnimationFrame :: Int -> Effect Unit
  ```
  The recursive `autoPan` loop becomes a recursive `Effect` function that reads from `Ref`s.
- **d3-drag dependency.** The TS implementation wraps d3's `drag()` behavior. In PS, this must be done via FFI. Create a thin FFI module `XYFlow.FFI.D3Drag` that wraps the d3 `drag` creation, event registration, and filter functions. The PS side sees only opaque FFI handles.
- **`DragUpdateParams.domNode :: Element`.** This is an HTML DOM element. Import `Element` from `web-dom` or `web-html`.
- **`StoreItems` / `getStoreItems`.** The TS drag instance reads from the framework store via `getStoreItems()` — a thunk that returns current state. In PS, the equivalent is `Effect DragStoreItems` — a getter that reads from `Ref`s held by the store.
- **`isParentSelected`.** This is a recursive function (walks the parent chain). It is pure since it only reads from `NodeLookup`. In PS it can be written as a recursive function over `Maybe String` (the `parentId` chain).
- **`hasSelector`.** Calls `element.matches(selector)` and `element.parentElement` — DOM operations, so `Effect Boolean`.
- **`getDragItems` return type.** TS returns `Map<string, NodeDragItem>`. PS returns `Map String NodeDragItem` (immutable). The function is pure since it only reads from `nodeLookup`.
- **`getEventHandlerParams` return type.** TS returns a 2-tuple `[NodeBase, NodeBase[]]`. In PS return a named record `{ currentNode, allNodes }`.
- **`calculateSnapOffset`.** TS returns `null` when `dragItems` is empty. PS returns `Maybe XYPosition`.
- **`OnDrag` callback type.** The TS signature mixes `Map<string, NodeDragItem>` with `NodeBase` and `NodeBase[]`. In PS, be explicit that the drag map and the current-node/all-nodes are computed from it.

## New Spago Dependencies
- `effect`
- `refs`
- `maybe`
- `ordered-collections`
- `aff` (for async panBy calls inside autoPan)
- `web-dom` (for `Element`)
- `web-html` (for `HTMLDivElement`)
- `web-events` (for `MouseEvent`)

## Prerequisite Tickets
- 001 (Geometry)
- 004 (Node types — `NodeDragItem`, `NodeLookup`)
- 005 (Edge types)
- 008 (Utils.General — `calcAutoPan`, `snapPosition`)
- 011 (Utils.Dom — `getPointerPosition`, `getEventPosition`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `createXYDrag` returns `Effect XYDragInstance`.
- `XYDragInstance` has `{ update :: DragUpdateParams -> Effect Unit, destroy :: Effect Unit }`.
- `isParentSelected` is a pure function.
- `getDragItems` is a pure function.
- `calculateSnapOffset` returns `Maybe XYPosition`.
- FFI companion files exist for d3-drag wrapper and requestAnimationFrame.
