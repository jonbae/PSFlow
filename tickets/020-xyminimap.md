# 020 — XYMinimap

## Title
Port the minimap pan/zoom controller

## Source Files
- `xyflow-main/packages/system/src/xyminimap/index.ts`

## Target Module
`XYFlow.XYMinimap`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `type XYMinimapInstance = { update :: XYMinimapUpdate -> void; destroy :: () -> void; pointer :: typeof pointer }` | `type XYMinimapInstance = { update :: XYMinimapUpdate -> Effect Unit, destroy :: Effect Unit, pointer :: Element -> Event -> Effect XYPosition }` |
| `type XYMinimapParams = { panZoom, domNode, getTransform, getViewScale }` | `type XYMinimapParams = { panZoom :: PanZoomInstance, domNode :: Element, getTransform :: Effect Transform, getViewScale :: Effect Number }` |
| `type XYMinimapUpdate` | `type XYMinimapUpdate = { translateExtent :: CoordinateExtent, width :: Number, height :: Number, inversePan :: Boolean, zoomStep :: Number, pannable :: Boolean, zoomable :: Boolean }` |
| `XYMinimap :: XYMinimapParams -> XYMinimapInstance` | `createXYMinimap :: XYMinimapParams -> Effect XYMinimapInstance` |

## Idiomatic Notes

- **`createXYMinimap` factory.** Creates a d3 selection and zoom behavior on the minimap DOM node. Returns `Effect XYMinimapInstance` because it calls `select(domNode)` (effectful d3 operation).
- **d3-zoom and d3-selection.** The minimap uses `zoom()`, `select()`, and `pointer()` from d3. Reuse the FFI modules from ticket 018 (`XYFlow.FFI.D3Zoom`, `XYFlow.FFI.D3Selection`).
- **`update` method.** Registers/re-registers zoom event handlers (`panStartHandler`, `panHandler`, `zoomHandler`) on the d3 selection. All handler closures read from `getTransform` and `getViewScale` — effectful getters. The handler functions themselves are `Effect Unit` actions.
- **`pointer` from d3-selection.** The TS `XYMinimapInstance` exposes d3's `pointer` function directly (`pointer: typeof pointer`). This function converts a DOM event to coordinates relative to a container element. In PS, wrap it:
  ```purescript
  d3Pointer :: Element -> Event -> Effect XYPosition
  ```
  as an FFI import from `d3-selection`.
- **Mutable `panStart` state.** The `panStartHandler` captures `let panStart = [0, 0]` in a closure and `panHandler` reads/writes it. In PS, allocate `Ref (Array Number)` inside `createXYMinimap` and share it between the two handlers.
- **`PanZoomInstance.scaleTo`, `setViewportConstrained`.** Both are `Aff`-returning (per ticket 006). The zoom and pan handlers must launch these `Aff` actions within an `Effect` context. Use `launchAff_` to fire-and-forget, matching the TS behavior (no await on these calls in the handlers).
- **Default parameter values.** TS uses `zoomStep = 1`, `pannable = true`, `zoomable = true`, `inversePan = false` as defaults in `update`. In PS, the caller must supply all fields, but provide a `defaultMinimapUpdate :: XYMinimapUpdate -> XYMinimapUpdate` helper or a `defaultXYMinimapUpdate :: XYMinimapUpdate` constant.

## New Spago Dependencies
- `effect`
- `refs`
- `aff` (for `launchAff_`)
- `foreign` (for opaque d3 types)
- `web-html` (for `Element`)
- `web-events` (for `Event`)

## Prerequisite Tickets
- 001 (Geometry — `Transform`, `CoordinateExtent`)
- 006 (PanZoom types — `PanZoomInstance`)
- 008 (Utils.General — `isMacOs`)
- 018 (XYPanZoom — reuse d3 FFI modules)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `createXYMinimap :: XYMinimapParams -> Effect XYMinimapInstance`.
- `update` and `destroy` are `Effect Unit`.
- `pointer` wrapper is `Element -> Event -> Effect XYPosition`.
- FFI companion `.js` exists for the `d3Pointer` import.
- No raw `Foreign` values appear in the exported API.
