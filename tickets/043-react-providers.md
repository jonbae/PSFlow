# 043 — Providers: ReactFlowProvider, BatchProvider, StoreUpdater, SelectionListener

## Title
Port the four plumbing components that wire the store, batching queue, prop sync, and selection callback aggregation.

## Source Files
- `xyflow-main/packages/react/src/components/ReactFlowProvider/index.tsx`
- `xyflow-main/packages/react/src/components/BatchProvider/index.tsx`
- `xyflow-main/packages/react/src/components/BatchProvider/useQueue.ts`
- `xyflow-main/packages/react/src/components/BatchProvider/types.ts`
- `xyflow-main/packages/react/src/components/StoreUpdater/index.tsx`
- `xyflow-main/packages/react/src/components/SelectionListener/index.tsx`

## Target Modules
- `React.Provider` — exports `reactFlowProvider`
- `React.Provider.Batch` — `batchProvider`, `useQueue`
- `React.Provider.StoreUpdater` — `storeUpdater`
- `React.Provider.SelectionListener` — `selectionListener`

## Key Components

### `reactFlowProvider`

```purescript
type ReactFlowProviderProps =
  { initialNodes :: Maybe (Array Node)
  , initialEdges :: Maybe (Array Edge)
  , defaultNodes :: Maybe (Array Node)
  , defaultEdges :: Maybe (Array Edge)
  , initialWidth :: Maybe Number
  , initialHeight :: Maybe Number
  , fitView :: Maybe Boolean
  , fitViewOptions :: Maybe FitViewOptions
  , initialMinZoom :: Maybe Number
  , initialMaxZoom :: Maybe Number
  , nodeOrigin :: Maybe NodeOrigin
  , nodeExtent :: Maybe CoordinateExtent
  , zIndexMode :: Maybe ZIndexMode
  , children :: JSX
  }

reactFlowProvider :: Component ReactFlowProviderProps
```

Behaviour:
1. `useMemo unit \_ -> createStore initialOptions` — allocate the store once.
2. Wrap children in `<storeContext.Provider value={Just store}>`.
3. Wrap the lot in `<batchProvider>` so node/edge queues are available.

### `batchProvider`

Sets up the node/edge update queues (`Ref (Array (Array Node -> Array Node))` and the edge equivalent). Provides them via `batchContext`. On every render, processes the queue: pulls all queued updaters, applies them serially over the current nodes/edges, and dispatches `SetNodes`/`SetEdges` actions if anything changed.

`useQueue` (helper hook):
```purescript
type Queue a =
  { push :: (a -> a) -> Effect Unit
  , reset :: Effect Unit
  , get :: Effect (Array (a -> a))
  }

useQueue :: forall a. Hook _ (Queue a)
```

### `storeUpdater`

Watches every `ReactFlow` prop and syncs to the store via dispatch. Long sequence of `useEffect`s, one per prop:
```purescript
useEffect [props.nodes] (dispatch (SetNodes (fromMaybe [] props.nodes)))
useEffect [props.edges] (dispatch (SetEdges (fromMaybe [] props.edges)))
useEffect [props.minZoom] (dispatch (SetMinZoom (fromMaybe 0.5 props.minZoom)))
... (~30 effects)
```

### `selectionListener`

Reads `state.onSelectionChangeHandlers`. On every change to `state.nodesSelectionActive`, gathers selected nodes/edges and fires each handler. Match TS exactly.

## Idiomatic Notes

- **Store is allocated once.** `useMemo unit` (a hook with empty deps) ensures one allocation per provider mount.
- **`BatchProvider` wraps children.** Nest order: `<reactFlowProvider> > <batchProvider> > children`.
- **`StoreUpdater` runs many `useEffect` hooks.** TS does this verbosely; PS does the same. Each `useEffect` has a single-element dep array. Don't try to "optimise" by batching — React's useEffect ordering depends on the explicit hook calls.
- **Prop sync is one-way.** From props to store. The reverse (store → callbacks like `onNodesChange`) is the reducer's job (ticket 026).
- **`SelectionListener` dedupes by Eq.** Avoid firing handlers when the selection set is identical.

## New Spago Dependencies
- None new

## Prerequisite Tickets
- 022, 024, 025, 026

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `reactFlowProvider` allocates exactly one `Store` per mount.
- `batchProvider` exposes `Queue`s via context; queued updaters apply correctly.
- `storeUpdater` dispatches actions on each tracked prop change.
- `selectionListener` fires each handler when the selection set changes (and only then).
