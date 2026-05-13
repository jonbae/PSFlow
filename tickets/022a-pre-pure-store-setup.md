# 022a — Pre-Pure: Strip Refs from `System.Utils.Store`

## Title
Refactor `System.Utils.Store` to value-in / value-out signatures. Move the `Effect.Ref` ceremony out of the framework-agnostic core so the React reducer in ticket 026 can call these functions inline as pure helpers.

## Motivation

`xyflow-main/packages/system/src/utils/store.ts` mutates `Map`s in place — its six top-level functions take `Map`s and reassign entries. The current PS port at [src/System/Utils/Store.purs](../src/System/Utils/Store.purs) faithfully mirrors that idiom by wrapping each Map in `Effect.Ref`, reading, computing, writing.

That mirroring is a TS-idiom artifact, not part of the user-facing xyflow API. The external API — `<ReactFlow nodes={...} />`, `useReactFlow()`, `reactFlowInstance.setNodes(...)`, store subscriptions — never sees `System.Utils.Store` directly. It is an *internal* seam between `@xyflow/system` (framework-agnostic core) and `@xyflow/react` (adapter). Its calling convention is therefore changeable without touching any external consumer.

Ticket [026 — React Store](026-react-store.md) prescribes a Redux-style pure reducer + `Effect`-typed shell for the React side. Its "Initial State" subsection states:

> Adopting user nodes via `System.Utils.Store.adoptUserNodes` (already returns the lookup pure-ly — see ticket 010 + the FP improvements in 021).

The current `System.Utils.Store.purs` has not delivered on that "already pure" claim. Until it does, the reducer in 026 cannot be pure either — its `SetNodes` handler would have to be `Effect` solely to thread Refs into `adoptUserNodes`. This ticket closes the gap before 026 starts.

## Scope

The only file modified is [src/System/Utils/Store.purs](../src/System/Utils/Store.purs). No other PS module calls these functions yet (verified by `grep` across `src/`: only `System.Types.Node` re-exports types from this module, no behavioral calls). Clean slate.

## Signature changes

### Pure (drop `Effect` + `Ref` entirely)

```purescript
-- before
adoptUserNodes
  :: forall n
   . Array (NodeBase n)
  -> Ref (NodeLookup n)
  -> Ref (ParentLookup n)
  -> UpdateNodesOptions n
  -> Effect AdoptUserNodesReturn

-- after
adoptUserNodes
  :: forall n
   . Array (NodeBase n)
  -> NodeLookup n
  -> ParentLookup n
  -> UpdateNodesOptions n
  -> { nodeLookup :: NodeLookup n
     , parentLookup :: ParentLookup n
     , nodesInitialized :: Boolean
     , hasSelectedNodes :: Boolean
     }
```

```purescript
-- before
updateAbsolutePositions
  :: forall n
   . Ref (NodeLookup n)
  -> Ref (ParentLookup n)
  -> UpdateNodesOptions n
  -> Effect Unit

-- after
updateAbsolutePositions
  :: forall n
   . NodeLookup n
  -> ParentLookup n
  -> UpdateNodesOptions n
  -> { nodeLookup :: NodeLookup n, parentLookup :: ParentLookup n }
```

```purescript
-- before
updateConnectionLookup
  :: forall e
   . Ref ConnectionLookup
  -> Ref (EdgeLookup e)
  -> Array (EdgeBase e)
  -> Effect Unit

-- after — clears and rebuilds, so input lookups are not parameters
updateConnectionLookup
  :: forall e
   . Array (EdgeBase e)
  -> { connectionLookup :: ConnectionLookup, edgeLookup :: EdgeLookup e }
```

### Effectful but value-shaped (keeps `Effect`, drops `Ref`)

```purescript
-- before
updateNodeInternals
  :: forall n
   . Map String InternalNodeUpdate
  -> Ref (NodeLookup n)
  -> Ref (ParentLookup n)
  -> Maybe HTMLElement
  -> NodeOrigin
  -> CoordinateExtent
  -> ZIndexMode
  -> Effect { changes :: Array (NodeChange n), updatedInternals :: Boolean }

-- after
updateNodeInternals
  :: forall n
   . Map String InternalNodeUpdate
  -> NodeLookup n
  -> ParentLookup n
  -> Maybe HTMLElement
  -> NodeOrigin
  -> CoordinateExtent
  -> ZIndexMode
  -> Effect { nodeLookup :: NodeLookup n
            , parentLookup :: ParentLookup n
            , changes :: Array (NodeChange n)
            , updatedInternals :: Boolean
            }
```

`Effect` remains because `getDimensions`, `elementBoundingRect`, `getHandleBounds`, and `findViewportZoom` are genuine DOM reads. The point is not to eliminate `Effect` but to keep it *value-shaped*: input state in as a record, output state out as a record, no mutation across the API boundary.

### Unchanged

- `handleExpandParent` — already pure, value-in / value-out.
- `panBy` — already value-shaped; async stays `Aff`.

## Why this is mostly deletion, not new logic

Each function's body is already structured as `read Refs → run pure fold → write Refs`. The pure folds are intact (`updateChildNodePure`, `calculateZ`, `calculateChildXYZ`, `updateParentLookup`, `parseHandles`, `stepExpansion`, `addConnectionToLookup`, `processUpdate`). The refactor amounts to:

