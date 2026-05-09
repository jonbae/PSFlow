# 044 — Portal components: Panel, EdgeLabelRenderer, ViewportPortal

## Title
Port the three React-portal-based components plus the `createPortal` FFI shim.

## Source Files
- `xyflow-main/packages/react/src/components/Panel/index.tsx`
- `xyflow-main/packages/react/src/components/EdgeLabelRenderer/index.tsx`
- `xyflow-main/packages/react/src/components/ViewportPortal/index.tsx`

## Target Modules
- `React.Portal.Panel`
- `React.Portal.EdgeLabelRenderer`
- `React.Portal.ViewportPortal`
- `React.Portal.FFI` — single `createPortal` FFI binding (`createPortal :: JSX -> Node -> JSX`)

## Key Components

```purescript
panel :: Component PanelProps
edgeLabelRenderer :: Component EdgeLabelRendererProps
viewportPortal :: Component ViewportPortalProps

createPortal :: JSX -> Node -> JSX   -- in React.Portal.FFI
```

### `Panel`

A floating UI panel rendered at one of nine `PanelPosition` values (top-left, top-right, …, bottom-center). Renders a fixed-position div inside the React Flow container.

```purescript
type PanelProps =
  { position :: PanelPosition
  , className :: Maybe String
  , style :: Maybe (Object String)
  , children :: JSX
  }
```

Doesn't actually use a React portal — it's named "Panel" but is a regular `<div>` with absolute positioning. Confirmed by reading the TS source. The "Portal" group label here is for the *logical* role (UI overlays) and the fact that the next two do use portals.

### `EdgeLabelRenderer`

Renders children into a separate DOM container above the SVG layer (so labels can use HTML, not SVG text). Uses `createPortal` to reach a stable DOM node mounted by `GraphView`.

```purescript
type EdgeLabelRendererProps =
  { children :: JSX
  }
```

Reads `state.domNode` (the React Flow root element) and finds a `.react-flow__edgelabel-renderer` child. If absent (rare race condition during mount), renders nothing.

### `ViewportPortal`

Like `EdgeLabelRenderer` but for content that should live inside the transformed viewport (so it pans/zooms with the flow). Portals into a `.react-flow__viewport` child.

## Idiomatic Notes

- **`createPortal` is the only FFI here.** One thin wrapper:
  ```js
  // React.Portal.FFI.js
  import { createPortal } from "react-dom";
  export const createPortal = (jsx) => (node) => createPortal(jsx, node);
  ```
  ```purescript
  -- React.Portal.FFI.purs
  foreign import createPortal :: JSX -> Node -> JSX
  ```
- **`Panel` is not a portal.** Named consistency with the TS source.
- **Portal target lookup is `Effect`.** `document.querySelector` returns `Maybe Node`. If the target is missing, render `mempty`.
- **Stable container element.** The portal target must exist before any portal child mounts. `GraphView` (ticket 041) mounts these elements as plain `<div>`s.

## New Spago Dependencies
- `web-dom` (already a dep) for `Node` and `querySelector`

## Prerequisite Tickets
- 022, 024
- 027 (`useStore` for `state.domNode`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `panel` renders at the specified `PanelPosition`.
- `edgeLabelRenderer` renders children into the `.react-flow__edgelabel-renderer` element.
- `viewportPortal` renders children into the `.react-flow__viewport` element.
- All three return `mempty` when their portal target isn't yet in the DOM.
