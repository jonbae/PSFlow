# 003 — Connection & Viewport Types

## Title
Port connection state, viewport, pan/zoom option types, and related callback aliases

## Source Files
- `xyflow-main/packages/system/src/types/general.ts`

## Target Module
`XYFlow.Types.Connection` (connection/viewport/mode types)

## Key Types / Functions

| TypeScript | Proposed PureScript |
|---|---|
| `type Connection = { source, target, sourceHandle, targetHandle }` | `type Connection = { source :: String, target :: String, sourceHandle :: Maybe String, targetHandle :: Maybe String }` |
| `type HandleConnection = Connection & { edgeId: string }` | `type HandleConnection = { source :: String, target :: String, sourceHandle :: Maybe String, targetHandle :: Maybe String, edgeId :: String }` |
| `type NodeConnection = Connection & { edgeId: string }` | same as `HandleConnection` — one shared record type |
| `enum ConnectionMode { Strict, Loose }` | `data ConnectionMode = Strict \| Loose` |
| `type Viewport = { x: number; y: number; zoom: number }` | `type Viewport = { x :: Number, y :: Number, zoom :: Number }` |
| `enum PanOnScrollMode { Free, Vertical, Horizontal }` | `data PanOnScrollMode = Free \| Vertical \| Horizontal` |
| `enum SelectionMode { Partial, Full }` | `data SelectionMode = Partial \| Full` |
| `type PanelPosition` (8-value string union) | `data PanelPosition = TopLeft \| TopCenter \| TopRight \| BottomLeft \| BottomCenter \| BottomRight \| CenterLeft \| CenterRight` |
| `type ColorModeClass = 'light' \| 'dark'` | `data ColorModeClass = Light \| Dark` |
| `type ColorMode = ColorModeClass \| 'system'` | `data ColorMode = LightMode \| DarkMode \| SystemMode` |
| `type ZIndexMode = 'auto' \| 'basic' \| 'manual'` | `data ZIndexMode = ZAuto \| ZBasic \| ZManual` |
| `type KeyCode = string \| Array<string>` | `data KeyCode = SingleKey String \| MultiKey (Array String)` |
| `type Padding` (complex union) | See idiomatic notes |
| `type ViewportHelperFunctionOptions` | `type ViewportHelperFunctionOptions = { duration :: Maybe Int, ease :: Maybe (Number -> Number), interpolate :: Maybe InterpolateMode }` |
| `type SetCenterOptions` | `type SetCenterOptions = { duration :: Maybe Int, ease :: Maybe (Number -> Number), interpolate :: Maybe InterpolateMode, zoom :: Maybe Number }` |
| `type FitBoundsOptions` | `type FitBoundsOptions = { duration :: Maybe Int, ease :: Maybe (Number -> Number), interpolate :: Maybe InterpolateMode, padding :: Maybe Number }` |
| `type SelectionRect = Rect & { startX, startY }` | `type SelectionRect = { x :: Number, y :: Number, width :: Number, height :: Number, startX :: Number, startY :: Number }` |
| `type ConnectionLookup` | `type ConnectionLookup = Map String (Map String HandleConnection)` |
| `type ConnectionState` (discriminated union) | `data ConnectionState node = NoConnection \| ConnectionInProgress (ConnectionInProgressData node)` |
| `type NoConnection` | Part of `ConnectionState` — the `NoConnection` constructor carries no fields |
| `type ConnectionInProgress` | `type ConnectionInProgressData node = { isValid :: Maybe Boolean, from :: XYPosition, fromHandle :: Handle, fromPosition :: Position, fromNode :: node, to :: XYPosition, toHandle :: Maybe Handle, toPosition :: Position, toNode :: Maybe node, pointer :: XYPosition }` |
| `initialConnection` | `noConnection :: ConnectionState node` (the value representing no connection) |
| `type FinalConnectionState` | `type FinalConnectionState node = ConnectionInProgressData node` (the `NoConnection` case can be represented as `Maybe (ConnectionInProgressData node)` at call sites) |

## Idiomatic Notes

- **`ConnectionState` discriminated union.** The TS uses literal-typed `inProgress: true/false` fields as the discriminant. In PS this becomes a proper ADT: `data ConnectionState node = NoConnection | ConnectionInProgress (ConnectionInProgressData node)`. The boolean discriminant field vanishes. Pattern matching replaces `if (state.inProgress)` checks.
- **`FinalConnectionState = Omit<ConnectionState, 'inProgress'>`.** This TS utility type trick (removing the discriminant) translates to `Maybe (ConnectionInProgressData node)` at call sites. A `Nothing` represents the no-connection state; `Just d` represents a completed connection.
- **`type Padding` union.** The TS type allows `number`, `"${number}px"`, `"${number}%"`, and an object with optional directional fields. This is a complex untagged union. Model it as:
  ```purescript
  data PaddingValue = PxPadding Number | PctPadding Number | RatioPadding Number
  data Padding
    = UniformPadding PaddingValue
    | DirectionalPadding { top :: Maybe PaddingValue, right :: Maybe PaddingValue, bottom :: Maybe PaddingValue, left :: Maybe PaddingValue, x :: Maybe PaddingValue, y :: Maybe PaddingValue }
  ```
  This is more explicit than the TS version and eliminates the need for runtime string parsing at the type boundary.
- **`type KeyCode = string | Array<string>`.** In PS, model as `data KeyCode = SingleKey String | MultiKey (NonEmptyArray String)`. Using `NonEmptyArray` instead of `Array` prevents a semantically empty multi-key.
- **Callback type aliases** (`OnMove`, `OnConnect`, `OnConnectStart`, etc.) are not exported types in PS — they are just type signatures in the function records that consume them. Do not create standalone type aliases for pure callback shapes; inline them.
- **`type ConnectionLookup = Map<string, Map<string, HandleConnection>>`.** Use `Data.Map.Map` (immutable). The keys are constructed as `"nodeId"`, `"nodeId-type"`, and `"nodeId-type-handleId"` strings. Consider a typed key `data ConnectionKey = ByNode String | ByNodeType String HandleType | ByNodeTypeHandle String HandleType String` rather than raw strings, but this can be deferred to an enhancement ticket.
- **`ProOptions`, `D3ZoomInstance`, `D3SelectionInstance`, `D3ZoomHandler`, `UseDragEvent`.** These are either internal FFI types or ergonomics types specific to the React layer. Do not port them at this stage.
- **`UpdateNodePositions`, `PanBy`, `UpdateConnection`, `OnBeforeDeleteBase`.** These are callback/function signatures used internally. Port them as type aliases only if they appear in public function signatures; otherwise inline them.

## New Spago Dependencies
- `maybe`
- `ordered-collections` (for `Data.Map`)

## Prerequisite Tickets
- 001 (Geometry)
- 002 (Handle)

## Acceptance Criteria
- `spago build` passes with zero warnings.
- `ConnectionState` ADT pattern matches exhaustively.
- `ConnectionMode`, `PanOnScrollMode`, `SelectionMode`, `PanelPosition`, `ColorMode`, `ZIndexMode` all derive `Eq`, `Show`, `Bounded`, `Enum`.
- `noConnection :: ConnectionState node` is exported.
- `Padding` ADT smart constructors cover all three TS variants.