1. Removing the `Ref.read` lines at the top of each function.
2. Replacing them with parameters (the current Ref *contents*).
3. Removing the `Ref.write` lines at the bottom.
4. Returning the fold result as a record instead.
5. Dropping `Effect.Ref` and `Effect.Ref as Ref` imports; keeping `Effect (Effect)` only for `updateNodeInternals` (and `Effect.Aff` for `panBy`).

## Where the Refs go

[Ticket 026](026-react-store.md)'s `React.Store.Shell` owns a single `Ref ReactFlowState`. The reducer (`React.Store.Reduce`) calls the now-pure system helpers inline:

```purescript
reduceSetNodes :: ReactFlowState -> Array Node -> { state :: ReactFlowState, effects :: Array Effect_ }
reduceSetNodes state nodes =
  let
    r = adoptUserNodes nodes state.nodeLookup state.parentLookup
          { nodeOrigin: state.nodeOrigin
          , nodeExtent: state.nodeExtent
          , elevateNodesOnSelect: state.elevateNodesOnSelect
          , defaults: Nothing
          , zIndexMode: state.zIndexMode
          , checkEquality: true
          }
  in
    { state: state
        { nodes = nodes
        , nodeLookup = r.nodeLookup
        , parentLookup = r.parentLookup
        , nodesInitialized = r.nodesInitialized
        , nodesSelectionActive = state.nodesSelectionActive && r.hasSelectedNodes
        }
    , effects: [] -- or [ResolveFitView] if state.fitViewQueued && r.nodesInitialized
    }
```

`UpdateNodeInternals` is the one action whose handler returns an `Effect_` describing the DOM read; the shell runs that effect, then dispatches a follow-up `MergeNodeInternalsResult` action to fold the result back into state. This mirrors The Elm Architecture: pure update with effect descriptions, runtime interprets the effects.

## Critical files

- **Modify**: [src/System/Utils/Store.purs](../src/System/Utils/Store.purs) — six function signatures and bodies.
- **No call-site updates needed**: confirmed by grep over `src/`.
- **Imports to remove from Store.purs**: `Effect.Ref`, `Effect.Ref as Ref`. `Effect (Effect)` stays for `updateNodeInternals` only.

## Idiomatic notes

- **The public contract for adapters is records, not Refs.** Future Svelte/Solid adapters would call the same value-shaped helpers and own their own state primitive (Svelte `$state`, Solid `createSignal`). The system layer stays adapter-agnostic.
- **`updateConnectionLookup` no longer takes input lookups.** The TS source clears them at the start anyway, so the inputs were never read — they were Ref handles for the write-back. The new signature exposes this honestly.
- **No `runEffectFn1`/`runEffectFn2` wrappers.** Pure functions, ordinary application.
- **The "parent nodes must precede child nodes in input array" quirk** (the `console.warn` in TS, line 226 of `store.ts`) becomes a testable property once `adoptUserNodes` is pure: write a property that asserts the warning case returns the input unchanged for the orphaned child.

## Property tests (new file: `test/Test/System/Utils/Store.purs`)

Pure, no `Effect` plumbing required:

1. **Idempotence of `adoptUserNodes`** — running it twice on its own output yields the same result.
   ```purescript
   let r1 = adoptUserNodes ns Map.empty Map.empty opts
       r2 = adoptUserNodes ns r1.nodeLookup r1.parentLookup opts
    in r1 == r2
   ```
2. **`updateConnectionLookup` is a function of its edge array alone** — same edges, any starting state, identical lookups.
3. **`handleExpandParent []` returns `[]`** regardless of node/parent lookup contents.
4. **`updateAbsolutePositions` preserves `parentLookup`** when all nodes have `parentId == Nothing` and `extent == Nothing`.
5. **`adoptUserNodes` round-trips selection state**: `r.hasSelectedNodes == Array.any _.selected ns`.

These give the reducer in 026 a pre-vetted dependency.

## Acceptance criteria

- `spago build` from repo root passes with zero warnings.
- `spago test` passes including the new properties.
- `System.Utils.Store` imports neither `Effect.Ref` nor `Ref` in any form.
- `adoptUserNodes`, `updateAbsolutePositions`, `updateConnectionLookup`, `handleExpandParent` have no `Effect` in their return type.
- `updateNodeInternals` returns `Effect { nodeLookup, parentLookup, changes, updatedInternals }`.
- `panBy` unchanged.
- No other source file under `src/` requires modification.

## Out of scope

- Ticket 026 itself (the reducer + shell). This ticket is its enabling refactor — it makes `adoptUserNodes` et al. callable from a pure reducer.
- Any DOM porting. `updateNodeInternals` keeps `Effect` precisely so DOM stays compartmentalized.
- Touching `panBy` — already value-shaped; async is a real concern.

## Prerequisite tickets

- 010 (`System.Utils.Store` initial port)
- 021 (FP improvements that produced the current pure-inside / Ref-outside structure)
- 022 (rename to `System.*`)

## Unblocks

- 026 — the reducer can now be pure.
- Any future non-React adapter port (Svelte, Solid) — they no longer inherit the React-Ref calling convention.
