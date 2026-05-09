# 025 — React Contexts

## Title
Port the three React contexts: `StoreContext`, `NodeIdContext`, `BatchContext`.

## Source Files
- `xyflow-main/packages/react/src/contexts/StoreContext.ts`
- `xyflow-main/packages/react/src/contexts/NodeIdContext.ts`
- `xyflow-main/packages/react/src/components/BatchProvider/index.tsx` (the `BatchContext` definition lives inside)

## Target Modules
- `React.Context.Store`
- `React.Context.NodeId`
- `React.Context.Batch`

## Key Types / Functions

### `React.Context.Store`

| TypeScript | Proposed PureScript |
|---|---|
| `const StoreContext = createContext<StoreApi \| null>(null)` | `storeContext :: ReactContext (Maybe StoreApi)` (from `React.FFI.React.createContext`) |
| `useContext(StoreContext)` | `useContext storeContext` returning `Hook _ (Maybe StoreApi)` |
| (consumed by `useStore`) | exposed as a single `storeContext` value plus a private `Provider` JSX wrapper |

### `React.Context.NodeId`

| TypeScript | Proposed PureScript |
|---|---|
| `const NodeIdContext = createContext<string \| null>(null)` | `nodeIdContext :: ReactContext (Maybe String)` |
| `export function useNodeId()` | `useNodeId :: Hook _ (Maybe String)` — public, re-exported from `React.purs` |
| `Provider` (re-exported as `Provider` from the module) | `nodeIdProvider :: Maybe String -> JSX -> JSX` |

### `React.Context.Batch`

| TypeScript | Proposed PureScript |
|---|---|
| `BatchContext = createContext<BatchContextType \| null>(null)` | `batchContext :: ReactContext (Maybe BatchContext)` |
| `useBatchContext()` | `useBatchContext :: Hook _ BatchContext` (asserts non-null; throws if used outside provider) |
| `BatchContextType` (the shape) | `type BatchContext = { nodeQueue :: Queue (Array Node), edgeQueue :: Queue (Array Edge) }` where `Queue a` is defined in the same module |

The `Queue a` shape (per `useQueue.ts`):
```purescript
type Queue a =
  { push :: (a -> a) -> Effect Unit
  , reset :: Effect Unit
  , get :: Effect (Array (a -> a))
  }
```

## Idiomatic Notes

- **`createContext` lives in the FFI layer.** `React.FFI.React.createContext :: forall a. a -> Effect (ReactContext a)`. PureScript type variable `a` must be `Maybe X` for nullable contexts to keep the API total.
- **Provider wrappers.** Each context module exports a `provider :: a -> JSX -> JSX` helper that wraps the children in `<Context.Provider value={a}>`. This keeps the FFI usage one-line and centralised.
- **`useNodeId` is public.** It's re-exported from `React.purs` (ticket 049) as part of the public surface. The other contexts and hooks are internal.
- **`useBatchContext` asserts non-null.** Throws with `errorMessages.error001` (system constant) if called outside a `BatchProvider`. Match the TS source.
- **The `Queue` is a `Ref (Array (a -> a))`.** Internally implemented as `Ref` + helper functions; not a separate datatype.
- **No `forwardRef` here.** Contexts are values, not components.

## New Spago Dependencies
- `react-basic` (for `ReactContext`, `JSX`)
- `react-basic-hooks` (for `useContext`)
- `refs` (already a dep — for `Queue`)

## Prerequisite Tickets
- 022 (rename)
- 024 (`StoreApi`, `Node`, `Edge` types are referenced)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `useNodeId` is exported from `React.Context.NodeId` and matches the TS signature: `Hook _ (Maybe String)`.
- `useBatchContext` throws (via `unsafeThrow` or `Effect.Exception.throwException`) when used outside a `BatchProvider`, matching TS behaviour.
- `storeContext`, `nodeIdContext`, `batchContext` are not directly exported from `React.purs` — only the hooks that consume them.
