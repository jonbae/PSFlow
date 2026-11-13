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
the repository.

**Step 3's queue is complete, updated 2026-11-13 UTC.** W00 established a fresh baseline at
`98a3f77ab1bb17d481c6dec4fed2e23174448e45`: the four cheap gates and boundary
checks passed, while 100 of 103 system scenarios failed. Its four self-inconsistent
scenarios were excluded pending E; the current isolated checkpoint reproduces all scenarios. All seven W02 crossings
then passed red/green JS-entry regressions and applicable gates. **Step 3 B is
complete: boundary stage 5 has 68 crossed exports and zero passthroughs.** See
[Step 3 results](AAMF_STEP3_RESULTS.md) and [evidence](aamf/step3/README.md).
**Step 3 C / W03 is complete, 2026-11-10:** change/add helpers retain original
consumer references and enumerable keys, and their three issue-150 return-value
exceptions have retired. Applicable surface/function/boundary checks pass.
**D / W04 is also complete:** original-node references survive adoption and JS
conversion, with focused reproducible browser evidence. E / W11 is now complete. **W08a onInit scheduling and W08b viewport listener mechanics are
complete**, with red/green public-interface proxies and a passing browser
checkpoint. **F / W05 resize lifecycle is now complete**, with genuine mounted
resize witnesses. G's missing `node.resizing` field is also implemented and
verified. E's bounded keyboard protocol and H's `onInit` witness are now complete.
The shared handle-bound and viewport-end scheduling fixes remain complete.
Order E is complete: keyboard announcements, focus panning, callback ordering
and gesture reproducibility are validated. **Order G is complete,
2026-11-12 UTC:** `useStore` and `useStoreApi` hand JavaScript consumers
upstream's store with zustand's read and write semantics, and all 23
`defaultEdgeOptions` members and the edge and node members they depend on are
implemented; see [Order G results](AAMF_STEP3_RESULTS.md#order-g-completion-november-12-utc).
**Order H is complete, 2026-11-12 UTC:** every coverage hole upstream can fire
has a witness on both sides, the flow-node probes pass, and consumers read back
their own objects as upstream hands them; see
[Order H results](AAMF_STEP3_RESULTS.md#order-h-completion-november-12-utc).
The fresh Linux checkpoint captures all 115 scenarios: **115 pass and 0 fail**, with **zero self-inconsistent scenarios and zero driving divergences**. Coverage is
**155/156 driven, 1 declared hole**, with 50 separate behavior-debt rows.
**Order I is complete, 2026-11-13 UTC:** `npm run build:package` builds a
package for JavaScript and TypeScript consumers: one ES module bundled from
`index.js`, upstream's declarations with ps-flow's gaps written in, and
upstream's stylesheets. `npm run parity:package` holds the packed package to
`index.js`, and the declarations exposed two runtime differences, both fixed;
see [Order I results](AAMF_STEP3_RESULTS.md#order-i-completion-november-13-utc).
Overall port completion remains open; [Step 4](#step-4-close-the-completion-criteria)
lists what is left.


**H / bounded W13 numeric work is implemented, November 11:** shared geometry
and resize helpers now preserve JavaScript's `NaN` and signed-zero min/max
behavior. Exact source comparisons and a real controller regression pass.
The [numeric task evidence](aamf/step3/numeric-semantics/) records its focused
browser checks and the then-current 95-failure checkpoint. The newer shared-fix
checkpoint is preserved; the Order E task provides the newer result above. Order H
moved the five other call sites W13 named to the same semantics.

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
| Boundary | [Manifest](src/Boundary.js): stage 5, all 68 values crossed, zero passthroughs | W02 and W03 are complete; the three consumer-object exceptions have retired. Order G replaced the store-hook and `defaultEdgeOptions` refusals with conversions; four precise exclusions remain, such as replacing the whole store state. |
| Surface report | [Current snapshot](parity/surface/report.md) refreshed at stage 5 | Passed; all stage-5 call-convention exceptions retired. [Step 3 results](AAMF_STEP3_RESULTS.md) distinguish baseline and checkpoint evidence. |
| System report | [Order I Linux checkpoint](parity/system/report.md): 115 of 115 passed, zero self-inconsistent | The Order H checkpoint it replaces is [preserved](aamf/step3/order-i/before-checkpoint.tar.gz), as are the Order G checkpoint ([archive](aamf/step3/order-h/before-checkpoint.tar.gz)), the Order E checkpoint ([archive](aamf/step3/order-g/before-checkpoint.tar.gz)) and the preceding 99-pass/8-failure Mac checkpoint ([archive](aamf/step3/order-e/before-canonical-checkpoint.tar.gz)); earlier checkpoints remain in their task archives. Capture platform, exact runtime, unchanged comparison policy and reproducibility evidence are recorded in [Order E](aamf/step3/order-e/). |
| Coverage | [Current coverage](parity/system/coverage.md): 155 of 156 export-bearing entries driven, 1 declared hole; 50 behaviors still awaiting gates | A declared hole is accounted for, not implemented or verified by that declaration. Export coverage and behavior coverage are different measures. |
| Package | `npm run build:package` writes `dist/`, which `npm pack` publishes; [how it is built](distribution/README.md) | `npm run parity:package` holds it to `index.js` in a scratch consumer. `package.json` stays `private`: publishing is a separate decision. |
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

Both remained open at the Step 3 W00 recheck on 2026-11-09. Check their
disposition before assigning overlapping work. This plan does not merge either
PR or assume it has landed.

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

**Status: complete, 2026-11-13 UTC.** Work started on 2026-11-09, and orders A
through I are all complete. A / W00's original unstable experiments remain
archived; E supplies reproducible replacement captures under the isolated
protocol. See the [execution results](AAMF_STEP3_RESULTS.md). Overall port
completion remains open; see [Completion criteria](#completion-criteria).

The following queue was refined against fresh captures. Independent branches
proceeded once their prerequisites and target-file ownership were clear. Each
behavior fix has its own observable acceptance criterion.

| Order | Work and existing starting point | Acceptance / dependency |
|---|---|---|
| A | **Complete.** W00 checked the two open PRs, rebuilt PSFlow, oracle, and driver at `98a3f77a`, ran the gates below, and clustered the remaining differences by mechanism. E resolved the self-inconsistent scenarios. | Save results with the exact source/target revisions. Resolve self-inconsistency before interpreting affected scenarios. See [the baseline](AAMF_STEP3_RESULTS.md#fresh-baseline-step-3-a--w00). |
| B | **Complete.** All seven remaining graph/bounds/reconnection/guard crossings landed in serialized W02 tasks, after the six edge-path helpers and Step 2 viewport pilot. | Empty `passthrough`, stage 5 recorded, matching transitional exceptions retired, surface parity green, and source-based JS-entry regressions pass. See [the results](AAMF_STEP3_RESULTS.md). |
| C | **Complete.** `applyNodeChanges`, `applyEdgeChanges`, and `addEdge` preserve consumer objects, keys, and identity, as [Hand back the consumer's own nodes and edges](https://github.com/jonbae/PSFlow/issues/150) asks; `reconnectEdge` crossed under the same policy in B. | Untouched elements retain reference identity; changed copies retain custom keys and explicitly present `undefined`; added edges retain consumer fields. The three issue-owned return-value allowlist entries are removed. See [the results](AAMF_STEP3_RESULTS.md#consumer-objects-step-3-c--w03-november-10). |
| D | **Complete.** Original-node provenance survives adoption and internal-node conversion: `NodeInternals` carries the actual typed `userNode`, and the outbound `internals.userNode` resolves the consumer's own JS object. | `getInternalNode().internals.userNode` and any reference-sensitive consumers match upstream. A fabricated equivalent record does not preserve identity. See [the results](AAMF_STEP3_RESULTS.md#original-node-provenance-step-3-d--w04-november-10). |
| E | **Complete.** Keyboard aria-live announcements, native focus-visible gating and the real focus-centering store effect match upstream. The shared viewport-end timer correction is retained. Browser driving now isolates native layout, timer completion, per-frame hover delivery and capture input state; a version-matched Linux runner isolates Mac physical modifiers. PR194 and PR195 were reviewed/adapted without merging or cherry-picking. | All nine targeted scenarios pass five independent rounds (180 raw traces), including full callback logs and across-round checks. The fresh 107-scenario wave has zero self-inconsistency or driving divergence. Four deliberate restored-defect probes are rejected by the unchanged official comparator. See [Order E results](AAMF_STEP3_RESULTS.md#order-e-completion-november-12-utc). |
| F | **Complete.** XYResizer maintains gesture state and uses the existing solver. The mounted JS controls resize and receive changed limits during a drag. | Basic lifecycle plus 65 vendored-source differential cases, actual control/store proxies, and mounted receipts. The resize scenarios pass in the full net; see [results](AAMF_STEP3_RESULTS.md#resize-lifecycle-f--w05-and-its-mounted-witnesses-h--w12). |
| G | **Complete.** `Boundary.Store` gives the store upstream's JavaScript shape: 85 members and 20 actions, the consumer's own objects, zustand's `setState`/`subscribe`/direct-write semantics, and `useStore`'s selector and `equalityFn`. `Edge`, `Node` and `DefaultEdgeOptions` carry every upstream member, and the edge merge, `onConnect` parameters, rendering and markers follow upstream's. | Store members, identity and write semantics match upstream in JS-entry tests; edge and node rendering match upstream's server render; the merge matches upstream's spread and `addEdge`. Four precise exclusions throw with messages. The flow probes lost every store difference. See [Order G results](AAMF_STEP3_RESULTS.md#order-g-completion-november-12-utc). |
| H | **Complete.** Every hole upstream can fire has a witness on both sides; one store-action hole stays declared. The flow-node probes pass after node-size, deprecation-warning, selection-listener and render-count fixes. Consumer reads, handler payloads and the server snapshot follow upstream's objects, and the remaining W13 numeric call sites and three node-geometry functions are under exact or oracle comparison. | A new witness must fire upstream as well as PSFlow. Retire the matching hole only after capture proves it. Keep declared behavior debt separate from export counts. |
| I | **Complete.** `npm run build:package` writes `dist/`: `index.js` and the compiled PureScript as one ES module, upstream's declarations generated from the vendored source with ps-flow's gaps written in, and upstream's stylesheets byte for byte. `package.json` exports them at upstream's paths, with React as a peer. Giving every export only what its declaration requires found `<Panel />` refusing an omitted `position` and server renders logging a layout-effect warning; both are fixed. | `parity:package` installs the packed package into a scratch consumer: the same names, shapes and server render as `index.js`, the stylesheets the driver loads, and a consumer that type-checks under bundler and Node 16 resolution. The declarations expose no PureScript type, and their header and two overlays state every known difference. PureScript remains the implementation language. See [Order I results](AAMF_STEP3_RESULTS.md#order-i-completion-november-13-utc). |

At W00, the committed report repeated missing `internals.userNode`,
callback-ordering differences, and null-versus-empty handle bounds across many
scenarios. Each repeated row was traced to its own cause rather than assumed to
share one. D retired the missing `userNode`. The shared handle-bound and
viewport-end fixes retired the handle-bound rows and the initial
measurement/end inversions; they adapt PR195's source without merging it. E
retired the last callback-order row. The Order I report has none of these
differences.

### Prioritize scenarios that prove an unobserved condition

- **Complete:** [Drag a selection](https://github.com/jonbae/PSFlow/issues/111).
  `drag-selection-moves-selected-nodes` drags a two-node selection by its
  rectangle, and all three selection-drag callbacks fire on both sides. A grid
  variant could still exercise multi-node snapping.
- **Complete:** [Hold auto-pan past the translate extent](https://github.com/jonbae/PSFlow/issues/108).
  Under Order E's frame protocol, `drag-node-autopan-past-extent` drives frames
  after the viewport reaches the extent, and each refused frame is observed on
  both sides.
- **Complete:** resize handlers, custom and alternate built-in edge types,
  portal content, an edge toolbar, reconnect gestures and default edge options
  now have witnesses. Connection-line components were already driven by the
  connection-line probe.
- **Complete:** the `onInit` driver callback is now observed on both sides and
  its single coverage hole has retired. Initialization ordering remains E work.
- **Complete for user nodes:** [function parity](tickets/059-layer1-behavioral-parity-coverage.md)
  covers `getNodePositionWithOrigin`, `nodeToRect` and `nodeToBox`.
  `getInternalNodesBounds` and `getNodesInside` stay deferred; they need
  internal nodes the oracle does not build.

Respect [reserved scenario IDs](parity/system/corpus/reserved.mjs), the fork
register, and per-test retirement evidence. A scenario that merely has a
relevant name is not proof it reaches the intended branch.

## Step 4: close the completion criteria

**Status: open, 2026-11-13 UTC.** Step 3 finished its queue, but three of the
six [completion criteria](#completion-criteria) still have open work. The
other three hold. The gates and the full net pass from fresh output, with no
transitional claim in any register. Stage 5 has no passthrough exports. And
`index.js`, `React`, and the package give consumers the compatibility they
claim.

| Completion criterion | Rows that close it |
|---|---|
| Every relevant upstream unit has a reviewed disposition | 10 and 11 |
| Behavior debt is implemented, gated, or explicitly accepted | 3 through 9 |
| The pilot, task graph, revisions, validation results, and resume procedure are recorded for the next baseline | 12 |

Rows 1 and 2 are housekeeping that no criterion names. Run the rows in this
order: behavior fixes come before the evidence rows that depend on their
traces, and the map refresh comes last because it records everything before
it. Each task follows the [verification contract](#verification-contract-for-aamf-tasks).

The rough size counts the fresh tokens one Claude Code session reads and
writes, estimated on 2026-11-13. Billed tokens run higher, because each turn
rereads the conversation. Rows 5 through 12 come to roughly 1.5 million to 3.3
million tokens, and row 8 is about half of that.

| Order | Work and starting point | Acceptance | Rough size |
|---|---|---|---|
| 1 | **Complete, 2026-11-13 UTC.** [#196](https://github.com/jonbae/PSFlow/pull/196), [#197](https://github.com/jonbae/PSFlow/pull/197) and [#198](https://github.com/jonbae/PSFlow/pull/198) are merged, and each one's head is in `master`. [#194](https://github.com/jonbae/PSFlow/pull/194) and [#195](https://github.com/jonbae/PSFlow/pull/195), which Step 3 adapted, are closed without merging. [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93) is closed as completed. | `master` holds Steps 1–3 and both follow-ups, and the superseded PRs are closed. | Done |
| 2 | **Complete in [#200](https://github.com/jonbae/PSFlow/pull/200).** The full net runs on every pull request, last among the five gates, through `parity/system/linux.mjs` in the Playwright image its checkpoints were captured in. `test:boundary` runs after `parity:boundary`, and a red net keeps its report and traces as an artifact. #196 had added the boundary and package checks and pinned the runner to Ubuntu 24.04. | README and `gates.yml` record the schedule. `test:ci` holds the unfiltered trigger, the net's runner and place, and the checks after it, each with a falsification probe. README, `CONTEXT.md` and the net's README describe the passing net. | Done |
| 3 | **Complete in [#197](https://github.com/jonbae/PSFlow/pull/197).** Fall back to the consumer's own `default` node and edge types, as upstream does (upstream #5384 and #5735). | Rows #5384 and #5735 are in `unit`, and `parity/boundary/type-fallback.test.mjs` matches upstream. | Done |
| 4 | **Complete in [#198](https://github.com/jonbae/PSFlow/pull/198).** Rebucket the three rows Order G resolved: #5299 (`ariaRole`), #5317 (`domAttributes`), and #5472 (type-only). | Each row is in a covered bucket with evidence, and `ported-ungated` is empty. | Done |
| 5 | Animate viewport transitions (upstream #5276, the last `not-ported` row). `setViewportImpl`, `scaleToImpl`, and `scaleByImpl` in `src/System/XYPanZoom.purs` ignore `duration` and `ease`. They jump to the target and resolve their promise at once. Upstream hands d3 a transition from `getD3Transition` and resolves when the transition ends. Port that through the d3 FFI, and keep the decisions in PureScript. | A red/green test runs upstream's `XYPanZoom` beside the port on native timers. A mounted scenario with a `duration` matches upstream's `onMove` sequence frame by frame. Row #5276 leaves `not-ported`, and the full wave passes. | 150k–300k |
| 6 | Compare selector results by upstream's equality (Step 2's W09). `useNodesData` (`src/React/Hook/Selectors.purs:142`) compares whole internal nodes by value. Upstream's `shallowNodeData` compares only `id`, `type`, and `data`, and compares `data` by reference. `useNodes`, `useEdges`, `useInternalNode`, and the toolbar selectors need the same direct comparison. Do this before row 8, because a fix changes captured traces. | The [W09 contract](AAMF_STEP2_RESULTS.md#w09--compare-selector-results-by-upstreams-equality): a probe against upstream observes returned projections and render counts, and only a demonstrated mismatch is fixed. | 100k–250k |
| 7 | Gate the five `unit` rows and three `function` rows. One `isInputDOMNode` predicate test covers #4880, #5090, #5118, and #5263, and a handle-id parsing test covers #5515. The function rows need checks against the oracle bundle for the selection helpers (#4929), connection snapping (#5266), and the parent-chain walk (#5550). | Each row moves to its covered bucket with evidence, and a falsification probe turns each new test red. | 140k–260k |
| 8 | Retire the 42 `system` rows. Each names one of 30 written, passing scenarios, but a passing scenario isn't proof it reaches the change's branch. For each row, revert that change's port in a scratch copy and watch the scenario fail, or show that the trace holds the branch's observable. Then move the row to `system`. Batch the rows by scenario, 8–10 per session, after rows 5 and 6 settle. If a scenario doesn't reach its branch, change it in a task that owns the corpus change. | All 42 rows are in `system` with evidence, and no `gate-pending` row names the net. | 700k–1.5M |
| 9 | Add function parity for `getInternalNodesBounds` and `getNodesInside`. Both take internal nodes, which the oracle doesn't build. Teach the oracle to build them the way upstream adopts user nodes. | Both functions are under differential function parity with a falsification probe, and [ticket 059](tickets/059-layer1-behavioral-parity-coverage.md) lists them as covered. | 80k–200k |
| 10 | Audit the type contracts field by field (Step 2's W10). Scope it first, because Orders G and H already compared many of the 14 E02 units' fields with upstream. Write `AAMF_TYPE_CONTRACT_REVIEW.md` one field and its callers at a time. | The [W10 contract](AAMF_STEP2_RESULTS.md#w10--audit-remaining-type-and-boundary-contracts-by-field): each guard, default, and absence branch is compared with an oracle call or a falsifying test, and each demonstrated gap is fixed in its own task. | 200k–500k |
| 11 | Refresh the reconciliation map. `aamf/step2/reconciliation.json` and [the mapping](AAMF_STEP2_MAPPING.md) still hold Step 2's dispositions: 42 Reuse, 99 Add evidence, 25 Fix behavior, 4 Finish conversion, and 1 Accepted difference. Update them from Steps 3 and 4 by profile. Use a script, because the JSON file is 16,673 lines. | Every unit's disposition and evidence describe the current code. No unit says Fix behavior or Finish conversion unless a row here owns it. | 60k–150k |
| 12 | Record the procedure for the next baseline. Steps 1 and 2 recorded their AAMF runs. Steps 3 and 4 ran through PSFlow's own workflow, with the AAMF inventory as context rather than as an autonomous AAMF migration. Record that, and record what a baseline bump reruns. | Someone holding only the repository can redo the inventory, the reconciliation, and the gates against a new baseline. | 40k–100k |

None of the following is required by the completion criteria:

- **Publishing the package.** `package.json` stays `private`, and publishing
  is a separate decision.
- **The declared coverage hole.** `UnselectNodesAndEdgesParams` already has a
  specific written reason, which satisfies the coverage criterion. Driving it
  means changing what the `api` witness can name, which is a change to the
  register, not to the corpus.

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
| Boundary or hook change | `npm run parity:boundary` and relevant existing boundary tests | Per-PR CI runs `parity:boundary`, including its server-rendering hook checks, and the boundary tests, after the net; run both locally before pushing. |
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

Steps 1 and 2 are complete. Step 3 A–D are complete, including stage 5, consumer
objects and original-node provenance. W08a onInit timing and W08b viewport
listener mechanics are also complete. F / W05, the resize witness family and
G's `node.resizing` field are complete. E's bounded keyboard protocol and H's
`onInit` witness are also complete. Bounded initialization/native-frame driving is
also complete. E / W11 is now complete, including keyboard behavior and isolated
viewport/gesture reproducibility. G is complete: the JS store view and the
default-edge, edge and node members. H is complete: the witnesses, reference
reads and numeric call sites. I is complete: the package, its declarations and
stylesheets, and `parity:package`. A–I are complete. Overall port completion
remains open; [Step 4](#step-4-close-the-completion-criteria) lists the
remaining work in order.
