# 026 — React Store (reducer + shell)

## Title
Replace the Zustand store with a Redux-style pure reducer and a thin `Effect`-typed shell. Implements the engine that all hooks bind against.

## Source Files
- `xyflow-main/packages/react/src/store/index.ts` (~500 LoC, the Zustand store + all 16 action methods)
- `xyflow-main/packages/react/src/store/initialState.ts`
- `xyflow-main/packages/react/src/utils/changes.ts` (`applyNodeChanges`, `applyEdgeChanges`, `createSelectionChange`, `getSelectionChanges`)

## Target Modules
- `React.Store.Action` — `Action` ADT and `Effect_` ADT
- `React.Store.Reduce` — pure `reduce` and per-action handlers
- `React.Store.InitialState` — pure initial-state builder
- `React.Store.Changes` — port of `utils/changes.ts`
- `React.Store.Shell` — `Effect`-typed shell: `Ref`, subscriptions, dispatch loop

## Key Types / Functions

### `React.Store.Action`

```purescript
data Action
  = SetNodes (Array Node)
  | SetEdges (Array Edge)
  | SetDefaultNodesAndEdges (Maybe (Array Node)) (Maybe (Array Edge))
  | UpdateNodeInternals (Map String NodeInternalsUpdate) UpdateNodeInternalsOptions
  | UpdateNodePositions (Array NodeDragItem) Boolean    -- positions, dragging
  | TriggerNodeChanges (Array NodeChange)
  | TriggerEdgeChanges (Array EdgeChange)
  | AddSelectedNodes (Array String)
  | AddSelectedEdges (Array String)
  | UnselectNodesAndEdges UnselectNodesAndEdgesParams
  | SetMinZoom Number
  | SetMaxZoom Number
  | SetTranslateExtent CoordinateExtent
  | SetNodeExtent CoordinateExtent
  | PanBy XYPosition
  | SetCenter Number Number SetCenterOptions
  | CancelConnection
  | UpdateConnection ConnectionState
  | ResetSelectedElements
  | Reset
  | PatchState (ReactFlowState -> ReactFlowState)   -- escape hatch for useStoreApi().setState

data Effect_
  = FireOnNodesChange (Array NodeChange)
  | FireOnEdgesChange (Array EdgeChange)
  | FireOnSelectionChange { nodes :: Array Node, edges :: Array Edge }
  | FireOnNodeDragStart NodeDragEventArgs
  | FireOnNodeDrag NodeDragEventArgs
  | FireOnNodeDragStop NodeDragEventArgs
  | FireOnConnect Connection
  | FireOnConnectStart OnConnectStartParams
  | FireOnConnectEnd FinalConnectionState
  | ResolveFitView
  | InvokeMiddleware (Array NodeChange) (Array EdgeChange)
  | LogError ErrorCode String     -- swallowed if state.onError is Nothing
```

### `React.Store.Reduce`

```purescript
reduce :: ReactFlowState -> Action -> { state :: ReactFlowState, effects :: Array Effect_ }
reduce state = case _ of
  SetNodes ns         -> reduceSetNodes state ns
  TriggerNodeChanges cs -> reduceTriggerNodeChanges state cs
  ...
  PatchState f        -> { state: f state, effects: [] }
```

One handler per constructor. Each handler is `ReactFlowState -> ...args -> { state, effects }`. Pure. Total. QuickCheck-able directly.

### `React.Store.InitialState`

```purescript
type InitialStateOptions =
  { nodes :: Maybe (Array Node)
  , edges :: Maybe (Array Edge)
  , defaultNodes :: Maybe (Array Node)
  , defaultEdges :: Maybe (Array Edge)
  , width :: Maybe Number
  , height :: Maybe Number
  , fitView :: Maybe Boolean
  , fitViewOptions :: Maybe FitViewOptions
  , minZoom :: Maybe Number
  , maxZoom :: Maybe Number
  , nodeOrigin :: Maybe NodeOrigin
  , nodeExtent :: Maybe CoordinateExtent
  , zIndexMode :: Maybe ZIndexMode
  }

initialState :: InitialStateOptions -> ReactFlowState
```

Pure. Builds the ~160-field record by:
1. Adopting user nodes via `System.Utils.Store.adoptUserNodes` (already returns the lookup pure-ly — see ticket 010 + the FP improvements in 021).
2. Building `edgeLookup` and `connectionLookup` via `System.Utils.Connections`.
3. Filling defaults from `Container/ReactFlow/init-values.ts` (port to `React.Container.InitValues`, ticket 042 — but the constants are referenced here, so factor them out earlier).

