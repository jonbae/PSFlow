# 037 — Selection overlays: ConnectionLine, NodesSelection, UserSelection

## Title
Port the three selection-related overlay components.

## Source Files
- `xyflow-main/packages/react/src/components/ConnectionLine/index.tsx`
- `xyflow-main/packages/react/src/components/NodesSelection/index.tsx`
- `xyflow-main/packages/react/src/components/UserSelection/index.tsx`

## Target Modules
- `React.Component.ConnectionLine`
- `React.Component.NodesSelection`
- `React.Component.UserSelection`

## Key Components

```purescript
connectionLine :: Component ConnectionLineProps
nodesSelection :: Component NodesSelectionProps
userSelection :: Component UserSelectionProps
```

### `ConnectionLine`

Renders an SVG path representing the in-progress connection. Reads `state.connection` from the store. When `state.connection` is `NoConnection`, renders nothing. When `ConnectionInProgress data`, renders the path from `data.from` to `data.to` using the configured `connectionLineType` and `connectionLineStyle`.

```purescript
type ConnectionLineProps =
  { containerStyle :: Maybe (Object String)
  , style :: Maybe (Object String)
  , type :: Maybe ConnectionLineType
  , component :: Maybe (Component ConnectionLineComponentProps)   -- user override
  }
```

### `NodesSelection`

Renders the rectangle around currently-selected nodes (the bounding box). Visible when `state.nodesSelectionActive` is `true`. Allows the user to drag the entire selection. Uses `useDrag` (ticket 031) on the bounding box.

### `UserSelection`

Renders the user's drag-selection rectangle (the lasso). Visible when `state.userSelectionActive` is `true`. Reads `state.userSelectionRect` for the rectangle coordinates.

## Idiomatic Notes

- **All three are conditional.** Each reads from the store and returns `mempty :: JSX` when the corresponding flag is false.
- **`ConnectionLine` path-generation depends on `connectionLineType`.** The type is one of `Default | Bezier | Straight | Step | SimpleBezier | SmoothStep`. Each maps to a `System.Utils.Edges.*.getXxxPath` call. Use the existing path functions; don't reimplement.
- **`NodesSelection` `useDrag` setup.** Matches a "virtual node" with id `'__nodes_selection__'` (per TS). Use the same sentinel.
- **User-overridable `ConnectionLine`.** The `component` prop accepts a custom component; if `Nothing`, the built-in path renderer is used.
- **`memo`-wrapped where TS does so.**

## New Spago Dependencies
- None new

## Prerequisite Tickets
- 027 (`useStore`)
- 031 (`useDrag` for `NodesSelection`)
- 032 (path functions via `System.Utils.Edges`)
- 024 (prop types)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `ConnectionLine` renders only during a connection drag.
- `NodesSelection` is draggable via `useDrag`.
- `UserSelection` renders the user's lasso rectangle.
- All three return `mempty` (or `null`-equivalent JSX) when their gate condition is false.
