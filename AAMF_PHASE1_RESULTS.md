# AAMF phase 1 — completed

Historical run record from November 7. That temporary workspace is no longer
available. The current, complete Step 1 inventory was rebuilt on November 9;
see [its completion report and preserved evidence](AAMF_STEP1_RESULTS.md).

Completed 2026-11-07 by resuming the successful
[phase 0 project](AAMF_PHASE0_RESULTS.md). AAMF exited **0** and checkpointed
**`completedPhases: [0, 1]`, `currentPhase: 2`**. Phase 2 was not executed.

This completes the normal phase 0/1 execution requested by
[Step 1 of the porting plan](AAMF_PORTING_PLAN.md#step-1-use-aamf-for-a-bounded-upstream-inventory).
AAMF's phases are distinct from the plan's steps: AAMF phase 1 constructs the
source task graph; the plan's Step 2 reconciles that inventory with PSFlow.

## Execution and checkpoint

```sh
export PATH="/Users/jonathanbae/.nvm/versions/node/v22.18.0/bin:/private/tmp/psflow-aamf/AAMF/node_modules/.bin:$PATH"
node /private/tmp/psflow-aamf/AAMF/dist/index.js migrate \
  -c /private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/analysis.json --resume --phase 1
node /private/tmp/psflow-aamf/AAMF/dist/index.js status \
  -c /private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/analysis.json
```

The same project, configuration, source snapshot, Node 22.18.0 toolchain, and
[Lore compatibility fixes](tools/aamf/README.md) were retained. Installed patch
hashes were verified before resuming. AAMF remains at
`7dc475d81ef9796b5b90f57a29475eaafa375753` with unchanged tracked files.

The CLI loaded resume #1 and generated the phase 1 graph in approximately
1.2 seconds. The command/status sequence took 5.36 seconds. Phase 0's database
SHA-256 and checkpoint fingerprint are unchanged: its certified index was
reused. Reported tokens were zero; no migration agent ran.

The graph is persisted as planning artifacts and structured flow-checkpoint
outputs. Both checkpoint copies of the task-graph output match the task, cycle,
and compilation-unit artifacts exactly. No checkpoint or task graph was edited
manually.

## Graph review

| Measure | Result |
|---|---:|
| Tasks / dependency edges | 120 / 460 |
| Cyclic task groups / compilation units | 4 / 0 |
| Simple / moderate / complex tasks | 74 / 37 / 9 |
| Largest task's reported lines | 653 |
| Source files directly assigned to tasks | 121 |
| Additional files retained in knowledge-base references | 32 |
| Verified re-export-only files without local definitions | 18 |
| Unaccounted scoped source files | **0** |
| File-only fallback tasks / dangling task dependencies | **0 / 0** |
| Dependency-summary files / modules / connected components | 171 / 152 / 7 |

All scoped files are accounted for: **121 + 32 + 18 = 171**. All tasks carry
structured symbols and every dependency refers to an existing task. An
independent traversal confirms that the persisted cyclic groups match the
dependency graph:

| Group | Tasks | Source files |
|---|---:|---|
| System types | 3 | `types/general.ts`, `types/nodes.ts`, `types/panzoom.ts` |
| React types | 4 | `types/edges.ts`, `types/general.ts`, `types/instance.ts`, `types/nodes.ts` |
| Pan/zoom controller | 2 | `xypanzoom/XYPanZoom.ts`, `xypanzoom/eventhandler.ts` |
| Flow containers | 2 | `container/FlowRenderer/index.tsx`, `container/ZoomPane/index.tsx` |

The index retains 56 React-to-system call edges and 324 cross-package type
references. Import records remain absent, and four duplicate-symbol groups
remain a non-blocking warning. These limits still apply to graph interpretation.

All **121 generated target paths still end in `.purescript`** and preserve
upstream's package layout. No such files were created. These paths need
reconciliation with existing `.purs` modules before code-writing phases. The
graph describes source dependencies, not remaining PSFlow behavior gaps;
successful phase 1 execution does not make it a reviewed implementation queue.

## Integrity and artifacts

Post-run hashes confirm all 1,158 copied target files and all 688 original copied
upstream files remain unchanged. The only extra upstream file remains the
analysis `tsconfig.json`. All 171 scoped files match the original vendored tree.
No port code, target scaffold, baseline, parity artifact, or allowlist changed.

| Artifact | Location |
|---|---|
| Command and exit code | [run-result.json](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/phase1-xa0fcnp_/run-result.json) |
| Runtime log | [migrate.log](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/phase1-xa0fcnp_/migrate.log) |
| Status | [status.txt](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/phase1-xa0fcnp_/status.txt) |
| Checkpoint before resume | [checkpoint-before.json](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/phase1-xa0fcnp_/checkpoint-before.json) |
| Completed phase 1 checkpoint | [checkpoint-after.json](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/phase1-xa0fcnp_/checkpoint-after.json) |
| Runtime task graph | [tasks-merged.json](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/.aamf/migration/psflow-phase0-fixed-d0j6ggeb/artifacts/planning/tasks-merged.json) |
| Cyclic groups | [sccs.json](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/.aamf/migration/psflow-phase0-fixed-d0j6ggeb/artifacts/planning/sccs.json) |
| Compilation units | [compilation-units.json](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/.aamf/migration/psflow-phase0-fixed-d0j6ggeb/artifacts/planning/compilation-units.json) |
| Dependency summary | [dependency-summary.json](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/.aamf/migration/psflow-phase0-fixed-d0j6ggeb/artifacts/planning/dependency-summary.json) |
| Graph review and artifact hashes | [graph-review.json](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/phase1-xa0fcnp_/graph-review.json) |
| Source/target integrity | [integrity-checks.json](/private/tmp/psflow-aamf/phase0-fix-d0j6ggeb/phase1-xa0fcnp_/integrity-checks.json) |

Stopped before AAMF phase 2, which is an agent-driven knowledge-base construction
phase. The project is preserved at that next checkpoint.
