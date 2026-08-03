# 071 — Behavioral-drift audit: 12.3.5 → 12.11.0

## ✅ RESOLVED (2026-08-03)

Both acceptance criteria met, plus the standing gate the criteria implied but
did not require.

1. **The written pass exists.** All **180 in-range PRs** (154 react + 85 system
   entries, deduped) are bucketed in `parity/changelog-audit/verdicts.json` and
   rendered to `parity/changelog-audit/report.md`: **113 covered, 66 silent
   gaps, 1 n/a**. Every covered row cites a specific artifact — all 154 file
   citations were verified to resolve, and ten covered rows were spot-checked
   against the cited source.

2. **Every silent gap is fixed or ticketed.** Mechanically checkable: all 66 gap
   rows carry a `ticket` value. Two are known-wrong behavior
   ([073](073-xyresizer-drag-lifecycle-scaffold.md),
   [075](075-custom-default-node-type-fallback.md)); the rest are missing
   features ([074](074-node-edge-domattributes-ariarole.md)) or test debt
   ([076](076-test-debt-drag-selection-store.md)–[079](079-test-debt-component-chrome.md)).

3. **The devDependency floor was corrected** — and the reason it understated
   parity turned out to be worse than "the floor is stale": see correction 2
   below.

**Yield was low, as the plan predicted.** The five behavioral entries
spot-checked during planning were all already correct. The lasting output is the
gate, not the sweep:

- `npm run parity:changelog` fails on any in-range PR without a verdict, and on
  any covered verdict without evidence. This is what catches the *next* bump.
- `npm run parity:api` now **gates** prop-member divergence instead of printing
  it. That printing-not-failing behavior is precisely how the `xPos`/`yPos`
  rename survived from 12.3.5 to 12.11.0 for months
  ([069](069-nodeprops-prop-member-gap.md)).

### Two established "facts" that were wrong

Both were corrected in this ticket's first commit, since both shaped how the
work was reasoned about:

1. **Layer 1 does not test against `node_modules`.** `oracle/esbuild.mjs`
   resolves every oracle entry against the vendored tree and `oracle/index.js`
   banners 12.11.0 / 0.0.77. Nothing in the repo imports `@xyflow/*` from
   `node_modules`, so Layer 0 and Layer 1 share **one** baseline and the
   installed 12.10.2 was dead weight. This ticket and 067 both claimed numeric
   behavior was tested at 12.10.2.

2. **The `type` keyword rationale was false.** `System/Types/Node.purs` and
   `System/Types/Edge.purs` claimed `type` was renamed because it is a
   PureScript keyword. It is not — `React/Types/Nodes.purs` has declared
   `type :: String` all along. The real reason is consistency with the
   `nodeTypes`/`edgeTypes` lookup maps; realigning the data records is
   [072](072-node-edge-data-record-type-field.md).

### Scope notes

`EdgeProps.edgeType` → `type` (upstream #5531) landed here, taking all three
prop records to 0 missing / 0 extra. **Zero inline fixes** were taken from the
sweep: the one tempting candidate (#5384, a genuine one-line divergence) failed
the triage rule's gate criterion, so it became
[075](075-custom-default-node-type-fallback.md). The cap of 5 was never
approached.

Known limits, stated rather than implied: the prop gate is **name-only** (a
changed member type or arity still passes), and it does not cover the
`Node`/`Edge` data records at all — which is why
[074](074-node-edge-domattributes-ariarole.md) was invisible to it.

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