### `React.Store.Changes`

| TypeScript | Proposed PureScript |
|---|---|
| `applyNodeChanges(changes, nodes)` | `applyNodeChanges :: Array NodeChange -> Array Node -> Array Node` |
| `applyEdgeChanges(changes, edges)` | `applyEdgeChanges :: Array EdgeChange -> Array Edge -> Array Edge` |
| `createSelectionChange(id, selected)` | `createSelectionChange :: String -> Boolean -> SelectionChange` |
| `getSelectionChanges(items, selectedIds, mutateItems?)` | `getSelectionChanges :: forall i. SelectableLike i => Array i -> Set String -> Maybe Boolean -> { changes :: Array SelectionChange, mutated :: Maybe (Array i) }` |

Port verbatim — these are already pure in TS.

### `React.Store.Shell`

```purescript
type Store =
  { getState :: Effect ReactFlowState
  , setState :: (ReactFlowState -> ReactFlowState) -> Effect Unit
  , subscribe :: forall a. Eq a => (ReactFlowState -> a) -> (a -> Effect Unit) -> Effect (Effect Unit)
  , dispatch :: Action -> Effect Unit
  }

createStore :: InitialStateOptions -> Effect Store

-- Public alias matching upstream's StoreApi shape:
type StoreApi = Store
```

Implementation:
- One `Ref ReactFlowState` for the state.
- One `Ref (Array Listener)` for subscriptions.
- `dispatch action`:
  1. Read state.
  2. `let { state: state', effects } = reduce state action`
  3. Write `state'`.
  4. Invoke each subscriber whose selector value changed (compare via `Eq`).
  5. Run each `Effect_` value sequentially.
- `setState f` is `dispatch (PatchState f)`.
- `subscribe selector callback` returns an `Effect Unit` unsubscribe handle.

The shell is the **only** module in this ticket that uses `Effect.Ref`. Reducer and changes are pure.

## Idiomatic Notes

- **The 16 named action methods stay named.** xyflow's TS source defines them as `setNodes(nodes) { set({...}) }` closures. Each becomes one `Action` constructor + one handler. No inline `set(...)` calls; everything goes through dispatch.
- **`Effect_` is data, not `Effect Unit`.** The reducer must return effects as values so it stays pure. The shell's dispatch loop is the only place that interprets `Effect_` into actual `Effect Unit`.
- **`PatchState` is the escape hatch for `useStoreApi().setState`.** It is the only constructor that takes a function. Reducer simply calls `f state`.
- **No middleware in the reducer.** Middleware (the experimental `useOnNodesChangeMiddlewareMap`) lives in the shell — it intercepts `TriggerNodeChanges` actions before they hit the reducer. Document this divergence from the TS source where middleware lived inside the Zustand `set` wrapper.
- **Selector subscriptions use `Eq`.** No `shallow`. Consumers wanting deep equality define `derive instance Eq` on their selector return record.
- **`fitViewResolver` is `Maybe (AVar Boolean)`.** TS uses `withResolvers`; PS uses `AVar` so both `resolve` and `await` paths exist. The shell calls `AVar.put true resolver` when fitView completes.
- **Property tests live in `test/Test/React/Store/Reduce.purs`.** At minimum:
  - `reduce s ResetSelectedElements` clears all `selected` flags on nodes and edges.
  - `reduce s (SetNodes ns)` is idempotent: `reduce (reduce s a).state a == reduce s a`.
  - `reduce s (PatchState id) == { state: s, effects: [] }`.
  - `applyNodeChanges` and `applyEdgeChanges` round-trip with create/remove pairs.

## New Spago Dependencies
- `aff` (for `AVar`-based `fitViewResolver`)
- `avar`
- `quickcheck` (for property tests in this ticket)
- All system deps already available

## Prerequisite Tickets
- 022 (rename)
- 024 (types: `ReactFlowState`, `Node`, `Edge`, `Action`-arg types are all defined here or pulled from `System.*`)
- System tickets 010 (Utils.Store — `adoptUserNodes`), 012 (Utils.Connections), 008 (Utils.General — `panBy`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `reduce` is total — every `Action` constructor has a handler.
- All handlers in `React.Store.Reduce` are pure (no `Effect`, no `Aff`).
- `Store` shape matches the public TS `StoreApi` exactly: `{ getState, setState, subscribe, dispatch }` (the `dispatch` is a PS-internal addition; consumers see it via the named hook).
- Property tests in `test/` cover at least the four cases above.
- `applyNodeChanges` and `applyEdgeChanges` are byte-equivalent in behaviour to the TS source (verified by porting the upstream test fixtures).
