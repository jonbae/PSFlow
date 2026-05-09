# 039 — Viewport + ZoomPane

## Title
Port the `Viewport` (SVG transform container) and `ZoomPane` (d3-zoom integration) components.

## Source Files
- `xyflow-main/packages/react/src/container/Viewport/index.tsx`
- `xyflow-main/packages/react/src/container/ZoomPane/index.tsx`

## Target Modules
- `React.Container.Viewport`
- `React.Container.ZoomPane`

## Key Types / Functions

```purescript
type ViewportProps = { children :: JSX }
viewport :: Component ViewportProps

type ZoomPaneProps =
  { onPaneContextMenu :: Maybe (MouseEvent -> Effect Unit)
  , zoomOnScroll :: Boolean
  , zoomOnPinch :: Boolean
  , zoomOnDoubleClick :: Boolean
  , panOnScroll :: Boolean
  , panOnScrollSpeed :: Number
  , panOnScrollMode :: PanOnScrollMode
  , panOnDrag :: PanOnDrag
  , defaultViewport :: Viewport
  , translateExtent :: CoordinateExtent
  , minZoom :: Number
  , maxZoom :: Number
  , zoomActivationKeyCode :: Maybe KeyCode
  , preventScrolling :: Boolean
  , children :: JSX
  , noWheelClassName :: String
  , noPanClassName :: String
  , onMove :: Maybe OnMove
  , onMoveStart :: Maybe OnMoveStart
  , onMoveEnd :: Maybe OnMoveEnd
  , onViewportChange :: Maybe (Viewport -> Effect Unit)
  , isControlledViewport :: Boolean
  , paneClickDistance :: Number
  }

zoomPane :: Component ZoomPaneProps
```

## Behaviour

### Viewport

Renders a `<div>` with `transform: translate(x,y) scale(z)` reading from `state.transform`. Children render inside this transformed container — so DOM coordinates match flow coordinates.

### ZoomPane

Wraps `Viewport`. On mount:
1. Calls `XYPanZoom` (system ticket 018) to create the d3-zoom instance, passing the rendered DOM element as the d3 `selection`.
2. Stores the resulting `PanZoomInstance` in `state.panZoom` via dispatch.
3. Wires the various `on*` callbacks.
4. On unmount, calls `panZoom.destroy`.

`useViewportSync` (ticket 031) keeps the controlled-viewport prop in sync.

## Idiomatic Notes

- **`Viewport` is a thin transform container.** Pure read of `state.transform`. Pure render.
- **`ZoomPane` mounts `XYPanZoom` exactly once.** Use `useEffect` with the empty deps array (or initialise via `useMemo` and a `Ref Boolean` guard). Subsequent prop changes update via `panZoom.update`.
- **`KeyCode` activation.** `zoomActivationKeyCode` enables zoom on ctrl-pinch etc. Use `useKeyPress` (ticket 031) to monitor; when active, set a ref the zoom callback consults.
- **`isControlledViewport` flag.** When true, viewport changes are reported via `onViewportChange` but not committed to the store (the user re-controls). Match TS exactly.
- **Default viewport** comes from `init-values.ts` (ticket 042): `{ x: 0, y: 0, zoom: 1 }`.
- **Scroll modes.** `PanOnScrollMode` is `Free | Vertical | Horizontal` — already an ADT in `System.Types.PanZoom`.

## New Spago Dependencies
- None new

## Prerequisite Tickets
- 022, 024
- 027 (`useStore`, `useStoreApi`)
- 031 (`useViewportSync`, `useKeyPress`)
- System ticket 018 (`XYPanZoom`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `viewport` renders a transformed `<div>` whose `transform` matches `state.transform` reactively.
- `zoomPane` initialises a `PanZoomInstance` on mount and tears it down on unmount.
- Pan via mouse drag updates the store via the `onMove` callback chain.
- Wheel zoom updates `state.transform`.
- Controlled-viewport mode reports changes without mutating the store.
