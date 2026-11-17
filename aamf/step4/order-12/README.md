# Step 4, order 12: the next baseline procedure

**Complete, 2026-11-17 UTC.** The
[baseline procedure](../../../AAMF_BASELINE_PROCEDURE.md) records the actual
execution boundary and the work a later baseline must repeat. The
[porting plan](../../../AAMF_PORTING_PLAN.md#step-4-close-the-completion-criteria),
root README and AAMF tooling guide link to it.

Steps 1 and 2 used the pinned AAMF runtime: source inventory, then one
reconciled viewport pilot. Steps 3 and 4 used PSFlow's own implementation,
review and parity workflow, with the AAMF inventory as context. They were not
an autonomous AAMF migration. Order 11's current version-2 reconciliation is
review-only; the original version-1 pilot and its checkpoint remain unchanged.

## Delivered procedure

The procedure starts from a checkout rather than an old temporary workspace.
It covers candidate pins and vendoring, source/target isolation, absolute
TypeScript aliases, frozen dependency installation, Lore patch application
and regression tests, certified inventory/import/graph review, source-to-target
reconciliation and ownership, all five gates, boundary/package checks, register
refreshes, durable artifacts, and the limits of inventory/pilot resume.

[inventory.mjs](../../../tools/aamf/inventory.mjs) automates the fresh inventory
setup and evidence preservation. It snapshots a committed target with
`git archive HEAD`, uses a separate complete source copy, builds pinned AAMF,
tests the guarded Lore fixes, and runs only internal phases 0–1. It removes an
inherited Step 2 runtime opt-in and never queues W01. New source layouts and
import exceptions require review. The current reconciliation generator is
explicitly baseline-specific; the procedure gives the inputs and invariants
to maintain for a new inventory instead of relabeling old evidence.

The guard tests execute the actual CLI and reject invalid AAMF project names,
existing state/evidence, state under the checkout and nested output paths,
including symlink aliases. Existing marker bytes must survive the failures.

## Fresh replay

The final replay used PSFlow **`82b17bec88ab42db430310edef4918064d066d10`**
and the unchanged React 12.11.0 / system 0.0.77 baseline, with Node 22.18.0
and npm 11.5.2. AAMF was cloned afresh at
`7dc475d81ef9796b5b90f57a29475eaafa375753`; its lock supplied Lore 0.4.2,
SCIP TypeScript 0.4.0 and parser 5.9.3. The source's package manager was
pnpm 10.33.4. It used no original Step 1/2 workspace or runtime state.
The upstream React release tag resolves to
`03221f25d1508130d321c498f432e2fd4f975298`; its
[tag lookup](verification/baseline-tag.txt) is preserved alongside the
scoped source hashes.

```sh
node tools/aamf/inventory.mjs \
  /private/tmp/psflow-order12-receipt-20261117 \
  aamf/step4/order-12/inventory \
  psflow-baseline-review-202611170350
```

The [command log](verification/inventory-command.log),
[execution receipt](inventory/execution.json), [review](inventory/review.json)
and [integrity checks](inventory/integrity.json) record the actual run.

| Check | Result |
|---|---|
| Isolated source and target | 171 scoped source files match the vendor; source and committed target unchanged except for the source copy's analysis tsconfig |
| Normal AAMF CLI and status | Exit 0; internal phases `[0,1]` complete, current phase 2, zero migration tokens; no later phase or agent ran |
| Certified index | 171 files, zero invalid spans, zero unexpectedly symbol-less files; 18 proven re-export-only files; four duplicate-symbol warning groups retained |
| Source graph | 120 tasks, 460 edges, four independently verified cyclic groups, zero file-only fallback tasks or dangling dependencies |
| Independent import audit | 689 declarations: 531 scoped and 158 external; zero unresolved/outside-scope imports; 80 React-to-system declarations |
| Patch regressions | All 13 real SCIP/validator tests pass in the new AAMF installation |
| Preservation | Portable JSON/logs, raw runtime archive and checksums in [inventory/](inventory/) |

This is a replay of the current baseline that verifies the procedure, not a
baseline bump or a new migration. The setup includes TS/TSX under both source
roots and excludes test/spec files of both extensions. A future release's
counts and dispositions must be reviewed from its own inputs.

## Other verification

The implementation is unchanged. Checks used PureScript 0.15.16 and Spago
1.0.4 on PATH:

| Check | Result |
|---|---|
| `node --check tools/aamf/inventory.mjs` | Passed |
| `node --test tools/aamf/inventory.test.mjs` | 3/3 passed; [guard log](verification/inventory-guards.log) |
| `node tools/aamf/refresh-reconciliation.mjs --check` | 171 units, 18 profiles, 170 Reuse/1 Accepted difference, zero tasks |
| `node --test tools/aamf/reconciliation.test.mjs` | 5/5 passed, including stale source/evidence, incomplete scope, unowned work and queued-task rejection |
| `spago build`, `npm run build:oracle` | Passed, zero compiler warnings/errors; oracle bytes unchanged; esbuild reports the existing missing vendored tsconfig bases |
| `npm run parity:surface`, then `spago test` | Passed from fresh output; stage 5, 68 crossed/zero passthroughs; [surface report](verification/surface-report.md) |
| `npm run test:ci` | 38/38 passed |
| `node parity/system/net.mjs --compare-only` | Stored 153/153 scenarios pass, 155/156 export-bearing entries driven, one declared hole; [stored-trace comparison](verification/system-rediff-report.md) |
| Local documentation links/anchors and artifact checksums | Passed |
| `git diff --cached --check` over authored source/docs | Passed; four generated captures retain their original blank lines at EOF |

The canonical surface/system reports were restored after saving these
verification reports here: their date/order and capture-vs-rediff description
changed during verification, while the parity result did not. The saved
surface report's changelog link is rebased for this directory. No canonical
trace, report, oracle, runtime module, comparison rule, fixture, region,
allowlist, historical archive or original checksum manifest is changed by
this order. No new browser capture or full browser-gate run is claimed.

The [inventory checksum manifest](inventory/SHA256SUMS) covers the generated
inventory evidence; [SHA256SUMS](SHA256SUMS) covers this record and the
verification files. From each manifest's directory, use `shasum -a 256 -c
SHA256SUMS` (or Linux `sha256sum -c SHA256SUMS`). The runtime archive preserves
raw absolute paths and checkpoint data, not a relocatable resume workspace.

All twelve Step 4 queue entries now have completion evidence within the
documented compatibility scope and issue-owned differences. Issues 207 and
208 remain separately owned. Publishing remains a separate decision.
