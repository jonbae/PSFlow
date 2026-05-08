# 008 — General Utility Functions

## Title
Port pure geometric and coordinate utility functions

## Source Files
- `xyflow-main/packages/system/src/utils/general.ts`
- `xyflow-main/packages/system/src/utils/types.ts` (helper types)

## Target Module
`XYFlow.Utils.General`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `clamp :: (val, min?, max?) -> number` | `clamp :: Number -> Number -> Number -> Number` (min/max required, no optionals) |
| `clampPosition :: (position?, extent, dimensions) -> XYPosition` | `clampPosition :: XYPosition -> CoordinateExtent -> { width :: Maybe Number, height :: Maybe Number } -> XYPosition` |
| `clampPositionToParent :: (childPos, childDims, parent) -> XYPosition` | `clampPositionToParent :: XYPosition -> Dimensions -> InternalNodeBase nodeData -> XYPosition` |
| `calcAutoPanVelocity :: (value, min, max) -> number` | private; inlined into `calcAutoPan` |
| `calcAutoPan :: (pos, bounds, speed?, distance?) -> number[]` | `calcAutoPan :: XYPosition -> Dimensions -> Number -> Number -> { x :: Number, y :: Number }` |
| `getBoundsOfBoxes :: (box1, box2) -> Box` | `getBoundsOfBoxes :: Box -> Box -> Box` |
| `rectToBox :: (rect) -> Box` | `rectToBox :: Rect -> Box` |
| `boxToRect :: (box) -> Rect` | `boxToRect :: Box -> Rect` |
| `nodeToRect :: (node, nodeOrigin?) -> Rect` | `nodeToRect :: Either (NodeBase nodeData) (InternalNodeBase nodeData) -> NodeOrigin -> Rect` |
| `nodeToBox :: (node, nodeOrigin?) -> Box` | `nodeToBox :: Either (NodeBase nodeData) (InternalNodeBase nodeData) -> NodeOrigin -> Box` |
| `getBoundsOfRects :: (rect1, rect2) -> Rect` | `getBoundsOfRects :: Rect -> Rect -> Rect` |
| `getOverlappingArea :: (rectA, rectB) -> number` | `getOverlappingArea :: Rect -> Rect -> Number` |
| `isRectObject :: (obj) -> boolean` | Not ported — runtime type guard, unnecessary in typed PS |
| `isNumeric :: (n) -> boolean` | `isNumeric :: Number -> Boolean` (just `not isNaN && isFinite`) — or inline as needed |
| `devWarn :: (id, message) -> void` | `devWarn :: Boolean -> String -> String -> Effect Unit` (takes `isDev` flag) |
| `snapPosition :: (position, snapGrid?) -> XYPosition` | `snapPosition :: XYPosition -> SnapGrid -> XYPosition` |
| `pointToRendererPoint :: (pos, transform, snapToGrid?, snapGrid?) -> XYPosition` | `pointToRendererPoint :: XYPosition -> Transform -> Boolean -> SnapGrid -> XYPosition` |
| `rendererPointToPoint :: (pos, transform) -> XYPosition` | `rendererPointToPoint :: XYPosition -> Transform -> XYPosition` |
| `parsePadding :: (padding, viewport) -> number` | private — inlined into `getViewportForBounds` |
| `parsePaddings :: (padding, width, height) -> {...}` | private — inlined |
| `getViewportForBounds :: (bounds, width, height, minZoom, maxZoom, padding) -> Viewport` | `getViewportForBounds :: Rect -> Number -> Number -> Number -> Number -> Padding -> Viewport` |
| `isMacOs :: () -> boolean` | `isMacOs :: Effect Boolean` (reads `navigator.userAgent`) |
| `isCoordinateExtent :: (extent?) -> boolean` | `isCoordinateExtent :: Maybe NodeExtent -> Maybe CoordinateExtent` (returns `Nothing` for parent/null) |
| `getNodeDimensions :: (node) -> { width, height }` | `getNodeDimensions :: { measured :: Maybe { width :: Maybe Number, height :: Maybe Number }, width :: Maybe Number, height :: Maybe Number, initialWidth :: Maybe Number, initialHeight :: Maybe Number } -> Dimensions` |
| `nodeHasDimensions :: (node) -> boolean` | `nodeHasDimensions :: NodeBase nodeData -> Boolean` |
| `evaluateAbsolutePosition :: (position, dimensions, parentId, nodeLookup, nodeOrigin) -> XYPosition` | `evaluateAbsolutePosition :: XYPosition -> Dimensions -> String -> NodeLookup nodeData -> NodeOrigin -> XYPosition` |
| `areSetsEqual :: (a, b) -> boolean` | `areSetsEqual :: Set String -> Set String -> Boolean` |
| `withResolvers :: () -> { promise, resolve, reject }` | Not ported — this is a Promise utility. Equivalent pattern in PS is `Aff`'s built-in. |
| `mergeAriaLabelConfig` | Moved to ticket 007 |
| `Optional<T, K>` utility type | Not ported — TS structural utility, not needed |
| `ParentExpandChild` | `type ParentExpandChild = { id :: String, parentId :: String, rect :: Rect }` |

