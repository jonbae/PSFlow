# 007 — Constants

## Title
Port system-level constants: error messages, default aria label config, sentinel values

## Source Files
- `xyflow-main/packages/system/src/constants.ts`

## Target Module
`XYFlow.Constants`

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `errorMessages` (record of functions) | `data ErrorCode = E001 \| E002 \| E003 \| ... \| E015`; `errorMessage :: ErrorCode -> String` |
| `infiniteExtent :: CoordinateExtent` | `infiniteExtent :: CoordinateExtent` |
| `elementSelectionKeys :: string[]` | `elementSelectionKeys :: Array String` |
| `defaultAriaLabelConfig` (heterogeneous record with one function field) | `type AriaLabelConfig = { ... }` with the function field modelled explicitly |
| `mergeAriaLabelConfig` (from `utils/general.ts`) | `mergeAriaLabelConfig :: Partial AriaLabelConfig -> AriaLabelConfig` — see notes |

## Idiomatic Notes

- **`errorMessages`.** The TS source is a plain JS object where values are thunks or functions. In PS, make error codes a proper `data ErrorCode` type so they can be referenced at call sites without magic strings. Provide `errorMessage :: ErrorCode -> String` that builds the error string. For the few error codes that take parameters (e.g. `error003 :: (nodeType: string) => string`), use a separate `errorMessageWith :: ErrorCode -> String -> String` or per-code variants.
- **`infiniteExtent`.** This is `[[-Infinity, -Infinity], [+Infinity, +Infinity]]`. In PS, `Number` supports `infinity` via `top` and `bottom` from the `Bounded` instance or `(1.0/0.0)`. Use:
  ```purescript
  infiniteExtent :: CoordinateExtent
  infiniteExtent = CoordinateExtent { minX: (-1.0/0.0), minY: (-1.0/0.0), maxX: (1.0/0.0), maxY: (1.0/0.0) }
  ```
- **`defaultAriaLabelConfig`.** This TS object contains one function-valued field: `'node.a11yDescription.ariaLiveMessage': ({ direction, x, y }) => string`. In PS, model that field as a regular function in the record:
  ```purescript
  type AriaLabelConfig =
    { nodeA11yDescriptionDefault :: String
    , nodeA11yDescriptionKeyboardDisabled :: String
    , nodeA11yDescriptionAriaLiveMessage :: { direction :: String, x :: Number, y :: Number } -> String
    , ... remaining string fields
    }
  ```
  Field names are camelCased translations of the dot-separated TS keys. The `mergeAriaLabelConfig` function in TS uses object spread; in PS, write a `mergeAriaLabelConfig :: Partial AriaLabelConfig -> AriaLabelConfig` that overlays provided values onto the default.
- **`Partial AriaLabelConfig`.** PS does not have structural `Partial<T>`. Use `Maybe`-wrapped fields in a separate `AriaLabelConfigOverride` record or use a simple overrides approach — but since each field could individually be overridden, model overrides as a record-of-Maybe:
  ```purescript
  type AriaLabelConfigOverride =
    { nodeA11yDescriptionDefault :: Maybe String
    , ... each field wrapped in Maybe
    }
  ```
- **`process.env.NODE_ENV`.** The `devWarn` function (in `utils/general.ts`) gates on `process.env.NODE_ENV === 'development'`. In PS, pass an explicit `Boolean` `isDevMode` parameter, or provide a build-time constant via FFI. Do not replicate Node.js environment checks in pure PS.

## New Spago Dependencies
None beyond existing (`prelude`).

## Prerequisite Tickets
- 001 (for `CoordinateExtent` type)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `infiniteExtent` compiles and has correct type.
- `ErrorCode` covers all error codes E001–E015.
- `defaultAriaLabelConfig` value is exported.
- `mergeAriaLabelConfig` is a pure function.
