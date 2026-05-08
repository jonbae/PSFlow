# 001 — Geometry & Primitive Types

## Title
Port geometry primitives: positions, dimensions, rects, boxes, transforms, extents

## Source Files
- `xyflow-main/packages/system/src/types/utils.ts`

## Target Module
`XYFlow.Types.Geometry`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `type XYPosition = { x: number; y: number }` | `type XYPosition = { x :: Number, y :: Number }` |
| `type XYZPosition = XYPosition & { z: number }` | `type XYZPosition = { x :: Number, y :: Number, z :: Number }` |
| `type Dimensions = { width: number; height: number }` | `type Dimensions = { width :: Number, height :: Number }` |
| `type Rect = Dimensions & XYPosition` | `type Rect = { x :: Number, y :: Number, width :: Number, height :: Number }` |
| `type Box = XYPosition & { x2: number; y2: number }` | `type Box = { x :: Number, y :: Number, x2 :: Number, y2 :: Number }` |
| `type Transform = [number, number, number]` | `newtype Transform = Transform { tx :: Number, ty :: Number, scale :: Number }` |
| `type CoordinateExtent = [[number, number], [number, number]]` | `newtype CoordinateExtent = CoordinateExtent { minX :: Number, minY :: Number, maxX :: Number, maxY :: Number }` |
| `type NodeOrigin = [number, number]` | `newtype NodeOrigin = NodeOrigin { ox :: Number, oy :: Number }` |
| `type SnapGrid = [number, number]` | `newtype SnapGrid = SnapGrid { gx :: Number, gy :: Number }` |
| `enum Position { Left, Top, Right, Bottom }` | `data Position = PosLeft \| PosTop \| PosRight \| PosBottom` |
| `oppositePosition` | `oppositePosition :: Position -> Position` |

## Idiomatic Notes

- **Tuple-types become records.** All TS tuples-used-as-named-data (`Transform`, `CoordinateExtent`, `NodeOrigin`, `SnapGrid`) are positionally fragile. Wrap each in a `newtype` with labelled fields. This is the single most important design decision in the whole port: it prevents silent argument transposition bugs.
- **`Rect = Dimensions & XYPosition` intersection.** Since PS records are structurally typed and extensible, this can be expressed as a plain record with all four fields. No need for row-polymorphic open rows here because these are always closed, concrete record types.
- **`Position` enum.** TS enums with string values become a PS `data` type. Constructor names are prefixed with `Pos` to avoid clashing with any future `Position`-named type class constraints. Derive `Eq`, `Ord`, `Show`, `Generic`, `Bounded`, `Enum` where possible.
- **`oppositePosition`.** In TS this is a lookup object (`{ [Position.Left]: Position.Right, ... }`). In PS it is a simple pure function via pattern matching — no `Map` needed.
- Do **not** use `Int` for geometry coordinates; these are floating-point values throughout (`Number`).
- The `DistributivePick` utility type from `types/utils.ts` is a TS-specific workaround for a compiler limitation and has no PS equivalent. It can be silently dropped; anywhere it was used, a concrete record type or a row-polymorphic constraint will work.

## New Spago Dependencies
None beyond the existing `prelude`.

## Prerequisite Tickets
None — this is the root of the dependency graph.

## Acceptance Criteria
- `spago build` passes with zero warnings.
- Module `XYFlow.Types.Geometry` exports all types listed above.
- `oppositePosition` passes round-trip property test: `oppositePosition (oppositePosition p) == p` for all `Position` constructors.
- `NodeOrigin`, `SnapGrid`, `Transform`, `CoordinateExtent` each have a smart constructor and field accessors.
