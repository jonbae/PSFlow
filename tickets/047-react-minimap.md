# 047 — MiniMap

## Title
Port the `MiniMap` add-on. Uses `System.XYMinimap` (ticket 020) for pan/zoom interactions on the minimap rectangle.

## Source Files
- `xyflow-main/packages/react/src/additional-components/MiniMap/MiniMap.tsx`
- `xyflow-main/packages/react/src/additional-components/MiniMap/MiniMapNode.tsx`
- `xyflow-main/packages/react/src/additional-components/MiniMap/MiniMapNodes.tsx`
- `xyflow-main/packages/react/src/additional-components/MiniMap/index.tsx`
- `xyflow-main/packages/react/src/additional-components/MiniMap/types.ts`

## Target Modules
- `React.Additional.MiniMap`
- `React.Additional.MiniMap.Node`
- `React.Additional.MiniMap.Nodes`

## Key Components

```purescript
miniMap :: Component MiniMapProps
miniMapNode :: Component MiniMapNodeProps
miniMapNodes :: Component MiniMapNodesProps
```

```purescript
type MiniMapProps =
  { nodeColor :: Maybe (Node -> String)
  , nodeStrokeColor :: Maybe (Node -> String)
  , nodeClassName :: Maybe (Node -> String)
  , nodeBorderRadius :: Maybe Number
  , nodeStrokeWidth :: Maybe Number
  , nodeComponent :: Maybe (Component MiniMapNodeProps)
  , bgColor :: Maybe String
  , maskColor :: Maybe String
  , maskStrokeColor :: Maybe String
  , maskStrokeWidth :: Maybe Number
  , position :: Maybe PanelPosition
  , onClick :: Maybe (MouseEvent -> XYPosition -> Effect Unit)
  , onNodeClick :: Maybe (MouseEvent -> Node -> Effect Unit)
  , pannable :: Maybe Boolean
  , zoomable :: Maybe Boolean
  , aria-label :: Maybe String
  , inversePan :: Maybe Boolean
  , zoomStep :: Maybe Number
  , offsetScale :: Maybe Number
  , children :: Maybe JSX
  , style :: Maybe (Object String)
  , className :: Maybe String
  }
```

## Behaviour

1. Reads `nodes`, `transform`, viewport bounds via `useStore`.
2. Computes a viewport-of-the-viewport: a rectangle indicating where the user is currently looking.
3. Renders an `<svg>` containing:
   - Background mask (everything outside the user's view, dimmed).
   - One `<MiniMapNode>` per node (a small rect at the node's flow coordinates).
   - The user-view rectangle on top.
4. Mounts `XYMinimap` (system ticket 020) on the SVG element to handle pan/zoom interactions on the minimap.

## Idiomatic Notes

- **`XYMinimap` lifecycle.** `useEffect` mounts on mount, calls `update` on prop change, and `destroy` on unmount. Same pattern as `XYDrag` in `useDrag`.
- **`MiniMapNodes` is the inner mapper.** Maps over visible nodes and renders one `MiniMapNode` each. User can override the per-node component via `nodeComponent`.
- **Defaults.** `bgColor=#fff`, `maskColor=rgba(240,240,240,0.6)`, `position=BottomRight`.
- **`pannable`, `zoomable`, `inversePan`, `zoomStep`, `offsetScale`** all wire into the `XYMinimap.update` call. Don't reimplement.
- **`children` slot** allows extra overlay content inside the SVG.

## New Spago Dependencies
- None new

## Prerequisite Tickets
- 022, 024
- 027 (`useStore`)
- 044 (`Panel`)
- System ticket 020 (`XYMinimap`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `miniMap` renders nodes proportional to flow coordinates.
- The viewport rectangle reflects the current `state.transform`.
- Clicking the minimap pans the main viewport (when `pannable=true`).
- Wheel-zoom on the minimap zooms the main viewport (when `zoomable=true`).
- Custom `nodeComponent` overrides the built-in `MiniMapNode`.
