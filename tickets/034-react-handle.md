# 034 — Handle component

## Title
Port the `Handle` component — the connection point on a node. Bridges user node components into the connection lifecycle. Wraps `System.XYHandle` (ticket 017).

## Source Files
- `xyflow-main/packages/react/src/components/Handle/index.tsx`

## Target Module
`React.Handle`

## Key Types / Functions

```purescript
type HandleProps =
  { type :: HandleType                      -- Source | Target
  , position :: Position
  , isConnectable :: Maybe Boolean
  , isConnectableStart :: Maybe Boolean
  , isConnectableEnd :: Maybe Boolean
  , onConnect :: Maybe (Connection -> Effect Unit)
  , id :: Maybe String
  , className :: Maybe String
  , style :: Maybe (Object String)
  , children :: Maybe JSX
  }

handle :: Component HandleProps
```

## Behaviour

`Handle`:
1. Reads the parent node's ID via `useNodeId` (ticket 025).
2. Reads `connectable`, `connectionStart`, `connectionState`, `noPanClassName` etc. from the store via `useStore` selectors.
3. On `pointerdown`, calls `XYHandle.onPointerDown` (ticket 017) which kicks off the connection drag.
4. On `click`, when in click-connect mode, dispatches `connectionClickStartHandle` etc.
5. Renders a `<div>` with class `react-flow__handle react-flow__handle-{position}` plus connection-state classes.

## Idiomatic Notes

- **Pulls from `System.XYHandle` for all connection lifecycle.** This module is the React-side wiring; the connection logic is already ported.
- **Reads parent node ID from context.** `useNodeId` returns `Maybe String`. If `Nothing` (i.e. used outside a node), throw the `errorMessages.error010` system constant.
- **`isConnectable` defaults from the store.** If `Nothing` on props, fall back to `state.nodesConnectable && (node.connectable !== false)`. Match TS's default-resolution logic precisely.
- **Connection state class names.** TS adds `connectingfrom`, `connectingto`, `valid`, `invalid` based on the current `connection` state. Mirror exactly so upstream CSS applies.
- **Pointer-down vs click.** TS distinguishes drag-connect (pointerdown → drag) from click-connect (`onClickConnectStart`/`onClickConnectEnd`). Both paths exist; respect `state.connectOnClick`.
- **Ref forwarding.** TS uses `forwardRef`. PS uses `React.FFI.React.forwardRef` so `ref` is exposed on the props record.
- **Children optional.** Handle can wrap content (icons, etc.). Render `children` inside the div.
- **`HandleType` is `Source | Target`** — already an ADT in `System.Types.Handle` (ticket 002).
- **The exported value is `handle :: Component HandleProps`.** The TS uses `forwardRef`; the PS exported component takes a record that includes an optional `ref` field handled internally by the forwardRef helper.

## New Spago Dependencies
- None new beyond tickets 027, 032 (`react-basic-dom` for `<div>`)

## Prerequisite Tickets
- 022 (rename)
- 024 (prop types)
- 025 (`useNodeId`)
- 027 (`useStore`, `useStoreApi`)
- System ticket 017 (`XYHandle`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `handle` component exists and renders a `<div>` with the correct class names.
- Pointer-down on a `Handle` initiates a connection drag via `System.XYHandle`.
- Click-connect mode dispatches the corresponding store actions.
- `useNodeId` is consumed; if absent, `error010` is thrown.
- `isConnectable` resolution matches TS exactly.
