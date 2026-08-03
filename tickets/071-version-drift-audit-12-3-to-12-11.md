# 071 — Behavioral-drift audit: 12.3.5 → 12.11.0

## Context

PSFlow was originally ported against `@xyflow/react@^12.3.5`. The current parity
gates pin the surface and numeric behavior much closer to head than that floor
suggests:

- **Export surface** — `parity:api` verified against the vendored **12.11.0**
  (0 missing).
- **Numeric behavior** — the Layer 1 differential property tests run against the
  **vendored** `@xyflow/react` **12.11.0** / `@xyflow/system` **0.0.77**, not the
  12.3.5 floor and not `node_modules`. `oracle/esbuild.mjs` resolves every oracle
  entry against `xyflow/`, and `oracle/index.js` banners those versions; nothing
  in the repo imports `@xyflow/*` from `node_modules`. Layer 0 and Layer 1 share
  one baseline, and `package.json` exact-pins both packages to it.

So the drift risk is **not** open-ended. It is bounded to: behavior that changed
*inside* functions between 12.3.5→12.11 that is **neither** (a) pure-math covered
by Layer 1 **nor** (b) exercised by the 5 ported Layer 2 e2e specs (`nodes`,
`pane`, `edges`, `node-toolbar`, `props`).

[069](069-nodeprops-prop-member-gap.md) (the `xPos`/`yPos` →
`positionAbsoluteX`/`positionAbsoluteY` rename + new `NodeProps` members) is a
concrete instance of exactly this class of drift — it slipped through because the
prop-member diff is informational, not a gate. This ticket is the systematic
sweep for the rest.

## Method

1. Diff upstream `CHANGELOG` / release notes for `@xyflow/react` and
   `@xyflow/system` across 12.3.5 → 12.11.0 (and 0.0.x system equivalents).
2. Bucket each change:
   - **Covered** — surface-only (already gated by Layer 0), pure-math (Layer 1),
     or hit by one of the 5 e2e specs. No action.
   - **Silent gap** — behavior change in a function/component PSFlow ported but
     that no gate exercises. File a follow-up or fix inline.
3. Pay special attention to: renamed prop/field members (informational diff, not
   gated — cf. 069), default-value changes, changed event/selection semantics,
   and additions to built-in node/edge components.

## Known instances (seed list)

- **`xPos`/`yPos` → `positionAbsoluteX`/`positionAbsoluteY`** — tracked in
  [069](069-nodeprops-prop-member-gap.md).
- **New `NodeProps` members** (`width`, `height`, `parentId`, `selectable`,
  `deletable`, `draggable`) — [069](069-nodeprops-prop-member-gap.md).
- _(extend as the audit finds them)_

## Acceptance Criteria

- A written pass over the 12.3.5→12.11.0 changelogs exists, with every entry
  bucketed **covered** or **silent gap**.
- Each **silent gap** is either fixed or has its own ticket.
- Consider bumping the installed `@xyflow/react` devDependency floor (currently
  `^12.3.5`) to reflect the real tested version, so the floor stops
  understating parity.

## Source Files

- [parity/layer0-api/report.md](../parity/layer0-api/report.md) — surface +
  prop-member baseline (notes the 12.3.5 origin)
- [059](059-layer1-behavioral-parity-coverage.md) — what Layer 1 does/doesn't
  cover (bucket (a))
- `examples/react-smoke/tests/` — the 5 e2e specs (bucket (b))
- Vendored `xyflow/` 12.11.0 / 0.0.77 — the single baseline for Layer 0 *and*
  Layer 1; `package.json` exact-pins the devDeps to match
- [069](069-nodeprops-prop-member-gap.md) — first confirmed instance
