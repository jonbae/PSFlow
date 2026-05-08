# 011 — DOM Utility Functions

## Title
Port DOM-touching utility functions behind an Effect layer

## Source Files
- `xyflow-main/packages/system/src/utils/dom.ts`

## Target Module
`XYFlow.Utils.Dom`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `getPointerPosition :: (event, params) -> XYPosition & { xSnapped, ySnapped }` | `getPointerPosition :: PointerEvent -> GetPointerPositionParams -> Effect PointerPosition` |
| `getDimensions :: (node: HTMLDivElement) -> Dimensions` | `getDimensions :: HTMLDivElement -> Effect Dimensions` |
| `getHostForElement :: (element) -> Document \| ShadowRoot` | `getHostForElement :: Maybe HTMLElement -> Effect (Either Document ShadowRoot)` |
| `isInputDOMNode :: (event: KeyboardEvent) -> boolean` | `isInputDOMNode :: KeyboardEvent -> Effect Boolean` |
| `isMouseEvent :: (event) -> boolean` | Not ported directly; see notes |
| `getEventPosition :: (event, bounds?) -> { x, y }` | `getEventPosition :: PointerEvent -> Maybe DOMRect -> Effect XYPosition` |
| `getHandleBounds :: (type, nodeElement, nodeBounds, zoom, nodeId) -> Handle[] \| null` | `getHandleBounds :: HandleType -> HTMLDivElement -> DOMRect -> Number -> String -> Effect (Maybe (Array Handle))` |
| `type GetPointerPositionParams` | `type GetPointerPositionParams = { transform :: Transform, snapGrid :: SnapGrid, snapToGrid :: Boolean, containerBounds :: Maybe DOMRect }` |
| `type PointerPosition` (synthesized) | `type PointerPosition = { x :: Number, y :: Number, xSnapped :: Number, ySnapped :: Number }` |

## Idiomatic Notes

- **Every function in this module is effectful.** All of them touch the DOM (`getBoundingClientRect`, `querySelectorAll`, `getAttribute`, `composedPath`, `getRootNode`). Every function must return `Effect a`, not a pure result.
- **`isMouseEvent` type guard.** TS uses `'clientX' in event` as a runtime discriminant between `MouseEvent` and `TouchEvent`. In PS, use separate FFI imports for mouse and touch events (from `web-events`). The `getEventPosition` function dispatches based on event type via the FFI. Do not try to encode this union as a PS ADT — keep the event types opaque from the web-events package.
- **`getHostForElement`.** Returns `Document | ShadowRoot`. In PS, these are different types from the web-html/web-shadow-root packages. Return `Either Document ShadowRoot`. If shadow root is not available (which is the common case), callers should handle the `Left Document` case.
- **`getHandleBounds`.** Calls `nodeElement.querySelectorAll(...)` and `getBoundingClientRect()`. The result is `Maybe (Array Handle)` — `Nothing` when no handles are found. The `Handle` values are constructed from DOM attributes (`data-handleid`, `data-handlepos`) using `getAttribute`.
- **`getPointerPosition` return type.** TS returns `XYPosition & { xSnapped, ySnapped }` — an intersection of two records. In PS, use a concrete `PointerPosition` record type.
- **FFI requirements.** This entire module requires FFI. The PS functions are thin wrappers over JS DOM APIs. Implement each as `foreign import` with a companion `.js` file. Use `EffectFn` from `effect-uncurried` for multi-argument effectful FFI calls.
- **`DOMRect`.** Use the `web-dom` / `web-html` package's `DOMRect` type or create an FFI newtype. The key fields needed are `left`, `top`, `width`, `height`.
- **`isInputDOMNode`.** Calls `composedPath()` which is available on events in shadow DOM contexts. Model as `Effect Boolean`.

## New Spago Dependencies
- `effect`
- `maybe`
- `either`
- `web-events` (for `MouseEvent`, `TouchEvent`, `KeyboardEvent`)
- `web-html` (for `HTMLElement`, `HTMLDivElement`, `Document`)
- `effect-uncurried` (for multi-arg FFI)

## Prerequisite Tickets
- 001 (Geometry — `Dimensions`, `XYPosition`)
- 002 (Handle — `Handle`, `HandleType`)
- 008 (Utils.General — `snapPosition`, `pointToRendererPoint`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- Every exported function returns `Effect a` (never a pure result).
- `getHandleBounds` returns `Effect (Maybe (Array Handle))`.
- `getPointerPosition` returns `Effect PointerPosition`.
- FFI companion `.js` files exist for each foreign import.
- No raw `Foreign` values leak into the exported API.
