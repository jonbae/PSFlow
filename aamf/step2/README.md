# Step 2 evidence — 2026-11-09

The [completion report](../../AAMF_STEP2_RESULTS.md) closes plan Step 2.
Step 3 was not started. The source baseline remains React 12.11.0 / system
0.0.77, with AAMF pinned to `7dc475d81ef9796b5b90f57a29475eaafa375753`.

| Artifact | Evidence |
|---|---|
| [reconciliation.json](reconciliation.json) | All 171 reviewed source units, source hashes, declarations, import/caller context, existing target modules, dispositions, work routing and target snapshot; only W01 selected |
| [review.json](review.json) | Source/target audit, exact permitted diff, 120 source-context tasks/four cycles, 23 file-context entries, stage 4/seven passthrough exports |
| [execution.json](execution.json) | Input revisions, toolchain, backend, commands, outcomes, numeric prerequisite and stop boundary |
| [integration-patches.json](integration-patches.json) | Original/patched hashes of the seven guarded AAMF build patches and adapter hash |
| [checkpoint.json](checkpoint.json) | Actual final structured AAMF checkpoint: internal phases 0–4 and exactly `psflow-w01-viewport` complete |
| [pre-pilot-checkpoint.json](pre-pilot-checkpoint.json) | Actual preparation checkpoint, before the selected code-writing task |
| [psflow-reconciliation.json](psflow-reconciliation.json) | Mapping digest and authoritative selected runtime graph |
| [psflow-phase4-discovery.json](psflow-phase4-discovery.json) | Task inventory observed by real phase-4 discovery |
| [psflow-target-files.json](psflow-target-files.json) | Refreshed target file/module/import hashes; symbol coverage explicitly null |
| [psflow-adopted-tests.json](psflow-adopted-tests.json) | Runtime execution of the unchanged, reviewed Node regression, with hash, command, TAP output and exit status |
| [resume-check.json](resume-check.json), [completed-resume.log](completed-resume.log) | Completed resume retains task identity and adds zero agent invocations |
| [stale-output-rejection.log](stale-output-rejection.log), [already-crossed-rejection.log](already-crossed-rejection.log) | Changed accepted output and duplicate pilot selection are refused |
| [adapter-tests.log](adapter-tests.log) | All eight integration regressions pass, including real phase-4/checkpoint services and failed/changed-test adoption |
| [viewport-red.log](viewport-red.log), [root-viewport.log](root-viewport.log) | All 28 JS-entry witnesses fail before crossing and pass afterward, against the rebuilt vendored oracle |
| [geometry-red.log](geometry-red.log), [geometry-green.log](geometry-green.log) | Differential NaN prerequisite observed red before its correction and green after |
| [root-checks.json](root-checks.json) | Successful checkout surface, viewport, PureScript, boundary and self-test commands |
| [root-build.log](root-build.log), [oracle-build.log](oracle-build.log), [root-fork.log](root-fork.log) | Compiler/driver provenance, vendored oracle build, and fork gate |
| [runtime.tar.gz](runtime.tar.gz) | Unmodified final source DB, structured checkpoint, planning artifacts, knowledge/plan, command logs, metrics and reports |
| [SHA256SUMS](SHA256SUMS) | Checksums of every preserved artifact |

The `root-*.log` files retain individual gate output. `baseline-*.log` records
the fresh pre-pilot build and surface gate. The initial build storage failure
is retained separately from its successful retry.

The first pilot stopped at 23/24 cases because geometry lost NaN. Its log and
input mapping are retained as `pilot-attempt1.log` and
`reconciliation-attempt1.json`; `recovery.log` records restoration through the
normal CLI. After the separately tested prerequisite, `pilot-attempt2.log`
records the existing-test attribution failure. The final `pilot-run.log`
records successful resume of the same selected graph after implementing
verified test adoption. The failed attempts are not counted as completed work.

The PSFlow base is `7e41ee8`, with the numeric prerequisite recorded through
file hashes in the reviewed input snapshot. That geometry and its property
remained read-only during the successful AAMF task. The working checkout also
refreshes the derived driver bundle at its integration point. No package,
source baseline, comparator, fixture, region, or unrelated implementation changed.

These JSON files are evidence of the original reviewed snapshot. They are not
stock AAMF configuration keys or a replacement for runtime checkpoint output.
Configurations remain in `/private/tmp/psflow-aamf-step2-20261109/`; the
successful project is `psflow-step2-pilot-20261109`. See the
[integration guide](../../AAMF_STEP2_INTEGRATION.md#execution-and-preservation)
for the supported resume command. If the workspace is lost or inputs change,
create a new isolated project and reconcile it normally; do not hand-edit
completion flags or substitute a portable JSON graph for runtime state.

With the recorded workspace present, audit it using Node 22:

```sh
node tools/aamf/inspect-step2.mjs /private/tmp/psflow-aamf-step2-20261109 aamf/step2
```

Refreshing the audit requires refreshing the runtime archive and checksums.
The Step 1 certificate/database remains independently preserved in
[aamf/step1](../step1/README.md). The integration demonstrates one bounded
completion task, not an autonomous migration of all remaining port work.
