# Step 3 execution evidence

**Latest checkpoint (November 13 UTC): Order I complete; 115/115 scenarios pass. Zero self-inconsistent scenarios or driving divergences.**
ps-flow builds a package for JavaScript and TypeScript consumers, and
`npm run parity:package` holds it to `index.js`. See [Order I](order-i/README.md)
for the current evidence, and [Order H](order-h/README.md),
[Order G](order-g/README.md) and [Order E](order-e/README.md) for the
checkpoints before it.

This directory preserves the November 9, 2026 W00 baseline, all seven W02
crossings and stage-5 checkpoint, plus November 10 W03/W04 and W08a/W08b work. See [the results](../../AAMF_STEP3_RESULTS.md)
for interpretation and remaining work. **Step 3 B / boundary stage 5 is complete:
68 crossed exports, zero passthroughs. Step 3 C / W03 and D / W04 are also
complete, along with W08a/W08b and F/W05. The resize witnesses, G node.resizing field, bounded keyboard protocol and H onInit witness are complete. E, G, H and I are now complete.**

## Baseline

`baseline/execution.json` records target commit
`98a3f77ab1bb17d481c6dec4fed2e23174448e45`, the unchanged 171-file certified
source inventory, and actual toolchain/browser versions. `inputs.json` hashes
524 nongenerated inputs before the crossing. `checks.json` gives exact commands,
UTC start/end times, exit codes, and log paths, including setup failures and
their successful retries. The source/target baseline stayed fixed throughout
the full capture.

Both open PRs were checked read-only; their responses are `pr194.json` and
`pr195.json`. `surface-report.md`, `surface-psflow.json`, and
`surface-upstream.json` preserve the pre-crossing surface snapshot. The current
surface report in `parity/` reflects the subsequent crossings.

The 412 W00 traces, original report and coverage file are preserved in
`wave1/w00-capture.tar.gz`; the readable original report is
`wave1/w00-system-report.md`. All 414 archived files match the preserved
pre-wave checksums (`wave1/w00-archive-verification.json`). The canonical files
under [`parity/system`](../../parity/system) now belong to the later stage-5
checkpoint. W00 returned 1: 100/103 scenarios failed, including four
self-inconsistent experiments. `scenarios.json` records consistency separately;
`summary.json` excludes unstable or differently driven runs from its observation
groups. `artifacts.json` fingerprints generated baseline outputs. Its driver
and oracle hashes equal their Git versions at the baseline commit.

To regenerate W00's summary, use an isolated copy of the repository/evidence,
restore the archive at its canonical relative paths there, then run:

```sh
node aamf/step3/summarize-baseline.mjs
```

The script calls the existing comparator with the unchanged committed registers.
It does not alter normalization, fixture behavior, regions, or gate outcomes.
Replacing the traces with another capture would describe that other experiment;
the checksums identify this one.

## First bounded crossing: `getConnectedEdges`

`connected-edges.json` is the concrete single-export task contract. `w02/`
contains its failing first regression, successful build and first green run,
then the expanded seven-case regression in the full 48/48 boundary suite and
all applicable validation logs. `w02/execution.json` records final output hashes
and the file audit: four existing nongenerated inputs changed as permitted,
520 remained unchanged, and all 171 upstream hashes still match. The new
JS-entry test is an explicitly owned additional output.

The retained PureScript graph function performs the filtering. Only its
boundary/export/manifest wiring and matching surface exceptions changed; no FFI operation,
element converter, core graph implementation, package, or scaffold changed.
After this crossing, stage remained 4 with 62 crossed exports and six passthroughs.

This is execution through the current PSFlow workflow using the certified AAMF
inventory and reviewed mapping. The Step 2 adapter remains restricted to its
completed viewport pilot. No AAMF agent was run for W00 or this crossing; this
does not claim autonomous AAMF migration or new checkpoint/resume behavior.

## Second bounded crossing: `getIncomers`

`incomers/task.json` defines this single-export task. Its `start.json` and
`inputs.json` record the actual working state including the earlier uncommitted
work. The starting source/allowlist files are preserved in
`incomers/before-source.tar.gz`; `execution.json` records output hashes and the
audit against those starting inputs. Earlier baseline, trace, and W02 evidence
files are retained unchanged.

