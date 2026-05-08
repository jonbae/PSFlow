# 014 — Toolbar Transform Utilities

## Title
Port node toolbar and edge toolbar CSS transform string generators

## Source Files
- `xyflow-main/packages/system/src/utils/node-toolbar.ts`
- `xyflow-main/packages/system/src/utils/edge-toolbar.ts`

## Target Module
`XYFlow.Utils.Toolbar`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `getNodeToolbarTransform :: (nodeRect, viewport, position, offset, align) -> string` | `getNodeToolbarTransform :: Rect -> Viewport -> Position -> Number -> Align -> String` |
| `getEdgeToolbarTransform :: (x, y, zoom, alignX?, alignY?) -> string` | `getEdgeToolbarTransform :: Number -> Number -> Number -> AlignX -> AlignY -> String` |

## Idiomatic Notes

- **Pure string generation.** Both functions are pure — they compute a CSS `transform` string from numeric inputs. No effects, no FFI.
- **`getNodeToolbarTransform` alignment offset.** The `align` parameter maps `'center' -> 0.5`, `'start' -> 0.0`, `'end' -> 1.0`. In PS this is a pure case expression on `Align`.
- **`getEdgeToolbarTransform` default arguments.** TS uses `alignX = 'center'` and `alignY = 'center'` as defaults. PS takes explicit `AlignX` and `AlignY` parameters. Provide `defaultAlignX :: AlignX = AlignXCenter` and `defaultAlignY :: AlignY = AlignYCenter` as exported constants for convenience.
- **`AlignX`, `AlignY`** from ticket 005 (Edge types) are re-used here. Import them from `XYFlow.Types.Edge`.
- **`Align`** from ticket 004 (Node types) is used in `getNodeToolbarTransform`. Import from `XYFlow.Types.Node`.
- **Output format.** The output `String` is a CSS transform value like `"translate(10px, 20px) translate(-50%, -100%)"`. This is purely a string-building exercise. Tests should verify the exact output format character-for-character.

## New Spago Dependencies
None beyond `prelude`.

## Prerequisite Tickets
- 001 (Geometry — `Rect`, `Viewport`)
- 003 (Connection — `Viewport`)
- 004 (Node types — `Align`, `Position`)
- 005 (Edge types — `AlignX`, `AlignY`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `getNodeToolbarTransform` and `getEdgeToolbarTransform` are pure functions.
- Unit tests verify pixel-exact output strings for representative inputs across all `Position`, `Align`, `AlignX`, `AlignY` combinations.
