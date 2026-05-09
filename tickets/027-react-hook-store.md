# 027 — Hooks: `useStore` and `useStoreApi`

## Title
Port the two foundational store hooks. All other hooks (028–031) build on these.

## Source Files
- `xyflow-main/packages/react/src/hooks/useStore.ts`

## Target Module
`React.Hook.Store`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `useStore<StateSlice>(selector, equalityFn?)` | `useStore :: forall a. Eq a => (ReactFlowState -> a) -> Hook _ a` |
| `useStoreApi()` | `useStoreApi :: Hook _ StoreApi` |

### `useStore`

```purescript
useStore :: forall a. Eq a => (ReactFlowState -> a) -> Hook _ a
useStore selector = React.do
  mStore <- useContext storeContext
  store <- case mStore of
    Nothing -> liftEffect $ throwException (error errorMessages.error001)
    Just s  -> pure s
  initial <- useMemo unit \_ -> unsafePerformEffect (selector <$> store.getState)
  Tuple value setValue <- useState initial
  useEffect store $ do
    cleanup <- store.subscribe selector (\v -> setValue (const v))
    pure cleanup
  pure value
```

(Sketch — actual implementation goes through `react-basic-hooks` discharge functions; the structure shown is conceptual. In particular, `useState`'s setter shape is `(a -> a) -> Effect Unit`.)

### `useStoreApi`

```purescript
useStoreApi :: Hook _ StoreApi
useStoreApi = React.do
  mStore <- useContext storeContext
  case mStore of
    Nothing -> unsafeThrow errorMessages.error001
    Just s  -> pure s
```

`StoreApi` is the same `Store` record exported from `React.Store.Shell`.

## Idiomatic Notes

- **Equality is implicit via `Eq`.** TS supports an optional `equalityFn` argument. PS uses the type-class instance — consumers either derive `Eq` on their selector return type, or wrap in a `newtype` with a custom instance. This is *not* a contract drift from the consumer's perspective: in TS the default behaviour is `Object.is` which corresponds to derived structural `Eq` for most records.
- **No `shallow` import.** TS's `import { shallow } from 'zustand/shallow'` is replaced by deriving `Eq`. Document this in `023-react-overview.md`.
- **Throws on missing provider.** Both hooks throw with the system-layer `errorMessages.error001` constant if called outside a `<ReactFlowProvider>`. Match TS exactly.
- **`useStoreApi` is stable across re-renders.** The store reference does not change after mount, so `useStoreApi` is effectively `const` within a session — no re-render is triggered when the store mutates. Match TS.
- **`useStore` re-renders on selector-result change only.** This is the whole point of the selector pattern. `subscribe` from the shell handles equality internally.
- **Selector function reference matters in TS.** TS users often use `useShallow(...)` or memoise the selector. PS users should pass a top-level selector (a stable reference) — document in the haddock-style comment.

## New Spago Dependencies
- `react-basic-hooks` (for `useState`, `useEffect`, `useMemo`, `useContext`)
- `effect-exception` (for `throwException`)

## Prerequisite Tickets
- 022, 024, 025, 026

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `useStore` accepts any `Eq a => ReactFlowState -> a` selector.
- `useStoreApi` returns the `Store` record from `React.Store.Shell`.
- Both hooks throw the upstream `error001` message when called outside a provider.
- `useStoreApi` reference is stable across renders.
- Re-render frequency matches TS Zustand: a `useStore (\s -> s.transform)` hook re-renders only when `transform` changes.
