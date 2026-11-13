# AAMF Step 2 — maintained integration and pilot

**Complete, 2026-11-09.** This implements the integration requirements in
[Step 2](AAMF_PORTING_PLAN.md#step-2-reconcile-the-inventory-with-the-existing-port).
The previous documentation-only design is superseded by this executed result.
See [results](AAMF_STEP2_RESULTS.md) and [preserved evidence](aamf/step2/README.md).

## Integration boundary

The adapter in [tools/aamf](tools/aamf/README.md#step-2-existing-project-adapter)
is opt-in and pinned to AAMF `7dc475d81ef9796b5b90f57a29475eaafa375753`.
Seven guarded distribution patches plus `psflow-integration.mjs` provide the
integration; these are not stock configuration keys. Install after building
AAMF and reapply after rebuilding. Unknown builds are rejected before writes.
The certified source index uses the maintained Lore 0.4.2 compatibility fixes
from Step 1. No upstream source or certification threshold was changed here.

| Concern | Implemented route |
|---|---|
| Existing paths | Join the reviewed 171-file map with certified source hashes/import consumers; canonicalize explicit `.purs`/converter/test paths beneath the target root |
| Reconciliation | Select only the reviewed viewport gap; preserve all 120 original tasks and four cyclic groups as read-only source context; do not fabricate completed dependency tasks |
| Runtime handoff | Reconcile before phase 1 publishes step/context/JSON output; phase 4 checks the same structured inventory and mapping digest before dependency normalization |
| Resume | Persist mapping identity and real task outputs; reject stale source/mapping, missing opt-in, or changed completed outputs; allow the runtime to recover an interrupted full rollback first |
| Target context | Explicit files, module/import headers, source callers and current hashes; refresh after accepted edits and invalidate after rollback; symbol coverage is null and no target Lore server is advertised |
| Existing project | Deterministic reviewed knowledge/plan route for internal phases 2/3; bypass agent planning and scaffolding instead of marking scaffold flags manually |
| Ownership/concurrency | Complete canonical `targetFiles`, existing overlap predecessors, full filesystem transaction, final allowed-diff check; strict gates, `per-task`, one agent at a time |
| Existing tests | Adopt only an unchanged reviewed `.test.mjs` file after a real successful Node test run; record its hash, command, output and status in runtime state |

The source graph remains available for context. It is not the write queue.
The actual queue contains only `psflow-w01-viewport`. Editing
`tasks-merged.json` alone is rejected; direct structured checkpoint output
remains authoritative. Changing the mapping requires a new reviewed project.
The pilot generator refuses to queue an already crossed viewport export.

The adapter tests use the actual AAMF phase-4 flow builder and checkpoint
manager. They cover selected inventory, checkpoint reload/completion skip,
stale mapping/source/completed outputs, shared-path aliases, escapes, project
preservation, file-context refresh/invalidation, interrupted rollback, and
successful/failed/changed-test adoption. All eight pass. The real CLI also
completed the pilot, resumed it without an agent invocation, and rejected a
changed completed output before task execution.

## Pilot scope and prerequisite

Source: system `utils/general.ts::getViewportForBounds`, `parsePadding`,
`parsePaddings`, `calculateAppliedPaddings`; caller context includes system
`utils/graph.ts`, React `store/initialState.ts` and `hooks/useViewportHelper.ts`.
The public function has six parameters and no padding default. The `0.1`
default belongs to callers.

The first attempt exposed a NaN mismatch in the reused geometry. A separate
local differential property was observed red, then green after a correction
local to `System.Utils.General.getViewportForBounds`: its min/max operations
now propagate NaN like upstream. Its existing geometry algorithm remains in
place. The shared clamp API was not changed; its remaining gap is recorded as
W13. A fresh target snapshot includes this prerequisite, and both the geometry
file and its property stayed read-only throughout the successful AAMF task.

The AAMF task owns `src/Boundary/Utils.purs`, its platform-only `.js` shim,
`src/Boundary.purs`, the manifest, the named JS regression, and surface
allowlist/generated evidence. Its audited diff changes only the crossing,
manifest, two retired exceptions and generated surface output. Core geometry,
project setup, package locks, entry point and other references are unchanged
relative to the reviewed prerequisite snapshot.

The crossing is an uncurried six-argument function returning the JS viewport.
Padding decisions remain in PureScript. FFI is limited to native property
reads, parseFloat and template-literal coercion. Unlike fit-view option parsing,
direct undefined padding means zero, null throws on its first property read,
and malformed scalar padding reports twice. No caller-specific default is
injected and no exception was broadened to obtain green.

`parity/boundary/viewport.test.mjs` compares the JS entry with the freshly rebuilt
vendored oracle: numeric/pixel/percent/directional/asymmetric padding, nullish
axis fallback, zoom clamps, omission, malformed values and console ordering,
parseFloat prefixes, infinities, and NaN padding/zoom limits. All 28 cases pass.
The PureScript geometry property and all existing function/unit tests pass.
Surface parity and boundary checks pass. Only this export's arity and
call-convention exceptions were retired; stage stays 4 with 61 crossed and
seven passthrough exports.

At promotion, `npm run build:driver` refreshed the derived
`parity/driver/dist/psflow.js` integration artifact with its provenance check.
Root surface/function/boundary gates, their self-tests and the fork gate pass.
Full browser/corpus baseline work remains Step 3.

## Execution and preservation

Workspace: `/private/tmp/psflow-aamf-step2-20261109/`; successful project:
`psflow-step2-pilot-20261109`. Source and AAMF remain separate from the target
copy. Configurations remain in the isolated workspace. Select the pinned
Node/compiler tools on PATH, including for backend login-shell commands:

```sh
export PATH=/private/tmp/psflow-step2-toolchain/purescript:/Users/jonathanbae/.nvm/versions/node/v22.18.0/bin:$PATH
export PSFLOW_AAMF_RECONCILIATION=/private/tmp/psflow-aamf-step2-20261109/reconciliation.json
export GHCRTS=-N2
node /private/tmp/psflow-aamf-step1-20261109/AAMF/dist/index.js migrate \
  -c /private/tmp/psflow-aamf-step2-20261109/pilot.json --resume --phase 4
```

The final checkpoint completes internal phases 0–4 and exactly one task.
Internal phase numbers are separate from the numbered porting-plan steps.
This adapter rejects later-phase execution. Completed resume adds zero agent
invocations and preserves the task identity and accepted files. The evidence
archive preserves raw runtime state; portable mapping JSON is review evidence,
not a replacement checkpoint. If the workspace is lost or an input changes,
prepare a new isolated project and normal source indexing/reconciliation.

**Stopped after plan Step 2.** This is a verified bounded integration pilot,
not a claim that the remaining port has been migrated autonomously.