`incomers/checks.json` and the adjacent logs preserve two red/green loops:
three-argument JS calls and the absent-id early return. The existing PureScript
graph traversal remains unchanged. The JS-entry regression now has nine cases,
all included in the 57/57 passing boundary suite. Surface parity, `spago test`,
boundary checks, 30/30 surface tests, and the driver rebuild passed. Only this
export's two surface exceptions were retired, plus the resulting count comment.

After this crossing, the manifest recorded 63 crossed exports and five
passthroughs, still stage 4.
The same current-PSFlow execution route applies; no AAMF runtime, compiler,
package, fixture, comparator, or coverage-register change is claimed. The W00
browser/system results remain the pre-crossing baseline.

## Completion of boundary stage 5

`outgoers/`, `node-bounds/`, `is-node/`, `is-edge/` and `reconnect-edge/` contain
the remaining single-export task contracts, starting input hashes, source
snapshots, red/green logs, gates and file audits. Their new regressions add
9, 19, 3, 3 and 16 cases respectively. All **107 boundary tests**, **30 surface
tests**, function parity/unit tests, surface parity, boundary checks and final
builds passed. All 68 values are crossed; stage is 5 and passthrough is empty.
The only remaining function-behavior exceptions belong to W03 / issue 150.

Bounds and reconnection have explicit narrower FFI scopes for native platform
operations. Node/lookup selection, defaults, validation, geometry, id generation
and callback decisions stay in PureScript. The graph/edge core and element
converters remain read-only. Reconnection establishes the raw-object policy for
W03 without changing the three earlier change/add helpers.

`wave1/inputs.json` identifies the actual frozen stage-5 target and apparatus;
the Git base is still Step 2 plus the recorded uncommitted work. The wave's
`execution.json` records toolchain/source fingerprints and its `checks.json`
records browser conformance, smoke, full system capture and changelog outcomes.
The checkpoint's conformance 41/41, smoke 2/2 and changelog audit passed. System
parity returned 1 after capturing all 103 scenarios: 100 failed, six were
self-inconsistent. Its 97 reproducible experiments alone enter triage; coverage
remains 122 driven / 34 declared holes, with 50 behavior debts. All 531 frozen
implementation/apparatus input hashes stayed unchanged. The current observation
groups are derived with the unchanged comparator:

```sh
node aamf/step3/summarize-wave1.mjs
```

W00's summary files remain unchanged. Both summary scripts group observations,
not proven causes, and exclude self-inconsistent or differently driven runs from
implementation triage. No fixture, tolerance, comparator or debt register was
modified to obtain a passing result. System parity remains separate from the
stage-completion claim.

## Reproduction and integrity

Use PureScript 0.15.16 and Spago 1.0.4 on `PATH`, dependencies from the committed
locks, and the fixed vendored baseline. To reproduce W00 specifically, use a
separate checkout at its recorded commit; the current working implementation
also includes the crossing. Rebuild before rerunning the commands recorded in
`baseline/checks.json`. Those capture commands overwrite the canonical reports
and traces, so a fresh evidence directory is needed to retain another run.

Commands are in each task directory's `checks.json`. The first crossing's red/green pair
ran one test; the unchanged first test plus six later cases run under
`npm run test:boundary`. Per-task browser recaptures were deferred until the
stage-5 wave checkpoint; W00 and that checkpoint are distinct experiments. Each
driver rebuild passed; output hashes identify the bundles. The W00 baseline
bundle is also recoverable from its recorded Git commit.

From the repository root, verify the evidence and the final owned outputs:

```sh
shasum -a 256 -c aamf/step3/SHA256SUMS
```

The checksum file covers this directory, the results/status documents, the
crossings and their tests, the generated reports and bundles, and all 412 traces.
Gitignored intermediate files are copied here where needed for the baseline;
reproducible intermediate files are not required by the checksum manifest.


## Consumer objects: W03

`consumer-objects/task.json` records the raw-object boundary policy and narrowly
owned outputs. `before-source.tar.gz`, `before-mount-check.tar.gz` and
`final-source.tar.gz` preserve the implementation and exact mount assertion.
`inputs.json` includes the actual uncommitted starting state; `source-audit.json`
finds no unexpected edits and verifies all 171 vendor files unchanged.

