# Type contract review (Step 4 order 10)

Prepared 2026-11-16 against `@xyflow/react` 12.11.0 / `@xyflow/system` 0.0.77,
starting from PSFlow `14338761`. This is the review the
[W10 contract](AAMF_STEP2_RESULTS.md#w10--audit-remaining-type-and-boundary-contracts-by-field)
asks for: the 14 E02 units of the [reconciliation map](AAMF_STEP2_MAPPING.md),
one field and its readers at a time.

**Result.** Every member of the 14 units has a reviewed disposition. Each
guard, default and absence branch a JavaScript consumer can reach is compared
with upstream by a differential test. The comparison found 20 gaps, numbered
G1 to G20, and each is fixed: 21 commits in all, some gaps covering two or
three related branches. Two differences that are not type contracts, both found
by the same tests and both older than this order, are filed as issues. One of
them was held as a known difference by four cases at the original checkpoint.
The [rendering follow-ups](#rendering-follow-ups-207-and-208) implement both
fixes and remove that allowance.

## Method

Since [Order I](AAMF_STEP3_RESULTS.md#order-i-completion-november-13-utc),
ps-flow publishes upstream's own declarations. A field's spelling and
optionality *as declared* are therefore upstream's by construction, and a
TypeScript consumer is held to them by the compiler. What the declarations
can't certify is the runtime: whether the boundary accepts every value a
declaration admits, and whether each reader treats that value as upstream's
reader does. This review compares that, field by field.

For each field, the review reads upstream's first reader and lists the
branches a value can take there:

- **Absence and explicit `undefined`.** A destructuring default applies to
  both; `??` applies to both and to `null`.
- **`null`**, where the declaration admits it. It is often not absence:
  `KeyCode | null` turns a key off.
- **Each member of a union**: `number | [number, number]`,
  `string | (node) => string`, `boolean | number[]`, the `Padding` union.
- **The numeric domain** `number` admits: `0`, `-0`, `NaN`, fractions,
  negatives and the infinities, where a reader's `||`, `??` or arithmetic
  treats them differently.
- **Falsy guards**, such as `size || default` or `if (!label)`.
- **The rest of an `HTMLAttributes` type**, which upstream's component
  spreads onto its root element in a set order.

Three instruments compare the branches with upstream. Each runs the same
consumer code over both libraries and compares what a consumer can read back.

| Instrument | What it compares | Tests |
|---|---|---:|
| [`chrome-contracts.test.mjs`](parity/boundary/chrome-contracts.test.mjs) | A server render of each chrome component's and `<Handle />`'s markup, one value of one field per case, attributes compared as the net compares them | 317 |
| [`flow-contracts.test.mjs`](parity/boundary/flow-contracts.test.mjs) | `<ReactFlow />` mounted in Chromium, one page per side, through the new [browser harness](parity/boundary/browser/harness.mjs): the store's state and lookups, the DOM, the callbacks fired and the console, after mount and after driving with the DOM events a browser dispatches | 456 |
| Earlier boundary tests and gates | The pure functions that take E02 types, and the members earlier orders compared; the next section lists them | — |

The browser suite carries a falsification case whose two sides mount
different props and must differ. At the starting commit, 119 of 307
server-render cases and 52 of 442 browser cases differed. The
[starting results](aamf/step4/order-10/) are recorded.

A value outside a declaration stays outside the claim, as in
[Order G's exclusions](AAMF_STEP3_RESULTS.md#precise-exclusions): an enum
member that doesn't exist, a node-attribute function that returns
`undefined` where the declaration says `string`, or
`useUpdateNodeInternals()` with no argument. The boundary refuses each of
these with a message, as before.

## Scope: what earlier orders already compared

Orders G, H and I and Step 4's earlier rows compared many E02 members with
upstream. This review cites that evidence and doesn't repeat it.

| Evidence | E02 members it compares |
|---|---|
| [Order G](AAMF_STEP3_RESULTS.md#order-g-completion-november-12-utc): `store.test.mjs`, `edge-fields.test.mjs`, `Test.Boundary.DefaultEdgeOptions` | The 85 store members and 20 actions, through `useStore` and `useStoreApi`; `defaultEdgeOptions`' 23 members and their merge |
| [Order H](AAMF_STEP3_RESULTS.md#order-h-completion-november-12-utc): `references.test.mjs`, `numeric.test.mjs`, the flow-node probes | Handler payloads (`OnNodesChange`, `OnDelete`, `OnSelectionChangeParams`, the drag and mouse handlers), node component size, `NaN` and `-0` in the shared geometry |
| [Order I](AAMF_STEP3_RESULTS.md#order-i-completion-november-13-utc): `declared-minimum.test.mjs` | Every component, hook and function with only its declared required members, so every optional member's absence branch mounts |
| Step 4 rows 3, 6 and 7 | `NodeTypes` and `EdgeTypes`' `default` fallback; the selector hooks' equality; `KeyCode` at `useKeyPress`, including `[]` and the modifier option |
| `consumer-objects.test.mjs`, `reconnect-edge.test.mjs` | `NodeChange` and `EdgeChange`: every variant, `setAttributes`, `resizing`, `dragging`, and `index` |
| `viewport.test.mjs`, `node-bounds.test.mjs` | `Padding` at `getViewportForBounds`; `Rect` and `Box` at `getNodesBounds` |
| The net's [coverage](parity/system/coverage.md) | 47 callback types driven with their real arguments, 155 of 156 export-bearing entries in all |

A probe of `applyNodeChanges` and `applyEdgeChanges` over 53 change shapes
for this review, including fractional, negative, `NaN` and infinite `index`
values, matched upstream throughout, because the JavaScript entry applies
changes as upstream's does. It needed no new test.

## Field by field

Each table names a field, upstream's reader and its branches, where the
branches are compared, and the result. **Matches** means every listed branch
compares equal. A gap names the commit that fixed it, under
[Gaps found and fixed](#gaps-found-and-fixed).

### `Background/types.ts`: `BackgroundVariant`, `BackgroundProps`

Reader: `BackgroundComponent`. Compared in `chrome-contracts.test.mjs`,
`Background.*`, under each variant.

| Field | Branches | Result |
|---|---|---|
| `id` | `` `${patternId}${id ? id : ''}` ``: absent, `''`, a string | Matches |
| `color`, `bgColor` | Written into two CSS variables; absent writes none | Matches |
| `className`, `patternClassName` | Joined with `cc`; absent and `''` add nothing | Matches |
| `gap` | Default `20`; `number \| [number, number]`; `gap * zoom \|\| 1`, so `0`, `-0` and `NaN` fall back | Gap: `NaN` didn't fall back (G1) |
| `size` | `size \|\| defaultSize[variant]`: `0`, `-0`, `NaN` and absence take the variant's default | Gap: `0` and `NaN` were used as given (G1) |
| `offset` | Default `0`; `number \| [number, number]`; `offset * zoom \|\| 1 + dimension / 2` | Gap: `NaN` didn't fall back (G1) |
| `lineWidth` | Default `1`; passed to the line pattern | Matches |
| `variant` | Default `Dots`; each member picks the pattern and the default size | Matches |
| `style` | Spread under the container style | Matches |

### `Controls/types.ts`: `ControlProps`, `ControlButtonProps`

Reader: `ControlsComponent` and `ControlButton`. Compared in
`chrome-contracts.test.mjs`, `Controls.*` and `ControlButton.*`, and in the
browser cases `ControlButton: *`.

| Field | Branches | Result |
|---|---|---|
| `showZoom`, `showFitView`, `showInteractive` | Default `true`; `false` omits the buttons | Matches |
| `fitViewOptions` | Passed to `fitView` on a click; see `FitViewOptions` | Matches |
| `onZoomIn`, `onZoomOut`, `onFitView`, `onInteractiveChange` | `?.()` after the store action | Matches; the net clicks each button in `test-debt.mjs` and `retirement-debt.mjs` |
| `position` | Default `'bottom-left'`; each of the eight `PanelPosition`s | Matches |
| `children` | Drawn after the buttons | Matches |
| `style`, `className` | Passed to the panel | Matches |
| `'aria-label'` | `ariaLabel ?? ariaLabelConfig['controls.ariaLabel']` | Matches |
| `orientation` | `'horizontal'`, otherwise `'vertical'` | Matches |
| Zoom limits | `disabled` from `minZoom` and `maxZoom` | Matches |
| `ControlButtonProps` | `ButtonHTMLAttributes`: `className` and `children` destructured, every other attribute spread after `type="button"`, and React's `onClick` receives the event | Gap: the rest was dropped and `onClick` got no arguments (G14) |

### `EdgeToolbar/types.ts`: `EdgeToolbarProps`

Reader: `EdgeToolbar`, which portals, so only the browser suite sees it:
`EdgeToolbar.*` cases.

| Field | Branches | Result |
|---|---|---|
| `edgeId` | Selects the edge; a missing edge leaves `data-id` `''` and `zIndex` `1` | Matches |
| `x`, `y` | Into the transform, fractional and negative | Matches |
| `isVisible` | `typeof isVisible === 'boolean' ? isVisible : edge?.selected`, under a selected and an unselected edge | Matches |
| `alignX`, `alignY` | Default `'center'`; each of the three members | Matches |
| `className` | Joined with `cc` | Matches |
| `style` | Spread **after** the toolbar's own position, transform and `zIndex` | Gap: the computed `zIndex` won (G16) |
| `children` | Drawn inside | Matches |
| The rest of `HTMLAttributes` | Spread after `data-id` | Gap: dropped (G16) |

### `MiniMap/types.ts`: `GetMiniMapNodeAttribute`, `MiniMapProps`, `MiniMapNodes`, `MiniMapNodeProps`

Reader: `MiniMapComponent`, `MiniMapNodes` and `MiniMapNode`. Compared in
`chrome-contracts.test.mjs`, `MiniMap.*`, over a sized node, a selected node
with a background, a hidden node and an unsized one, and in the browser over a
flow whose user nodes never receive measurements.

| Field | Branches | Result |
|---|---|---|
| `nodeColor`, `nodeStrokeColor` | `string \| (node) => string`; a string also writes a CSS variable; absent is `() => undefined` | Gap: the string form threw (G9) |
| `nodeClassName` | Default `''`; the same union | Gap: the string form threw (G9) |
| `nodeBorderRadius` | Default `5` | Matches |
| `nodeStrokeWidth` | `typeof … === 'number'` writes a CSS variable; passed to each node | Matches |
| `nodeComponent` | Default `MiniMapNode`; a consumer's component gets `MiniMapNodeProps` | Matches |
| `bgColor`, `maskColor`, `maskStrokeColor` | `typeof … === 'string'` writes a CSS variable, `''` included | Matches |
| `maskStrokeWidth` | `typeof … === 'number'`, times the view scale | Matches |
| `position` | Default `'bottom-right'`; each `PanelPosition` | Matches |
| `onClick`, `onNodeClick` | Present attaches the handler | Matches |
| `pannable`, `zoomable`, `inversePan`, `zoomStep` | Defaults `false`, `false`, `undefined`, `1`; handed to `XYMinimap.update`; a drag and a wheel over the minimap with each | Matches: browser `MiniMap * — a drag` and `— a wheel` cases |
| `ariaLabel` | `string \| null`; `ariaLabel ?? config`; the title only when truthy | Gap: the boundary read `aria-label` instead (G10) |
| `offsetScale` | Default `5`; into the viewBox | Matches |
| `style` | `style.width ?? 200` and `style.height ?? 150` size the svg, string or number, and the viewBox divides by them | Gap: always 200 by 150 (G11) |
| `className` | Joined with `cc` | Matches |
| `children` | Admitted by `HTMLAttributes`, never read | Gap: drawn inside the svg (G11) |
| `MiniMapNodes`: which nodes | From `internals.userNode`: hidden, or without a size on the user node, is not drawn | Gap: read the internal node (G13) |
| `MiniMapNodeProps.x`, `y` | The internal node's `positionAbsolute` | Matches |
| `MiniMapNodeProps.width`, `height` | `getNodeDimensions(userNode)` | Gap: read the internal node (G13) |
| `MiniMapNodeProps.style` | `node.style` | Gap: always absent (G13) |
| `MiniMapNodeProps.color` | Fill is `color \|\| background \|\| backgroundColor` | Gap: an empty colour didn't fall through (G12) |
| `MiniMapNodeProps.shapeRendering` | `crispEdges` without a `window` or with `window.chrome`, else `geometricPrecision` | Gap: always `geometricPrecision` (G13) |
| `MiniMapNodeProps.selected`, `className`, `strokeColor`, `strokeWidth`, `borderRadius`, `id`, `onClick` | From the user node and the props above | Matches |

### `NodeToolbar/types.ts`: `NodeToolbarProps`

Reader: `NodeToolbar`, which portals: browser `NodeToolbar.*` cases.

| Field | Branches | Result |
|---|---|---|
| `nodeId` | `string \| string[]`; absent reads the node context; a missing id is skipped; `[]` draws nothing | Matches |
| `isVisible` | `typeof … === 'boolean'`, else one selected node of one selected | Matches |
| `position` | Default `Top`; each `Position` | Matches |
| `offset` | Default `10`; `0`, fractions, negatives | Matches |
| `align` | Default `'center'`; each `Align` | Matches |
| `className`, `style`, `children` | `style` over the wrapper style | Matches |
| The rest of `HTMLAttributes` | Spread before `data-id` | Gap: dropped (G16) |

### `BatchProvider/types.ts`: `QueueItem`, `Queue`

Internal types of the batch provider. No consumer reaches them. Their effect,
the order in which queued `setNodes` and `setEdges` updates apply, is compared
by the instance cases (`instance.*`, `onBeforeDelete: *`) and the net's
imperative scenarios. **No reviewed difference.**

### `types/component-props.ts`: `ReactFlowProps`

Readers: `ReactFlow`'s destructuring defaults, `<StoreUpdater />`, which
writes every tracked prop that is defined and changed, and `<GraphView />`
and the pane, which read the rest. Every member below has an absent case (the
`defaults` case) and an explicit-`undefined` case, and is compared in the
browser after mount; members read on input also have a driven case.

**Store members.**

| Field | Default and branches | Result |
|---|---|---|
| `nodes`, `edges` | Controlled arrays; the consumer's own arrays in the store | Matches (G and H) |
| `defaultNodes`, `defaultEdges` | Uncontrolled; `<StoreUpdater />` also writes both into the state as keys `ReactFlowState` doesn't declare | Gap: the two keys were missing (G4) |
| `defaultEdgeOptions` | Compared by Order G | Matches |
| `nodesDraggable`, `nodesConnectable`, `nodesFocusable`, `edgesFocusable`, `edgesReconnectable`, `elementsSelectable`, `snapToGrid`, `connectOnClick`, `autoPanOnConnect`, `autoPanOnNodeDrag`, `autoPanOnNodeFocus`, `selectNodesOnDrag`, `debug` | Store initial values unless defined; `true` and `false` each | Matches, one row per field in the suite |
| `elevateNodesOnSelect`, `elevateEdgesOnSelect` | Destructured defaults `true` and `false` | Matches |
| `minZoom`, `maxZoom` | Defaults `0.5` and `2`; `setMinZoom`; `0`, fractions, a minimum above the maximum | Matches |
| `nodeExtent`, `translateExtent` | Absent, finite, infinite and degenerate extents; a drag past the node extent | Matches |
| `snapGrid` | `[x, y]`, fractional; a drag with `snapToGrid` | Matches |
| `nodeOrigin` | Default `[0, 0]`; four origins | Matches |
| `connectionMode` | Default `strict`; a source dropped on a source in each mode | Matches |
| `fitView` | Queues the initial fit | Matches |
| `fitViewOptions` | Read by the queued fit, then cleared to `undefined` with `fitViewQueued` | Gap: kept after the fit, with the spent resolver (G6) |
| `noPanClassName` | Store member | Matches |
| `nodeDragThreshold`, `connectionDragThreshold` | `0`, fractions, a drag below and above | Matches |
| `autoPanSpeed`, `connectionRadius` | `0`, fractions, a release near a handle | Matches |
| `onError` | Store default `devWarn`, which warns in development, until `<StoreUpdater />` installs the consumer's | Gap: errors with no handler were dropped (G7) |
| `ariaLabelConfig` | Merged over the defaults; partial, empty and full configs, with and without keyboard support | Matches |
| `zIndexMode` | Default `'basic'`; each mode over a selected node, a selected edge and a child | Matches |
| `id` | `rfId = id \|\| '1'`, the prefix of every description id, handle `data-id` and pattern id; also written into the store | Gap: always `'1'` (G3) |
| The callback props written to the store: `onNodesChange`, `onEdgesChange`, `onConnect`, `onConnectStart`, `onConnectEnd`, `onClickConnectStart`, `onClickConnectEnd`, `onNodesDelete`, `onEdgesDelete`, `onDelete`, `onNodeDrag`, `onNodeDragStart`, `onNodeDragStop`, `onSelectionDrag`, `onSelectionDragStart`, `onSelectionDragStop`, `onMove`, `onMoveStart`, `onMoveEnd`, `isValidConnection`, `onBeforeDelete` | Present in the store; called with upstream's arguments | Matches: mount cases, the connection and deletion cases, and the net's 47 callback types |

**Members `<GraphView />` and the pane read.**

| Field | Default and branches | Result |
|---|---|---|
| `nodeTypes`, `edgeTypes` | Row 3's fallback; an unknown type warns `003` or `011` | Matches; the warnings needed G7 |
| `connectionLineType` | Default `Bezier`; each type, on a held connection | Matches |
| `connectionLineStyle`, `connectionLineContainerStyle` | On a held connection | Matches |
| `connectionLineComponent` | `ConnectionLineComponentProps`, `connectionStatus`, `toNode` and `toHandle` `null` with nothing under the pointer | Gap: `undefined` for the three (G8) |
| `deleteKeyCode`, `selectionKeyCode`, `panActivationKeyCode`, `multiSelectionKeyCode`, `zoomActivationKeyCode` | `KeyCode \| null`; defaults `'Backspace'`, `'Shift'`, `'Space'` and `Meta` or `Control`; `null` turns the key off; a string, an array, `[]`; each driven with the key | Gap: `null` threw (G2) |
| `selectionOnDrag`, `selectionMode` | Defaults `false` and `full`; a drag over one node and part of another, in each mode | Matches |
| `onlyRenderVisibleElements` | Default `false`; a node outside the viewport | Matches |
| `defaultViewport` | Default `{ x: 0, y: 0, zoom: 1 }`; a zoom outside the limits | Matches |
| `viewport`, `onViewportChange` | Controlled viewport | Matches |
| `preventScrolling`, `zoomOnScroll`, `zoomOnPinch`, `zoomOnDoubleClick` | Defaults `true`; a wheel, a pinch and a double click with each | Matches |
| `panOnScroll`, `panOnScrollSpeed`, `panOnScrollMode` | Defaults `false`, `0.5`, `free`; a diagonal wheel in each mode | Matches |
| `panOnDrag` | `boolean \| number[]`; `true`, `false`, `[0]`, `[1]`, `[2]`, `[0, 1, 2]`, `[]`, each dragged with the main and the middle button | Matches |
| `paneClickDistance`, `nodeClickDistance` | Defaults `1` and `0`; a 3-pixel drag, then a click | Matches |
| `reconnectRadius` | Default `10`; the anchor radius | Matches |
| `defaultMarkerColor` | `string \| null`, default `'#b1b1b7'` for `undefined` only; `null` and `''` draw markers with no stroke | Gap: `null` drew the default colour (G5) |
| `noDragClassName`, `noWheelClassName` | Defaults `'nodrag'`, `'nowheel'`; a drag on a marked node | Matches |
| `disableKeyboardA11y` | Descriptions and focus | Matches |
| `autoPanOnSelection` | Default `true` | Matches |
| `onInit`, the node, edge, pane and selection mouse handlers, `onReconnect*`, `onSelectionChange`, `onSelectionStart`, `onSelectionEnd`, `onSelectionContextMenu`, `onPaneScroll`, `onScroll` | Called with upstream's arguments | Matches: the mount, pane-click and node-click cases and the net |
| `width`, `height` | Initial size for a server render | Matches, server and browser |
| `colorMode` | Default `'light'`; `'dark'`, `'system'` | Matches |
| `attributionPosition`, `proOptions` | Default `'bottom-right'`; each position; `hideAttribution` | Matches |
| `className`, `style`, the rest of `HTMLAttributes` | On the wrapper `<div>` | Matches |

### `types/general.ts`

| Type | Readers and branches | Result |
|---|---|---|
| `OnNodesChange`, `OnEdgesChange`, `OnNodesDelete`, `OnEdgesDelete`, `OnDelete`, `OnSelectionChangeFunc`, `OnSelectionChangeParams`, `OnInit`, `OnBeforeDelete` | Arguments and, for `OnBeforeDelete`, each result: `true`, `false`, a subset, empty arrays | Matches: `onBeforeDelete: *` cases, Order H and the net |
| `NodeTypes`, `EdgeTypes` | Row 3 | Matches |
| `UnselectNodesAndEdgesParams` | No argument, `{}`, nodes only, edges only | Matches: `store action: unselectNodesAndEdges(*)` |
| `FitViewParams`, `FitViewOptions`, `FitView` | `padding` in each `Padding` form, `minZoom`, `maxZoom`, `nodes`, `includeHiddenNodes`, `duration`; `nodes` naming no node fits the zero rect | Gap: an empty match left the viewport alone (G15) |
| `ViewportHelperFunctions` | Every method, with and without options, and zooms past the limits | Matches |
| `IsValidConnection` | `true`, `false`, absent on a connection | Matches |

### `system/src/constants.ts`

| Member | Readers and branches | Result |
|---|---|---|
| `errorMessages` | `onError(code, message)`: unknown node and edge types, a missing handle, a missing parent, a parent extent without a parent, an unknown marker; the message for a missing handle id prints `null` | Gap: `008` was never reported, and printed `""` for `null` (G7, G17); upstream's separate missing-parent `console.warn` was missing (G18) |
| `infiniteExtent` | Default `translateExtent` | Matches |
| `elementSelectionKeys` | Keyboard selection | Matches: Order E's keyboard scenarios |
| `defaultAriaLabelConfig`, `AriaLabelConfig` | The store's merged config; every label | Matches |

### `system/src/types/changes.ts`

`NodeDimensionChange`, `NodePositionChange`, `NodeSelectionChange`,
`NodeRemoveChange`, `NodeAddChange`, `NodeReplaceChange` and the four edge
changes: every member and optional member through `applyNodeChanges` and
`applyEdgeChanges`, and the changes the store reports through the callback
cases. **Matches.**

### `system/src/types/general.ts`

| Type | Readers and branches | Result |
|---|---|---|
| `Connection` | `sourceHandle` and `targetHandle` `string \| null` in `onConnect`'s argument | Matches |
| `HandleConnection`, `NodeConnection` | The hooks' results | Matches |
| `UseNodeConnectionsParams` | `id`, `handleType`, `handleId` absent and each value; `onConnect` and `onDisconnect` skip the first run and compare by the lookup's key; `useHandleConnections` hands the handlers the lookup's connections, `edgeId` included | Gap: both handlers ran at mount, and `useHandleConnections` stripped `edgeId` (G19) |
| `ConnectionMode`, `PanOnScrollMode`, `SelectionMode`, `ColorMode`, `ZIndexMode`, `PanelPosition` | Each member | Matches |
| `OnConnectStartParams` | `nodeId`, `handleId`, `handleType`, `null` where unknown | Matches |
| `OnConnect*`, `OnReconnect*`, `OnMove*`, `OnError` | Arguments | Matches; `OnError`'s default needed G7 |
| `FitViewParamsBase`, `FitViewOptionsBase`, `Padding`, `PaddingUnit`, `PaddingWithUnit` | As `FitViewOptions`; `fitBounds`' `padding` takes the whole union | Gap: `fitBounds` read a number only and computed `NaN` for a string (G15) |
| `Viewport`, `SnapGrid`, `KeyCode`, `SetCenterOptions`, `FitBoundsOptions`, `ViewportHelperFunctionOptions` | Each option, with `ease` and both `interpolate` modes | Matches, after G2 and G15 |
| `ProOptions` | `hideAttribution`, `account` | Matches |
| `NoConnection`, `ConnectionInProgress`, `ConnectionState`, `FinalConnectionState`, `initialConnection` | The store's `connection` and `useConnection`, through a held connection | Matches |
| `ConnectionLookup` | The store's lookup | Matches |
| `OnBeforeDeleteBase` | As `OnBeforeDelete` | Matches |
| `UpdateNodeInternals` | `string \| string[]`, a missing id | Matches |
| `PanBy`, `UpdateNodePositions` | `panBy({ x, y })`, zero; drags | Matches |
| `Project`, `ZoomInOut`, `ZoomTo`, `GetZoom`, `GetViewport`, `SetViewport`, `SetCenter`, `FitBounds` | The instance methods | Matches |
| `D3ZoomInstance`, `D3SelectionInstance`, `D3ZoomHandler`, `UseDragEvent`, `SelectionRect`, `ColorModeClass`, `UpdateConnection` | Internal to the pane, drag and connection machinery | No consumer reader; their behavior is the net's |

### `system/src/types/handles.ts`: `HandleType`, `Handle`, `HandleProps`

| Field | Branches | Result |
|---|---|---|
| `Handle` | `id` `null` or a string; bounds in the lookup | Matches |
| `HandleProps.type` | Default `'source'` | Matches |
| `HandleProps.position` | Default `Top`; each `Position` | Matches |
| `HandleProps.id` | `id \|\| null`: absent, `undefined`, `null` and `''` are all `null` | Matches |
| `isConnectable`, `isConnectableStart`, `isConnectableEnd` | Defaults `true`; each class token | Matches |
| `isValidConnection`, `onConnect` | Present | Matches |
| React's `HandleProps` additions | `onMouseDown` and `onTouchStart` called after the connection starts; every other attribute spread last, an `onClick` included | Gap: all dropped (G20) |

### `system/src/types/utils.ts` and `system/src/utils/types.ts`

`Position`, `XYPosition`, `XYZPosition`, `Dimensions`, `Rect`, `Box`,
`Transform` and `CoordinateExtent` reach consumers through the members above
and through `nodeLookup`, which the browser suite compares entry for entry.
`oppositePosition` is a constant map, `DistributivePick` and `Optional` are
type-only, and `ParentExpandChild` is internal to parent expansion, which
Order H and the net's `expand-parent` fixture compare. **Matches.**

## Gaps found and fixed

Each gap is fixed in its own commit, with the cases that were red before it
green after it. G11 and G16 each fix two related gaps in one commit, because
both live in one component's render.

| | Gap | Commit |
|---|---|---|
| G1 | `Background`'s `size`, `gap` and `offset` didn't fall back on `0`, `-0` or `NaN` | Fall back on any falsy Background size, gap or offset |
| G2 | `null` on the five key-code props threw; it now turns the key off | Accept null on the five key-code props, as a key nothing presses |
| G3 | The flow's `id` never reached `rfId` | Take the flow's rfId from its id attribute |
| G4 | `defaultNodes` and `defaultEdges` were missing from the store's state | Write defaultNodes and defaultEdges into the store as upstream does |
| G5 | A `null` `defaultMarkerColor` drew the default grey | Draw default markers with no stroke when defaultMarkerColor is null |
| G6 | `fitViewOptions` and the resolver outlived the queued fit | Clear fitViewOptions and the resolver once a queued fit runs |
| G7 | Errors with no `onError` were dropped; the development gate defaulted to on | Start the store's onError at upstream's devWarn |
| G8 | A custom connection line got `undefined` where upstream passes `null` | Hand a custom connection line upstream's null members |
| G9 | `MiniMap`'s string node colour, stroke and class threw | Accept MiniMap's string node colour, stroke and class |
| G10 | `MiniMap` read `aria-label` instead of `ariaLabel` | Read MiniMap's ariaLabel, not aria-label |
| G11 | `MiniMap` ignored `style.width` and `style.height`, and drew children | Size MiniMap's svg from its style, and draw no children |
| G12 | An empty minimap node colour didn't fall through to the node's style | Fill a minimap node with the first truthy colour, as upstream does |
| G13 | Minimap nodes were read from the internal node; style and rendering hint differed | Draw minimap nodes from the consumer's node, as upstream does |
| G14 | `ControlButton` dropped its other attributes and called `onClick` with nothing | Spread ControlButton's other attributes, and hand onClick the click |
| G15 | `fitView` skipped options matching no node; `fitBounds` read only a number padding | Fit the zero rect when fitView's nodes match no node; Read fitBounds' padding as upstream's Padding union |
| G16 | Both toolbars dropped their other attributes, and `EdgeToolbar`'s `zIndex` beat the consumer's style | Spread the toolbars' other attributes, and let EdgeToolbar's style win |
| G17 | A missing edge handle was never reported as `008` | Report a missing edge handle as error 008, through upstream's onError |
| G18 | A missing parent was skipped in silence | Warn when a child node's parent is missing, as upstream does |
| G19 | The connection hooks ran their handlers at mount and `useHandleConnections` stripped `edgeId` | Call the connection hooks' handlers as upstream does |
| G20 | `Handle` dropped its other attributes and its pointer handlers | Spread Handle's other attributes last, and call its pointer handlers |

Four of these change how a mount check holds a field. `parity/boundary/mount.mjs`
no longer asserts that a `null` key code or a string `nodeColor` is refused,
and it accepts both instead. `parity/boundary/drift.mjs` names a rest field for
`ControlButtonProps`, `HandleProps` and both toolbars, and reads
`JsAriaLabelConfig` from `Boundary.FlowMembers`, where it moved so that the
flow could reach the store's JavaScript view.

## Differences routed to issues

Two differences these tests found aren't type contracts. Both are older than
this order: they are in its starting results.

- [A custom node renders once more than upstream at mount](https://github.com/jonbae/PSFlow/issues/207).
  Every custom node renders three times by the time a flow settles, where
  upstream's renders twice. `useHandleConnections`' deprecation warning,
  written on every call, showed it. The original four `useHandleConnections`
  cases held that difference; the rendering follow-up removes the allowance.
- [A node selected in place re-renders on the next store notification](https://github.com/jonbae/PSFlow/issues/208).
  Upstream mutates an internal node's `selected` in place, and ps-flow
  replaces the node, so in a controlled flow that ignores its changes the
  next notification draws the node selected on ps-flow only. The key-code
  cases run in an uncontrolled flow, where the selection applies on both
  sides.

## Evidence

This table records the original Order 10 checkpoint. The rendering follow-up's
validation is recorded separately below.

| Check | Result |
|---|---|
| `chrome-contracts.test.mjs` at the starting commit | 119 of 307 differ |
| `flow-contracts.test.mjs` at the starting commit | 52 of 442 differ |
| `chrome-contracts.test.mjs`, final | 317 of 317 pass |
| `flow-contracts.test.mjs`, final | 456 of 456 pass, four as the known difference above; the falsification case differs |
| `spago build`, `spago test` | Passed |
| `npm run parity:surface` | Passed; one more ps-flow type export, `MiniMapNodeAttribute` |
| `npm run parity:boundary` | Passed: drift with the four new rest fields, and the mount checks |
| `npm run test:boundary` | 1,029 of 1,029; 213 at Order I |
| `test:surface`, `test:harness`, `test:compare`, `test:coverage`, `test:census`, `test:ci`, `test:audit` | 30, 281, 109, 39, 5, 38 and 96 passed |
| `npm run build:package`, `parity:package`, `test:package` | Built; 10 of 10 checks; 8 of 8 tests |
| Conformance and smoke | 41 of 41 and 2 of 2 |
| Linux full net | 153 of 153 scenarios pass, every side reproducing itself; coverage 155 of 156 driven, 1 declared hole. The report and coverage file are unchanged, and the only trace values that changed are 1,443 event `timeStamp`s |

The [evidence directory](aamf/step4/order-10/) keeps the starting and final
results of both contract suites.

## What remains

Nothing in W10. At this review's completion, Step 4 rows 11 and 12 remained:
the reconciliation map's refresh and the procedure for the next baseline.
[Order 11](aamf/step4/order-11/README.md) subsequently refreshed the map;
[order 12](aamf/step4/order-12/README.md) completed the baseline procedure.
The two runtime differences above are addressed by the follow-ups below.

## Rendering follow-ups (207 and 208)

The follow-up implementation is based on PSFlow `43d08c76`, against the same
React 12.11.0 / system 0.0.77 baseline, within the existing compatibility
exclusions.

- **207:** GraphView allocated a new `Just nodeClickDistance` on each render.
  That changed NodeWrapper's prop identity and rendered an unchanged consumer
  component. Its optional representation is now memoized with `Object.is`
  equality, including `NaN`. The custom node mounts twice, as upstream's does.
- **208:** Selection kept the state object but replaced its internal nodes.
  A later notification then looked like a changed node to the wrapper.
  Selection now mutates the retained nodes and keeps the lookup object;
  their cached JavaScript views update `selected` without replacing either
  the view or its `internals`.

[`node-rendering.test.mjs`](parity/boundary/node-rendering.test.mjs) compares
both libraries in Chromium: ignored controlled changes with and without a
handler, Backspace, click then Shift-click, edge selection, unselection, and
controlled/uncontrolled/sized custom nodes. It checks retained references,
the DOM before and after a notification, and that a later user-node update
still renders. All seven original cases failed before the fixes. The
PureScript in-place selection proxy also checks lookup and node identity.

The four existing `useHandleConnections` browser cases now require equality
instead of holding the extra-render difference. Their full console, DOM,
store and callback comparisons stay enabled.

Removing the allowance exposed another mechanism mismatch in the existing
edge-add/remove case: measurement must publish its internals before triggering
uncontrolled node changes, and EdgeWrapper's position selector must retain
upstream's `useCallback` lifetime. The store now emits the second update
through `RunTriggerNodeChanges`, and the selector itself is memoized. This
preserves missing-handle and deprecation warning counts and ordering. The
measurement shell proxy failed before the update split: it observed one
notification where upstream produces two.

The full system net also caught a touch-selection callback ordering difference.
Constructing the box-selection action ran the new in-place discovery before
its `nodesChanged` guard, deselecting a node even when the action was skipped.
The action now reads its lookup and discovers changes inside the executed
effect. A store proxy reproduced this guarded-call failure before the fix;
`selection-box-touch` checks the resulting event order against upstream.
The drag reducer also retains its state when a controlled drag leaves the
connection unchanged, avoiding a notification upstream does not make. Its
real-store proxy failed before that fix.

Follow-up validation on 2026-11-17:

| Check | Result |
|---|---|
| `spago build`, `spago test` | Passed, including the guarded selection action, selection identity, measurement notification and controlled-drag proxies |
| Focused rendering and `useHandleConnections` browser regressions | 15/15 pass, with no known-difference allowance |
| `npm run parity:surface`, `npm run parity:boundary` | Passed |
| `npm run test:boundary` | 1,040/1,040 pass |
| Linux conformance and smoke suites | 41/41 and 2/2 pass |
| Linux full net | 153/153 pass; both captures reproduce on each side; coverage 155/156 driven, one declared hole |
| `npm run build:package`, `npm run parity:package` | Built; 10/10 checks pass |
| Current reconciliation and its fault-injection tests | 171 units, zero queued tasks or remaining issue-owned differences; 6/6 tests pass |

The full net used the canonical serial Linux runner and the existing fixtures
and comparison policy. Its driver was byte-identical to the local
`parity/driver/dist/psflow.js`, SHA-256
`b76f2a1bd22650e3f79e120dd442e81a96e3b17bd7e3a69c86c65894a02f769f`.
The fresh captures ran in a disposable checkout, preserving the committed
trace corpus. The report and coverage artifacts match the committed versions.
