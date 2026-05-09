# 036 — EdgeWrapper

## Title
Port the per-edge wrapper component, plus `EdgeUpdateAnchors` (the reconnect handles).

## Source Files
- `xyflow-main/packages/react/src/components/EdgeWrapper/index.tsx`
- `xyflow-main/packages/react/src/components/EdgeWrapper/EdgeUpdateAnchors.tsx`
- `xyflow-main/packages/react/src/components/EdgeWrapper/utils.ts`

## Target Modules
- `React.Component.EdgeWrapper`
- `React.Component.EdgeWrapper.UpdateAnchors`
- `React.Component.EdgeWrapper.Util`

## Key Types / Functions

```purescript
type EdgeWrapperProps =
  { id :: String
  , edgesFocusable :: Boolean
  , edgesReconnectable :: Boolean
  , elementsSelectable :: Boolean
  , noPanClassName :: String
  , onClick :: Maybe (EdgeMouseHandler)
  , onDoubleClick :: Maybe (EdgeMouseHandler)
  , onContextMenu :: Maybe (EdgeMouseHandler)
  , onMouseEnter :: Maybe (EdgeMouseHandler)
  , onMouseMove :: Maybe (EdgeMouseHandler)
  , onMouseLeave :: Maybe (EdgeMouseHandler)
  , onReconnect :: Maybe OnReconnect
  , onReconnectStart :: Maybe (Edge -> Handle -> HandleType -> Effect Unit)
  , onReconnectEnd :: Maybe (Edge -> Handle -> HandleType -> Effect Unit)
  , rfId :: String
  , edgeTypes :: Object (Component EdgeProps)
  , onError :: Maybe (ErrorCode -> String -> Effect Unit)
  , disableKeyboardA11y :: Boolean
  }

edgeWrapper :: Component EdgeWrapperProps
edgeUpdateAnchors :: Component EdgeUpdateAnchorsProps
```

## Behaviour

For each edge:
1. Read `edge`, `sourceNode`, `targetNode`, `sourceHandle`, `targetHandle`, computed coordinates from the store.
2. Compute path coordinates via `System.Utils.Edges.Positions.getEdgePosition` (ticket 013).
3. Resolve the user edge component via `edgeTypes[edge.type]` with fallback to built-ins (`bezierEdgeInternal`, `straightEdgeInternal`, etc.). On miss, dispatch `error011`.
4. Render a `<g>` with edge interaction handlers; inside it the user edge component, optionally wrapped by `<EdgeUpdateAnchors>` if reconnect is allowed.
5. Selection, focus, keyboard handlers.

`EdgeUpdateAnchors` renders two `<EdgeAnchor>`s (source and target) that listen for pointerdown to start a reconnect via `XYHandle`.

## Idiomatic Notes

- **`builtinEdgeTypes`** — `{ default: bezierEdgeInternal, straight: straightEdgeInternal, step: stepEdgeInternal, smoothstep: smoothStepEdgeInternal, simplebezier: simpleBezierEdgeInternal }`. Defined in `React.Component.EdgeWrapper.Util`.
- **Position resolution is impure-looking but pure.** It reads from `nodeLookup`, computes coordinates. Wrap in a `useStore` selector.
- **Reconnect uses `System.XYHandle`** (ticket 017). The reconnect handler dispatches the same `connection-in-progress` lifecycle as a fresh connect, but with the extra `OnReconnect` callback fired at the end.
- **`memo`-wrapped.** Same as `NodeWrapper`. Derive `Eq` on the prop record.
- **`EdgeUpdateAnchors` rendered conditionally.** Only when `edgesReconnectable && edge.reconnectable !== false`.
- **`onError` reports `error011`** when `edge.type` doesn't resolve. Match TS exactly.

## New Spago Dependencies
- None new

## Prerequisite Tickets
- 022, 024
- 027 (`useStore`, `useStoreApi`)
- 031 (key/drag hooks if used)
- 032 (built-in edges)
- System tickets 013 (Utils.Edges)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `edgeWrapper` renders the resolved user edge component inside a `<g>` with handlers.
- Reconnect handles render only when allowed, and pointerdown initiates a reconnect via `XYHandle`.
- Missing `edgeTypes[edge.type]` fires `error011` and falls back to `bezierEdgeInternal`.
- Edge selection updates the store correctly.