`checks.json` preserves the red/green slices and final passing build,
surface/function/boundary checks, 118 boundary cases and 30 surface cases.
`execution.json` distinguishes the premature first green attempt, the corrected
proxy receipt, the former PS-only unknown-change assertion, and browser setup
issues from product assertions. Smoke passed 2/2; conformance passed 40 in its
full run and its one setup-timeout case passed in isolation. The archived
failure artifacts remain available. A frozen full browser pass follows W04.
The stage-5 corpus traces and all earlier evidence remain unchanged.


## Original nodes: W04

`user-node/task.json` records the typed original-node representation, native
weak association and required-constructor scope. Before/final source archives,
`constructor-updates.json`, and `source-audit.json` preserve the exact changes.
Red/green JS-entry and local proxy logs plus passing surface/function/boundary
checks are in `checks.json`; the final boundary suite has 119 cases.

`validation-snapshot.json` records a frozen browser-validation copy. It passes
41 conformance and two smoke tests. Its source and compiled output remain
unchanged (`validation-integrity.json`). Both focused system experiments
reproduce; each removes its missing-original-node difference and remains red
on unrelated differences. All eight traces, reports and the read-only summary
script survive here. The canonical stage-5 corpus was not overwritten.
See `execution.json` for setup failures, exact verdicts and interpretation.


## Listener timing: W08a and W08b

`on-init/` preserves the synchronous-call and late-handler failures, the final
fake-clock proxy, diagnosis and source archives. `viewport-listeners/` holds
the slot-retention failure, the additional public index.js callback-identity
failure, three independent slot-update observations, source archives and final
checks. Both cards are complete. Step 3 E's wider repeatability work is open.

The combined frozen browser checkpoint passes 41 conformance and two smoke
tests. Its source/output integrity check is clean. Twelve new focused traces
cover the parented-node scenario and two independent pan experiments; each
experiment reproduces internally while retaining other parity differences.
Before-capture inputs and comparison policy are retained beside the read-only
summary script. No canonical stage-5 trace was overwritten. Each
`validation-runtime.tar.gz` preserves the complete isolated runtime without
node_modules; use Node 22.18.0 and locked dependencies to replay it.


The earlier November 10 [continuation audit](continuation-audit.json) compares the actual
starting working tree, including uncommitted W02 work, with the final owned
outputs. All 171 certified vendor files and the canonical system captures remained
unchanged at that checkpoint; the later wave below owns a new canonical capture. The prior checksum manifest is preserved as
`consumer-objects/before-checksums.sha256`; the current manifest seals this
continuation's evidence and final owned source files as well.

## Later resize continuation: W11, W05, W12 and node.resizing

`repeatability/` preserves the six-scenario remeasurement, independent repeats,
three keyboard scheduling experiments, policy inputs and their read-only summary.
Its bounded capture work is complete; the wider E investigation remains open.

`resize/` holds the genuine controller implementation's source archives and
local red/green receipts, including the vendored-source differential oracle,
React control lifecycle, callback identity/payload and parent-change checks.
`resize-witness/` holds the shared fixture's mounted receipts, explicit hole
retirement, full-policy comparisons, targeted witness verification/falsification,
and the first frozen 41-conformance/two-smoke checkpoint. A log named
`red-fractional-child-extent` exited zero before source arithmetic alignment;
it is explicitly not counted as a failing regression.

`node-resizing/` records the additional store/API flag regression, required-field
constructor updates, and the fresh combined full-corpus validation. Its
`before-canonical-checkpoint.tar.gz` retains all 414 previous canonical files;
`before-checksums.sha256` retains the earlier 822-file seal. The later wave owns
the canonical trace/report/coverage refresh, unlike the earlier focused cards.
The final `execution.json` and source audit identify the exact validation state.


The final combined runtime passes 41 conformance and two smoke tests. Its full
preserved resize/store 107-scenario wave has 13 passes, 94 failures and five self-inconsistent
experiments. All 428 fresh traces are canonical; `wave-summary.json` excludes
unstable experiments from triage. Coverage is 127/156 driven with 29 declared
holes and no undeclared holes. The direct/resizer witness rows pass their targeted
checks with only PR195 handle-bound differences left; the active-limit row is
excluded in this wave and in its independent repeat, both inconsistent upstream.
`validation-runtime.tar.gz` freezes the full wave before the independent repeat.


