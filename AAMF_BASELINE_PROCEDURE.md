# Repeating the port review for a new baseline

This is Step 4 order 12's procedure. Start from a PSFlow checkout, the exact
versions being reviewed, and the tools below. None of the old `/private/tmp`
workspaces is required. The examples run from the repository root; paths saved
in shell variables must remain available in the same shell.

The current review is for **React 12.11.0 / system 0.0.77**. A new baseline
requires new evidence. The historical counts below are comparison points,
never expected counts for a newer release.

## What actually ran

| Plan work | Execution and surviving evidence |
|---|---|
| Step 1 | The real pinned AAMF CLI ran internal phases 0–1, with maintained Lore fixes. It certified the index and produced the source graph; no migration agent ran. [Results](AAMF_STEP1_RESULTS.md), [artifacts and checksums](aamf/step1/README.md). |
| Step 2 | An opt-in adapter reconciled that graph with existing PureScript modules and ran exactly `psflow-w01-viewport` through internal phases 0–4. The prerequisite numeric fix was separate PSFlow work. Successful resume, zero additional agent invocations, and stale-output rejection are recorded. [Integration](AAMF_STEP2_INTEGRATION.md), [results](AAMF_STEP2_RESULTS.md), [raw checkpoint and logs](aamf/step2/README.md). |
| Steps 3 and 4 | PSFlow's own implementation, differential tests, review and gate workflow completed the queue. The AAMF inventory supplied source/dependency context. These steps were **not an autonomous AAMF migration**. [Step 3 results](AAMF_STEP3_RESULTS.md), [Step 4 orders](AAMF_PORTING_PLAN.md#step-4-close-the-completion-criteria). |
| Step 4 order 11 | A PSFlow script refreshed the completed review: 171 units, 18 profiles, 170 Reuse and one ambient-declaration exclusion. Version 2 has zero executable tasks; no AAMF phase or agent ran. [Record](aamf/step4/order-11/README.md). |

The two number systems differ: plan Step 1 ends at AAMF **internal phase 1**;
internal phase 3 can scaffold a project. `--dry-run` validates configuration
without building an inventory. A fresh run can clear existing project state.
Always use a new workspace/project for changed inputs.

## Tools and the starting receipt

Use Node **22.18 or newer**, PureScript **0.15.16**, Spago **1.0.4**, Git and
`tar`. [CI](.github/workflows/gates.yml) contains the compiler installation and
browser setup commands. Install root dependencies from `package-lock.json`
with `npm ci`; Spago uses `spago.lock`. The inventory command installs AAMF's
locked dependencies and invokes the copied source's exact `pnpm` version
itself. It needs network access to GitHub and the package registries, but phases
0–1 need no agent-backend login or CLI. A Docker engine is required for the
recorded Linux capture environment; Ubuntu 24.04 is CI's host.

Before changing the pins, choose a new evidence directory, for example
`aamf/baselines/react-<react-version>-system-<system-version>/`. Record the
old PSFlow commit (`git rev-parse HEAD`), both old/new version pairs, the
upstream release tag and resolved commit, Node/npm/compiler/Spago versions,
and the locked Playwright version/image in its README or execution receipt.
The vendoring command prints its tag URL; inventory hashes identify the actual
scoped source bytes. Record the resolved tag commit too, rather than treating a
version label as source integrity evidence.

Preserve the previous reports, traces and comparison policy **before** a new
capture overwrites them. From the root, with an existing external directory:

```sh
export PSFLOW_BASELINE_BEFORE=/absolute/path/to/baseline-before
mkdir -p "$PSFLOW_BASELINE_BEFORE"
git rev-parse HEAD > "$PSFLOW_BASELINE_BEFORE/psflow-commit.txt"
git archive HEAD parity oracle/index.js aamf/step1 aamf/step2 \
  AAMF_STEP2_MAPPING.md > "$PSFLOW_BASELINE_BEFORE/previous-evidence.tar"
tar -xf "$PSFLOW_BASELINE_BEFORE/previous-evidence.tar" -C "$PSFLOW_BASELINE_BEFORE"
```

This archives the committed checkpoint. If uncommitted captures matter,
preserve them separately and label their revision/diff. Keep the old
`aamf/step1`, Step 2 pilot/checkpoint/archives/checksums and order evidence as
historical records. New inventory output goes in the new baseline directory.

