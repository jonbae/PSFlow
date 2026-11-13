# AAMF phase 0 — completed

Historical run record from November 7. That temporary workspace is no longer
available. The current, complete Step 1 inventory was rebuilt on November 9;
see [its completion report and preserved evidence](AAMF_STEP1_RESULTS.md).

Completed 2026-11-07 with the maintained
[Lore compatibility fixes](tools/aamf/README.md). The real AAMF CLI exited **0**
and checkpointed **`completedPhases: [0]`, `currentPhase: 1`**. This report covers
phase 0 only. Phase 1 subsequently completed; see [its results](AAMF_PHASE1_RESULTS.md).

## Inputs and changes

- PSFlow: `04fd4f246eb02d311effbf4fb1debedcbc21ba01`.
- AAMF: `7dc475d81ef9796b5b90f57a29475eaafa375753`, with unchanged tracked files.
- Lore: 0.4.2, with the two reviewed installed-distribution fixes and helper
  applied by [the guarded installer](tools/aamf/apply-phase0-fixes.mjs).
- Upstream: `@xyflow/react` 12.11.0 / `@xyflow/system` 0.0.77; the same complete
  vendored source copy and analysis-only root TypeScript configuration.
- Toolchain: Node 22.18.0; SCIP TypeScript 0.4.0; its TypeScript parser 5.9.3.
- Project: `psflow-phase0-fixed-d0j6ggeb`.
- Isolated run: `/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/`.

This succeeds with a reproducible local tooling patch, not stock Lore 0.4.2.
No AAMF configuration threshold was increased or disabled. Span handling was
fixed at ingestion, and symbol-less-file validation now recognizes proven
re-export-only modules while preserving their raw counts. See the linked
README for the exact qualification rules and limitations.

## Execution and certification

```sh
export PATH="/Users/jonathanbae/.nvm/versions/node/v22.18.0/bin:/private/tmp/psflow-aamf/AAMF/node_modules/.bin:$PATH"
node /private/tmp/psflow-aamf/AAMF/dist/index.js migrate \
  -c /private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/analysis.json --phase 0
node /private/tmp/psflow-aamf/AAMF/dist/index.js status \
  -c /private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/analysis.json
```

The CLI confirmed `Running phases 0–0 (--phase 0)` and reported successful phase
0 indexing in 42 seconds. The total command/status sequence took 51 seconds.
No migration agent ran; reported tokens were zero.

| Certified index measure | Result |
|---|---:|
| Scoped files | 171: 44 system, 127 React |
| Symbols | 2,484 |
| Call references / internally resolved | 1,258 / 410 |
| Type references / internally resolved | 3,752 / 2,152 |
| Invalid symbol, call, and type-reference spans | **0** |
| Raw symbol-less files | 18 |
| Verified re-export-only files | 18 |
| Unexpected symbol-less files | **0** |
| Validation errors | **0** |
| Duplicate symbol groups / excess rows | 4 / 7, warning only |
| Import records | 0 |

The certified index was rebuilt and promoted by AAMF into its normal `kb.db`.
An independent validation of that promoted database also returned `ok: true`
with the migration-grade policy, valid spans required, structural coverage and
provenance required, `minCallRefs: 1`, and `maxSymbolLessFiles: 0`.

Health status is **`degraded`** because the existing duplicate-symbol warning
remains. That warning does not fail the configured policy. Empty import records
still limit import-level analysis; certification is not proof of complete
dependency or behavioral coverage.

## Regression evidence and integrity

The minimized two-file reproduction initially produced one invalid span and
one symbol-less-file error. The broader regression fixture reproduced both
same-line and multiline span failures before the fix. After the fix,
**all 13 regression tests pass**, including rejection cases for actual lost
definitions, corrupt spans, absent SCIP coverage, stale hashes, malformed or
non-export code, unresolved exports, and definition-free export cycles.

The installer was also reapplied successfully and produced identical patch
hashes. Reinstalling dependencies requires applying it again.

Post-run hash checks confirm all 1,158 target files and all 688 original copied
upstream files remain unchanged. The only extra upstream file remains the
previous analysis `tsconfig.json`. All 171 scoped files also match the original
PSFlow vendored tree. No port implementation, parity artifact, baseline,
allowlist, or target scaffold changed.

## Artifacts and next checkpoint

| Artifact | Location |
|---|---|
| Configuration | [analysis.json](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/analysis.json) |
| Command and exit code | [run-result.json](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/run-result.json) |
| Runtime log | [migrate.log](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/migrate.log) |
| Status | [status.txt](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/status.txt) |
| Phase 0 checkpoint snapshot, preserved before phase 1 | [checkpoint-before.json](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/phase1-xa0fcnp_/checkpoint-before.json) |
| Certified database | [kb.db](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/.aamf/migration/psflow-phase0-fixed-d0j6ggeb/kb.db) |
| Full health report | [index-health.json](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/index-health.json) |
| Dependency patch hashes | [compatibility-patches.json](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/compatibility-patches.json) |
| Regression results | [tests-after.log](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/tests-after.log) |
| Source/target integrity | [integrity-checks.json](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/integrity-checks.json) |

For a later authorized phase 1 run, preserve this project/configuration and use
`migrate -c <the configuration above> --resume --phase 1`. Do not start a fresh
run under this project name. Phase 1 and subsequent phases were not started
as part of this completion.