## Keyboard dispatch and initialization witnesses

`keyboard-driving/` preserves the E/W11 keyboard protocol task, native red/green
regressions, 120 valid frozen-runtime traces, two independent five-pair candidate
runs, and the ten active-resize receipt/corruption checks. Both scenarios
reproduce in all ten candidate pairs, while their two unrelated full-net
differences remain. The `setup-*` directories are excluded setup failures.
`validation-integrity.json` confirms no runtime or policy changes during those
measurements. E remains open for other timing and frame-count work.

`on-init-witness/` owns enabling the already-crossed initialization callback in
the driver. Its real browser receipts prove the existing witness on both sides
before retiring the single coverage hole. Driver register tests preserve stale
and contradiction checks even with no withheld callback props. The previous
canonical 428 traces and report/coverage are retained in
`before-canonical-checkpoint.tar.gz`; the subsequent full wave is its own
checkpoint, not a reinterpretation of the previous captures.


The preceding initialization-observation wave had **13 passes, 94 failures and 34
self-inconsistent scenarios**. All 34 vary upstream; four also vary in PSFlow.
`on-init-witness/repeatability-details.json` records the exact callback sequences,
including initial `onInit`/`onMoveEnd` interleavings. The existing live upstream
whole-trace check now reports that ordering too (**22/23 live checks pass**).
Its failure artifacts are retained, and the check is unchanged. Coverage is
**128/156 driven, 28 declared holes, zero undeclared holes**. E and G–I remain
open; export witnesses do not establish full behavioral parity.


Final conformance is **41/41** and smoke **2/2**. The fresh runtime and all 428
canonical traces are archived in `on-init-witness/validation-runtime.tar.gz`;
`source-audit.json` verifies source/output/policy integrity, all 171 certified
vendor hashes, the exact 430-file predecessor checkpoint, and task ownership.
The keyboard archive is the earlier frozen experiment with its original
observation set; it is not the later initialization-observation checkpoint.


## Initialization and native frame protocol

`initialization-driving/` preserves the original mount-order loop, seven isolated
clock/layout probes, native red/green regressions, the intermediate full wave,
and the final protocol. Application timers stay held until native DOM stability;
timer stepping follows, and time resumes before actions. Later ticks await
application and native rendering. No callback or comparison rule changes.

`red-across-rounds.log` records the real keyboard hover-order regression;
`red-native-post-mount-frame.log` exited 0 and is not counted as red evidence.
The final 60 bounded traces cover initialization, keyboard and active resizing,
with the official self-comparator checking across independent rounds as well as
within each pair. Original geometry and missing/corrupted callback checks pass.
Historical diagnostic probes require restoring `diagnostic-runtime.tar.gz` in a
separate checkout; their source guard rejects changed driving machinery.

The current full wave has **95/107 failures and 5 unstable scenarios**.
All **25 live harness checks**, **41 conformance tests** and **two smoke tests**
pass. Coverage is **128/156 driven, 28 declared holes**. The exact 430-file prior
checkpoint is `initialization-driving/before-canonical-checkpoint.tar.gz`; the
intermediate trial is `mount-only-checkpoint.tar.gz`. The final runtime, raw
traces and policy are in `validation-runtime.tar.gz`, verified by
`source-audit.json` and `archive-integrity.json`. E and G–I remain open.

## Shared geometry and resize numeric behavior

`numeric-semantics/` preserves the bounded H/W13 task. PureScript min/max now
propagates `NaN` and preserves both zero signs throughout shared geometry,
resize constraints and the controller's child-extent aggregation. Four real
red regressions precede the corrections. The full function/unit suite includes
15,934 exact source comparisons and 66 controller differential cases.

All 24 focused raw browser traces remain in `final/`. Resize and viewport helpers
reproduce within and across independent rounds, with the same two known full
comparison differences. Both wheel-zoom pairs are upstream self-inconsistent
(`onMoveEnd` present versus absent), so that experiment remains excluded. The
strict three-scenario verification is red; no later capture replaces it.
`probe-results.json` separates successful diagnostic checks from actual red
evidence. `checks.json` records exact gate commands and results.