## Pin and vendor the candidate

Choose the exact released React/system pair; the React release tag must
contain the declared system version. Set `PSFLOW_NEXT_REACT` and
`PSFLOW_NEXT_SYSTEM` to those exact versions, then:

```sh
npm install --save-dev --save-exact \
  "@xyflow/react@$PSFLOW_NEXT_REACT" "@xyflow/system@$PSFLOW_NEXT_SYSTEM"
```

Review and commit the candidate `package.json` and `package-lock.json` changes
on the baseline branch before inventorying. The inventory takes its target
from `git archive HEAD`, so commit any target changes that belong in that
snapshot too. It refuses pins that disagree with HEAD. No publishing is
involved.

Move an existing `xyflow/` out of the checkout to a separate unused path, then
run the vendoring script. On a fresh clone, just run the script:

```sh
node .github/scripts/vendor-baseline.mjs
npm ci
```

The script refuses an existing `xyflow/` and checks both package versions. A
system mismatch means the pair is wrong; do not edit the extracted manifests
to make it pass. Resolve the tag's commit with Git and record it:

```sh
git ls-remote https://github.com/xyflow/xyflow.git \
  "refs/tags/@xyflow/react@$PSFLOW_NEXT_REACT" \
  "refs/tags/@xyflow/react@$PSFLOW_NEXT_REACT^{}"
```

Use the peeled `^{}` commit for an annotated tag, otherwise the tag ref's
commit. Keep the dependency/source baseline update and its resulting port,
register and evidence changes together in the final review.

## Rebuild the bounded AAMF inventory

Run this also when repeating the current baseline from a fresh checkout.
`xyflow/` must be the unmodified tree from the pins. The workspace and artifact
directory below must **not exist**; the workspace's parent must exist, and
the workspace must be outside the checkout:

```sh
export PSFLOW_AAMF_WORKSPACE="$(mktemp -d)/inventory"
export PSFLOW_BASELINE_ID="react-$(node -p 'require("./package.json").devDependencies["@xyflow/react"]')-system-$(node -p 'require("./package.json").devDependencies["@xyflow/system"]')"
export PSFLOW_BASELINE_EVIDENCE="aamf/baselines/$PSFLOW_BASELINE_ID"
node tools/aamf/inventory.mjs "$PSFLOW_AAMF_WORKSPACE" \
  "$PSFLOW_BASELINE_EVIDENCE/inventory" "psflow-baseline-review-$(date -u +%Y%m%d%H%M%S)"
```

For a second run, choose a new evidence directory and project suffix too.
Project names contain only lowercase letters, digits and hyphens, as the
pinned AAMF configuration requires.
[inventory.mjs](tools/aamf/inventory.mjs) performs the missing setup as well as
the CLI invocation:

1. Copies the complete vendored source separately from a committed PSFlow
   target, omitting Git/dependency directories. Snapshots both before analysis.
2. Creates an analysis-only root `tsconfig.json` in the source copy, with
   **absolute** `baseUrl` and `@xyflow/*` source aliases and bundler resolution.
   These settings are necessary for React-to-system edges. Neither repository
   source nor package-specific compiler configuration is edited.
3. Clones AAMF at `7dc475d81ef9796b5b90f57a29475eaafa375753`, runs `npm ci` and
   its build, applies the hash-guarded Lore 0.4.2 fixes, and runs their actual
   SCIP/validator regressions. Source dependencies use a frozen, script-free
   filtered pnpm install in the source copy with an isolated store.
4. Runs the normal `migrate -c analysis.json --phase 1` and `status` from the
   new workspace. Git automation is off, one agent is configured, and target
   indexing is not claimed. An inherited Step 2 opt-in is removed.
5. Uses [inspect-step1.mjs](tools/aamf/inspect-step1.mjs) to revalidate the real
   DB/certificate, source scope/hashes, all task references, SCCs, structured
   checkpoint outputs, import/re-export resolution and source/target integrity.
6. Writes portable review JSON, command/install/test logs, raw runtime archive
   and `SHA256SUMS` to the new artifact directory. Actual configurations stay
   in the workspace; their hashes and the deterministic setup live in the
   execution receipt/script. Failed command logs remain in the workspace.

