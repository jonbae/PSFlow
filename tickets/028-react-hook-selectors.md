# 028 — Hooks: Selector wrappers

## Title
Port the thin selector hooks: `useNodes`, `useEdges`, `useViewport`, `useConnection`, `useNodesData`, `useInternalNode`, `useNodesInitialized`, `useNodeId`. Each is a one- or two-line `useStore` wrapper.

## Source Files
- `xyflow-main/packages/react/src/hooks/useNodes.ts`
- `xyflow-main/packages/react/src/hooks/useEdges.ts`
- `xyflow-main/packages/react/src/hooks/useViewport.ts`
- `xyflow-main/packages/react/src/hooks/useConnection.ts`
- `xyflow-main/packages/react/src/hooks/useNodesData.ts`
- `xyflow-main/packages/react/src/hooks/useInternalNode.ts`
- `xyflow-main/packages/react/src/hooks/useNodesInitialized.ts`
- (`useNodeId` already covered by ticket 025; re-export from `React.purs` only)

## Target Module
`React.Hook.Selectors` (one module, one section per hook)

## Key Functions

| TypeScript | Proposed PureScript |
|---|---|
| `useNodes<NodeType>(): NodeType[]` | `useNodes :: Hook _ (Array Node)` |
| `useEdges<EdgeType>(): EdgeType[]` | `useEdges :: Hook _ (Array Edge)` |
| `useViewport(): { x, y, zoom }` | `useViewport :: Hook _ Viewport` |
| `useConnection(selector?, eq?)` | `useConnection :: Hook _ ConnectionState` (no-arg form) <br/> `useConnectionWith :: forall a. Eq a => (ConnectionState -> a) -> Hook _ a` (selector form) |
| `useNodesData<T>(ids)` | `useNodesData :: Array String -> Hook _ (Array Node)` |
| `useInternalNode(id)` | `useInternalNode :: String -> Hook _ (Maybe InternalNode)` |
| `useNodesInitialized(opts?)` | `useNodesInitialized :: Maybe UseNodesInitializedOptions -> Hook _ Boolean` |

## Idiomatic Notes

- **All thin wrappers over `useStore`.** Each is one to five lines. Example:
  ```purescript
  useNodes = useStore _.nodes

  useViewport = useStore \s ->
    let Tuple3 x y zoom = s.transform
    in { x, y, zoom }

  useInternalNode id = useStore (\s -> Map.lookup id s.nodeLookup)
  ```
- **`useConnection` has two TS overloads.** TS exposes `useConnection()` returning the full state, plus `useConnection(selector, eq?)` returning a selected slice. PS splits these into two named functions to keep types clean. Document the divergence in the module comment.
- **`useNodesData` deduplicates IDs.** Match the TS source's behaviour: build a `Set String` first, then look up each.
- **`useNodesInitialized` short-circuits.** Returns `false` as soon as one node has missing measurements. Use `Array.all` over `nodeLookup`.
- **Selector functions are top-level values.** Use `where`-bound selectors when possible so the function reference is stable across re-renders.
- **No `Effect` in the public type signature.** Selectors are pure. Side-effecting hooks are in tickets 029 (listeners) and 031 (internal effects).

## New Spago Dependencies
- None beyond ticket 027

## Prerequisite Tickets
- 027 (`useStore`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- All seven hooks listed above exist with the proposed PS signatures.
- `useViewport` returns a `Viewport` record with the same field names as the TS source (`{ x, y, zoom }`).
- `useNodesData` deduplicates IDs.
- Each hook re-renders only when its selected slice changes (verified by an integration smoke-test in ticket 049).