The previous canonical full wave is unchanged; 95/107 failures and five unstable
scenarios describe that earlier complete checkpoint. `validation-inputs.json`
and `runtime-integrity.json` identify and verify the newer frozen runtime,
compiled JS, apparatus, 171 vendor files and runtime archive. This task changes
no fixture or comparison policy and invokes no AAMF migration agent.

The numeric-task browser suites pass **41/41 conformance** and **2/2 smoke**.
See [execution metadata](numeric-semantics/execution.json) for the separate red focused wheel experiment.


## Shared handle bounds and viewport-end scheduling

`shared-handle-timing/` records the two shared production fixes, adapted PR195
source patches, native timing regression and comparison against executing
pinned source. Nine handle checks pass. Zero/150 ms end scheduling and
cancellation match source, including real d3 transforms and event identity.
All six full comparisons of the three focused scenarios pass across independent
rounds, and both restored-defect faults are rejected by the official comparator.

The fresh full checkpoint is **99 passed / 8 failed** over 107 scenarios, down
from 95 failed. Reproducible handle-bound differences and the 71 shared initial
callback inversions are gone. One controlled-viewport order row remains; its
12 independent follow-up traces prove unchanged upstream produces both orders.
The full wave still records its original failure. Four full-wave scenarios are
self-inconsistent; broader timing, keyboard, store/probe and Step3 G/H/I work
remains open. Coverage stays at 128/156 driven and 28 holes.

The old 430 canonical files are preserved and hash-verified in
`before-canonical-checkpoint.tar.gz`. `validation-inputs.json` freezes the source,
apparatus and compiled code before captures; `validation-outputs.json` identifies
the final canonical outputs. The runtime archive and integrity/audit metadata
preserve this new checkpoint. Build/surface/function/boundary, 119 boundary
checks, 41 conformance, two smoke and changelog validation pass. See
[execution.json](shared-handle-timing/execution.json) and its exact command
receipts. No policy/register/fixture change or AAMF migration-agent run occurred.


## Order E complete

Order E is complete: keyboard announcements, focus panning, callback ordering
and gesture reproducibility are validated. The fresh Linux checkpoint captures
all 107 scenarios: **105 pass and 2 fail**, with **zero self-inconsistent
scenarios and zero driving divergences**. The remaining two failures are the
flow/node probes for G/H store, connection and node-prop compatibility. Coverage
remains **128/156 driven, 28 declared holes**, with 50 separate behavior-debt rows.
G–I and overall Step 3 completion remain open.

[Execution and reproducibility evidence](order-e/README.md) includes the
version-matched Linux runner, 180 focused traces, the fresh 428-trace wave,
and the exact preceding checkpoint. Earlier sections are historical.


## Order H complete

Order H is complete: witnesses for every hole upstream can fire, the flow-node
probes, the objects a consumer reads back, and the numeric call sites W13
named. The fresh Linux checkpoint captures all 115 scenarios: **115 pass and 0 fail**, with **zero self-inconsistent scenarios and zero driving divergences**.
Coverage is **155/156 driven, 1 declared hole**, with 50 separate
behavior-debt rows. Step 3 I and overall port completion remain open.

[Execution evidence](order-h/README.md) includes the red runs, the focused
captures, the gates, the first full wave before the drag-payload fix, and the
Order G checkpoint the final wave replaces.

## Order I complete

Order I is complete: the package, its declarations and stylesheets, and the
check that installs it. Giving every export only what upstream's declarations
require found two runtime differences, both fixed. The fresh Linux checkpoint
captures all 115 scenarios: **115 pass and 0 fail**, with **zero
self-inconsistent scenarios and zero driving divergences**. Coverage is
**155/156 driven, 1 declared hole**, with 50 separate behavior-debt rows.
Step 3's queue is complete; overall port completion remains open.

[Execution evidence](order-i/README.md) includes the red runs from a rebuild of
the starting commit, the falsification probes, the gates, the package checks
and the Order H checkpoint the final wave replaces.