## Idiomatic Notes

- **`clamp`.** TS signature `(val, min = 0, max = 1)` uses default parameters. PS takes all three arguments explicitly. Provide `clamp01 :: Number -> Number` as a convenience alias for the `[0, 1]` case.
- **`calcAutoPan` return type.** TS returns `number[]` (a 2-element array). In PS return `{ x :: Number, y :: Number }` — named fields are safer.
- **`nodeToRect` and `nodeToBox`.** TS uses a runtime check (`isInternalNodeBase`) to decide which path to take. In PS, accept `Either (NodeBase nodeData) (InternalNodeBase nodeData)` to make the distinction explicit at the type level.
- **`isMacOs`.** This reads the DOM's `navigator.userAgent`, making it effectful. It must be `Effect Boolean`, not a pure function. At call sites, thread it through `Effect`.
- **`isCoordinateExtent`.** TS is a type guard `(extent?) => extent is CoordinateExtent`. In PS, this becomes a conversion function: given `Maybe NodeExtent`, return `Maybe CoordinateExtent` (returning `Nothing` if the extent is `ParentExtent` or absent). This is total and eliminates the type guard pattern entirely.
- **`withResolvers`.** This polyfill for `Promise.withResolvers` is purely about managing async promise lifecycles. It has no PS equivalent because `Aff` handles this differently. Any code that uses `withResolvers` should be rewritten using `AVar` from `aff-avar` or by restructuring the async flow.
- **`devWarn`.** The TS version checks `process.env.NODE_ENV`. In PS, accept a `Boolean` `isDev` parameter so callers can thread the development mode flag without environment coupling. Alternatively, provide a `devWarn` that is `Effect Unit` and always logs, letting callers guard it. The former approach is cleaner.
- **`evaluateAbsolutePosition`.** TS performs a mutable lookup on a `Map`. The PS version is pure: it reads from an immutable `Map` and returns `XYPosition`. It cannot fail to find the parent — if the parent is absent, the input position is returned unchanged (match TS behavior).

## New Spago Dependencies
- `maybe`
- `either`
- `ordered-collections` (for `Set`)
- `effect`

## Prerequisite Tickets
- 001 (Geometry types)
- 003 (Connection — for `Padding`, `Viewport`)
- 004 (Node types — for `NodeBase`, `InternalNodeBase`, etc.)
- 007 (Constants — for `AriaLabelConfig`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `clamp` is a total pure function.
- `getViewportForBounds` passes tests matching the TS behavior for symmetric and asymmetric padding.
- `isMacOs :: Effect Boolean` — confirmed in the type signature.
- No `isRectObject` or `isNumeric` type-guards appear in the exported API.
- `pointToRendererPoint` and `rendererPointToPoint` are inverses: `rendererPointToPoint (pointToRendererPoint p t false (SnapGrid 1 1)) t == p`.
