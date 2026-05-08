# 019 — XYResizer

## Title
Port the node resize controller: XYResizer factory, resize types, and resize math utilities

## Source Files
- `xyflow-main/packages/system/src/xyresizer/XYResizer.ts`
- `xyflow-main/packages/system/src/xyresizer/utils.ts`
- `xyflow-main/packages/system/src/xyresizer/types.ts`
- `xyflow-main/packages/system/src/xyresizer/index.ts`

## Target Modules
- `XYFlow.XYResizer`
- `XYFlow.XYResizer.Utils`

## Key Types / Functions

### `XYFlow.XYResizer` (types from `types.ts`)

| TypeScript | Proposed PureScript |
|---|---|
| `type ResizeParams` | `type ResizeParams = { x :: Number, y :: Number, width :: Number, height :: Number }` |
| `type ResizeParamsWithDirection` | `type ResizeParamsWithDirection = { x :: Number, y :: Number, width :: Number, height :: Number, direction :: Array Int }` |
| `type ControlLinePosition` | `data ControlLinePosition = LineTop \| LineBottom \| LineLeft \| LineRight` |
| `type ControlPosition` | `data ControlPosition = ControlLine ControlLinePosition \| CornerTopLeft \| CornerTopRight \| CornerBottomLeft \| CornerBottomRight` |
| `enum ResizeControlVariant { Line, Handle }` | `data ResizeControlVariant = LineVariant \| HandleVariant` |
| `type ResizeControlDirection` | `data ResizeControlDirection = Horizontal \| Vertical` |
| `const XY_RESIZER_HANDLE_POSITIONS` | `xyResizerHandlePositions :: Array ControlPosition` |
| `const XY_RESIZER_LINE_POSITIONS` | `xyResizerLinePositions :: Array ControlLinePosition` |
| `type ShouldResize` | `type ShouldResize = ResizeDragEvent -> ResizeParamsWithDirection -> Effect Boolean` |
| `type OnResizeStart` | `type OnResizeStart = ResizeDragEvent -> ResizeParams -> Effect Unit` |
| `type OnResize` | `type OnResize = ResizeDragEvent -> ResizeParamsWithDirection -> Effect Unit` |
| `type OnResizeEnd` | `type OnResizeEnd = ResizeDragEvent -> ResizeParams -> Effect Unit` |
| `type ResizeDragEvent` | `newtype ResizeDragEvent = ResizeDragEvent Foreign` (opaque d3 drag event, via FFI) |

### `XYFlow.XYResizer` (controller)

| TypeScript | Proposed PureScript |
|---|---|
| `type XYResizerChange` | `type XYResizerChange = { x :: Maybe Number, y :: Maybe Number, width :: Maybe Number, height :: Maybe Number }` |
| `type XYResizerChildChange` | `type XYResizerChildChange = { id :: String, position :: XYPosition, extent :: Maybe NodeExtent }` |
| `type XYResizerInstance = { update :: XYResizerUpdateParams -> void; destroy :: () -> void }` | `type XYResizerInstance = { update :: XYResizerUpdateParams -> Effect Unit, destroy :: Effect Unit }` |
| `type XYResizerUpdateParams` | `type XYResizerUpdateParams = { controlPosition :: ControlPosition, boundaries :: ResizeBoundaries, keepAspectRatio :: Boolean, resizeDirection :: Maybe ResizeControlDirection, onResizeStart :: Maybe OnResizeStart, onResize :: Maybe OnResize, onResizeEnd :: Maybe OnResizeEnd, shouldResize :: Maybe ShouldResize }` |
| `type ResizeBoundaries` (synthesized) | `type ResizeBoundaries = { minWidth :: Number, minHeight :: Number, maxWidth :: Number, maxHeight :: Number }` |
| `type XYResizerParams` | `type XYResizerParams nodeData = { domNode :: HTMLDivElement, nodeId :: String, getStoreItems :: Effect (ResizerStoreItems nodeData), onChange :: XYResizerChange -> Array XYResizerChildChange -> Effect Unit, onEnd :: Maybe (RequiredXYResizerChange -> Effect Unit) }` |
| `type ResizerStoreItems` (synthesized) | `type ResizerStoreItems nodeData = { nodeLookup :: NodeLookup nodeData, transform :: Transform, snapGrid :: Maybe SnapGrid, snapToGrid :: Boolean, nodeOrigin :: NodeOrigin, paneDomNode :: Maybe HTMLDivElement }` |
| `type RequiredXYResizerChange` (synthesized from `Required<XYResizerChange>`) | `type RequiredXYResizerChange = { x :: Number, y :: Number, width :: Number, height :: Number }` |
| `XYResizer :: XYResizerParams -> XYResizerInstance` | `createXYResizer :: forall nodeData. XYResizerParams nodeData -> Effect XYResizerInstance` |

