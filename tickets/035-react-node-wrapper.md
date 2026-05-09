# 035 — NodeWrapper

## Title
Port the per-node wrapper component. Handles drag, selection, keyboard, ResizeObserver, and provides `NodeIdContext` to the user node component.

## Source Files
- `xyflow-main/packages/react/src/components/NodeWrapper/index.tsx`
- `xyflow-main/packages/react/src/components/NodeWrapper/utils.tsx` (`arrowKeyDiffs`, `builtinNodeTypes`, `getNodeInlineStyleDimensions`)
- `xyflow-main/packages/react/src/components/NodeWrapper/useNodeObserver.ts` (covered by ticket 031, imported here)

## Target Modules
- `React.Component.NodeWrapper`
- `React.Component.NodeWrapper.Util`

## Key Types / Functions

```purescript
type NodeWrapperProps =
  { id :: String
  , onClick :: Maybe (NodeMouseHandler)
  , onMouseEnter :: Maybe (NodeMouseHandler)
  , onMouseMove :: Maybe (NodeMouseHandler)
  , onMouseLeave :: Maybe (NodeMouseHandler)
  , onContextMenu :: Maybe (NodeMouseHandler)
  , onDoubleClick :: Maybe (NodeMouseHandler)
  , nodesDraggable :: Boolean
  , elementsSelectable :: Boolean
  , nodesConnectable :: Boolean
  , nodesFocusable :: Boolean
  , resizeObserver :: Maybe ResizeObserverHandle
  , noDragClassName :: String
  , noPanClassName :: String
  , disableKeyboardA11y :: Boolean
  , rfId :: String
  , nodeTypes :: Object (Component NodeProps)
  , nodeClickDistance :: Number
  , onError :: Maybe (ErrorCode -> String -> Effect Unit)
  }

nodeWrapper :: Component NodeWrapperProps
```

## Behaviour

For each node:
1. Read `node`, `internals`, `isParent` from the store via `useStore` (selecting one entry from `nodeLookup`).
2. Resolve the user node component via `nodeTypes[node.type]` with fallback to `builtinNodeTypes`. If still missing, dispatch `error003` and render a default.
3. Mount a `useDrag` hook for this node.
4. Mount a `useNodeObserver` hook for ResizeObserver wiring.
5. Render a `<div>` with all interaction handlers, and inside it the resolved user component wrapped in `<NodeIdContext.Provider value={id}>`.
6. Handle keyboard navigation: `arrowKeyDiffs` map and `useMoveSelectedNodes`.
7. Handle selection via `handleNodeClick` (from ticket 033).

## Idiomatic Notes

- **Stable component reference required.** TS uses `memo`. PS wraps in `react-basic-hooks` `memo` and uses a custom equality check (`shallow`-equivalent) — but since we're using `Eq` on props, just derive `Eq NodeWrapperProps` and the default `memo` compares structurally.
- **`useStore` selector returns three things.** Matches TS. Use a record return type with derived `Eq`.
- **Forward `ref` to wrapped DOM.** TS does this. PS uses `React.FFI.React.forwardRef` from inside the wrapper.
- **`builtinNodeTypes` lives here** (per the TS source). Move the registry from ticket 033's `Node.Util` to `React.Component.NodeWrapper.Util`. Reconfirm that ticket 033 doesn't need it.
- **`getNodeInlineStyleDimensions`** computes the inline `width`/`height` style. Pure function. Port verbatim from the TS util.
- **`arrowKeyDiffs` is a static map** from key code to `{ x, y }` deltas. Define as `Map String XYPosition`.
- **`Provider` from `React.Context.NodeId`** wraps the user component, exposing the node ID to nested `Handle`s.
- **`onError`** is the system-layer error reporter (defaulted to `console.warn` in dev). Pass through.

## New Spago Dependencies
- None new

## Prerequisite Tickets
- 022, 024
- 027 (`useStore`, `useStoreApi`)
- 031 (`useDrag`, `useNodeObserver`, `useMoveSelectedNodes`)
- 033 (`builtinNodeTypes`, `handleNodeClick`)
- 034 (`Handle` — for built-in nodes mounted inside)
- System tickets 008 (`getNodeDimensions`), 009 (`nodeHasDimensions`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `nodeWrapper` renders the resolved user component inside a `<div>` with all expected class names.
- The user component receives the `NodeIdContext` value matching the wrapper's `id`.
- Drag, selection, and keyboard handlers wire to the store correctly.
- ResizeObserver triggers `UpdateNodeInternals` on element resize.
- Missing `nodeTypes[node.type]` fires `error003` and falls back to a default.
