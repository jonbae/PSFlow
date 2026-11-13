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
Overall port completion remains open.


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

**Status: started, 2026-11-09.** A / W00's baseline capture and triage are
complete; its original unstable experiments remain archived. E now supplies
reproducible replacement captures under the isolated protocol. **B / W02 is complete: stage 5, 68 crossed, zero passthroughs.** See the
[execution results](AAMF_STEP3_RESULTS.md). C through I are also complete.

The following is a proposed queue, to refine against fresh captures. Independent
branches may proceed once their prerequisites and target-file ownership are
clear. Each behavior fix needs its own observable acceptance criterion.

| Order | Work and existing starting point | Acceptance / dependency |
|---|---|---|
| A | Establish a fresh baseline after checking the two open PRs. Rebuild PSFlow, oracle, and driver; run the gates below. Cluster remaining differences by mechanism. | Save results with the exact source/target revisions. Resolve self-inconsistency before interpreting affected scenarios. |
| B | **Complete.** All seven remaining graph/bounds/reconnection/guard crossings landed in serialized W02 tasks, after the six edge-path helpers and Step 2 viewport pilot. | Empty `passthrough`, stage 5 recorded, matching transitional exceptions retired, surface parity green, and source-based JS-entry regressions pass. See [the results](AAMF_STEP3_RESULTS.md). |
| C | Preserve consumer objects, keys, and identity in `applyNodeChanges`, `applyEdgeChanges`, and `addEdge`; inspect `reconnectEdge` as part of B. Start with [Hand back the consumer's own nodes and edges](https://github.com/jonbae/PSFlow/issues/150) and `src/Boundary/Utils.purs`. | Untouched elements retain reference identity; changed copies retain custom keys and explicitly present `undefined`; added edges retain consumer fields. Remove the three issue-owned return-value allowlist entries. B and C share boundary concerns and should be serialized where files overlap. |
| D | Restore original-node provenance through adoption and internal-node conversion. `NodeInternals` and `JsNodeInternals` currently omit `userNode`. | `getInternalNode().internals.userNode` and any reference-sensitive consumers match upstream. Coordinate the representation with C; a fabricated equivalent record does not preserve identity. |
| E | **Complete.** Keyboard aria-live announcements, native focus-visible gating and the real focus-centering store effect match upstream. The shared viewport-end timer correction is retained. Browser driving now isolates native layout, timer completion, per-frame hover delivery and capture input state; a version-matched Linux runner isolates Mac physical modifiers. PR194 and PR195 were reviewed/adapted without merging or cherry-picking. | All nine targeted scenarios pass five independent rounds (180 raw traces), including full callback logs and across-round checks. The fresh 107-scenario wave has zero self-inconsistency or driving divergence. Four deliberate restored-defect probes are rejected by the unchanged official comparator. See [Order E results](AAMF_STEP3_RESULTS.md#order-e-completion-november-12-utc). |
| F | **Complete.** XYResizer maintains gesture state and uses the existing solver. The mounted JS controls resize and receive changed limits during a drag. | Basic lifecycle plus 65 vendored-source differential cases, actual control/store proxies, and mounted receipts. The full net remains red on separate differences; see [results](AAMF_STEP3_RESULTS.md). |
| G | **Complete.** `Boundary.Store` gives the store upstream's JavaScript shape: 85 members and 20 actions, the consumer's own objects, zustand's `setState`/`subscribe`/direct-write semantics, and `useStore`'s selector and `equalityFn`. `Edge`, `Node` and `DefaultEdgeOptions` carry every upstream member, and the edge merge, `onConnect` parameters, rendering and markers follow upstream's. | Store members, identity and write semantics match upstream in JS-entry tests; edge and node rendering match upstream's server render; the merge matches upstream's spread and `addEdge`. Four precise exclusions throw with messages. The flow probes lost every store difference. See [Order G results](AAMF_STEP3_RESULTS.md#order-g-completion-november-12-utc). |
| H | **Complete.** Every hole upstream can fire has a witness on both sides; one store-action hole stays declared. The flow-node probes pass after node-size, deprecation-warning, selection-listener and render-count fixes. Consumer reads, handler payloads and the server snapshot follow upstream's objects, and the remaining W13 numeric call sites and three node-geometry functions are under exact or oracle comparison. | A new witness must fire upstream as well as PSFlow. Retire the matching hole only after capture proves it. Keep declared behavior debt separate from export counts. |
| I | **Complete.** `npm run build:package` writes `dist/`: `index.js` and the compiled PureScript as one ES module, upstream's declarations generated from the vendored source with ps-flow's gaps written in, and upstream's stylesheets byte for byte. `package.json` exports them at upstream's paths, with React as a peer. Giving every export only what its declaration requires found `<Panel />` refusing an omitted `position` and server renders logging a layout-effect warning; both are fixed. | `parity:package` installs the packed package into a scratch consumer: the same names, shapes and server render as `index.js`, the stylesheets the driver loads, and a consumer that type-checks under bundler and Node 16 resolution. The declarations expose no PureScript type, and their header and two overlays state every known difference. PureScript remains the implementation language. See [Order I results](AAMF_STEP3_RESULTS.md#order-i-completion-november-13-utc). |

D and E are high-impact investigation candidates: the committed report repeats
missing `internals.userNode`, callback ordering differences, and null-vs-empty
handle bounds across many scenarios. Those repeated rows are evidence to trace
back to shared causes, not permission to assume each has one cause. The
handle-bound PR already addresses part of that list.

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
remains open: 50 behavior-debt rows await their gates, and
`getInternalNodesBounds` and `getNodesInside` have no function parity.
