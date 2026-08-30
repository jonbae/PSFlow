# 058 — Layer 0 API-surface parity gaps

## Context

The **Layer 0 API-surface parity check** (`parity/surface/`, added
alongside this ticket) diffs the upstream `@xyflow/react` public export set
(extracted via the TypeScript compiler API) against PSFlow's surfaced API
(`index.js` values + `src/React.purs` type re-exports). Run it with
`npm run parity:surface`; the generated snapshot is
[`parity/surface/report.md`](../parity/surface/report.md).

Most upstream symbols map cleanly. This ticket tracks the residual **missing
in PSFlow** symbols that are *not* intentional modelling divergences (those —
change-constructor unions, `NoConnection`, renames — are documented inline in
the allowlist). They fall into two groups. Each is allowlisted against this
ticket so the parity gate stays green while the gap is tracked here; close a
row by surfacing the symbol and striking it.

Upstream baseline at filing: `@xyflow/react` 12.11.0 / `@xyflow/system` 0.0.77.
PSFlow was ported against `@xyflow/react@^12.3.5`, so some rows may be upstream
additions since 12.3.5 rather than port regressions.

**Closed.** Seventeen of the twenty-one rows are surfaced; the other four are
documented divergences, in `src/React.purs`'s header (points 6–8) and in the
allowlist. Nothing here is allowlisted against this ticket any more.

## Group A — defined in PSFlow, not surfaced through the React barrel