The runner deliberately stops for a pre-existing upstream root tsconfig,
new JavaScript sources, an unsupported package-manager declaration, unknown
Lore distribution bytes, unresolved imports, or imports outside the scoped
roots. Review and extend the recipe/indexing coverage for that source layout;
do not silently exclude the new files or relax certification thresholds.
Also recount `.ts`/`.tsx` and any other source languages under **both** roots,
including new roots or extensions. The current scope excludes tests, Svelte,
examples, CSS and tooling; retain those as reference/test assets as needed.

Review the artifacts even after exit 0:

| Receipt | Acceptance |
|---|---|
| `inventory.json`, `review.json` | Every selected file is accounted for by a task, reference or proven re-export-only module; no file-only fallback or dangling dependency. Explain all scope changes. |
| `index-health.json` | Certified, valid spans, structural coverage, provenance/indexer success, zero unexpectedly symbol-less files. Inspect warnings; the old four duplicate groups are not a permanent allowance. |
| `imports.json` | Every import/re-export declaration resolved with the actual installed parser/config. Review cross-package consumers and external targets; Lore's empty import table is a known limitation. |
| `task-graph.json`, `dependency-summary.json` | Review changed edges and cyclic groups. The graph's `.purescript` paths are provisional context, never approved destinations. |
| `integrity.json`, `execution.json`, raw checkpoint | Source bytes match the vendor; copied source/target are unchanged apart from the analysis tsconfig. Internal phases `[0,1]` complete, current phase 2, zero migration tokens. |
| `SHA256SUMS`, logs, `runtime.tar.gz` | All checksums pass and the evidence is durable before deleting the workspace. |

The old inventory had 171 files (44 system/127 React), 120 tasks, 460 edges,
four cyclic groups and 689 resolved import/re-export declarations. Differences
from those counts require explanation, not restoration of the old counts.
Verify checksums from the artifact directory with `shasum -a 256 -c SHA256SUMS`
on macOS or `sha256sum -c SHA256SUMS` on Linux. Add the baseline's review README
beside `inventory/` so it does not invalidate that directory's manifest.

## Reconcile the new source with the existing port

Inventory success does not establish parity. Compare the new inventory and
import audit with the [current unit map](AAMF_STEP2_MAPPING.md) and
[current review JSON](aamf/step2/reconciliation.json). Write a new
`$PSFLOW_BASELINE_EVIDENCE/reconciliation.json` and review table, with one row
for **every new inventory unit**, and an explicit old-to-new list of added,
removed, moved and hash-changed files. A move needs source/symbol review; a
matching basename is insufficient.

Use this contract for each row:

| Field | Required review |
|---|---|
| `source`, package, `sha256`, symbols | Join to the newly certified inventory. New/changed symbols are read against upstream source and its callers. |
| `imports`, `importedBy`, caller context | Rejoin the new AST import audit in both directions. Check unchanged callers of changed dependencies as well. |
| `targets`, `converters` | Existing canonical `.purs` modules, boundary conversion and necessary FFI. Validate each path/module/import and pair its FFI. An exclusion states exactly why no runtime body is needed. |
| disposition, evidence | Reuse, Finish conversion, Fix behavior, Add evidence, or Accepted difference. Name the branch/field observable and the actual gate/test/scenario. A green export count alone cannot retire branch debt. |
| work and ownership | For a gap: owning issue/task, exact permitted outputs, read-only context, acceptance command, and dependencies from both source and shared target files. |

Review the 18 profiles and each changed unit, including field-by-field type
contracts using [the order 10 review](AAMF_TYPE_CONTRACT_REVIEW.md) as the
previous checklist. Add new fields/units; retire removed ones explicitly.
Recheck the compatibility limits in [distribution/gaps.mjs](distribution/gaps.mjs)
and remaining issues in the current JSON against the new source and evidence.
Do not carry the old 170/1 dispositions or counts over by assumption. Issues
207/208 were separately owned at order 11; inspect their current evidence and
disposition when doing the bump.

**The current refresh is baseline-specific.** On the unchanged baseline, run:

```sh
node tools/aamf/refresh-reconciliation.mjs --check
node --test tools/aamf/reconciliation.test.mjs
```

