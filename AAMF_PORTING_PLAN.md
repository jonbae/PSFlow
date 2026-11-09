# Completing the xyflow → PSFlow port with AAMF

Prepared 2026-11-07 against PSFlow commit
`04fd4f246eb02d311effbf4fb1debedcbc21ba01` and AAMF commit
[`7dc475d81ef9796b5b90f57a29475eaafa375753`](https://github.com/jafreck/AAMF/tree/7dc475d81ef9796b5b90f57a29475eaafa375753).

This began as a documentation-only assessment and proposed workflow. The
execution updates below record the later isolated analysis and reconciliation.
Commands and configuration in the original plan remain proposals except where
the linked execution results explicitly report them as run. The baseline stays
fixed; Step 2 runtime changes are limited to its recorded pilot and numeric
prerequisite.

Execution update (2026-11-09): **Step 1 is complete.** The bounded inventory was
rebuilt with the maintained [Lore compatibility fixes](tools/aamf/README.md),
and all Step 1 requirements were reviewed. All 171 scoped files are accounted
for; the graph has 120 tasks, 460 edges, and four cyclic groups, with zero
file-only fallback tasks. A direct audit resolved all 689 import/re-export
declarations. The source index has no validation errors. See
[the Step 1 completion checklist](AAMF_STEP1_RESULTS.md) and
[the preserved artifacts](aamf/step1/README.md).

**Step 2 is also complete, 2026-11-09.** The 171-file mapping was revalidated
against the certified inventory. A maintained adapter now supplies explicit
existing-module paths, a single reconciled runtime task, checkpoint/resume,
file-based PureScript context, and an existing-project route. The
`getViewportForBounds` pilot passed its regression and applicable gates. A
small, separately tested NaN-compatibility prerequisite preserves the existing
geometry algorithm; that file stayed read-only during the AAMF pilot.

See [Step 2 results](AAMF_STEP2_RESULTS.md), the
[integration implementation](AAMF_STEP2_INTEGRATION.md), and
[preserved evidence](aamf/step2/README.md). The original November 7 temporary
workspace is gone; the completed Step 1 and Step 2 evidence now survives in
the repository. **Stopped at the end of Step 2. Step 3 was not started.**

## Recommendation

Use AAMF to inventory upstream dependencies and, after an integration pilot,
coordinate small tasks that finish the existing port. Preserve PSFlow's current
architecture and parity apparatus. The implementation destination remains
PureScript; JavaScript remains limited to the platform and interop operations
described in [PORTING.md](PORTING.md#ffi).

**Stock AAMF needs integration work before it should execute this migration.**
Its current task builder derives output paths from upstream paths, does not
recognize PureScript's extension, and does not reconcile its task inventory with
PSFlow's already implemented modules. Setting `target.language` to `purescript`
alone would produce paths ending in `.purescript`, rather than the existing
`.purs` modules. [AAMF path mapping](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/core/task-graph-builder.ts#L1648-L1665)

The first useful milestone is therefore an upstream index plus a reviewed map
from source symbols to existing target modules, followed by one successful
completion task. A whole-repository migration run is premature.

## What is already here

The source baseline is **`@xyflow/react` 12.11.0 / `@xyflow/system` 0.0.77**,
exact-pinned in [package.json](package.json). `xyflow/` is the vendored,
gitignored source tree, not a separately tracked submodule. Keep this baseline
fixed while completing the port; follow [README.md](README.md#the-parity-baseline)
when a later baseline update is intentional.

| Area | Evidence in this checkout | Planning consequence |
|---|---|---|
| Implementation | 169 `.purs` modules and 50 JavaScript FFI files under `src/`, counted for this assessment | Reuse the existing implementation; file count is not a completion percentage. |
| Public API | [Census](parity/census/report.md): 68 value exports and 142 type exports | Track source behavior, boundary conversion, and evidence separately. |
| Boundary | [Manifest](src/Boundary.js): stage 4, with seven exports still passing through raw after the Step 2 viewport pilot | The six edge-path helpers have already crossed. Finish the remaining graph/bounds/reconnection crossings. |
| Surface report | [Committed snapshot](parity/surface/report.md) says last run 2026-09-22 | It predates some current boundary code and allowlist changes; regenerate before making numerical claims. |
| System report | [Committed snapshot](parity/system/report.md), last changed in commit `c3e242a7` on 2026-10-20: 100 of 103 scenarios failed | This is a snapshot of observed differences, not 100 separate missing features. Re-capture after the baseline build. |
| Coverage | [Committed snapshot](parity/system/coverage.md): 122 of 156 export-bearing entries driven, 34 declared holes; 50 behaviors still awaiting gates | A declared hole is accounted for, not implemented or verified by that declaration. Export coverage and behavior coverage are different measures. |
| Porting contract | [PORTING.md](PORTING.md), [CONTEXT.md](CONTEXT.md), and the [five gates](README.md#the-five-gates) | Use these as the migration and verification rules. |

The live issue index is [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
The [tracker convention](.claude/issue-tracker.md) identifies GitHub issues as
current work and `tickets/*.md` as older reference material. In particular,
[the old consolidation ticket](tickets/067-xyflow-parity-remaining-work.md)
claims functional completeness and contains several superseded descriptions.
Do not turn that ticket directly into AAMF tasks.

Two open PRs were present during this assessment:

- [Announce an arrow-key move in the aria-live region](https://github.com/jonbae/PSFlow/pull/194).
- [Hold null for a side with no handle](https://github.com/jonbae/PSFlow/pull/195).

Check their disposition before assigning overlapping work. This plan does not
merge either PR or assume it has landed.

## What AAMF can and cannot supply today

These findings describe the pinned AAMF revision above. Prefer its source over
CLI help or README text where they disagree.

| Capability | Verified behavior | Application to PSFlow |
|---|---|---|
| Source analysis | Phase 0 indexes source with Lore; phase 1 derives dependency tasks. Includes/excludes apply to source indexing. | Start with `packages/system/src` and `packages/react/src`. Inspect symbol and edge coverage before trusting the graph. |
| Target mapping | Mapping replaces the source extension and preserves its relative path. PureScript is absent from the extension table. | Add explicit mappings into PSFlow's existing module layout; adding `.purs` alone is insufficient. |
| Existing implementation | Task construction is source-driven. It is not a comparison of completed target behavior against source. | Supply a reconciliation step that distinguishes reuse, boundary work, behavior fixes, evidence gaps, and accepted differences. |
| Project guidance | Root `guidance: string[]` is inserted into agent contexts. | Point agents to the existing porting rules and constrain each task's output. Guidance is not an enforced write boundary. |
| Agent runtimes | Config accepts `copilot` and `claude-code`. | An execution run needs a supported CLI and its authentication. Native Codex is not a configured backend in this revision. |
| Build and tests | `target` accepts `buildCommand`, `testCommand`, `formatCommand`, and `lintCommand`. | Connect the actual PSFlow commands; an agent's parity judgment cannot replace their results. |
| Target indexing | AAMF re-indexes target changes through Lore with LSP disabled. | Prove that `.purs` symbols are indexed, or implement an explicit supported alternative before relying on target queries. Successful indexing of FFI `.js` files alone proves little about PSFlow. |
| Checkpointing | Resume and restart-from-phase exist; phase 4 prefers structured task output over a JSON artifact fallback. | Do not assume hand-editing `tasks-merged.json` replaces the executable graph. Mapping and task selection must reach the actual runtime task state. |

Sources: [configuration schema](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/config/schema.ts),
[context construction](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/agents/context-builder.ts#L130-L131),
[task construction](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/core/task-graph-builder.ts),
[target indexer](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/core/target-indexer.ts#L33-L35),
[phase 4 task discovery](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/flow/steps/migration.ts#L1282-L1306).

### Execution boundaries to understand first

- `--phase 1` runs phases **0 through 1**. It is the appropriate cutoff for
  initial indexing and task derivation in an isolated workspace.
- `--dry-run` validates and returns before executing any phase. It does not
  produce the dependency graph or a migration plan, despite the CLI help text.
  It still initializes checkpoint/progress state.
- `--phase 3` includes planning **and scaffolding**. It can write target files,
  build the scaffold, and commit when Git automation is enabled. It is not a
  documentation-only planning mode.
- A fresh non-resume run clears previous run artifacts. Startup can also recover
  a pending target change set before executing a phase. Use a new project name,
  isolated state, and disposable source/target copies for analysis.

Sources: [CLI](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/index.ts#L13-L19),
[runtime startup and dry run](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/core/runtime.ts#L229-L294),
[phase 3](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/flow/steps/planning.ts),
[fresh-run cleanup](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/src/core/run-provenance.ts).

## Step 1: use AAMF for a bounded upstream inventory

**Status: complete, 2026-11-09.** See the requirement-by-requirement
[completion report](AAMF_STEP1_RESULTS.md). The instructions below describe the
bounded inventory procedure; AAMF's internal phases are distinct from the
numbered steps in this plan.

Prepare an isolated workspace, for example `/private/tmp/psflow-aamf/`, with
three independent directories: the pinned AAMF checkout, a copy of the complete
vendored xyflow tree, and a copy of the existing PSFlow checkout. Preserve
upstream package manifests and TypeScript configuration for index resolution.
Keep target output outside the indexed source tree.

Use Node 22 or a compatible newer version. AAMF's package is private; build its
CLI from the repository root with `npm ci` and `npm run build`, then invoke
`dist/index.js`. These paths and requirements come from
[AAMF's package manifest](https://github.com/jafreck/AAMF/blob/7dc475d81ef9796b5b90f57a29475eaafa375753/package.json).
Source indexing may require installing source dependencies and authorizing its
SCIP subprocess; keep that setup inside the source copy.

The following is the **original proposed analysis configuration**, checked
against the schema by inspection. The actual Step 1 configuration and extra
TypeScript resolution setup are recorded in [its results](AAMF_STEP1_RESULTS.md).
Save configurations only in the isolated workspace. Use a new `projectName`
for another fresh experiment.

```json
{
  "projectName": "psflow-gap-analysis-2026-11-07",
  "source": {
    "path": "/private/tmp/psflow-aamf/source/xyflow",
    "language": "typescript",
    "languages": ["typescript"],
    "includePatterns": [
      "packages/system/src/**/*.ts",
      "packages/react/src/**/*.ts",
      "packages/react/src/**/*.tsx"
    ],
    "excludePatterns": [
      "node_modules", ".git", "dist", "build",
      "**/*.test.ts", "**/*.spec.ts"
    ]
  },
  "target": {
    "language": "purescript",
    "outputPath": "/private/tmp/psflow-aamf/target/PSFlow"
  },
  "options": {
    "maxParallelAgents": 1,
    "git": {
      "enabled": false,
      "autoInit": false,
      "commitPerTask": false
    },
    "kbIndex": {
      "execution": { "allowSubprocessExecution": true },
      "lsp": { "enabled": false },
      "embeddings": { "enabled": false }
    }
  },
  "agentBackend": {
    "runtime": "claude-code",
    "cliCommand": "claude"
  },
  "guidance": [
    "The target is an existing PureScript port. Reuse its modules and architecture.",
    "Read the target's PORTING.md, CONTEXT.md, and README.md before proposing changes.",
    "Business logic belongs in PureScript. Keep FFI limited to platform and interop operations.",
    "Treat generated target paths as provisional until reconciled with existing .purs modules."
  ]
}
```

The runtime selection illustrates a supported backend; use an already available
supported CLI when preparing the real environment. Phases 0 and 1 are runtime
analysis steps, not code-writing agent phases. This configuration does **not**
solve target mapping and must not be promoted unchanged into an execution run.

For this pinned source/tooling combination, apply the
[phase 0 compatibility fixes](tools/aamf/README.md) after installing AAMF's
dependencies. The completed Step 1 project and its latest checkpoint are
recorded in [the Step 1 results](AAMF_STEP1_RESULTS.md); retain that state
instead of restarting it as a fresh run.

From the isolated workspace, after building its AAMF checkout:

```sh
node /private/tmp/psflow-aamf/AAMF/dist/index.js migrate \
  -c /private/tmp/psflow-aamf/analysis.json --phase 1
node /private/tmp/psflow-aamf/AAMF/dist/index.js status \
  -c /private/tmp/psflow-aamf/analysis.json
```

Review the indexing diagnostics and graph artifacts. In this checkout, the
intended source scope contains 44 system and 127 React `.ts`/`.tsx` files.
Recount for the actual snapshot and explain omitted files. Inspect resolved
cross-package edges, unresolved imports, large cycles, and file-only fallback
tasks. A successful process exit does not establish a useful call graph.
Keep Svelte, examples, tests, styles, and tooling outside migration task scope;
retain them as reference/validation assets where needed. Add upstream JavaScript
to the inventory if present and relevant, after verifying its indexing coverage.

## Step 2: reconcile the inventory with the existing port

**Status: complete, 2026-11-09.** See the [completion report](AAMF_STEP2_RESULTS.md)
and [maintained integration](AAMF_STEP2_INTEGRATION.md). The procedure below
records the requirements satisfied by the bounded pilot.

Create a reviewed mapping artifact before enabling phase 4. This is a proposed
PSFlow integration artifact, **not an existing AAMF configuration feature**.
Give each source unit these fields:

| Field | Required content |
|---|---|
| Source | Pinned package, file, symbol, and the callers needed to understand its mechanism |
| Target | Existing `.purs` module(s), JS boundary converter, and any necessary FFI |
| Disposition | Reuse; finish conversion; fix behavior; add evidence; accepted difference |
| Evidence | Gate, test/scenario, and the precise behavior it observes |
| Work | One observable gap, permitted output files, dependencies, and acceptance criteria |

Examples of mappings that cannot be produced by extension replacement:

| Upstream | Existing PSFlow destination |
|---|---|
| `packages/system/src/utils/general.ts` | `src/System/Utils/General.purs`, plus boundary handling for JS consumers |
| `packages/system/src/xyresizer/XYResizer.ts` | `src/System/XYResizer.purs`, `src/System/XYResizer/Utils.purs` |
| `packages/react/src/utils/changes.ts` | `src/React/Store/Changes.purs`, `src/Boundary/Utils.purs` |
| `packages/react/src/store/index.ts` | `src/React/Store/Action.purs`, `Reduce.purs`, `Shell.purs`, and related store modules |
| React hooks/components | Existing `src/React/Hook/`, `Component/`, `Container/`, and `src/Boundary/` modules |

A source file can map to several target modules, and several source units can
share one target module. Use the resulting **target file overlap** as an
additional scheduling dependency. Source independence alone does not make two
tasks safe to execute concurrently.

Before executing migration tasks, implement and verify these integration pieces
in a separate AAMF change or a maintained adapter:

1. Correct `.purs` extensions and explicit existing-module mappings.
2. Reconciliation that keeps already implemented units out of the write queue,
   while retaining them as dependencies and reference context.
3. A supported route for that reconciled graph to become the runtime's actual
   task inventory, including checkpoint/resume behavior.
4. Target indexing that can represent PureScript, or an explicit alternative
   that supplies target context without claiming nonexistent symbol coverage.
5. Reuse of the existing Spago/package setup; phase 3 must preserve the working
   target rather than generate a parallel project structure.

Pilot this with the JS crossing of `getViewportForBounds`: retain the existing
PureScript implementation, accept upstream's call/default conventions, and
return the expected JS viewport. Pass its surface behavior check and a local
regression test, then confirm no unrelated module or project scaffold changed.
Start with one agent and `per-task` execution. Raise concurrency only after
mapping and file ownership have been demonstrated.

If those integration changes cost more than the remaining port work, retain
AAMF for source indexing and dependency analysis and execute the reviewed tasks
through the current PSFlow workflow. Record that limitation explicitly; do not
describe that fallback as a completed autonomous AAMF migration.

## Step 3: complete the remaining work in dependency order

The following is a proposed queue, to refine against fresh captures. Independent
branches may proceed once their prerequisites and target-file ownership are
clear. Each behavior fix needs its own observable acceptance criterion.

| Order | Work and existing starting point | Acceptance / dependency |
|---|---|---|
| A | Establish a fresh baseline after checking the two open PRs. Rebuild PSFlow, oracle, and driver; run the gates below. Cluster remaining differences by mechanism. | Save results with the exact source/target revisions. Resolve self-inconsistency before interpreting affected scenarios. |
| B | Finish boundary stage 5 from the **current** manifest: `getConnectedEdges`, `getIncomers`, `getOutgoers`, `getNodesBounds`, `reconnectEdge`, `isNode`, `isEdge`. The six edge-path helpers and Step 2 viewport pilot already have converters. | Empty `passthrough`, stage 5 recorded, and applicable transitional allowlist entries retired while surface parity remains green. Use [the older stage specification](tickets/082-boundary-stage-5-pure-functions.md) for intent, not its obsolete count of fourteen remaining functions. |
| C | Preserve consumer objects, keys, and identity in `applyNodeChanges`, `applyEdgeChanges`, and `addEdge`; inspect `reconnectEdge` as part of B. Start with [Hand back the consumer's own nodes and edges](https://github.com/jonbae/PSFlow/issues/150) and `src/Boundary/Utils.purs`. | Untouched elements retain reference identity; changed copies retain custom keys and explicitly present `undefined`; added edges retain consumer fields. Remove the three issue-owned return-value allowlist entries. B and C share boundary concerns and should be serialized where files overlap. |
| D | Restore original-node provenance through adoption and internal-node conversion. `NodeInternals` and `JsNodeInternals` currently omit `userNode`. | `getInternalNode().internals.userNode` and any reference-sensitive consumers match upstream. Coordinate the representation with C; a fabricated equivalent record does not preserve identity. |
| E | Re-measure callback ordering, keyboard behavior, and auto-pan against upstream. The committed report marks `drag-node-autopan`, `arrow-key-selected-node`, and `drag-node-reports-changes` self-inconsistent. Account for the open keyboard/handle-bound PRs first. | Both captures reproduce before their cross-side diff is interpreted. Port timing and state reads; do not remove callbacks or broaden tolerance to gain green. |
| F | Complete the genuine resize implementation gap in [the XYResizer lifecycle](tickets/073-xyresizer-drag-lifecycle-scaffold.md). `onStart`, `onDrag`, and `onEnd` still emit initial/zero values and ignore resize state. | Maintain start/previous values and resize detection; call the existing resize math; match constraints, parent/child changes, `shouldResize`, mid-drag prop updates, and callback payload/order. Add a fixture that actually resizes plus a local lifecycle test. |
| G | Close explicit JS compatibility gaps: `useStore` / `useStoreApi` currently throw in `Boundary.Hooks`; thirteen `defaultEdgeOptions` fields are refused in `Boundary.Flow`. Check missing edge/node fields against source. | Implement a faithful JS store view and required edge fields/default merge behavior, or record precise permanent exclusions. A callable export that throws is not full functional parity. Keep read identity, subscriptions, setters, and mutation semantics in the store task's scope. |
| H | Add missing behavioral witnesses and deepen function parity. Start with the coverage register and the scenarios below. | A new witness must fire upstream as well as PSFlow. Retire the matching hole only after capture proves it. Keep declared behavior debt separate from export counts. |
| I | Finish distribution compatibility after runtime behavior is settled: `.d.ts` for JS/TS consumers, package entry points, and distributable styles/assets. | Declarations describe the actual crossed JS API and accepted gaps. They must not expose PureScript ADT representations or blindly promise all upstream behavior. PureScript remains the implementation language. |

D and E are high-impact investigation candidates: the committed report repeats
missing `internals.userNode`, callback ordering differences, and null-vs-empty
handle bounds across many scenarios. Those repeated rows are evidence to trace
back to shared causes, not permission to assume each has one cause. The
handle-bound PR already addresses part of that list.

### Prioritize scenarios that prove an unobserved condition

- [Drag a selection](https://github.com/jonbae/PSFlow/issues/111): select at least
  two nodes, drag the selection, and witness all three selection-drag callbacks
  on both sides. A grid variant can also exercise multi-node snapping.
- [Hold auto-pan past the translate extent](https://github.com/jonbae/PSFlow/issues/108):
  witness at least one refused pan frame. Decide how callback frame counts are
  made reproducible; longer wall-clock sleeps alone do not prove that.
- Add a resize fixture for F; custom edge types and connection-line components;
  portal content; alternate built-in edge types; an edge toolbar; reconnect
  gestures; and supported default edge options. These are starting points in
  [the hole register](parity/system/coverage/holes.json), not claims that all
  need separate new fixtures.
- Reassess the withheld `onInit` driver callback: its converter exists, while
  the hole register still describes it as absent from captures.
- Extend [function parity](tickets/059-layer1-behavioral-parity-coverage.md)
  for node-bounds/origin/internal-node functions using richer oracle inputs
  when that gives evidence the browser corpus cannot provide.

Respect [reserved scenario IDs](parity/system/corpus/reserved.mjs), the fork
register, and per-test retirement evidence. A scenario that merely has a
relevant name is not proof it reaches the intended branch.

## Verification contract for AAMF tasks

Preserve upstream's mechanism as [PORTING.md](PORTING.md) requires: missing vs
`undefined` vs `null`, insertion order, reference identity, optional Boolean
defaults, uncurried JS calls, DOM shape, effect order, microtasks, animation
frames, and pre-update store reads. Keep the existing React/store design until
parity is established. Leave AAMF's optional idiomatic refactor disabled during
this effort.

For an eventual execution config, begin with `target.buildCommand` set to
`spago build`. Set `target.testCommand` to a deliberately chosen existing
validation sequence, with surface parity first. Do not set the entire currently
red system corpus as every task's unconditional success gate: that would make
unrelated known differences block all progress.

| Checkpoint | Commands in the target root | What the result means |
|---|---|---|
| Baseline / integration point | `spago build`, `npm run build:oracle`, `npm run build:driver` | Gates read current compiled output and regenerated bundles. The driver build includes a build too. |
| Every task | `npm run parity:surface`, then `spago test` | Surface convention remains usable, and function parity/unit tests pass. A behavior-fix task includes a local test demonstrated red before its fix. |
| Boundary or hook change | `npm run parity:boundary` and relevant existing boundary tests | Includes checks that the per-PR CI does not run, such as server rendering hooks. |
| Browser behavior change | `npm run test:conformance`, `npm run test:smoke`, and `node parity/system/net.mjs --scenario <existing-or-added-id>` | Compare affected behavior from a freshly compiled target. If a scenario cannot see the class, add evidence in a task that explicitly owns that change. |
| Corpus / gate machinery change | Relevant `test:harness`, `test:coverage`, `test:compare`, `test:census`, `test:surface`, or `test:boundary`; `npm run parity:fork` | Verify the apparatus and its registers, in addition to behavior. |
| Wave / final checkpoint | `npm run parity:system`, `npm run parity:changelog` | Re-capture the full corpus and reassess debt against the fixed baseline. |

Use the PureScript toolchain pinned by [CI](.github/workflows/gates.yml):
PureScript 0.15.16 and Spago 1.0.4, with dependencies from the committed locks.
Maintain the provenance checks that prevent either driver from silently loading
the wrong library. Rebuild before a revert/probe experiment too; stale `output/`
would invalidate its conclusion.

Generated reports and traces are evidence artifacts. Regenerating them changes
tracked files; commit them only in a task that owns that refresh. AAMF agents
must not alter comparator rules, fixtures, tests, regions, or allowlists unless
that task explicitly includes the change. Any accepted difference needs a
specific reason; temporary claims carry their owning issue and retire when
their cause disappears.

## Completion criteria

Treat the port as complete against the pinned baseline when:

- All relevant upstream units have a reviewed disposition and an existing
  PureScript destination or a precise documented exclusion.
- The four cheap gates and boundary checks pass from fresh output; the full
  system net passes with reproducible captures and no unresolved transitional
  regions or transitional surface exceptions.
- Stage 5 has no raw passthrough exports. Resize behavior and any remaining
  deliberate refusals have been implemented or explicitly scoped out of the
  advertised compatibility contract.
- Coverage has no undeclared residue. Remaining declared holes have specific
  reasons; behavior debt is implemented, gated, or explicitly accepted. A
  green net over unexercised behavior does not close that debt.
- JS consumers enter through `index.js`, PureScript consumers through `React`,
  and any published declarations/assets match the compatibility being claimed.
- The AAMF integration pilot, selected task graph, source/target revisions,
  validation results, and resume procedure are recorded for the next baseline.

Steps 1 and 2 are complete. The next plan step is Step 3: establish its fresh
baseline and choose the next bounded gap from the reviewed work contracts.
The viewport pilot is already crossed; the remaining boundary work and consumer
object preservation remain future work. This execution stopped after Step 2.
