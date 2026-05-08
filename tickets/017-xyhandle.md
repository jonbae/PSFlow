# 017 — XYHandle

## Title
Port the connection handle pointer-interaction controller and its validation utilities

## Source Files
- `xyflow-main/packages/system/src/xyhandle/XYHandle.ts`
- `xyflow-main/packages/system/src/xyhandle/utils.ts`
- `xyflow-main/packages/system/src/xyhandle/types.ts`
- `xyflow-main/packages/system/src/xyhandle/index.ts`

## Target Modules
- `XYFlow.XYHandle`
- `XYFlow.XYHandle.Utils`

## Key Types / Functions

### `XYFlow.XYHandle`

| TypeScript | Proposed PureScript |
|---|---|
| `type XYHandleInstance = { onPointerDown :: ...; isValid :: ... }` | `type XYHandleInstance = { onPointerDown :: (MouseEvent \| TouchEvent) -> OnPointerDownParams -> Effect Unit, isValid :: (MouseEvent \| TouchEvent) -> IsValidParams -> Effect HandleValidationResult }` |
| `type OnPointerDownParams` | `type OnPointerDownParams = { autoPanOnConnect :: Boolean, connectionMode :: ConnectionMode, connectionRadius :: Number, domNode :: Maybe HTMLDivElement, handleId :: Maybe String, nodeId :: String, isTarget :: Boolean, nodeLookup :: NodeLookup nodeData, lib :: String, flowId :: Maybe String, edgeUpdaterType :: Maybe HandleType, updateConnection :: ConnectionState nodeData -> Effect Unit, panBy :: XYPosition -> Aff Boolean, cancelConnection :: Effect Unit, onConnectStart :: Maybe OnConnectStart, onConnect :: Maybe OnConnect, onConnectEnd :: Maybe OnConnectEnd, isValidConnection :: Connection -> Boolean, onReconnectEnd :: Maybe OnReconnectEnd, getTransform :: Effect Transform, getFromHandle :: Effect (Maybe Handle), autoPanSpeed :: Maybe Number, dragThreshold :: Number, handleDomNode :: Element }` |
| `type IsValidParams` | `type IsValidParams = { handle :: Maybe HandleRef, connectionMode :: ConnectionMode, fromNodeId :: String, fromHandleId :: Maybe String, fromType :: HandleType, isValidConnection :: Connection -> Boolean, doc :: Document, lib :: String, flowId :: Maybe String, nodeLookup :: NodeLookup nodeData }` |
| `type Result` | `type HandleValidationResult = { handleDomNode :: Maybe Element, isValid :: Boolean, connection :: Maybe Connection, toHandle :: Maybe Handle }` |
| `type HandleRef` (synthesized from `Pick<Handle, 'nodeId' \| 'id' \| 'type'>`) | `type HandleRef = { nodeId :: String, id :: Maybe String, handleType :: HandleType }` |
| `XYHandle :: XYHandleInstance` | `xyHandle :: XYHandleInstance` (singleton value) |

### `XYFlow.XYHandle.Utils`

| TypeScript | Proposed PureScript |
|---|---|
| `getClosestHandle :: (position, connectionRadius, nodeLookup, fromHandle) -> Handle \| null` | `getClosestHandle :: XYPosition -> Number -> NodeLookup nodeData -> HandleRef -> Maybe Handle` |
| `getHandle :: (nodeId, handleType, handleId, nodeLookup, connectionMode, withAbsolutePosition?) -> Handle \| null` | `getHandle :: String -> HandleType -> Maybe String -> NodeLookup nodeData -> ConnectionMode -> Boolean -> Maybe Handle` |
| `getHandleType :: (edgeUpdaterType, handleDomNode) -> HandleType \| null` | `getHandleType :: Maybe HandleType -> Maybe Element -> Effect (Maybe HandleType)` |
| `isConnectionValid :: (isInsideConnectionRadius, isHandleValid) -> boolean \| null` | `isConnectionValid :: Boolean -> Boolean -> Maybe Boolean` |

## Idiomatic Notes

- **`onPointerDown` is deeply effectful.** It registers event listeners on `document`, triggers auto-pan via `requestAnimationFrame`, calls `updateConnection`, and may call `onConnect`. This entire function must be `Effect Unit`.
- **Event listener registration.** `onPointerDown` adds `mousemove`, `mouseup`, `touchmove`, `touchend` listeners to `document` (or shadow root). In PS, use `addEventListener` from `web-events`. The cleanup (removing listeners) should return an `Effect Unit` teardown function or use `Event.once`-style wrappers.
- **`requestAnimationFrame` in auto-pan loop.** Same approach as in ticket 016 (XYDrag): FFI bindings for `requestAnimationFrame` and `cancelAnimationFrame`.
- **Internal mutable state.** `onPointerDown` uses local mutable variables (`autoPanId`, `closestHandle`, `connectionStarted`, `position`, `autoPanStarted`, `connection`, `isValid`, `resultHandleDomNode`, `previousConnection`). These must become `Ref` values inside the `Effect Unit` action or be threaded via `ST` since they don't escape the function boundary. Use `ST` for the closure-local mutable cells — it keeps the mutation pure and contained.
- **`XYHandle` singleton.** TS exports `XYHandle` as a module-level object `{ onPointerDown, isValid }`. In PS this is a `xyHandle :: XYHandleInstance` value. Since `onPointerDown` is an `Effect`, the instance record holds `Effect`-typed fields.
- **`isValidHandle` (internal function).** This calls `document.querySelector(...)` and `document.elementFromPoint(...)` — DOM operations. It must be `Effect HandleValidationResult`.
- **`getHandleType`.** Reads CSS class attributes (`classList.contains('target')`, `classList.contains('source')`) on a DOM element — `Effect (Maybe HandleType)`.
- **`getHandle` (in utils).** Pure function: reads from `NodeLookup` and optionally calls `getHandlePosition`. If `withAbsolutePosition = true`, it calls `getHandlePosition` which is pure (from ticket 013). This function can be pure overall.
- **`getClosestHandle`.** Pure: only reads from `nodeLookup` and does distance arithmetic. Returns `Maybe Handle`.
- **`isConnectionValid`.** Converts two Booleans to `Maybe Boolean` — pure.
- **`panBy` in `OnPointerDownParams`.** Uses `Aff Boolean` matching the type from ticket 010.
- **`MouseEvent | TouchEvent` union in PS.** Use `Either MouseEvent TouchEvent` or wrap in a newtype `data PointerInputEvent = MouseInput MouseEvent | TouchInput TouchEvent`. Since these come from FFI, this ADT must be backed by FFI converters.

## New Spago Dependencies
- `effect`
- `refs`
- `aff`
- `either`
- `maybe`
- `web-dom` (for `Document`, `Element`)
- `web-html` (for `HTMLDivElement`)
- `web-events` (for `MouseEvent`, `TouchEvent`, `addEventListener`)
- `control` (for `ST` if using local mutable state)

## Prerequisite Tickets
- 001 (Geometry)
- 002 (Handle)
- 003 (Connection)
- 004 (Node types)
- 006 (PanZoom types)
- 008 (Utils.General)
- 011 (Utils.Dom)
- 013 (Utils.Edges.Positions — for `getHandlePosition`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `xyHandle.onPointerDown` has type `... -> Effect Unit`.
- `getClosestHandle` is a pure function.
- `isConnectionValid` is a pure function returning `Maybe Boolean`.
- `getHandle` is a pure function returning `Maybe Handle`.
- No raw DOM operations appear outside the FFI or `Effect`-typed functions.
