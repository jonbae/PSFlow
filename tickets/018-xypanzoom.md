# 018 — XYPanZoom

## Title
Port the d3-backed pan/zoom controller: XYPanZoom factory, event handlers, and filter

## Source Files
- `xyflow-main/packages/system/src/xypanzoom/XYPanZoom.ts`
- `xyflow-main/packages/system/src/xypanzoom/eventhandler.ts`
- `xyflow-main/packages/system/src/xypanzoom/filter.ts`
- `xyflow-main/packages/system/src/xypanzoom/utils.ts`
- `xyflow-main/packages/system/src/xypanzoom/index.ts`

## Target Modules
- `XYFlow.XYPanZoom`
- `XYFlow.XYPanZoom.EventHandler`
- `XYFlow.XYPanZoom.Filter`
- `XYFlow.XYPanZoom.Utils`

## Key Types / Functions

### `XYFlow.XYPanZoom`

| TypeScript | Proposed PureScript |
|---|---|
| `type ZoomPanValues` (internal mutable state) | Internal `Ref` bundle — not exported |
| `XYPanZoom :: PanZoomParams -> PanZoomInstance` | `createXYPanZoom :: PanZoomParams -> Effect PanZoomInstance` |

### `XYFlow.XYPanZoom.Utils`

| TypeScript | Proposed PureScript |
|---|---|
| `transformToViewport :: (transform: ZoomTransform) -> Viewport` | `transformToViewport :: ZoomTransform -> Viewport` (pure, via FFI) |
| `viewportToTransform :: (viewport: Viewport) -> ZoomTransform` | `viewportToTransform :: Viewport -> ZoomTransform` (pure, via FFI) |
| `isWrappedWithClass :: (event, className?) -> boolean` | `isWrappedWithClass :: Event -> Maybe String -> Effect Boolean` |
| `isRightClickPan :: (panOnDrag, usedButton) -> boolean` | `isRightClickPan :: PanOnDrag -> Int -> Boolean` |
| `getD3Transition :: (selection, duration?, ease?, onEnd?) -> D3SelectionOrTransition` | `getD3Transition :: D3Selection -> Maybe Int -> Maybe (Number -> Number) -> Effect Unit -> Effect D3SelectionOrTransition` |
| `wheelDelta :: (event) -> number` | `wheelDelta :: WheelEvent -> Effect Number` |

### `XYFlow.XYPanZoom.EventHandler`

| TypeScript | Proposed PureScript |
|---|---|
| `createPanOnScrollHandler :: (params) -> EventHandler` | `createPanOnScrollHandler :: PanOnScrollParams -> Effect WheelEventHandler` |
| `createZoomOnScrollHandler :: (params) -> EventHandler` | `createZoomOnScrollHandler :: ZoomOnScrollParams -> Effect WheelEventHandler` |
| `createPanZoomStartHandler :: (params) -> D3ZoomEventHandler` | `createPanZoomStartHandler :: PanZoomStartHandlerParams -> Effect D3ZoomEventHandler` |
| `createPanZoomHandler :: (params) -> D3ZoomEventHandler` | `createPanZoomHandler :: PanZoomHandlerParams -> Effect D3ZoomEventHandler` |
| `createPanZoomEndHandler :: (params) -> D3ZoomEventHandler` | `createPanZoomEndHandler :: PanZoomEndHandlerParams -> Effect D3ZoomEventHandler` |

### `XYFlow.XYPanZoom.Filter`

| TypeScript | Proposed PureScript |
|---|---|
| `createFilter :: (params: FilterParams) -> (event: any) -> boolean` | `createFilter :: FilterParams -> Event -> Effect Boolean` |
| `type FilterParams` | `type FilterParams = { zoomActivationKeyPressed :: Boolean, zoomOnScroll :: Boolean, zoomOnPinch :: Boolean, panOnDrag :: PanOnDrag, panOnScroll :: Boolean, zoomOnDoubleClick :: Boolean, userSelectionActive :: Boolean, noWheelClassName :: String, noPanClassName :: String, lib :: String, connectionInProgress :: Boolean }` |

## Idiomatic Notes

