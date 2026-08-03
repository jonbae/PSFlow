# 074 — `domAttributes` and `ariaRole` are not carried on nodes/edges

## Context

Found by the [071](071-version-drift-audit-12-3-to-12-11.md) changelog sweep;
both are pre-existing, already-documented deviations rather than new drift.

Two in-range upstream PRs add per-element escape hatches that PSFlow does not
model:

| PR | Upstream change |
|---|---|
| [#5317](https://github.com/xyflow/xyflow/pull/5317) | Add `domAttributes` option for nodes and edges |
| [#5299](https://github.com/xyflow/xyflow/pull/5299) | Add `ariaRole` prop to nodes and edges |

Neither field exists on `NodeBase` / `EdgeBase`, so neither wrapper can honour
it. Both wrappers already say so in their fidelity notes:

- `src/React/Component/NodeWrapper.purs:33` — "`node.domAttributes` spread and
  `node.ariaRole` aren't carried on `NodeBase` yet."
- `src/React/Component/EdgeWrapper.purs:27` — "`edge.ariaRole` /
  `edge.domAttributes` / `edge.reconnectable` aren't carried on `EdgeBase`; the
  wrapper substitutes `"img"`/`"group"` for `role`, skips the dom-attribute
  spread, and keys reconnect off the global `edgesReconnectable` flag alone."

Note the third field in that second list: **`edge.reconnectable`** is missing
too, and for the same reason. It is not attached to an in-range changelog entry,
so the sweep did not surface it independently, but it belongs to this cluster.

These do not appear in the Layer 0 prop diff because they live on the `Node` /
`Edge` data records, which that diff does not compare — it covers
`ReactFlowProps`, `NodeProps` and `EdgeProps` only. Worth noting as a real
blind spot in the current gate, distinct from the name-only limit already
documented in `parity/layer0-api/report.md`.

## Related

[#5472](https://github.com/xyflow/xyflow/pull/5472) ("Remove
`dangerouslySetInnerHTML` from `domAttributes`") is upstream hardening the
attribute spread this ticket would introduce. Implement the spread with that
exclusion already in place rather than porting the vulnerability and the fix in
sequence.

## Scope

- Add `domAttributes`, `ariaRole` (and `reconnectable`) to `NodeBase` /
  `EdgeBase` as appropriate.
- Spread `domAttributes` in both wrappers, excluding `dangerouslySetInnerHTML`
  per #5472.
- Use `ariaRole` where each wrapper currently hard-codes `role`.
- Key edge reconnection off `edge.reconnectable` with the global
  `edgesReconnectable` flag as the fallback.

## Acceptance criteria

- Both wrappers honour all three fields; the fidelity notes in
  `NodeWrapper.purs` and `EdgeWrapper.purs` are updated to drop them.
- A Layer 2 spec asserts a custom `ariaRole` and a spread `domAttributes` entry
  reach the DOM, and that `dangerouslySetInnerHTML` does not.
- Consider extending the Layer 0 prop diff to cover the `Node`/`Edge` data
  records, which is what would have caught this mechanically.
- `npm run parity:api`, `spago test`, `npm run test:smoke` stay green.
- PRs #5317 and #5299 flip from `not-ported` to a covered bucket in
  `parity/changelog-audit/verdicts.json`.

## Source files

- `src/System/Types/Node.purs`, `src/System/Types/Edge.purs`
- `src/React/Component/NodeWrapper.purs:33`, `src/React/Component/EdgeWrapper.purs:27`
- `parity/layer0-api/prop-types.mjs` — where data-record coverage would be added
