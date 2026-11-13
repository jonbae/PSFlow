# AAMF Step 1 — upstream inventory results

**Step 1 is complete as of 2026-11-09.** This report closes
[Step 1 of the porting plan](AAMF_PORTING_PLAN.md#step-1-use-aamf-for-a-bounded-upstream-inventory):
prepare the isolated inventory, run AAMF's bounded analysis, and review its
scope, diagnostics, imports, dependency edges, cycles, and fallback tasks.

The November 7 CLI runs succeeded, but their detailed artifacts were left in
temporary storage and that workspace no longer exists. The complete bounded
analysis was rebuilt on November 9. Its outputs are now preserved under
[aamf/step1/](aamf/step1/README.md), including the unmodified certified database
and structured checkpoint in [runtime.tar.gz](aamf/step1/runtime.tar.gz).

## Completion checklist

| Step 1 requirement | Verified result | Evidence |
|---|---|---|
| Isolated AAMF, complete upstream, and target copies | Three separate directories under `/private/tmp/psflow-aamf-step1-20261109/`; all 688 upstream files retained | [Integrity](aamf/step1/integrity.json), archived snapshot manifests |
| Pinned inputs and built CLI | PSFlow `04fd4f2`; AAMF `7dc475d`; React 12.11.0 / system 0.0.77; Node 22.18.0; `npm ci` and build succeeded | [Execution](aamf/step1/execution.json) |
| Indexing prerequisite fixes verified | Existing guarded Lore fixes reapplied; all 13 regression tests pass | [Patch hashes](aamf/step1/compatibility-patches.json), [tests](aamf/step1/tests.log) |
| Bounded normal AAMF run completed | CLI exit 0; indexing and task graph both checkpointed; no later stage executed | [Run log](aamf/step1/migrate.log), [status](aamf/step1/status.txt) |
| Scope recounted and omissions explained | 44 system + 127 React TS/TSX files; zero selected files omitted; zero JS/JSX/MJS/CJS source files | [Per-file inventory](aamf/step1/inventory.json) |
| Index diagnostics reviewed | 2,484 symbols; zero invalid spans; 18 verified re-export-only files; zero unexpectedly symbol-less files | [Health report](aamf/step1/index-health.json) |
| Cross-package edges reviewed | 56 React-to-system call references and 324 type references; independent import audit finds 80 React-to-system declarations | [Graph review](aamf/step1/review.json), [imports](aamf/step1/imports.json) |
| Unresolved imports inspected directly | All 689 import/re-export declarations resolve: 531 within scope, 158 external; zero unresolved or outside-scope targets | [Import audit](aamf/step1/imports.json) |
| Cycles and file-only fallbacks inspected | 120 tasks, 460 edges, four cyclic groups; zero dangling dependencies or file-only fallback tasks | [Task graph](aamf/step1/task-graph.json), [review](aamf/step1/review.json) |
| All source files accounted for in graph/context | 121 directly assigned + 32 retained as references + 18 re-export-only = 171 | [Inventory](aamf/step1/inventory.json) |
| Source/target integrity and stop boundary | All 1,167 copied target files and 688 original upstream files unchanged; no port or Step 2 implementation work | [Integrity](aamf/step1/integrity.json) |
| Evidence survives temporary-workspace cleanup | Review JSON, logs, runtime archive, and checksums saved in the repository | [Artifact guide](aamf/step1/README.md), [checksums](aamf/step1/SHA256SUMS) |

## Findings and remaining limitations

Source indexing is certified under the maintained Lore 0.4.2 compatibility
fixes, rather than stock Lore. Its health is `degraded` solely because four
duplicate-symbol groups (seven excess rows) remain warnings; there are no
validation errors. The configured zero threshold for unexpectedly missing
symbols and required valid spans remain enforced.

Lore's import table is still empty. To complete the required import review,
the new inspector parsed the actual 171 source files with the pinned SCIP
TypeScript parser (5.9.3) and resolved their module specifiers using the isolated
analysis tsconfig and installed source dependencies. It inspected **579 import
declarations and 110 re-exports**. All 689 resolve. This separate audit does not
populate Lore's import table, add those dependency edges to the task graph, or
prove compatibility of individual imported/exported symbols.

The four cyclic task groups are retained explicitly:

| Group | Tasks | Source units |
|---|---:|---|
| System types | 3 | `types/general.ts`, `types/nodes.ts`, `types/panzoom.ts` |
| React types | 4 | `types/edges.ts`, `types/general.ts`, `types/instance.ts`, `types/nodes.ts` |
| Pan/zoom controller | 2 | `xypanzoom/XYPanZoom.ts`, `xypanzoom/eventhandler.ts` |
| Flow containers | 2 | `container/FlowRenderer/index.tsx`, `container/ZoomPane/index.tsx` |

The dependency summary has 152 modules in seven connected components; its
largest connected component contains 146 modules. The strongly connected
task groups above were independently checked against the graph. These are
different representations and must not be combined into a completion count.

Svelte, examples, tests, CSS, tooling, and dependencies remain outside the
migration inventory. Their source assets were retained in the complete upstream
copy. `packages/react/src/styles/utils.ts` remains included as TypeScript.
There was no relevant upstream JavaScript to add to the scoped inventory.

All 121 proposed target paths still end in `.purescript`. No target files were
generated. Correct `.purs` paths, reconciliation with existing modules, and an
implementation pilot belong to Step 2; this source graph is not an approved
code-writing queue.

## Reproduction and stop point

The bounded CLI invocation used `--phase 1`, which runs AAMF's internal indexing
and task-graph stages. Those are implementation details of **plan Step 1**.
The final checkpoint contains `completedPhases: [0, 1]`, `currentPhase: 2`, with
zero reported tokens and no migration-agent invocations. The raw graph in both
structured checkpoint outputs matches the raw planning artifacts exactly.

The new workspace and its configuration are recorded in the artifact guide.
Regenerate the review from the repository, with Node 22 selected, using:

```sh
node tools/aamf/inspect-step1.mjs /private/tmp/psflow-aamf-step1-20261109 aamf/step1
```

**Stopped at the end of Step 1.** No Step 2 mapping, integration, or pilot work
was performed in this completion run. The pre-existing Step 2 documents were
left unchanged. No PSFlow build or parity gate was needed for this isolated
source inventory; no baseline, comparator, allowlist, or port implementation
was changed.

## Historical execution notes — 2026-11-07

The remaining sections preserve the earlier attempts and diagnostic inventory.
Their `/private/tmp/psflow-aamf/` links are historical and no longer available.
Use the repository artifacts above for the completed Step 1 evidence.

## Phase 0 execution — 2026-11-07

Executed the requested phase-0-only run with Node 22.18.0, a fresh project
`psflow-phase0-ez9ddpru`, and independent state:

```sh
/Users/jonathanbae/.nvm/versions/node/v22.18.0/bin/node \
  /private/tmp/psflow-aamf/AAMF/dist/index.js migrate \
  -c /private/tmp/psflow-aamf/phase0-ez9ddpru/analysis.json --phase 0
```

The CLI confirmed `Running phases 0–0 (--phase 0)`. Indexing covered 171 files
and persisted 2,484 symbols, 1,258 call references, and 3,752 type references.
Phase 0 failed certification after a reported 23 seconds, exiting **1**:
`INVALID_SPANS` (103) and `THRESHOLD_MAX_SYMBOL_LESS_FILES` (18, maximum 0).
Status confirms no completed phases or tasks and zero tokens. No subsequent
phase ran, no certification policy was changed, and source/target file checks
remain unchanged from the recorded snapshots.

Evidence: [run result](/private/tmp/psflow-aamf/phase0-ez9ddpru/run-result.json),
[migration log](/private/tmp/psflow-aamf/phase0-ez9ddpru/migrate.log),
[checkpoint status](/private/tmp/psflow-aamf/phase0-ez9ddpru/status.txt),
and [integrity checks](/private/tmp/psflow-aamf/phase0-ez9ddpru/integrity-checks.json).

## Step 1 recheck — 2026-11-07

The existing Step 1 workspace and reports were present when this request began.
Rechecked the pinned inputs and repeated only the normal `--phase 1` run under
the new project name `psflow-step1-recheck-6vamgsw7`, with independent state in
`/private/tmp/psflow-aamf/step1-recheck-6vamgsw7/`. Existing Step 2 documents
predate this recheck; no later-step work was performed during this run.

Rebuilding the pinned AAMF checkout with `npm run build` succeeded after
explicitly selecting Node 22.18.0 on `PATH`. The isolated directory's default
shell selected Node 18.7.0, which failed the initial build attempt. For
reproduction, select the installed Node 22 toolchain before building or running
the CLI, and expose AAMF's local indexer executable:

```sh
export PATH="/Users/jonathanbae/.nvm/versions/node/v22.18.0/bin:/private/tmp/psflow-aamf/AAMF/node_modules/.bin:$PATH"
```

The fresh migration attempt again exited **1**, after a reported 30-second
phase 0, with **103 invalid spans** and **18 symbol-less files**. Status reports
phase `0/8`, no completed phases or tasks, and zero tokens. The run retained
the normal certification policy; phase 1 did not execute.

Independent read-only checks of the preserved diagnostic database and graph
confirmed all 171 scoped files, 2,484 symbols, 120 provisional tasks, 460
dependency edges, and four cyclic groups. File accounting still closes at
121 directly assigned files + 32 reference-only files + 18 symbol-less files.
The 56 React-to-system call edges and 324 type-reference edges are present;
import records remain absent. Diagnostic artifact hashes match the original
review. These checks verify existing uncertified evidence, not a newly
certified graph.

Post-run hashes confirm all 1,158 target files and all 688 original upstream
files remain unchanged. The only extra upstream file is still the previously
added analysis `tsconfig.json`; all 171 scoped files also match the original
repository. AAMF remains at the pinned commit with clean tracked files.

Recheck evidence: [configuration](/private/tmp/psflow-aamf/step1-recheck-6vamgsw7/analysis.json),
[run result](/private/tmp/psflow-aamf/step1-recheck-6vamgsw7/run-result.json),
[migration log](/private/tmp/psflow-aamf/step1-recheck-6vamgsw7/migrate.log),
[checkpoint status](/private/tmp/psflow-aamf/step1-recheck-6vamgsw7/status.txt),
[inventory verification](/private/tmp/psflow-aamf/step1-recheck-6vamgsw7/inventory-verification.json),
and [post-run integrity](/private/tmp/psflow-aamf/step1-recheck-6vamgsw7/output-verification.json).

## Inputs and isolation

| Input | Recorded value |
|---|---|
| PSFlow snapshot | `04fd4f246eb02d311effbf4fb1debedcbc21ba01` |
| AAMF snapshot | `7dc475d81ef9796b5b90f57a29475eaafa375753` |
| Source packages | `@xyflow/react` 12.11.0; `@xyflow/system` 0.0.77 |
| Toolchain used | Node 22.18.0; npm 11.5.2; pnpm 10.33.4 |
| Indexing dependencies | Lore 0.4.2; scip-typescript 0.4.0, from AAMF's lockfile |
| Workspace | `/private/tmp/psflow-aamf/` |
| Final AAMF project name | `psflow-gap-analysis-2026-11-07-source-aliases` |
| Agent invocations / reported tokens | 0 / 0 |

The AAMF checkout, copied upstream tree, copied PSFlow target, configuration,
dependency installations, logs, and diagnostic databases are under the temporary
workspace. The upstream copy retains the complete vendored tree and its package
and TypeScript configuration files. Its dependencies were installed with:

```sh
pnpm --filter @xyflow/react... --filter @xyflow/system... install \
  --frozen-lockfile --ignore-scripts \
  --store-dir /private/tmp/psflow-aamf/pnpm-store
```

AAMF was checked out at the pinned commit, installed with `npm ci` using a
temporary npm cache, and compiled successfully with `npm run build`. Its tracked
source and lockfile remain unchanged.

SHA-256 comparisons found **no changed, removed, or added files in the copied
PSFlow target**: all 1,158 copied files match their pre-run hashes. All 171
scoped upstream source files match in both the original and copied trees. The
only added non-dependency file in the upstream copy is an analysis-only root
`tsconfig.json`; none of the original 688 files changed. No port code, baseline,
test, comparator, region, allowlist, trace, or bundle changed in the repository.

## Source scope and indexing

| Package | Selected TS/TSX files | Files with symbols | Re-export-only files |
|---|---:|---:|---:|
| `packages/system/src` | 44 | 36 | 8 |
| `packages/react/src` | 127 | 117 | 10 |
| **Total** | **171** | **153** | **18** |

No selected source file was omitted from SCIP coverage. There are no `.js`
files under these two source roots, so no JavaScript indexer was needed.
Svelte, examples, tests, tooling, CSS, and dependencies remain outside the
migration inventory. `packages/react/src/styles/utils.ts` is included because
it is TypeScript source; CSS files are not.

The original configuration in the plan is valid JSON and accepted by AAMF, but
the monorepo needs additional analysis setup:

1. With no root `tsconfig.json`, the default SCIP command failed and produced
   171 discovered files but zero symbols. AAMF rejected that index.
2. Adding a root config enabled structural indexing, but relative source aliases
   produced zero React-to-system edges. Lore generates a temporary TypeScript
   config outside the source root, so those relative paths were unsuitable.
3. Making `baseUrl` and both `@xyflow/*` source aliases absolute, and explicitly
   setting `moduleResolution: "bundler"`, restored cross-package references.
   No package source file or package-specific tsconfig was edited.

The final root analysis config includes the selected source globs, `jsx:
"react-jsx"`, DOM/ESNext libraries, `module`/`target: "esnext"`, `strict`,
`esModuleInterop`, `skipLibCheck`, and `noEmit`. Its aliases resolve directly to
the two packages' `src/index.ts` files. These are indexing settings, not a
proposed change to xyflow's build.

### Final observed index metrics

| Measure | Count |
|---|---:|
| Indexed files / symbols | 171 / 2,484 |
| Call references | 1,258 |
| Calls resolved to indexed definitions | 410 |
| Calls classified as external | 848 |
| Type references | 3,752 |
| Types resolved to indexed definitions | 2,152 |
| Types classified as external | 1,600 |
| React → system internal call edges | 56 |
| React → system internal type-reference edges | 324 |
| Recorded unresolved calls / types | 0 / 0 |
| Import records | 0 |

Examples verified in the database include `useDrag` → `XYDrag`, `ZoomPane` →
`XYPanZoom`, `NodeResizeControl` → `XYResizer`, and React's initial-state
construction → `adoptUserNodes` / `updateConnectionLookup`.

**Zero recorded unresolved references does not prove complete resolution.**
The report's classification rate includes external references, and this index
contains no import records at all. Import-level coverage cannot be assessed
from that empty table. Source imports and re-exports still need explicit
attention when reviewing any future execution graph.

## Why stock AAMF certification failed

The final normal CLI run used `migrate -c analysis.json --phase 1`. It exited
with code 1 after approximately 23 seconds. AAMF's status command confirms
phase `0/8`, no completed phases, and no completed tasks. Its validation policy
was left intact.

| Finding | Observed evidence | Consequence |
|---|---|---|
| Invalid symbol spans | 103 symbols: 102 have identifier selection characters before the recorded enclosing span; one has its selection line outside that span | Fails `INVALID_SPANS`. Call and type-reference spans themselves have zero reported invalid entries. |
| Symbol-less files | 18 files contain only re-export statements, confirmed by TypeScript AST inspection | Fails the required `maxSymbolLessFiles: 0` threshold even though SCIP covered those files. |
| Duplicate symbols | Four exact duplicate groups, seven excess rows | Warning; visible in the health report, but not the cause of this failure. |

For example, `isEdgeBase` in `packages/system/src/utils/graph.ts` has a
zero-based identifier selection at line 38, character 13, but its enclosing
span begins at character 26. The source declaration is intact. The observed
pattern is consistent with using the initializer's enclosing-expression range
as the entire variable declaration span; that interpretation still needs a
separate tool fix and regression test.

The relevant installed implementation reads SCIP `enclosingRange` into symbol
span bounds in Lore's `dist/indexer/stages/scip-indexer.js`, while
`dist/validation/index-health.js` requires the identifier selection to lie
inside those bounds. AAMF explicitly requires valid spans and zero symbol-less
files in
[its phase 0 policy](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/flow/steps/kb-indexing.ts#L67-L74).
Its [configuration schema](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/config/schema.ts#L22-L25)
also restricts the overall symbol-less threshold to zero.

No validation threshold was relaxed in the AAMF migration configuration, no
barrel file was silently excluded, and no failed candidate was promoted into
AAMF's certified `kb.db`.

## Diagnostic graph review

To preserve inspectable data after the failed pipeline, a **separate** Lore
database was built outside `.aamf` using its diagnostic API with automatic
validation disabled. The normal migration-grade policy was then run explicitly
against that database, and its complete failing report was saved. AAMF's
exported `buildTaskGraph` and `buildDependencySummary` functions were applied
to the raw database without invoking migration agents or writing target files.

This diagnostic procedure does not complete the normal phase 0/1 checkpoints.
It produces useful inventory evidence while retaining the failure as a failure.

| Diagnostic output | Count |
|---|---:|
| Proposed tasks / dependency edges | 120 / 460 |
| Cyclic task groups | 4 |
| Compilation units | 0 |
| Simple / moderate / complex tasks | 74 / 37 / 9 |
| Largest task's reported lines | 653 |
| Source files explicitly assigned to tasks | 121 |
| Additional source files absorbed into knowledge-base references | 32 |
| Re-export-only files without local symbols | 18 |
| File-only fallback tasks | 0 |
| Dependency-summary modules / connected components | 152 / 7 |

The file accounting closes: **121 + 32 + 18 = 171**. AAMF's micro-task
elision folds small dependencies into consumers' knowledge-base references;
their absence from `sourceFiles` alone is not a missing file. All emitted tasks
carry structured symbol entries. The largest dependency-summary component
contains 146 of its 152 modules.

The four cyclic task groups are:

| Group | Tasks | Source files involved |
|---|---:|---|
| System types | 3 | `types/general.ts`, `types/nodes.ts`, `types/panzoom.ts` |
| React types | 4 | `types/edges.ts`, `types/general.ts`, `types/instance.ts`, `types/nodes.ts` |
| Pan/zoom controller | 2 | `xypanzoom/XYPanZoom.ts`, `xypanzoom/eventhandler.ts` |
| Flow containers | 2 | `container/FlowRenderer/index.tsx`, `container/ZoomPane/index.tsx` |

These cycles are recorded in AAMF's graph output; do not flatten them into a
simple dependency queue. The task and dependency-summary counts describe
different intermediate representations and should not be added together.

All **121 generated target filenames end in `.purescript`** and preserve
upstream's package paths. This confirms the target-mapping limitation in the
plan. No such target files were created. The graph also describes migration
from source, not which behavior remains unfinished in PSFlow. It must not be
used as a write queue without the later reconciliation step.

## Artifacts and reproduction

These raw artifacts are local temporary files; this report preserves their
important results in the repository.

| Artifact | Location |
|---|---|
| Final run configuration | [analysis.json](/private/tmp/psflow-aamf/analysis.json) |
| Analysis-only TypeScript configuration | [source/xyflow/tsconfig.json](/private/tmp/psflow-aamf/source/xyflow/tsconfig.json) |
| Normal AAMF run log | [source-aliases-index.log](/private/tmp/psflow-aamf/source-aliases-index.log) |
| Full failing health report | [index-health.json](/private/tmp/psflow-aamf/diagnostics/index-health.json) |
| Raw diagnostic database | [kb-uncertified.db](/private/tmp/psflow-aamf/diagnostics/kb-uncertified.db) |
| Provisional task graph | [task-graph-UNCERTIFIED.json](/private/tmp/psflow-aamf/diagnostics/task-graph-UNCERTIFIED.json) |
| Dependency summary | [dependency-summary-UNCERTIFIED.json](/private/tmp/psflow-aamf/diagnostics/dependency-summary-UNCERTIFIED.json) |
| Per-file inventory | [file-inventory.json](/private/tmp/psflow-aamf/diagnostics/file-inventory.json) |
| Review metrics | [review-summary.json](/private/tmp/psflow-aamf/diagnostics/review-summary.json) |
| Hash verification | [integrity-checks.json](/private/tmp/psflow-aamf/integrity-checks.json) |
| Diagnostic reproduction helper | [inspect-index.mjs](/private/tmp/psflow-aamf/diagnostics/inspect-index.mjs) |

From `/private/tmp/psflow-aamf`, inspect the preserved checkpoint with:

```sh
node AAMF/dist/index.js status -c analysis.json
```

To repeat the normal attempt, copy `analysis.json` to a new config, give it a
new `projectName`, and expose `AAMF/node_modules/.bin` on the subprocess's
`PATH` so Lore can find the installed `scip-typescript` executable. Run:

```sh
node AAMF/dist/index.js migrate -c <new-analysis-config.json> --phase 1
```

With the unpatched Lore distribution and these pinned inputs, expect the
certification failure above. After applying the maintained tooling fixes, use
[the successful phase 0 configuration and checkpoint](AAMF_PHASE0_RESULTS.md).
Preserve the current run directories instead of starting a fresh run under an
existing project name. The original failed run and the intermediate relative-
alias diagnostic were retained separately for comparison.

## Original Step 1 stop point

At this original stop point, the inventory and review were recorded, but a
certified phase 0/1 run remained blocked by the two validation failures. Span
handling and the policy for re-export-only files were subsequently corrected
for [the successful phase 0 run](AAMF_PHASE0_RESULTS.md), followed by
[the completed phase 1 run](AAMF_PHASE1_RESULTS.md). The diagnostic graph below
is still historical, uncertified evidence.

No PSFlow build or parity gate was run: those belong to later implementation
steps. No agent was asked to migrate code, and the original inventory run did
not start Step 2.

## Per-file inventory

Counts below are from the final, uncertified diagnostic database. `Calls` and
`Types` count references observed in each file, not distinct target symbols.

| Source file | Symbols | Calls | Types |
|---|---:|---:|---:|
| `packages/react/src/additional-components/Background/Background.tsx` | 8 | 10 | 24 |
| `packages/react/src/additional-components/Background/Patterns.tsx` | 10 | 2 | 3 |
| `packages/react/src/additional-components/Background/index.tsx` | 0 | 0 | 0 |
| `packages/react/src/additional-components/Background/types.ts` | 16 | 0 | 2 |
| `packages/react/src/additional-components/Controls/ControlButton.tsx` | 1 | 1 | 1 |
| `packages/react/src/additional-components/Controls/Controls.tsx` | 10 | 20 | 2 |
| `packages/react/src/additional-components/Controls/Icons/FitView.tsx` | 1 | 0 | 0 |
| `packages/react/src/additional-components/Controls/Icons/Lock.tsx` | 1 | 0 | 0 |
| `packages/react/src/additional-components/Controls/Icons/Minus.tsx` | 1 | 0 | 0 |
| `packages/react/src/additional-components/Controls/Icons/Plus.tsx` | 1 | 0 | 0 |
| `packages/react/src/additional-components/Controls/Icons/Unlock.tsx` | 1 | 0 | 0 |
| `packages/react/src/additional-components/Controls/index.tsx` | 0 | 0 | 0 |
| `packages/react/src/additional-components/Controls/types.ts` | 16 | 0 | 7 |
| `packages/react/src/additional-components/EdgeToolbar/EdgeToolbar.tsx` | 7 | 9 | 4 |
| `packages/react/src/additional-components/EdgeToolbar/index.tsx` | 0 | 0 | 0 |
| `packages/react/src/additional-components/EdgeToolbar/types.ts` | 1 | 0 | 5 |
| `packages/react/src/additional-components/MiniMap/MiniMap.tsx` | 24 | 16 | 20 |
| `packages/react/src/additional-components/MiniMap/MiniMapNode.tsx` | 6 | 3 | 1 |
| `packages/react/src/additional-components/MiniMap/MiniMapNodes.tsx` | 17 | 12 | 25 |
| `packages/react/src/additional-components/MiniMap/index.tsx` | 0 | 0 | 0 |
| `packages/react/src/additional-components/MiniMap/types.ts` | 21 | 0 | 30 |
| `packages/react/src/additional-components/NodeResizer/NodeResizeControl.tsx` | 14 | 24 | 39 |
| `packages/react/src/additional-components/NodeResizer/NodeResizer.tsx` | 1 | 2 | 8 |
| `packages/react/src/additional-components/NodeResizer/index.tsx` | 0 | 0 | 0 |
| `packages/react/src/additional-components/NodeResizer/types.ts` | 20 | 0 | 16 |
| `packages/react/src/additional-components/NodeToolbar/NodeToolbar.tsx` | 8 | 23 | 34 |
| `packages/react/src/additional-components/NodeToolbar/NodeToolbarPortal.tsx` | 3 | 3 | 2 |
| `packages/react/src/additional-components/NodeToolbar/index.tsx` | 0 | 0 | 0 |
| `packages/react/src/additional-components/NodeToolbar/types.ts` | 1 | 0 | 5 |
| `packages/react/src/additional-components/index.ts` | 0 | 0 | 0 |
| `packages/react/src/components/A11yDescriptions/index.tsx` | 12 | 3 | 4 |
| `packages/react/src/components/Attribution/index.tsx` | 4 | 0 | 3 |
| `packages/react/src/components/BatchProvider/index.tsx` | 6 | 13 | 19 |
| `packages/react/src/components/BatchProvider/types.ts` | 7 | 0 | 7 |
| `packages/react/src/components/BatchProvider/useQueue.ts` | 4 | 4 | 9 |
| `packages/react/src/components/ConnectionLine/index.tsx` | 27 | 11 | 27 |
| `packages/react/src/components/EdgeLabelRenderer/index.tsx` | 4 | 3 | 3 |
| `packages/react/src/components/EdgeWrapper/EdgeUpdateAnchors.tsx` | 4 | 3 | 38 |
| `packages/react/src/components/EdgeWrapper/index.tsx` | 12 | 23 | 20 |
| `packages/react/src/components/EdgeWrapper/utils.ts` | 13 | 0 | 1 |
| `packages/react/src/components/Edges/BaseEdge.tsx` | 1 | 1 | 1 |
| `packages/react/src/components/Edges/BezierEdge.tsx` | 4 | 5 | 3 |
| `packages/react/src/components/Edges/EdgeAnchor.tsx` | 13 | 1 | 26 |
| `packages/react/src/components/Edges/EdgeText.tsx` | 10 | 7 | 4 |
| `packages/react/src/components/Edges/SimpleBezierEdge.tsx` | 19 | 8 | 10 |
| `packages/react/src/components/Edges/SmoothStepEdge.tsx` | 4 | 5 | 3 |
| `packages/react/src/components/Edges/StepEdge.tsx` | 4 | 4 | 1 |
| `packages/react/src/components/Edges/StraightEdge.tsx` | 4 | 5 | 1 |
| `packages/react/src/components/Edges/index.ts` | 0 | 0 | 0 |
| `packages/react/src/components/Handle/index.tsx` | 34 | 11 | 36 |
| `packages/react/src/components/NodeWrapper/index.tsx` | 13 | 23 | 16 |
| `packages/react/src/components/NodeWrapper/useNodeObserver.ts` | 5 | 12 | 9 |
| `packages/react/src/components/NodeWrapper/utils.tsx` | 14 | 4 | 7 |
| `packages/react/src/components/Nodes/DefaultNode.tsx` | 1 | 0 | 4 |
| `packages/react/src/components/Nodes/GroupNode.tsx` | 1 | 0 | 0 |
| `packages/react/src/components/Nodes/InputNode.tsx` | 1 | 0 | 3 |
| `packages/react/src/components/Nodes/OutputNode.tsx` | 1 | 0 | 3 |
| `packages/react/src/components/Nodes/utils.ts` | 10 | 3 | 7 |
| `packages/react/src/components/NodesSelection/index.tsx` | 17 | 13 | 12 |
| `packages/react/src/components/Panel/index.tsx` | 2 | 1 | 7 |
| `packages/react/src/components/ReactFlowProvider/index.tsx` | 16 | 3 | 10 |
| `packages/react/src/components/SelectionListener/index.tsx` | 19 | 15 | 34 |
| `packages/react/src/components/StoreUpdater/index.tsx` | 29 | 8 | 29 |
| `packages/react/src/components/UserSelection/index.tsx` | 7 | 2 | 1 |
| `packages/react/src/components/ViewportPortal/index.tsx` | 3 | 3 | 2 |
| `packages/react/src/container/EdgeRenderer/MarkerDefinitions.tsx` | 5 | 6 | 3 |
| `packages/react/src/container/EdgeRenderer/MarkerSymbols.tsx` | 10 | 4 | 7 |
| `packages/react/src/container/EdgeRenderer/index.tsx` | 11 | 7 | 13 |
| `packages/react/src/container/FlowRenderer/index.tsx` | 11 | 13 | 11 |
| `packages/react/src/container/GraphView/index.tsx` | 7 | 11 | 24 |
| `packages/react/src/container/GraphView/useNodeOrEdgeTypesWarning.ts` | 4 | 0 | 1 |
| `packages/react/src/container/GraphView/useStylesLoadedWarning.ts` | 1 | 6 | 0 |
| `packages/react/src/container/NodeRenderer/index.tsx` | 11 | 8 | 9 |
| `packages/react/src/container/NodeRenderer/useResizeObserver.ts` | 2 | 7 | 11 |
| `packages/react/src/container/Pane/index.tsx` | 35 | 43 | 89 |
| `packages/react/src/container/ReactFlow/Wrapper.tsx` | 15 | 3 | 9 |
| `packages/react/src/container/ReactFlow/index.tsx` | 7 | 10 | 23 |
| `packages/react/src/container/ReactFlow/init-values.ts` | 2 | 0 | 2 |
| `packages/react/src/container/Viewport/index.tsx` | 5 | 1 | 3 |
| `packages/react/src/container/ZoomPane/index.tsx` | 10 | 12 | 11 |
| `packages/react/src/contexts/NodeIdContext.ts` | 4 | 2 | 0 |
| `packages/react/src/contexts/StoreContext.ts` | 2 | 1 | 1 |
| `packages/react/src/custom.d.ts` | 4 | 0 | 5 |
| `packages/react/src/hooks/useColorModeClass.ts` | 2 | 10 | 3 |
| `packages/react/src/hooks/useConnection.ts` | 8 | 5 | 31 |
| `packages/react/src/hooks/useDrag.ts` | 9 | 7 | 5 |
| `packages/react/src/hooks/useEdges.ts` | 3 | 2 | 5 |
| `packages/react/src/hooks/useGlobalKeyHandler.ts` | 9 | 8 | 4 |
| `packages/react/src/hooks/useHandleConnections.ts` | 7 | 12 | 23 |
| `packages/react/src/hooks/useInternalNode.ts` | 2 | 4 | 6 |
| `packages/react/src/hooks/useIsomorphicLayoutEffect.ts` | 1 | 2 | 0 |
| `packages/react/src/hooks/useKeyPress.ts` | 11 | 58 | 66 |
| `packages/react/src/hooks/useMoveSelectedNodes.ts` | 4 | 4 | 5 |
| `packages/react/src/hooks/useNodeConnections.ts` | 2 | 11 | 22 |
| `packages/react/src/hooks/useNodes.ts` | 3 | 2 | 5 |
| `packages/react/src/hooks/useNodesData.ts` | 8 | 0 | 4 |
| `packages/react/src/hooks/useNodesEdgesState.ts` | 4 | 6 | 21 |
| `packages/react/src/hooks/useNodesInitialized.ts` | 4 | 2 | 3 |
| `packages/react/src/hooks/useOnEdgesChangeMiddleware.ts` | 2 | 6 | 11 |
| `packages/react/src/hooks/useOnInitHandler.ts` | 3 | 4 | 9 |
| `packages/react/src/hooks/useOnNodesChangeMiddleware.ts` | 2 | 6 | 11 |
| `packages/react/src/hooks/useOnSelectionChange.ts` | 9 | 3 | 16 |
| `packages/react/src/hooks/useOnViewportChange.ts` | 8 | 4 | 4 |
| `packages/react/src/hooks/useReactFlow.ts` | 18 | 33 | 81 |
| `packages/react/src/hooks/useResizeHandler.ts` | 3 | 9 | 4 |
| `packages/react/src/hooks/useStore.ts` | 6 | 4 | 17 |
| `packages/react/src/hooks/useUpdateNodeInternals.ts` | 2 | 7 | 16 |
| `packages/react/src/hooks/useViewport.ts` | 5 | 2 | 2 |
| `packages/react/src/hooks/useViewportHelper.ts` | 6 | 4 | 5 |
| `packages/react/src/hooks/useViewportSync.ts` | 3 | 3 | 2 |
| `packages/react/src/hooks/useVisibleEdgeIds.ts` | 1 | 8 | 1 |
| `packages/react/src/hooks/useVisibleNodeIds.ts` | 2 | 7 | 10 |
| `packages/react/src/index.ts` | 1 | 0 | 1 |
| `packages/react/src/store/index.ts` | 55 | 39 | 46 |
| `packages/react/src/store/initialState.ts` | 6 | 2 | 30 |
| `packages/react/src/styles/utils.ts` | 1 | 0 | 1 |
| `packages/react/src/types/component-props.ts` | 125 | 0 | 133 |
| `packages/react/src/types/edges.ts` | 73 | 0 | 127 |
| `packages/react/src/types/general.ts` | 51 | 0 | 92 |
| `packages/react/src/types/index.ts` | 0 | 0 | 0 |
| `packages/react/src/types/instance.ts` | 36 | 0 | 87 |
| `packages/react/src/types/nodes.ts` | 36 | 0 | 58 |
| `packages/react/src/types/store.ts` | 114 | 1 | 125 |
| `packages/react/src/utils/changes.ts` | 27 | 21 | 49 |
| `packages/react/src/utils/edges.ts` | 7 | 0 | 12 |
| `packages/react/src/utils/general.ts` | 5 | 1 | 13 |
| `packages/react/src/utils/index.ts` | 0 | 0 | 0 |
| `packages/system/src/constants.ts` | 32 | 0 | 1 |
| `packages/system/src/index.ts` | 0 | 0 | 0 |
| `packages/system/src/types/changes.ts` | 45 | 0 | 35 |
| `packages/system/src/types/edges.ts` | 64 | 0 | 21 |
| `packages/system/src/types/general.ts` | 133 | 0 | 190 |
| `packages/system/src/types/handles.ts` | 18 | 0 | 5 |
| `packages/system/src/types/index.ts` | 0 | 0 | 0 |
| `packages/system/src/types/nodes.ts` | 25 | 0 | 58 |
| `packages/system/src/types/panzoom.ts` | 48 | 0 | 47 |
| `packages/system/src/types/utils.ts` | 20 | 0 | 9 |
| `packages/system/src/utils/connections.ts` | 3 | 5 | 18 |
| `packages/system/src/utils/dom.ts` | 15 | 12 | 56 |
| `packages/system/src/utils/edge-toolbar.ts` | 9 | 0 | 2 |
| `packages/system/src/utils/edges/bezier-edge.ts` | 27 | 10 | 23 |
| `packages/system/src/utils/edges/general.ts` | 36 | 8 | 36 |
| `packages/system/src/utils/edges/index.ts` | 0 | 0 | 0 |
| `packages/system/src/utils/edges/positions.ts` | 21 | 13 | 24 |
| `packages/system/src/utils/edges/smoothstep-edge.ts` | 45 | 15 | 85 |
| `packages/system/src/utils/edges/straight-edge.ts` | 6 | 1 | 1 |
| `packages/system/src/utils/general.ts` | 63 | 51 | 207 |
| `packages/system/src/utils/graph.ts` | 65 | 39 | 128 |
| `packages/system/src/utils/index.ts` | 0 | 0 | 0 |
| `packages/system/src/utils/marker.ts` | 6 | 14 | 11 |
| `packages/system/src/utils/node-toolbar.ts` | 1 | 0 | 7 |
| `packages/system/src/utils/shallow-node-data.ts` | 2 | 3 | 23 |
| `packages/system/src/utils/store.ts` | 91 | 83 | 160 |
| `packages/system/src/utils/types.ts` | 7 | 0 | 9 |
| `packages/system/src/xydrag/XYDrag.ts` | 61 | 30 | 132 |
| `packages/system/src/xydrag/index.ts` | 0 | 0 | 0 |
| `packages/system/src/xydrag/utils.ts` | 20 | 12 | 45 |
| `packages/system/src/xyhandle/XYHandle.ts` | 16 | 44 | 52 |
| `packages/system/src/xyhandle/index.ts` | 0 | 0 | 0 |
| `packages/system/src/xyhandle/types.ts` | 48 | 0 | 63 |
| `packages/system/src/xyhandle/utils.ts` | 13 | 18 | 29 |
| `packages/system/src/xyminimap/index.ts` | 23 | 12 | 30 |
| `packages/system/src/xypanzoom/XYPanZoom.ts` | 14 | 46 | 38 |
| `packages/system/src/xypanzoom/eventhandler.ts` | 38 | 11 | 51 |
| `packages/system/src/xypanzoom/filter.ts` | 13 | 4 | 17 |
| `packages/system/src/xypanzoom/index.ts` | 0 | 0 | 0 |
| `packages/system/src/xypanzoom/utils.ts` | 7 | 8 | 13 |
| `packages/system/src/xyresizer/XYResizer.ts` | 51 | 24 | 63 |
| `packages/system/src/xyresizer/index.ts` | 0 | 0 | 0 |
| `packages/system/src/xyresizer/types.ts` | 22 | 0 | 18 |
| `packages/system/src/xyresizer/utils.ts` | 32 | 45 | 69 |
