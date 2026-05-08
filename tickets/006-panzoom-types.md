# 006 — PanZoom Interface Types

## Title
Port PanZoomInstance and related parameter types (the abstract interface, not the d3 implementation)

## Source Files
- `xyflow-main/packages/system/src/types/panzoom.ts`

## Target Module
`XYFlow.Types.PanZoom`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `type PanZoomParams` | `type PanZoomParams = { domNode :: Element, minZoom :: Number, maxZoom :: Number, viewport :: Viewport, translateExtent :: CoordinateExtent, onDraggingChange :: Boolean -> Effect Unit, onPanZoomStart :: Maybe OnPanZoom, onPanZoom :: Maybe OnPanZoom, onPanZoomEnd :: Maybe OnPanZoom }` |
| `type PanZoomTransformOptions` | `type PanZoomTransformOptions = { duration :: Maybe Int, ease :: Maybe (Number -> Number), interpolate :: Maybe InterpolateMode }` |
| `type PanZoomUpdateOptions` | `type PanZoomUpdateOptions = { noWheelClassName :: String, noPanClassName :: String, onPaneContextMenu :: Maybe (Effect Unit), preventScrolling :: Boolean, panOnScroll :: Boolean, panOnDrag :: PanOnDrag, panOnScrollMode :: PanOnScrollMode, panOnScrollSpeed :: Number, userSelectionActive :: Boolean, zoomOnPinch :: Boolean, zoomOnScroll :: Boolean, zoomOnDoubleClick :: Boolean, zoomActivationKeyPressed :: Boolean, lib :: String, onTransformChange :: Transform -> Effect Unit, connectionInProgress :: Boolean, paneClickDistance :: Number, selectionOnDrag :: Boolean }` |
| `type PanZoomInstance` | See below |
| `type OnPanZoom` | `type OnPanZoom = Maybe (MouseEvent \| TouchEvent) -> Viewport -> Effect Unit` (see notes) |
| `type OnDraggingChange` | `type OnDraggingChange = Boolean -> Effect Unit` |
| `type OnTransformChange` | `type OnTransformChange = Transform -> Effect Unit` |
| `type PanOnDrag = boolean \| number[]` | `data PanOnDrag = NoPan \| PanAlways \| PanOnButtons (Array Int)` |
| `type InterpolateMode = 'smooth' \| 'linear'` | `data InterpolateMode = SmoothInterp \| LinearInterp` |

### `PanZoomInstance` record

```purescript
type PanZoomInstance =
  { update :: PanZoomUpdateOptions -> Effect Unit
  , destroy :: Effect Unit
  , getViewport :: Effect Viewport
  , setViewport :: Viewport -> Maybe PanZoomTransformOptions -> Aff (Maybe ZoomTransform)
  , setViewportConstrained :: Viewport -> CoordinateExtent -> CoordinateExtent -> Aff (Maybe ZoomTransform)
  , setScaleExtent :: Number -> Number -> Effect Unit
  , setTranslateExtent :: CoordinateExtent -> Effect Unit
  , scaleTo :: Number -> Maybe PanZoomTransformOptions -> Aff Boolean
  , scaleBy :: Number -> Maybe PanZoomTransformOptions -> Aff Boolean
  , syncViewport :: Viewport -> Effect Unit
  , setClickDistance :: Number -> Effect Unit
  }
```

## Idiomatic Notes

- **`PanZoomInstance` as a record of functions.** The TS `PanZoomInstance` is an interface that `XYPanZoom(...)` returns. In PS this becomes a record of effectful functions (a "service object"). Each method that mutates d3 state is `Effect`; each method returning a `Promise<T>` becomes `Aff T`.
- **`ZoomTransform` opaque type.** The TS methods return `Promise<ZoomTransform | undefined>`. `ZoomTransform` is a d3 type. At the PS type-system boundary, represent it as `Foreign` (opaque) wrapped in `Maybe`. Name it `ZoomTransform` (a `newtype Foreign`) in a small FFI module so it does not leak raw `Foreign` into the business-logic code.
- **`setViewport`, `setViewportConstrained`.** These return `Aff (Maybe ZoomTransform)` because they internally animate via d3 and can fail if the selection is absent.
- **`scaleTo`, `scaleBy`.** Return `Aff Boolean` — `true` when the animation completed, `false` if d3 selection was absent.
- **`destroy :: Effect Unit`.** In the TS source this also calls `d3ZoomInstance.on('zoom', null)`. The PS signature is `Effect Unit`; callers should treat it as an irreversible teardown.
- **`PanOnDrag = boolean | number[]`.** The three semantic values are: completely disabled, enabled for any button, enabled only for specific mouse button numbers. Model as `data PanOnDrag = NoPan | PanAlways | PanOnButtons (NonEmptyArray Int)`.
- **`OnPanZoom` callback.** The TS signature is `(event: MouseEvent | TouchEvent | null, viewport: Viewport) => void`. The event is a DOM event (effectful, from FFI); use `Maybe (Either MouseEvent TouchEvent)` for the event parameter. Mouse and touch events are FFI types from `web-events`.
- **This ticket ports only the types.** The actual d3-backed implementation is ticket 010 (XYPanZoom).

## New Spago Dependencies
- `aff` (for `Aff`)
- `effect` (already in project)
- `maybe`
- `foreign` (for `ZoomTransform` opaque wrapper)
- `web-events` (for `MouseEvent`, `TouchEvent`)
- `web-html` (for `Element`)

## Prerequisite Tickets
- 001 (Geometry — `Transform`, `CoordinateExtent`)
- 003 (Connection — `Viewport`, `PanOnScrollMode`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `PanZoomInstance` record type is fully defined with accurate effect types.
- `PanOnDrag` ADT covers all three TS variants.
- `InterpolateMode` derives `Eq`, `Show`.
- No `any`, `Foreign`, or untyped values appear in the public API except the deliberately-opaque `ZoomTransform`.
