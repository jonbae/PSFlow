# 045 — Background

## Title
Port the `Background` add-on component plus its `Patterns` sub-module (SVG dot/grid pattern generators).

## Source Files
- `xyflow-main/packages/react/src/additional-components/Background/Background.tsx`
- `xyflow-main/packages/react/src/additional-components/Background/Patterns.tsx`
- `xyflow-main/packages/react/src/additional-components/Background/index.tsx`
- `xyflow-main/packages/react/src/additional-components/Background/types.ts`

## Target Modules
- `React.Additional.Background`
- `React.Additional.Background.Patterns`

## Key Types / Components

```purescript
data BackgroundVariant = Lines | Dots | Cross

type BackgroundProps =
  { id :: Maybe String
  , variant :: Maybe BackgroundVariant
  , gap :: Maybe (Either Number (Tuple Number Number))
  , size :: Maybe Number
  , offset :: Maybe (Either Number (Tuple Number Number))
  , color :: Maybe String
  , bgColor :: Maybe String
  , style :: Maybe (Object String)
  , className :: Maybe String
  , patternClassName :: Maybe String
  , lineWidth :: Maybe Number
  }

background :: Component BackgroundProps
linePattern :: Component LinePatternProps
dotPattern :: Component DotPatternProps
```

## Behaviour

1. Reads `state.transform` from the store.
2. Computes the `<pattern>` repeat unit (size, offset, line/dot/cross).
3. Renders an `<svg>` with a single `<pattern>` `<defs>` and a `<rect>` filled with the pattern.
4. Defaults: `variant=Dots`, `gap=20`, `size=variant-dependent`, `color=#aaa`.

## Idiomatic Notes

- **`BackgroundVariant` is an ADT.** TS has `'lines' | 'dots' | 'cross'`. Standard PS conversion.
- **`gap` and `offset` accept either `Number` or `[Number, Number]`.** Use `Either Number (Tuple Number Number)` and a small normaliser.
- **Three pattern variants.** Each renders a different SVG — `<line>` for grid, `<circle>` for dots, two crossed lines for cross. Defined in `Patterns`.
- **Pure SVG.** No DOM measurements, no FFI beyond `react-basic-dom`.
- **`useStore` selector for transform.** Recompute pattern offset based on viewport pan. Match TS computation.

## New Spago Dependencies
- None new

## Prerequisite Tickets
- 022, 024
- 027 (`useStore`)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `background` renders the correct variant.
- Pattern offset tracks viewport pan correctly.
- Default styling matches TS.