### `XYFlow.XYResizer.Utils`

| TypeScript | Proposed PureScript |
|---|---|
| `getResizeDirection :: (params) -> number[]` | `getResizeDirection :: { width :: Number, prevWidth :: Number, height :: Number, prevHeight :: Number, affectsX :: Boolean, affectsY :: Boolean } -> Array Int` |
| `getControlDirection :: (controlPosition) -> { isHorizontal, isVertical, affectsX, affectsY }` | `getControlDirection :: ControlPosition -> ControlDirection` |
| `getDimensionsAfterResize :: (startValues, controlDirection, pointerPosition, boundaries, keepAspectRatio, nodeOrigin, extent?, childExtent?) -> { width, height, x, y }` | `getDimensionsAfterResize :: ResizeStartValues -> ControlDirection -> PointerPosition -> ResizeBoundaries -> Boolean -> NodeOrigin -> Maybe CoordinateExtent -> Maybe CoordinateExtent -> ResizeParams` |
| `type ControlDirection` (synthesized) | `type ControlDirection = { isHorizontal :: Boolean, isVertical :: Boolean, affectsX :: Boolean, affectsY :: Boolean }` |
| `type ResizeStartValues` (synthesized) | `type ResizeStartValues = { x :: Number, y :: Number, width :: Number, height :: Number, pointerX :: Number, pointerY :: Number, aspectRatio :: Number }` |

## Idiomatic Notes

- **`createXYResizer` factory.** Like `XYDrag` and `XYPanZoom`, this creates a d3-drag instance and closes over mutable state (`prevValues`, `startValues`, `node`, `containerBounds`, `childNodes`, `parentNode`, `parentExtent`, `childExtent`, `resizeDetected`). In PS, these become `Ref` values allocated in `Effect`.
- **d3-drag dependency.** `XYResizer` also wraps d3's `drag()`. Reuse the `XYFlow.FFI.D3Drag` module introduced in ticket 016. The FFI is already warranted by `XYDrag`.
- **`ResizeDragEvent`.** The TS type is `D3DragEvent<HTMLDivElement, null, SubjectPosition>`. In PS, represent as `newtype ResizeDragEvent = ResizeDragEvent Foreign` with accessor FFI for the `sourceEvent` field.
- **`getDimensionsAfterResize`.** This is the most mathematically complex function in the codebase — 280 lines of resize constraint solving. It is pure (no DOM calls, no effects). The PS implementation should be a direct, careful translation of the constraint logic. Write thorough unit tests before considering it done.
- **`getResizeDirection` return type.** TS returns `number[]` (a 2-element direction vector). In PS, return `{ dx :: Int, dy :: Int }` with values in `{-1, 0, 1}`.
- **`ControlPosition` ADT design.** The TS type is `ControlLinePosition | 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'`. Rather than a flat 8-constructor ADT, use:
  ```purescript
  data ControlPosition
    = ControlLine ControlLinePosition
    | ControlCorner CornerPosition
  
  data CornerPosition = TopLeft | TopRight | BottomLeft | BottomRight
  ```
  This groups semantically related variants. `getControlDirection` then dispatches on the nested structure.
- **`nodeToParentExtent`, `nodeToChildExtent` (internal).** Private helpers in `XYResizer.ts`. Implement as unexported `where` bindings.
- **`initPrevValues`, `initStartValues`.** Default initial values for the resize session. In PS, use named constants:
  ```purescript
  initResizeValues :: ResizeValues
  initResizeValues = { width: 0.0, height: 0.0, x: 0.0, y: 0.0 }
  ```

## New Spago Dependencies
- `effect`
- `refs`
- `foreign` (for `ResizeDragEvent`)
- `maybe`
- `web-html` (for `HTMLDivElement`)

## Prerequisite Tickets
- 001 (Geometry)
- 004 (Node types — `NodeLookup`, `InternalNodeBase`, `NodeExtent`)
- 008 (Utils.General)
- 011 (Utils.Dom — `getPointerPosition`)
- 016 (XYDrag — reuse FFI.D3Drag)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `createXYResizer` returns `Effect XYResizerInstance`.
- `getDimensionsAfterResize` is a pure function.
- `getControlDirection` is a pure function.
- `ControlPosition` ADT covers all 8 positions (4 lines + 4 corners).
- Comprehensive unit tests for `getDimensionsAfterResize` covering: aspect ratio, min/max boundary clamping, parent extent, child extent constraints.