`refresh-reconciliation.mjs` validates the historical pilot's exact 171-unit
scope, pins, hashes, table ownership, profiles and 170/1 completed result.
It intentionally rejects a new baseline. It is not the new inventory importer.
For a bump, maintain a new baseline-specific generator/checker alongside the
new review, deriving scope and versions from **that** inventory. Use the
existing script and fault-injection tests as the implementation reference:

- Join every new source path/hash to its certified inventory/imports; reject
  duplicate, missing and extra units and broken destinations.
- Validate evidence paths/anchors, runtime and evidence hashes, and the
  reviewed target commit's ancestry. Reject stale generated output and
  unowned pending work. Derive counts from the reviewed dispositions.
- Keep review-only data at version 2 with `purpose: current-review-only` and
  `tasks: []`; pending work belongs in explicit work contracts. Fault-inject
  stale source/evidence, missing units, queued tasks and broken links to prove
  the checker rejects them. Run it in check mode after final gates.

The coupled inputs to replace in that new checker are the inventory/import
paths, review/profile path, table/output paths, package pins, source-unit set
and disposition assertions. Preserve the old pilot digest as historical
provenance; do not modify the old artifacts to satisfy new inputs. Link the
new review from README once it supersedes the old current review.

Execute gaps through PSFlow's workflow: retain upstream's mechanism in
PureScript, observe a focused differential red before the fix and green after,
then run the applicable [verification contract](AAMF_PORTING_PLAN.md#verification-contract-for-aamf-tasks).
The old AAMF graph remains context, and shared target files impose ordering.
`prepare-step2.mjs` is specifically the old W01 preparer and refuses an
already-crossed viewport; it is **not** a general bump/reconciliation command.

## Rebuild the gates and review the registers

Use fresh compiled output and freshly vendored upstream. These are the CI
gate order and subsequent checks, run from the root:

```sh
spago build
npm run build:oracle
npm run build:driver
npm run parity:surface
spago test
npm run test:conformance
npm run test:smoke
node parity/system/linux.mjs npm run parity:system
npm run parity:boundary
npm run test:boundary
npm run build:package
npm run parity:package
```

Install Chromium with `npx playwright install --with-deps chromium` first.
Surface is the hard precondition. Resolve its failures before interpreting
later gates. The system runner derives its Noble Playwright image from the
lockfile and rebuilds both driver bundles. Record that exact environment in
the receipt; an arbitrary host capture is not the Linux checkpoint. The
browser boundary contracts also launch Chromium through their own harness.

A bump also requires these register reviews and apparatus checks:

| Area | What to rerun and decide |
|---|---|
| Surface and census | `npm run parity:surface`, then `node parity/census/build.mjs`. Classify added/removed values and types in `parity/census/classification.json`, implement conversions, and review `parity/surface/allowlist.json`. Retire stale exceptions. Keep stage 5's manifest complete with zero passthroughs. |
| Function oracle | `npm run build:oracle`, then `spago test`. Extend `oracle/esbuild.mjs` and actual differential tests for new pure functions/branches; check each caller too. |
| Changelog and branch debt | `npm run parity:changelog`. Read every new upstream patch and bucket it in `parity/changelog-audit/verdicts.json` with precise evidence or an owned gap. Recheck `aamf/step4/order-8/rows.json` branch receipts through `parity/changelog-audit/system-evidence.mjs`. Keep the historical exclusive floors (React 12.3.5/system 0.0.46); moving them is a separate audit decision. |
| Fork, fixtures and conformance | `npm run parity:fork`. Read every moved/added/removed registered spec, fixture and example driver. Update scenarios and register decisions first, then use `node parity/system/fork.mjs --affirm` for reviewed moved entries, and rerun `parity:fork`. Affirm cannot add or remove entries. The net refuses capture until the fork is green. |
| System evidence and coverage | Full Linux `parity:system`, then `npm run parity:coverage` and `npm run parity:changelog`. Review witnesses in `parity/system/coverage/`, declared holes, branch receipts, regions and weakenings. New exports need actual upstream and port witnesses or specific declared reasons; removed exports must not leave stale witnesses. Require reproducible captures, no driving divergence, no transitional region/exception and no unowned debt. |
| Boundary and declarations | `parity:boundary`, `test:boundary`, `build:package`, `parity:package`, `test:package`. Re-audit new props/store members through JavaScript and PureScript consumers, the overlays in `distribution/gaps.mjs`, emitted declarations and stylesheet bytes. Package remains private. |
| Apparatus | `npm run test:ci`, `test:audit`, `test:surface`, `test:census`, `test:compare`, `test:coverage`, `test:harness`, and `test:package`. Run `test:harness:live` for capture changes. Run `node --test tools/aamf/inventory.test.mjs` for replay guards. For maintained AAMF changes, rerun `phase0.test.mjs` with `PSFLOW_AAMF_ROOT` set; run `step2.test.mjs` only after installing the guarded Step 2 adapter in its own AAMF build. |

The receipt uses package-script commands, e.g. `npm run test:audit` for each
script named above. Run `node --test tools/aamf/reconciliation.test.mjs` and
the new reconciliation checker's rejection tests too. A comparator, fixture,
test, region or allowlist change needs its own stated reason and validation;
a baseline bump does not justify making differences disappear.

`node parity/system/net.mjs --compare-only` rechecks stored traces; it does
not replace the fresh capture. For a behavioral changelog, compare the old and
new **upstream** traces for each shared scenario after both checkpoints have
proved self-consistency, for example:

```sh
node parity/system/compare.mjs \
  "$PSFLOW_BASELINE_BEFORE/parity/system/traces/mount-baseline--nodes-general.upstream.capture1.json" \
  parity/system/traces/mount-baseline--nodes-general.upstream.capture1.json \
  --out "$PSFLOW_BASELINE_BEFORE/upstream-change.md"
```

Exit 1 here reports baseline differences to review; the two-trace command
does not check self-consistency. Review all shared scenario ids, both captures
and the added/removed scenario list. Keep prior capture protocols/environments
with their archives so a driving change is not misreported as library behavior.

## Resume and finish the receipt

For an interrupted **inventory** with unchanged inputs, retain the original
workspace/config and run from it, using the same Node and AAMF bin directory
on PATH:

```sh
export PATH="$PSFLOW_AAMF_WORKSPACE/AAMF/node_modules/.bin:$PATH"
(cd "$PSFLOW_AAMF_WORKSPACE" && node AAMF/dist/index.js migrate \
  -c analysis.json --resume --phase 1)
```

Save the resume command, exit status, log and `status` output separately;
refresh `run-result.json` to describe the actual attempts before re-inspecting
and repacking evidence. The one-shot runner refuses existing directories. A
completed replay still ends at internal phase 1, never phase 3 or 4.

For the **historical Step 2 pilot**, its [integration guide](AAMF_STEP2_INTEGRATION.md#execution-and-preservation)
records the exact opt-in resume. It requires the original source/target paths,
configuration, reviewed version-1 mapping and patched build. Apply Lore fixes
after dependency installation and the seven guarded Step 2 patches after the
AAMF build. `npm ci`/rebuilding requires reapplying the corresponding patches.
Run the eight adapter tests with `PSFLOW_AAMF_ROOT` pointing at that build.
Version-2 review data cannot execute. Do not replay W01 on the completed port.
If a future task is deliberately delegated to AAMF, it needs a new reviewed
runtime mapping, allowed outputs, adapter validation/tests and isolated
project; record it separately from PSFlow-executed work.

Preserved portable JSON is a review projection. Archives/checkpoints contain
absolute paths and are not relocatable resume projects. If paths, mapping,
source, target or tooling change, start a new project and normally index and
reconcile it. Never substitute `tasks-merged.json` for structured checkpoint
output or hand-edit completion flags. A lost workspace means fresh setup;
the repository contains the recipe and historical evidence, not its secrets
or machine state.

Finish the baseline's README with source/target/tool revisions, source scope
and exceptions, old-to-new unit/disposition changes, owned gaps/limits, exact
commands/exit statuses, focused red/green/probe results and full gate counts.
Save the new inventory and reconciliation, raw checkpoint/logs, oracle and
driver artifacts, census/surface/changelog reports, fork register, complete
system traces/report/coverage and package validation receipt. Hash preserved
artifacts, validate local links and run `git diff --check`. Inspect generated
diffs before committing; no mutable temporary path may be the only evidence.

Only the new review and fresh gates can establish the new baseline's
completion. This procedure's delivery does not resolve separately owned
runtime issues or publish the package.
