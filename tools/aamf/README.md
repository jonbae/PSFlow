# AAMF phase 0 compatibility fixes

This directory also maintains the opt-in [Step 2 integration](#step-2-existing-project-adapter).

These fixes let the pinned AAMF checkout index PSFlow's pinned xyflow source.
They apply to Lore **0.4.2** as installed by AAMF commit
`7dc475d81ef9796b5b90f57a29475eaafa375753`. They do not change PSFlow's runtime
or upstream source. See [the completed run](../../AAMF_PHASE0_RESULTS.md).

## Apply and verify

Select Node 22 or newer, then run from the PSFlow repository:

```sh
export PSFLOW_AAMF_ROOT=/private/tmp/psflow-aamf-step1-20261109/AAMF
node tools/aamf/apply-phase0-fixes.mjs "$PSFLOW_AAMF_ROOT"
node --test tools/aamf/phase0.test.mjs
```

Install/build AAMF before applying these fixes. `npm ci` in AAMF replaces its
dependencies, so reapply afterwards. The installer checks the Lore version and
exact SHA-256 hashes of both original distribution files before writing. It
also accepts an exact prior application, without rewriting files. Other
dependency modifications cause an error. Its JSON output records the original
and patched hashes. No package manifests or lockfiles are changed.

The helper uses the TypeScript compiler API installed with `scip-typescript`
(5.9.3 in this lockfile), rather than AAMF's TypeScript 7 CLI package.

## What changes

SCIP sometimes supplies an initializer's `enclosingRange` for a variable
definition. Lore previously used it as the whole symbol span, excluding the
actual name. The importer now takes the union with the definition occurrence's
full range. Identifier positions remain exact; invalid positions still fail
the normal span validator. Tests cover same-line, multiline, and Unicode source.

The validator now distinguishes expected re-export-only modules from
unexpectedly missing definitions. A file qualifies only when:

- The stored source matches its recorded SHA-256 hash.
- A successful SCIP run covers the file in the current baseline generation.
- The TypeScript parser finds one or more re-export declarations and no other
  statements or syntax errors.
- Every relative module target resolves to another currently covered file.
- Every re-export branch ultimately reaches indexed definitions. Cycles without
  definitions are rejected conservatively.

The configured `maxSymbolLessFiles: 0` threshold now applies to **unexpected**
symbol-less files, including language-specific thresholds. Raw file and symbol
counts are unchanged. The health report retains all raw symbol-less files,
adds `symbolLessFiles.reexportOnly` evidence and `unexpectedTotal`, and still
enforces structural coverage, provenance, source spans, and indexer success.
Explicit `requiredGlobs` still require local symbols. This classification
establishes expected local-definition coverage; it does not verify the complete
export API or create import records.

The regression suite builds a real SCIP index and exercises Lore's real
validator. It also corrupts separate database copies to confirm that missing
definitions, invalid spans, missing SCIP coverage, stale hashes, empty files,
side effects, malformed exports, unresolved targets, and definition-free
re-export cycles remain failures. It does not edit the certified index.

## Run boundary

Use the isolated configuration recorded in the results, with `--phase 0`.
Keep the successful project state for a later `--resume --phase 1` request.
The old diagnostic database and graph remain uncertified historical evidence;
they are not substituted for the new runtime-managed `kb.db`.

## Step 1 review and preservation

The completed plan Step 1 inventory is preserved in
[aamf/step1](../../aamf/step1/README.md), including a direct audit of all source
import/re-export declarations. See its artifact guide for the portable JSON,
raw runtime archive, and checksums. The older November 7 temporary workspace
no longer exists.

To inspect the November 9 workspace again, use Node 22:

```sh
node tools/aamf/inspect-step1.mjs /private/tmp/psflow-aamf-step1-20261109 aamf/step1
```

The inspector requires the isolated `analysis.json`, the original
`source-before.json` and `target-before.json` snapshot manifests, normal CLI
`run-result.json`/logs, and the successfully checkpointed AAMF state. It
validates the certified database and graph, resolves imports using the pinned
TypeScript parser, and checks the original vendored source plus copied target
for changes. It performs no migration or target mapping. Configurations stay
in the isolated workspace; refresh the preserved runtime archive and checksums
if regenerating the review artifacts.

## Step 2 existing-project adapter

`psflow-integration.mjs` and the seven guarded build patches in
`step2-patches.json` integrate a reviewed single-task pilot with the pinned
AAMF runtime. Apply **after** `npm run build`; rebuilding replaces the patched
distribution. The installer rejects other revisions/builds, validates every
input before writing, and supports exact reapplication. It changes neither
the upstream checkout nor the original Step 1 checkpoint.

```sh
node tools/aamf/apply-step2-integration.mjs /private/tmp/psflow-aamf-step1-20261109/AAMF
PSFLOW_AAMF_ROOT=/private/tmp/psflow-aamf-step1-20261109/AAMF \
  node --test tools/aamf/step2.test.mjs
```

Use Node 22.18.0, PureScript 0.15.16 and Spago 1.0.4. This is maintained adapter
data with an explicit opt-in environment variable, not a stock configuration
feature. Ordinary AAMF behavior remains available without opt-in; a reconciled
checkpoint refuses resume without its mapping.

`prepare-step2.mjs <PSFlow root> <output JSON>` joins all 171 Markdown mappings
to the certified inventory and import audit. It records package versions,
source hashes, declarations, callers/import consumers, existing modules and
converters, dispositions, evidence, work contracts and target snapshot hashes.
It selects only W01; the complete source graph and its cycles remain read-only
context. Another write task requires a new reviewed mapping and project,
with its own allowed outputs and acceptance criteria.

The runtime hook replaces the graph **before** phase 1 publishes its structured
output, context output, and disk artifacts. Phase 4 checks that same inventory
on fresh execution and checkpoint reload. Existing-project phases 2/3 consume
reviewed knowledge/plan files and bypass both agent planning and scaffolding.
The pilot uses one agent at a time and `per-task`; this also caps the stock
parity/test-writer pair, which otherwise launches two agents.

PureScript target context is explicitly **files**, including read-only geometry,
module/import headers, source callers and fresh per-invocation file hashes.
No target Lore DB or target symbol server is advertised. Context refresh and
rollback invalidation use the original target indexer's lifecycle. The runtime's
full filesystem transaction and the adapter's ownership check reject a diff
outside reviewed outputs before marking the task completed.

The strict pilot can adopt its pre-existing Node regression: the launcher
executes the unchanged, snapshot-pinned test and records its hash, command,
TAP output and status in `psflow-adopted-tests.json`. Changed or failing tests
cannot be adopted. This replaces stock AAMF's changed-file requirement for
this explicit existing-test route; it does not replace the runtime gates.
Completed resume also verifies accepted output hashes before skipping work.
Interrupted rollback can restore missing target files before those checks.
All eight adapter regression tests pass, including the negative paths.

The isolated pilot configuration and mapping live at
`/private/tmp/psflow-aamf-step2-20261109/`. With that workspace present and the
recorded Node/compiler tools on PATH:

```sh
export PSFLOW_AAMF_RECONCILIATION=/private/tmp/psflow-aamf-step2-20261109/reconciliation.json
node /private/tmp/psflow-aamf-step1-20261109/AAMF/dist/index.js migrate \
  -c /private/tmp/psflow-aamf-step2-20261109/pilot.json --resume --phase 4
node tools/aamf/inspect-step2.mjs /private/tmp/psflow-aamf-step2-20261109 aamf/step2
```

Never replace only `tasks-merged.json`, reset completion flags manually, or
run beyond `--phase 4` with this adapter. A changed mapping/source/project
snapshot needs a new project and normal indexing/reconciliation. Preserved
JSON is evidence of the original pilot, not permission to rerun W01 against a
new target revision. See [integration details](../../AAMF_STEP2_INTEGRATION.md).
