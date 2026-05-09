# 038 — Pane

## Title
Port the `Pane` container — the pan/select interaction surface that hosts nodes, edges, and selection rectangles. Translates pointer events into pan, click, or selection-rect drag.

## Source Files
- `xyflow-main/packages/react/src/container/Pane/index.tsx`

## Target Module
`React.Container.Pane`

## Key Types / Functions

```purescript
type PaneProps =
  { isSelecting :: Boolean
  , selectionMode :: SelectionMode
  , panOnDrag :: PanOnDrag                  -- Boolean | Array Int (button-mode array)
  , onSelectionStart :: Maybe (MouseEvent -> Effect Unit)
  , onSelectionEnd :: Maybe (MouseEvent -> Effect Unit)
  , onPaneClick :: Maybe (MouseEvent -> Effect Unit)
  , onPaneContextMenu :: Maybe (MouseEvent -> Effect Unit)
  , onPaneScroll :: Maybe (WheelEvent -> Effect Unit)
  , onPaneMouseEnter :: Maybe (MouseEvent -> Effect Unit)
  , onPaneMouseMove :: Maybe (MouseEvent -> Effect Unit)
  , onPaneMouseLeave :: Maybe (MouseEvent -> Effect Unit)
  , children :: JSX
  }

pane :: Component PaneProps
```

## Behaviour

1. Renders a `<div>` with class `react-flow__pane`.
2. On pointerdown: if `isSelecting` and the button matches selection-button rules, start drawing a selection rect. Otherwise, defer to ZoomPane (which handles pan).
3. On pointermove during selection: update `state.userSelectionRect` and compute which nodes are inside via `System.Utils.Graph.getNodesInside` (ticket 009).
4. On pointerup: finalise selection, dispatch `AddSelectedNodes`/`AddSelectedEdges`, clear `userSelectionActive`.
5. Renders children.

## Idiomatic Notes

- **`PanOnDrag` is a sum type.** TS uses `boolean | number[]`. PS:
  ```purescript
  data PanOnDrag = PanOnDragOff | PanOnDragOn | PanOnDragButtons (Array Int)
  ```
  with conversion from a `Foreign`-style entrypoint at the React boundary.
- **Selection-rect math is pure.** Computes start/current corners; the inside-set computation calls `System.Utils.Graph.getNodesInside`. Don't reimplement.
- **Refs for the pane element.** `useRef Nothing :: Ref (Maybe HTMLDivElement)`, attached to the rendered div.
- **`useDrag` is NOT used here.** TS uses raw pointer event handlers because the drag here is for a selection rect, not a node. Keep it that way.
- **Cancel on pointer-leaving with button up.** TS clears the rect on `pointerup`. Match.
- **Edge selection inside the rect.** TS also marks edges contained within the rect; that path goes through `getEdgesInside` (a system util). Mirror.

## New Spago Dependencies
- None new

## Prerequisite Tickets
- 022, 024
- 027 (`useStore`, `useStoreApi`)
- System ticket 009 (`getNodesInside`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `pane` renders a `<div>` with the `react-flow__pane` class.
- Pointerdown + drag in selection mode draws a rect and selects nodes underneath on release.
- Click on pane clears selection (matching TS behaviour).
- Children prop renders inside the pane container.
