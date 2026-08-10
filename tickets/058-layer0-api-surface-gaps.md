# 058 — Layer 0 API-surface parity gaps

## Context

The **Layer 0 API-surface parity check** (`parity/surface/`, added
alongside this ticket) diffs the upstream `@xyflow/react` public export set
(extracted via the TypeScript compiler API) against PSFlow's surfaced API
(`index.js` values + `src/React.purs` type re-exports). Run it with
`npm run parity:api`; the generated snapshot is
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

## Group A — defined in PSFlow, not surfaced through the React barrel

The type/value exists in the codebase but is not re-exported from
`src/React.purs` / `index.js`. Mostly a one-line addition to the relevant
`ReExport*` block (cf. ticket 054's mechanism).

| Symbol | Exists in PSFlow | Note |
|--------|------------------|------|
| `NodeProps` | `src/React/Types/Nodes.purs` | Asymmetric: `EdgeProps` *is* re-exported, `NodeProps` is not. |
| `BackgroundVariant` | `src/React/Types/Component.purs` | Background variant enum. |
| `NodeHandle` | `src/System/Types/Node.purs` | |
| `MiniMapNode` | `src/React/Additional/MiniMap/Node.purs` | Component (value). |
| `MiniMapNodes` | `src/React/Additional/MiniMap.purs` | Component (value). |
| `MiniMapNodeProps` | `src/React/Types/Component.purs` | |
| `ReactFlowStore` | `src/React/Types/Store.purs` | |
| `ReactFlowActions` | `src/React/Types/Store.purs` | |
| `GeneralHelpers` | `src/React/Types/Instance.purs` | |
| `FitViewParams` | `src/System/Utils/Graph.purs` | |
| `UseNodeConnectionsParams` | `src/React/Hook/NodeConnections.purs` | |
| `GetBezierPathParams` | `src/System/Utils/Edges/Bezier.purs` (as `BezierPathParams`) | `Get` prefix dropped; not surfaced. |
| `GetStraightPathParams` | `src/System/Utils/Edges/Straight.purs` (as `StraightPathParams`) | As above. |
| `GetSmoothStepPathParams` | `src/System/Utils/Edges/SmoothStep.purs` (as `SmoothStepPathParams`) | As above. |

## Group B — not modelled in PSFlow (upstream-only types)

No PSFlow equivalent exists. Decide per-row whether to model it or document
the divergence (cf. ticket 054's `NoConnection` precedent).

| Symbol | Upstream role |
|--------|---------------|
| `ConnectionLineComponent` | Connection-line component type. PSFlow surfaces `ConnectionLineComponentProps` but not the component-type alias. |
| `EdgeComponentWithPathOptions` | Edge component type variant. |
| `BuiltInEdge` | Union of the built-in edge variants. |
| `BuiltInNode` | Union of the built-in node variants. |
| `GetMiniMapNodeAttribute` | MiniMap node-attribute accessor type. |
| `ResizeControlProps` | `NodeResizeControl` prop type. |
| `ResizeControlLineProps` | `NodeResizeControl` line-variant prop type. |

## Acceptance Criteria

- Each row above is either surfaced (and struck) or converted into a documented
  intentional divergence in the `src/React.purs` header + allowlist.
- `npm run parity:api` stays green (no un-allowlisted missing exports).

## Source Files

- [parity/surface/report.md](../parity/surface/report.md) — generated snapshot
- [parity/surface/allowlist.json](../parity/surface/allowlist.json) — divergence allowlist
- [src/React.purs](../src/React.purs) — the public-API barrel
- [tickets/054-react-public-api-missing-symbols.md](054-react-public-api-missing-symbols.md) — related surface-gap tracker
