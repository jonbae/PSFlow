# 048 — NodeResizer, NodeToolbar, EdgeToolbar

## Title
Port the three remaining add-on components: `NodeResizer` (with `NodeResizeControl`), `NodeToolbar`, and `EdgeToolbar`. The resizer wraps `System.XYResizer` (ticket 019).

## Source Files
- `xyflow-main/packages/react/src/additional-components/NodeResizer/NodeResizer.tsx`
- `xyflow-main/packages/react/src/additional-components/NodeResizer/NodeResizeControl.tsx`
- `xyflow-main/packages/react/src/additional-components/NodeResizer/types.ts`
- `xyflow-main/packages/react/src/additional-components/NodeToolbar/NodeToolbar.tsx`
- `xyflow-main/packages/react/src/additional-components/NodeToolbar/NodeToolbarPortal.tsx`
- `xyflow-main/packages/react/src/additional-components/NodeToolbar/types.ts`
- `xyflow-main/packages/react/src/additional-components/EdgeToolbar/EdgeToolbar.tsx`
- `xyflow-main/packages/react/src/additional-components/EdgeToolbar/types.ts`

## Target Modules
- `React.Additional.NodeResizer`
- `React.Additional.NodeResizer.Control`
- `React.Additional.NodeToolbar`
- `React.Additional.NodeToolbar.Portal`
- `React.Additional.EdgeToolbar`

## Key Components

```purescript
nodeResizer :: Component NodeResizerProps
nodeResizeControl :: Component NodeResizeControlProps
nodeToolbar :: Component NodeToolbarProps
edgeToolbar :: Component EdgeToolbarProps
```

### `NodeResizer`

Renders eight `<NodeResizeControl>` instances around a node — four edges and four corners. Each uses `XYResizer` (system ticket 019) to handle the drag-resize interaction.

```purescript
type NodeResizerProps =
  { color :: Maybe String
  , handleClassName :: Maybe String
  , handleStyle :: Maybe (Object String)
  , lineClassName :: Maybe String
  , lineStyle :: Maybe (Object String)
  , isVisible :: Maybe Boolean
  , minWidth :: Maybe Number
  , minHeight :: Maybe Number
  , maxWidth :: Maybe Number
  , maxHeight :: Maybe Number
  , keepAspectRatio :: Maybe Boolean
  , autoScale :: Maybe Boolean
  , shouldResize :: Maybe ShouldResize
  , onResizeStart :: Maybe OnResizeStart
  , onResize :: Maybe OnResize
  , onResizeEnd :: Maybe OnResizeEnd
  }
```

Reads the parent node's id from `useNodeId`.

### `NodeToolbar`

A floating toolbar above (or beside) one or more selected nodes. Uses `NodeToolbarPortal` to render outside the node's clipping region.

```purescript
type NodeToolbarProps =
  { nodeId :: Maybe (Either String (Array String))
  , isVisible :: Maybe Boolean
  , position :: Maybe Position
  , offset :: Maybe Number
  , align :: Maybe Align
  , style :: Maybe (Object String)
  , className :: Maybe String
  , children :: JSX
  }
```

Computes anchor position from the bounding box of the targeted node(s); positions the toolbar via inline `transform`.

### `EdgeToolbar`

Same shape as `NodeToolbar` but anchored to an edge.

## Idiomatic Notes

- **`NodeResizer` mounts `XYResizer`.** Same lifecycle pattern as `useDrag`. Don't reimplement resize math.
- **`NodeResizeControl` is one of eight handles.** TS uses a `<position>` discriminator (`top-left`, etc.). PS uses `data ControlPosition = TopLeft | Top | TopRight | Right | BottomRight | Bottom | BottomLeft | Left` — already in `System.Types.PanZoom` (ticket 006).
- **`NodeToolbarPortal` uses `createPortal`** (ticket 044's FFI shim). Anchors to a child of the React Flow root so the toolbar is unaffected by node clipping.
- **`isVisible` defaults to `selected`.** When unset, the toolbar appears only if the targeted node(s) are selected.
- **`align: Align`** is `Start | Center | End` — already in `System.Types.PanZoom`.
- **All three are `memo`-wrapped** since their prop records have stable derived `Eq`.

## New Spago Dependencies
- None new

## Prerequisite Tickets
- 022, 024
- 025 (`useNodeId`)
- 027 (`useStore`, `useStoreApi`)
- 044 (`createPortal`)
- System ticket 019 (`XYResizer`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `nodeResizer` renders 8 handles and resizes the node via `XYResizer`.
- `nodeToolbar` portals to the React Flow root and anchors to the targeted node.
- `edgeToolbar` anchors to the targeted edge.
- `keepAspectRatio` is honoured during resize.
- Toolbars hide when their `isVisible` resolves to `false`.
