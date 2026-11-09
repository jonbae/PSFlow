# AAMF Step 2 — integration contract

Reviewed 2026-11-07 against PSFlow `04fd4f246eb02d311effbf4fb1debedcbc21ba01`
and AAMF [`7dc475d81ef9796b5b90f57a29475eaafa375753`](https://github.com/jafreck/AAMF/tree/7dc475d81ef9796b5b90f57a29475eaafa375753).
This records the integration portion of
[Step 2](AAMF_PORTING_PLAN.md#step-2-reconcile-the-inventory-with-the-existing-port).
It is a design for later implementation, not an installed adapter or an
executable AAMF configuration. No code, checkpoint, target index, or migration
runtime state was changed to produce it.

## Decision

Keep AAMF in analysis-only use for this snapshot. Use its diagnostic graph as
source context for the reviewed PSFlow work queue. Complete later port tasks
through PSFlow's existing workflow until the requirements below are implemented
and verified in a separate AAMF integration change. The original docs-only
scope permits this reconciliation, but does not permit implementing that
adapter or executing the code-writing pilot.

This decision does not claim that a full adapter would cost more than the
remaining port; neither has been estimated. It avoids making integration work
a prerequisite for documenting the existing port. It is also not a completed
autonomous AAMF migration.

## Prerequisite: a certified source index

The [Step 1 results](AAMF_STEP1_RESULTS.md#why-aamf-certification-fails) record
103 invalid symbol spans and 18 files containing only re-exports. The normal
pipeline stopped in phase 0; its 120-task diagnostic graph is uncertified.
AAMF's phase 0 policy requires valid spans, structural indexing, provenance,
successful indexers, and zero symbol-less files. The migration configuration
schema permits only zero for the overall symbol-less threshold.
[Policy](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/flow/steps/kb-indexing.ts#L67-L74),
[schema](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/config/schema.ts#L20-L23).

Before a normal migration run, fix the recorded span interpretation and provide
an explicit, validated representation or policy for re-export-only modules.
Keep all 171 source files accounted for. Regression evidence must cover an
identifier before an initializer's enclosing range and the 18 barrel files.
Then repeat the normal phase 0/1 run with the same pins, source hashes, and
absolute source aliases. Do not rename the diagnostic database to `kb.db` or
mark either phase complete manually.

## Verified capability and missing integration

| Concern | What the pinned implementation does | Required integration |
|---|---|---|
| Target paths | Replaces the extension and retains upstream package paths; no PureScript extension entry | Map to explicit existing `.purs` destinations; do not create a parallel package tree |
| Task selection | Builds source-derived tasks; `MigrationTask` has files, symbols, dependencies and acceptance criteria, but no reuse disposition | Apply reviewed dispositions before constructing the executable write queue |
| Runtime inventory | Phase 4 first uses the phase 1 step output, then context structured output, then filesystem fallbacks | Publish one reconciled graph consistently through the actual step output and persisted state |
| Target context | Builds Lore with LSP disabled; agents also receive source and target file paths | Prove PureScript symbol coverage, or explicitly supply file-based target context without a PureScript-index claim |
| Existing project | Phase 3 can launch a planner and generate/build scaffold files | Add and verify a deliberate existing-project route that preserves PSFlow's setup |
| File ownership | Per-task flow adds predecessors for shared `targetFiles` | Supply canonical, complete target write paths so this existing protection sees overlaps |

Sources: [path mapper](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/core/task-graph-builder.ts#L1648-L1665),
[task contract](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/agents/types.ts#L395-L451),
[task discovery](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/flow/steps/migration.ts#L1285-L1309),
[target indexer](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/core/target-indexer.ts#L33-L35),
[agent input files](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/agents/context-builder.ts#L187-L205),
[scaffolding](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/flow/steps/planning.ts#L105-L147),
[overlap scheduling](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/flow/steps/migration.ts#L171-L185).

## Proposed adapter contract

These are requirements for a future maintained integration, not configuration
keys accepted by stock AAMF.

1. Identify the reconciliation by source package versions, source-file hashes,
   PSFlow commit, AAMF commit, and a mapping revision or digest. Reject a stale
   mapping when any of these inputs changes.
2. Record source file and symbol identities independently of provisional AAMF
   task IDs. Retain the diagnostic task IDs only as traceability references;
   task clustering may change after the source index is fixed.
3. Resolve each source unit to existing target modules, boundary converters,
   necessary FFI, reference files, evidence, and permitted outputs. Permit
   many-to-many mappings. Resolve paths beneath the designated target root,
   reject escapes, and canonicalize aliases before checking overlaps.
4. Treat `reuse` and `accepted difference` as context, not write tasks. Reuse
   means an existing implementation is the starting point; it does not certify
   all behavior. An accepted difference needs its own reason and issue/region
   evidence. Keep `add evidence` separate from demonstrated behavior defects.
5. Construct gap-sized tasks only for the remaining reviewed work. Preserve
   required source dependency and cycle context. When a dependency is reused,
   retain it as reference context rather than inventing a migration task or
   falsely marking one completed.
6. Include all permitted code, boundary, manifest and named test outputs in
   each task's ownership set. Serialize tasks whose sets overlap. Use
   `maxParallelAgents: 1` and `per-task` for the pilot. The existing per-task
   flow already augments source dependencies with overlapping target writers;
   the adapter must provide correct paths rather than duplicate that mechanism.
7. Make the selected graph authoritative for phase 4 and checkpoint/resume.
   Refuse a changed mapping digest on resume until dependent outputs and task
   completion state have been deliberately invalidated through a supported
   integration path.

The per-task overlap mechanism is wired into task-node dependencies in
[migration.ts](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/flow/steps/migration.ts#L590-L610).
It depends on exact filenames, so two spellings of the same file must not
create independent ownership entries.

## Runtime handoff and resume

The appropriate integration seam is the deterministic task-graph result,
before it is consumed by later phases. Phase 1 writes `tasks-merged.json`,
`sccs.json` and `compilation-units.json`, creates
`ctx.phase1TaskGraphResult.extensions.structuredOutput`, and returns the graph.
Phase 4 receives that step output directly from the parent flow.
[Phase 1 output](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/flow/steps/task-graph.ts#L80-L107),
[phase 4 handoff](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/flow/migration-flow.ts#L113-L122).

A future adapter must therefore publish the same reconciled tasks, cycles and
compilation-unit metadata through all authoritative outputs. Editing only
`tasks-merged.json` is insufficient: direct step output takes precedence, and
filesystem JSON is only a fallback when the relevant step/context output is
unavailable. Dependencies on omitted task IDs are dropped by the current
normalizer, so retained source context must be represented deliberately rather
than left as dangling task dependencies.
[Discovery and normalization](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/flow/steps/migration.ts#L1285-L1325).

Checkpoint snapshots persist both step outputs and execution outputs while
reconstructing runtime service context on resume. The nested phase 4 flow has
its own checkpoint. Adapter acceptance must inspect the task set seen by phase
4 on a fresh run and after an interrupted resume, not just compare disk JSON.
[Checkpoint adapter](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/flow/checkpoint-adapter.ts#L40-L68),
[nested checkpoint](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/flow/checkpoint-adapter.ts#L79-L111).

Required integration evidence: exactly the selected pilot appears; a reused
geometry implementation never enters the write queue; interruption preserves
the same mapping and task identity; completion skips only that completed task;
a stale mapping is rejected; shared output files impose a predecessor. None of
these adapter behaviors has been implemented or tested in this docs session.

## Target context and project preservation

PureScript target symbol coverage has not been demonstrated. A successful Lore
build over PSFlow's JavaScript FFI would not establish `.purs` coverage. A later
integration may either prove extraction and queries for representative
PureScript definitions and their references, or explicitly operate with
file-based target context.

For the file-based route, provide the reviewed `.purs` files, their module
exports/imports, boundary/FFI counterparts, and caller files as explicit agent
inputs with paths and snapshot hashes. Label these as file context, not
resolved target symbols. Refresh that context after changes and invalidate it
after rollback. Stock AAMF's code-migrator already includes `targetFiles` in
`inputFiles`; attaching additional read-only target dependencies and selecting
an honest target-index mode still needs integration verification.
[Existing input route](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/agents/context-builder.ts#L187-L205).

Preserve PSFlow's Spago and npm setup, module names, package entry points and
existing assets. A maintained existing-project route should explicitly bypass
scaffold generation while preserving truthful phase state; manually setting
`scaffoldComplete` is not that route. Also constrain the phase 3 planner's
outputs. An empty diagnostic compilation-unit list happens to avoid the
current scaffold loop, but does not establish a durable preservation contract.
[Planner and scaffold lifecycle](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/flow/steps/planning.ts#L50-L147).

Verify project preservation with before/after file hashes in a disposable
copy. Require `npx spago build`, the relevant local regression, surface parity,
and boundary checks for a future code pilot, following [README.md](README.md)
and [PORTING.md](PORTING.md#proving-a-port). AAMF's agent verdict is additional
review, not a replacement for those commands.

## Pilot specification: cross `getViewportForBounds`

**Status: specified only; not executed.** The core computation already exists
in [System.Utils.General](src/System/Utils/General.purs#L248). The missing
crossing remains in [the manifest's passthrough list](src/Boundary.js#L165)
and [Boundary's raw imports](src/Boundary.purs#L232).

| Item | Concrete scope |
|---|---|
| Source | `@xyflow/system` 0.0.77, `utils/general.ts`, `getViewportForBounds`, `parsePaddings`, `parsePadding`, `calculateAppliedPaddings` |
| Caller context | System `utils/graph.ts` fit-view path; React `store/initialState.ts` and `hooks/useViewportHelper.ts` |
| Reuse | `src/System/Utils/General.purs`; `src/Boundary/Elements.purs` viewport conversion; inspect `src/Boundary/FitView.purs` padding conversion before reuse |
| Observable gap | Calling the JS export with six arguments must return a JS `{ x, y, zoom }` viewport rather than the next curried function |
| Proposed code outputs | `src/Boundary/Utils.purs`, `src/Boundary.purs`, `src/Boundary.js` |
| Proposed evidence outputs | `parity/boundary/mount.mjs` for focused JS-entry regression; `parity/surface/allowlist.json` only to retire the two named pilot exceptions; generated surface artifacts only when the documented gate regenerates them |
| Read-only references | `index.js`, core geometry and padding code, existing geometry parity tests and oracle |
| Dependency | Certified source analysis and the adapter requirements above for an AAMF pilot; a fresh baseline and explicit implementation scope for a normal PSFlow task |

Direct upstream `getViewportForBounds` has six parameters and **no default
padding**. Its callers supply their own defaults, including `0.1`; the crossing
must not inject that caller-specific default into the public function.
[Source](xyflow/packages/system/src/utils/general.ts#L292),
[viewport helper caller](xyflow/packages/react/src/hooks/useViewportHelper.ts#L70).
The existing fit-view converter was written for option fields where null and
undefined are folded one level up, so it needs review before use on an
unfiltered direct function argument.
[Padding converter contract](src/Boundary/FitView.purs#L100).

Pilot acceptance requires all of the following:

1. A focused JS-entry regression fails before the crossing and passes after
   it. Compare identical calls against vendored upstream, including numeric,
   pixel, percent and directional padding, asymmetric sides and zoom clamps.
   Exercise omitted padding and malformed values separately against upstream;
   preserve observed return/error behavior rather than silently normalizing it.
2. The existing [geometry function properties](test/Test/Parity/Geometry.purs#L263)
   continue to cover the reused computation. They do not replace the JS-entry
   regression: they call the PureScript function directly.
3. After building, surface parity observes the six-argument calling convention
   and JS viewport result. Retire only `getViewportForBounds`' arity exception
   and `getViewportForBounds.call-convention` exception in
   [the allowlist](parity/surface/allowlist.json#L37). Boundary checks pass.
4. Move only this export from passthrough to crossed manifest ownership; seven
   passthrough exports remain and the overall boundary stays at stage 4 until
   the remaining stage 5 work is done. Do not relabel the whole boundary stage
   because one pilot passes.
5. The allowed diff contains no core algorithm rewrite, new JavaScript business
   logic, new scaffold or unrelated module changes. If a converter defect
   requires additional outputs, revise the reviewed task scope before the run.
6. For the AAMF route, fresh execution and resume both use the same single
   reconciled task, preserve the source/target snapshot identities, and keep
   all reused geometry units out of the write queue.

No pilot test, build or parity gate was run here. Integration implementation,
certified indexing, and the pilot remain future work; Step 3 was not started.