- **Heavy d3 dependency.** `XYPanZoom` is fundamentally a wrapper around `d3-zoom`. It creates `d3ZoomInstance`, `d3Selection`, calls `d3ZoomInstance.filter(...)`, `d3ZoomInstance.on('zoom', ...)`, etc. Almost all of this must go through FFI.
- **FFI strategy.** Create `XYFlow.FFI.D3Zoom` and `XYFlow.FFI.D3Selection` modules. Expose the minimum d3 surface needed:
  - `zoomCreate :: Effect D3ZoomBehavior`
  - `scaleExtent :: D3ZoomBehavior -> Number -> Number -> Effect Unit`
  - `translateExtent :: D3ZoomBehavior -> CoordinateExtent -> Effect Unit`
  - `selectElement :: Element -> Effect D3Selection`
  - `callZoom :: D3Selection -> D3ZoomBehavior -> Effect Unit`
  - `onZoom :: D3ZoomBehavior -> String -> D3ZoomEventHandler -> Effect Unit`
  - `scaleTo :: D3ZoomBehavior -> D3Selection -> Number -> Effect Unit`
  - `scaleBy :: D3ZoomBehavior -> D3Selection -> Number -> Effect Unit`
  - `translateBy :: D3ZoomBehavior -> D3Selection -> Number -> Number -> Effect Unit`
  - `constrain :: D3ZoomBehavior -> ZoomTransform -> CoordinateExtent -> CoordinateExtent -> ZoomTransform`
  - `transform :: D3ZoomBehavior -> D3Selection -> ZoomTransform -> Effect Unit`
  - `currentZoomTransform :: Element -> Effect ZoomTransform`
  - `zoomIdentity :: ZoomTransform`
  - `zoomTranslate :: ZoomTransform -> Number -> Number -> ZoomTransform`
  - `zoomScale :: ZoomTransform -> Number -> ZoomTransform`

- **`ZoomPanValues` mutable state.** In TS this is a plain mutable object. In PS, wrap in a single `Ref ZoomPanValues` or use individual `Ref`s for each field. The former is cleaner.
- **`createXYPanZoom` factory.** Returns `Effect PanZoomInstance` because it reads `getBoundingClientRect()` on initialization and calls d3 selection APIs.
- **`setTransform` internal.** Calls `d3ZoomInstance.interpolate(...).transform(getD3Transition(...), transform)`. The interpolate and transition calls involve d3 internals and `Promise`-based animation callbacks. Model as `Aff Boolean` in PS using `makeAff` or `launchAff` to bridge the promise-based d3 animation with PS's `Aff`.
- **`syncViewport`.** Modifies d3's internal `__zoom` property directly via a d3 `transform` call with special metadata `{ sync: true }`. This is an implementation detail — expose as `Effect Unit`.
- **Event handler creators.** Functions like `createPanOnScrollHandler` return event handler callbacks (`(event) => void`). In PS, they return `Effect EventHandler` where `EventHandler = Event -> Effect Unit`. The `Effect` wrapping of the creator is needed because the handlers close over `Ref`-based mutable state (`zoomPanValues`).
- **`setTimeout` usage.** `createPanZoomEndHandler` uses `clearTimeout` and `setTimeout`. Wrap via FFI:
  ```purescript
  foreign import setTimeout :: Effect Unit -> Int -> Effect TimeoutId
  foreign import clearTimeout :: TimeoutId -> Effect Unit
  ```
- **`isWrappedWithClass`.** Calls `event.target.closest(...)` — DOM operation, `Effect Boolean`.
- **`wheelDelta`.** Reads `event.deltaY`, `event.deltaMode`, `event.ctrlKey`. All these are available from `WheelEvent` via the `web-events` package. The function body also calls `isMacOs` (which is `Effect Boolean`). So `wheelDelta :: WheelEvent -> Effect Number`.
- **`transformToViewport`, `viewportToTransform`.** These convert between d3's `ZoomTransform` (x, y, k) and our `Viewport` (x, y, zoom). Implement via FFI accessors on the opaque `ZoomTransform` type. Pure functions.
- **`PanOnScrollParams`, `ZoomOnScrollParams`, etc.** These are the params records for the handler creators. Many fields are `Ref`-based mutable state or d3 opaque types. Port them as concrete record types in the module, keeping `ZoomPanValues` as a `Ref` reference.

## New Spago Dependencies
- `effect`
- `refs`
- `aff`
- `foreign` (for opaque d3 types)
- `web-events` (for `WheelEvent`, `MouseEvent`, `TouchEvent`)
- `web-html` (for `Element`)
- `effect-uncurried` (for multi-arg FFI)

## Prerequisite Tickets
- 001 (Geometry)
- 003 (Connection — `Viewport`, `PanOnScrollMode`)
- 006 (PanZoom types — `PanZoomInstance`, `PanZoomParams`)
- 008 (Utils.General — `isMacOs`, `clamp`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `createXYPanZoom :: PanZoomParams -> Effect PanZoomInstance`.
- All five event handler creators return `Effect <handler type>`.
- `createFilter :: FilterParams -> Event -> Effect Boolean`.
- `transformToViewport` and `viewportToTransform` are pure (backed by FFI accessors, no side effects).
- FFI companion `.js` files exist for all d3 wrappers.
- Manual smoke test: creating an `XYPanZoom` instance and calling `update` should not throw at the JS level.