The type/value exists in the codebase but is not re-exported from
`src/React.purs` / `index.js`. Mostly a one-line addition to the relevant
`ReExport*` block (cf. ticket 054's mechanism).

| Symbol | Exists in PSFlow | Note |
|--------|------------------|------|
| ~~`NodeProps`~~ | `src/React/Types/Nodes.purs` | Surfaced. |
| ~~`BackgroundVariant`~~ | `src/React/Types/Component.purs` | Already surfaced when this ticket was picked up — the enum object crossed in boundary stage 1. |
| ~~`NodeHandle`~~ | `src/System/Types/Node.purs` | Surfaced. |
| ~~`MiniMapNode`~~ | `src/React/Additional/MiniMap/Node.purs` | Surfaced as a **value**, which is what an upstream value asks for: `miniMapNode` on the PureScript surface, `MiniMapNode` passthrough on the JS surface. Its shape already agrees with upstream's (memoized, arity 1), so it needed no allowlist entry. |
| ~~`MiniMapNodes`~~ | `src/React/Types/Component.purs` (as `MiniMapNodesProps`) | Upstream names it after the component, not with a `Props` suffix; surfaced as a TS-name alias. Not a component — the ticket's original note was wrong about that. |
| ~~`MiniMapNodeProps`~~ | `src/React/Types/Component.purs` | Surfaced. |
| ~~`ReactFlowStore`~~ | `src/React/Types/Store.purs` (as `ReactFlowState`) | Surfaced as a TS-name alias: PS `ReactFlowState` mirrors upstream's `ReactFlowStore` field by field, because the actions live elsewhere (below). |
| `ReactFlowActions` | — | **Documented divergence.** PS models the action half as constructors of `React.Store.Action.Action`, a sum type a pure reducer folds, so there is no record for the name to denote. |
| ~~`GeneralHelpers`~~ | `src/React/Types/Instance.purs` | Surfaced. `ReactFlowInstance` is now `GeneralHelpersRow` extended by `ViewportHelperFunctionsRow` — upstream's `&` written the PS way — instead of transcribing both halves. |
| ~~`FitViewParams`~~ | `src/System/Utils/Graph.purs` | Surfaced. |
| ~~`UseNodeConnectionsParams`~~ | `src/React/Hook/NodeConnections.purs` | Surfaced. |
| ~~`GetBezierPathParams`~~ | `src/System/Utils/Edges/Bezier.purs` (as `BezierPathParams`) | Surfaced as a TS-name alias; both names resolve. |
| ~~`GetStraightPathParams`~~ | `src/System/Utils/Edges/Straight.purs` (as `StraightPathParams`) | As above. |
| ~~`GetSmoothStepPathParams`~~ | `src/System/Utils/Edges/SmoothStep.purs` (as `SmoothStepPathParams`) | As above. |

## Group B — not modelled in PSFlow (upstream-only types)

No PSFlow equivalent exists. Decide per-row whether to model it or document
the divergence (cf. ticket 054's `NoConnection` precedent).

| Symbol | Upstream role |
|--------|---------------|
| ~~`ConnectionLineComponent`~~ | Connection-line component type. **Modelled**, as `ConnectionLineComponentProps n -> JSX` — the shape `ReactFlowProps.connectionLineComponent` has always held — rather than upstream's `ComponentType<Props>`. |
| ~~`EdgeComponentWithPathOptions`~~ | Edge component type variant. **Modelled**, and load-bearing: `BezierEdgeProps`, `SmoothStepEdgeProps` and `StepEdgeProps` are defined through it instead of restating the nineteen shared members each. |
| `BuiltInEdge` | Union of the built-in edge variants. **Documented divergence** — upstream discriminates on a string-literal `type`; PS `Edge e` carries `type :: Maybe String`, so there are no distinct types to union. |
| `BuiltInNode` | Union of the built-in node variants. **Documented divergence**, as `BuiltInEdge`. |
| ~~`GetMiniMapNodeAttribute`~~ | MiniMap node-attribute accessor type. **Modelled**; the minimap's three accessors on `MiniMapProps` and `MiniMapNodesProps` are typed through it. |
| ~~`ResizeControlProps`~~ | `NodeResizeControl` prop type. Surfaced as a TS-name alias of PS `NodeResizeControlProps`. |
| `ResizeControlLineProps` | `NodeResizeControl` line-variant prop type. **Documented divergence** — PS has no `ResizeControlLine` component; `nodeResizeControl` serves both variants off one props record, selected by `variant`. |

## Acceptance Criteria

- ✅ Each row above is either surfaced (and struck) or converted into a documented
  intentional divergence in the `src/React.purs` header + allowlist.
- ✅ `npm run parity:surface` stays green (no un-allowlisted missing exports).

## Follow-on found while closing this

Surfacing `GeneralHelpers` needed `ReactFlowInstance` to be composed from two
rows rather than written out as one literal, and the record reader the two
boundary checks share (`parity/boundary/purs.mjs`) could not follow a row. It
can now — and the first thing it found was that the `InternalNode` drift pair
had been comparing **one field out of twenty-nine**, because both sides are
`{ internals :: … | SomeRow }` and both read back as `internals` alone. The
undeclared `nodeType`/`type` rename underneath it is now declared. The reader
has a self-test of its own (`npm run test:boundary`).

The reader change is forced work — this ticket cannot close without it — but
**the blind drift pair it uncovered is not this ticket's**, and neither is the
question it raises: how many other pairs read short for reasons the reader
never reported. That deserves a ticket of its own; nothing here has looked for
a second instance.

Two things surfaced here are worth reading as narrower claims than they look,
both recorded in `src/React.purs`'s header:

- A TS-name alias makes upstream's **name** resolve; it says nothing about the
  record's members. `MiniMapNodes` reaches a record whose `nodeBorderRadius` is
  required where upstream's is optional, and no gate would see that — surface
  parity's prop comparison is name-only and covers three records, none of them
  this one.
- PS `ReactFlowState` is now knowably *narrower* than the upstream export of
  that name: it is the store half, because the actions are an ADT. Closing
  `ReactFlowStore` is what made that legible, and it is a name-only gate's
  blind spot rather than a new divergence.

## Source Files

- [parity/surface/report.md](../parity/surface/report.md) — generated snapshot
- [parity/surface/allowlist.json](../parity/surface/allowlist.json) — divergence allowlist
- [src/React.purs](../src/React.purs) — the public-API barrel
- [tickets/054-react-public-api-missing-symbols.md](054-react-public-api-missing-symbols.md) — related surface-gap tracker
