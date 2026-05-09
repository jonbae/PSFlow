# 046 — Controls

## Title
Port the `Controls` add-on — the floating zoom/pan/fit/lock button bar — plus `ControlButton` and the SVG icons.

## Source Files
- `xyflow-main/packages/react/src/additional-components/Controls/Controls.tsx`
- `xyflow-main/packages/react/src/additional-components/Controls/ControlButton.tsx`
- `xyflow-main/packages/react/src/additional-components/Controls/index.tsx`
- `xyflow-main/packages/react/src/additional-components/Controls/types.ts`
- `xyflow-main/packages/react/src/additional-components/Controls/Icons/` — `FitView`, `Lock`, `Unlock`, `Plus`, `Minus`

## Target Modules
- `React.Additional.Controls`
- `React.Additional.Controls.Button`
- `React.Additional.Controls.Icons` — one component per icon

## Key Components

```purescript
controls :: Component ControlsProps
controlButton :: Component ControlButtonProps

iconFitView :: JSX
iconLock :: JSX
iconUnlock :: JSX
iconPlus :: JSX
iconMinus :: JSX
```

```purescript
type ControlsProps =
  { showZoom :: Maybe Boolean
  , showFitView :: Maybe Boolean
  , showInteractive :: Maybe Boolean
  , fitViewOptions :: Maybe FitViewOptions
  , onZoomIn :: Maybe (Effect Unit)
  , onZoomOut :: Maybe (Effect Unit)
  , onFitView :: Maybe (Effect Unit)
  , onInteractiveChange :: Maybe (Boolean -> Effect Unit)
  , position :: Maybe PanelPosition
  , children :: Maybe JSX
  , style :: Maybe (Object String)
  , className :: Maybe String
  , aria-label :: Maybe String
  , orientation :: Maybe Orientation   -- horizontal | vertical
  }
```

## Behaviour

1. Reads `viewportInitialized`, `nodesDraggable`, etc. via `useStore`.
2. Uses `useReactFlow` to get `zoomIn`, `zoomOut`, `fitView`.
3. Wrapped in a `<Panel>` (ticket 044) at the chosen position.
4. Renders four buttons: zoom-in, zoom-out, fit-view, lock-unlock. Each is a `<controlButton>` containing an icon.
5. Lock toggles `nodesDraggable`, `nodesConnectable`, `elementsSelectable` together via `useStoreApi().setState`.

## Idiomatic Notes

- **Defaults match TS.** All `Show*` flags default to `true`. Position defaults to `BottomLeft`.
- **`useReactFlow` for action methods.** Don't reimplement zoom/fit logic; delegate.
- **`children` slot for custom buttons.** Append after the built-ins.
- **Icons are pure JSX values, not components.** Render directly. Each icon is ~5 lines of `<svg>`.
- **Lock state derived from store flags.** Three booleans aggregated; if any is `false`, the icon shows "locked".
- **`orientation` controls layout.** Vertical = stacked column, horizontal = row. Reflected via class names; CSS does the layout.

## New Spago Dependencies
- None new

## Prerequisite Tickets
- 022, 024
- 027 (`useStore`, `useStoreApi`)
- 030 (`useReactFlow`)
- 044 (`Panel`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `controls` renders four buttons by default plus any `children`.
- Zoom, fit-view, lock buttons trigger the correct `useReactFlow` methods or store mutations.
- Lock state correctly reflects all three store booleans.
- Position via `<Panel>` works.
