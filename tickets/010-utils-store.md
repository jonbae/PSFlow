# 010 — Store Utility Functions

## Title
Port node internals update, position adoption, connection lookup, and panBy utilities

## Source Files
- `xyflow-main/packages/system/src/utils/store.ts`
- `xyflow-main/packages/system/src/utils/types.ts`

## Target Module
`XYFlow.Utils.Store`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `updateAbsolutePositions :: (nodeLookup, parentLookup, options?) -> void` | `updateAbsolutePositions :: NodeLookup nodeData -> ParentLookup nodeData -> UpdateNodesOptions nodeData -> Effect Unit` (mutates the maps — see notes) |
| `adoptUserNodes :: (nodes, nodeLookup, parentLookup, options?) -> AdoptUserNodesReturn` | `adoptUserNodes :: Array (NodeBase nodeData) -> Ref (NodeLookup nodeData) -> Ref (ParentLookup nodeData) -> UpdateNodesOptions nodeData -> Effect { nodesInitialized :: Boolean, hasSelectedNodes :: Boolean }` |
| `updateNodeInternals :: (updates, nodeLookup, parentLookup, domNode, ...) -> { changes, updatedInternals }` | `updateNodeInternals :: Map String InternalNodeUpdate -> Ref (NodeLookup nodeData) -> Ref (ParentLookup nodeData) -> HTMLElement -> NodeOrigin -> CoordinateExtent -> ZIndexMode -> Effect { changes :: Array NodeChange, updatedInternals :: Boolean }` |
| `handleExpandParent :: (children, nodeLookup, parentLookup, nodeOrigin?) -> NodeChange[]` | `handleExpandParent :: Array ParentExpandChild -> NodeLookup nodeData -> ParentLookup nodeData -> NodeOrigin -> Array (NodeChange nodeData)` |
| `updateConnectionLookup :: (connectionLookup, edgeLookup, edges) -> void` | `updateConnectionLookup :: Ref ConnectionLookup -> Ref (EdgeLookup edgeData) -> Array (EdgeBase edgeData) -> Effect Unit` |
| `panBy :: ({delta, panZoom, transform, translateExtent, width, height}) -> Promise<boolean>` | `panBy :: XYPosition -> Maybe PanZoomInstance -> Transform -> CoordinateExtent -> Number -> Number -> Aff Boolean` |
| `isManualZIndexMode :: (zIndexMode?) -> boolean` | `isManualZIndexMode :: ZIndexMode -> Boolean` |
| `type UpdateNodesOptions` | `type UpdateNodesOptions nodeData = { nodeOrigin :: NodeOrigin, nodeExtent :: CoordinateExtent, elevateNodesOnSelect :: Boolean, defaults :: Maybe (Partial (NodeBase nodeData)), zIndexMode :: ZIndexMode, checkEquality :: Boolean }` |
| `type AdoptUserNodesReturn` | `type AdoptUserNodesReturn = { nodesInitialized :: Boolean, hasSelectedNodes :: Boolean }` |
| `type ParentExpandChild` | `type ParentExpandChild = { id :: String, parentId :: String, rect :: Rect }` (move to `XYFlow.Types.Node` or keep local) |

## Idiomatic Notes

- **Core design challenge: mutation.** This is the most mutation-heavy file in the system package. The TS code passes `Map`s by reference and mutates them in-place (`nodeLookup.clear()`, `nodeLookup.set(...)`). In PS, there are two approaches:

  **Option A (recommended): `Effect (Ref (Map k v))` pattern.** Wrap each mutable lookup in a `Ref`. Functions that update them take `Ref (NodeLookup nodeData)` and return `Effect Unit`. This mirrors the TS semantics most closely and composes well with the rest of the application state.

  **Option B: Pure, returning new maps.** Return new `Map` values instead of mutating in place. This is idiomatically cleaner but means callers must thread the new maps through. This approach makes `adoptUserNodes` a pure function: `NodeLookup -> NodeLookup -> ...`. The downside is that the calling framework (Zustand in TS) handles the assignment; without a store, callers must be disciplined.

  **Decision: start with Option A** for `adoptUserNodes` and `updateNodeInternals` since they are called by a reactive store. Use pure functions for `handleExpandParent` since it only reads maps and returns changes.

- **`adoptUserNodes` reference equality check.** TS checks `userNode === internalNode?.internals.userNode` for object identity. PS has no reference equality (`==` is structural via `Eq`). Remove this optimization; always re-compute the internal node from the user node. Performance can be addressed later if needed.
- **`updateNodeInternals` and DOM access.** This function calls `getBoundingClientRect()`, `querySelectorAll()`, and `window.getComputedStyle()`. All DOM operations must be `Effect`. The PS signature takes `HTMLElement` (from `web-html` FFI) and returns `Effect { ... }`.
- **`panBy`.** Returns `Promise<boolean>`. In PS this is `Aff Boolean`. The function calls `panZoom.setViewportConstrained(...)` which is itself `Aff`. The `panZoom :: Maybe PanZoomInstance` argument handles the null check.
- **`updateConnectionLookup`.** Mutates `connectionLookup` and `edgeLookup` in place. Takes `Ref` parameters in the `Effect` approach.
- **`mergeObjects` (internal).** A generic shallow merge utility. In PS, this is not needed because PS records are immutable and record update syntax (`{ ...existing, field: newValue }`) handles overlaying. Replace its usages with direct record construction.
- **`SELECTED_NODE_Z`, `ROOT_PARENT_Z_INCREMENT`.** Internal number constants. Define as module-level `Int` values in `XYFlow.Utils.Store`.
- **`calculateZ`, `calculateChildXYZ`, `updateChildNode`, `updateParentLookup`, `parseHandles`.** These are internal helpers. Implement as private `where` or top-level unexported functions in the module.
- **`Partial<NodeType>` in `UpdateNodesOptions.defaults`.** This is an optional partial record of node defaults to merge onto every user node. In PS, use `Maybe (NodeBase nodeData -> NodeBase nodeData)` — a function that applies defaults — or keep a concrete `NodeBase nodeData` and use record-union semantics. The function approach is more flexible.

## New Spago Dependencies
- `refs` (for `Data.IORef` / `Effect.Ref`)
- `aff`
- `maybe`
- `ordered-collections`
- `web-html` (for `HTMLElement`, DOM access)

## Prerequisite Tickets
- 001 (Geometry)
- 004 (Node types — `NodeLookup`, `ParentLookup`, `InternalNodeUpdate`)
- 005 (Edge types — `EdgeLookup`)
- 006 (PanZoom types — `PanZoomInstance`)
- 008 (Utils.General)
- 009 (Utils.Graph)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `handleExpandParent` is a pure function returning `Array (NodeChange nodeData)`.
- `panBy` has type `... -> Aff Boolean`.
- `updateConnectionLookup` operates on `Ref`-wrapped maps and returns `Effect Unit`.
- `updateNodeInternals` returns `Effect { changes :: Array NodeChange, updatedInternals :: Boolean }`.
- No reference-equality (`===`) comparisons appear anywhere in the implementation.
