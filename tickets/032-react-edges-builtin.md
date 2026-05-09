# 032 — Built-in edge components

## Title
Port the built-in edge components: `BaseEdge`, `StraightEdge`, `BezierEdge`, `SimpleBezierEdge`, `StepEdge`, `SmoothStepEdge`, `EdgeText`, `EdgeAnchor`. Plus the `getSimpleBezierPath` helper.

## Source Files
- `xyflow-main/packages/react/src/components/Edges/BaseEdge.tsx`
- `xyflow-main/packages/react/src/components/Edges/StraightEdge.tsx`
- `xyflow-main/packages/react/src/components/Edges/BezierEdge.tsx`
- `xyflow-main/packages/react/src/components/Edges/SimpleBezierEdge.tsx`
- `xyflow-main/packages/react/src/components/Edges/StepEdge.tsx`
- `xyflow-main/packages/react/src/components/Edges/SmoothStepEdge.tsx`
- `xyflow-main/packages/react/src/components/Edges/EdgeText.tsx`
- `xyflow-main/packages/react/src/components/Edges/EdgeAnchor.tsx`
- `xyflow-main/packages/react/src/components/Edges/index.ts`

## Target Modules
- `React.Edge.Base`
- `React.Edge.Straight`
- `React.Edge.Bezier`
- `React.Edge.SimpleBezier`
- `React.Edge.Step`
- `React.Edge.SmoothStep`
- `React.Edge.Text`
- `React.Edge.Anchor`

## Key Components

Each module exports one `Component` (per `react-basic-hooks` `mkComponent`):

| TS | PS |
|---|---|
| `BaseEdge: React.FC<BaseEdgeProps>` | `baseEdge :: Component BaseEdgeProps` |
| `StraightEdge: React.FC<StraightEdgeProps>` | `straightEdge :: Component StraightEdgeProps` |
| `BezierEdge: React.FC<BezierEdgeProps>` | `bezierEdge :: Component BezierEdgeProps` |
| (etc.) | (etc.) |

Internal-vs-public distinction: each TS file exports both `BezierEdge` (public) and `BezierEdgeInternal` (rendered by `EdgeWrapper`). Mirror this — each module exports both:
```purescript
bezierEdge :: Component BezierEdgeProps          -- public
bezierEdgeInternal :: Component BezierEdgeProps  -- internal, sets `isInternal: true`
```

### `BaseEdge`

The shared rendering component that all built-in edges delegate to. Renders an SVG `<path>` plus optional invisible interaction `<path>` and an `EdgeText` label.

```purescript
type BaseEdgeProps =
  { id :: Maybe String
  , path :: String
  , labelX :: Maybe Number
  , labelY :: Maybe Number
  , label :: Maybe JSX
  , labelStyle :: Maybe (Object String)   -- CSS styles
  , labelShowBg :: Maybe Boolean
  , labelBgStyle :: Maybe (Object String)
  , labelBgPadding :: Maybe (Tuple Number Number)
  , labelBgBorderRadius :: Maybe Number
  , style :: Maybe (Object String)
  , markerEnd :: Maybe String
  , markerStart :: Maybe String
  , interactionWidth :: Maybe Number
  , className :: Maybe String
  }
```

### Path-generating edges

All four (`Straight`, `Bezier`, `SimpleBezier`, `Step`, `SmoothStep`) follow the same shape:
1. Read source/target coords from props.
2. Call the corresponding path function from `System.Utils.Edges.*`:
   - `getStraightPath` (ticket 013, `System.Utils.Edges.Straight`)
   - `getBezierPath`
   - `getSimpleBezierPath` (also exported publicly — see `index.ts`)
   - `getSmoothStepPath` (used by both `Step` and `SmoothStep`; `Step` passes `borderRadius: 0`)
3. Render `<BaseEdge>` with the path.

### `EdgeText`

A standalone label component used by `BaseEdge`. Renders a `<g>` with `transform="translate(x,y)"` containing optional `<rect>` background and `<text>`.

### `EdgeAnchor`

The reconnect-handle anchor. Renders an invisible circle on top of an edge endpoint. Used by `EdgeUpdateAnchors` (ticket 036).

## Idiomatic Notes

- **All path math comes from `System.Utils.Edges`.** Don't reimplement Bezier/SmoothStep math here. This ticket is purely React-rendering.
- **Default `Position` values match TS.** `BezierEdge` defaults `sourcePosition = Position.Bottom`, `targetPosition = Position.Top`. Encode in PS via record-update with defaults at the call site (since PS records don't have field defaults).
- **`memo` wrapping.** TS uses `memo(...)` on each component. PS uses `react-basic-hooks`'s `memo` wrapper.
- **`isInternal` flag stripping the `id` prop.** TS uses `const _id = params.isInternal ? undefined : id`. PS does the same in the internal variant.
- **No CSS-in-JS — class names are static.** `react-flow__edge-path`, `react-flow__edge-textbg`, etc. Construct via string concat or `classcat` FFI.
- **SVG element constructors come from `react-basic-dom`.** `R.path`, `R.text`, `R.g`, `R.circle`, etc. Use `react-basic-dom`'s `Props_*` row types for each element.
- **`getSimpleBezierPath` is publicly exported.** Re-export from `React.Edge.SimpleBezier` and from `React.purs` (ticket 049).
- **`Object String` for inline styles.** Use `Foreign.Object` from the `foreign-object` package; matches React's style-object shape.

## New Spago Dependencies
- `react-basic-dom` — SVG/HTML element constructors
- `foreign-object` — for inline style records (TS `React.CSSProperties`)

## Prerequisite Tickets
- 022 (rename)
- 024 (prop types)
- System tickets 013 (Utils.Edges path functions)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- All 8 components plus `getSimpleBezierPath` are exported from their modules.
- Each public component is wrapped in `memo`.
- Public/internal pairs exist for every edge type (`bezierEdge` and `bezierEdgeInternal`, etc.).
- Class names emitted in the rendered DOM match the TS source so the upstream CSS applies cleanly.
- Default `Position` values match TS.
