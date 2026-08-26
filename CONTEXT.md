# PSFlow

A PureScript port of `@xyflow/react`, built so that JS/TS consumers of a library
they already use gain confidence in it. This glossary fixes the vocabulary used
across the parity effort, where several ordinary words carry precise meanings.

## Language

### Surfaces and gating

**JS surface**:
The public API as reached through `index.js` — the door `package.json` `main`
points at, and the one the audience this repo exists for comes through.
_Avoid_: primary surface, the shim, the public API (unqualified)

**PureScript surface**:
The public API as reached through the `React` module — the door PureScript
consumers come through. Supported, but incidental to the destination.
_Avoid_: incidental surface, the barrel, the internals

**Boundary module**:
`src/Boundary.purs`, the single PureScript module standing between the internals
and the JS surface. It re-exports all 60 public symbols, crossing each into a
JS-native shape as the staging reaches it, and `index.js` is a bare re-export of
its compiled output. The conversion lives in PureScript so the compiler checks
it; the internals and the PureScript surface are untouched by it.
_Avoid_: the adapter, the wrapper layer, the shim

**Gated**:
Of an export, always relative to one named surface: some gate would go red if
that export's behavior on that surface broke. Never write "gated" unqualified —
a gate proves the surface it entered through, and the two surfaces can disagree.
_Avoid_: covered, proven, tested, and bare "gated"

**Crossed**:
Of an export: a JS-shaped wrapper for it exists, so it is callable from
JavaScript. Independent of gated — an export can be crossed with nothing proving
the conversion is right.
_Avoid_: converted, wrapped, adapted

**Shape** (of an export):
What a JavaScript caller sees before calling: `typeof`, arity
(`Function.length`), and the React wrapper chain (`memo`, `forwardRef`). Not
the value's contents — deep-equalling the enum objects and calling the pure
functions are separate claims. Compared across the whole JS surface and
deliberately not scoped to the **crossed** set, because a gate bounded by the
conversion plan is invisible-by-construction outside it.
_Avoid_: signature, type (a shape is neither), interface

**Manifest**:
The boundary module's machine-readable record of which exports have **crossed**
and which are still passing through raw, in `src/Boundary.js`. It exists so a
gate can scope itself to the crossed set and grow with the staging instead of
carrying a hand-maintained list of its own.
_Avoid_: the export list, the crossing table

**Converter**:
One translation between a PureScript type and its JS-native shape, in
`src/Boundary/`. The **unit of work** in the boundary staging — the 60 exports
collapse onto a handful of shared types, and the flow-props record is largely
indivisible, so a stage is measured in converters and not in exports.
_Avoid_: adapter, marshaller, codec (reserved for the enum string tables)

**Deferred prop**:
A prop that resolves on the JS surface but whose converter has not landed. It
**throws at mount**, naming the stage that will land it, because a prop that was
silently ignored would be indistinguishable from a prop the consumer never set.
_Avoid_: unsupported prop, unimplemented prop, TODO prop

### The gates

**Gate**:
Something that goes red. There are five, and each is named for what its red
means. Never numbered — see *Layer* below. Other things in this repo also go
red without being one of the five: `parity:boundary`, `parity:changelog`,
`parity:fork`, `test:surface`, `test:compare`, `test:harness`,
`test:harness:live`, `test:census`, `test:ci`, `test:node-props`, and the
**unit tests**. Each entry below says where it sits.
_Avoid_: layer, check, suite (when a gate is meant)

**The four cheap gates**:
The five minus **system parity** — what per-PR CI runs
(`.github/workflows/gates.yml`). *Cheap* is per-run cost and nothing else: the
one left out is the gate whose cost is not yet measurable, not the one with the
coarsest grain. Not a sixth thing that goes red, and not a tier — the collective
exists because CI's scope needed one word for it.
_Avoid_: the fast gates, the CI gates, the cheap ladder

**Parity gate**:
One of the three gates that compares PSFlow against **executing** upstream, so
neither side is a hand-authored reading of xyflow: **surface parity**,
**function parity**, **system parity**. That is what the word `parity` marks in
a gate name, and it is the sense the common noun *oracle* used to carry. The
script *prefix* is looser than the term: `parity:boundary` is a staleness check
over `src/Boundary/`, `parity:changelog` measures what a baseline bump costs,
and `parity:fork` reads the **fork register** — none of the three is a parity
gate. Renaming them was ruled out of scope; read the prefix as "lives under
`parity/`". `parity:fork` differs from the other two in one way worth knowing:
it is also **system parity**'s first step, so it can turn a gate red as well as
go red on its own.

**The delete-`xyflow/` test**:
What decides membership of the parity gates. Delete the vendored checkout from
the machine: all three become impossible, having nothing left to compare
against. Conformance and smoke still run and still mean something. The same
test decides membership inside `spago test` — `Test.Parity.*` imports
`Test.Oracle` and cannot run without the checkout; the **unit tests** can.
QuickCheck is *not* the criterion: `Test.System.Utils.Store` runs properties
with no upstream at all.

**Surface parity** (`npm run parity:surface`):
The parity gate at the grain of one export: the **values** `index.js` publishes
and their **shapes** — `typeof`, arity, React wrapper kind — plus prop members
and two behavioral checks: deep-equality of the eight frozen enum objects and
call-and-compare over the seventeen pure functions. All are compared against
the vendored upstream. It *imports* `index.js` rather than reading it, so it
proves a binding resolves rather than that a line exists, and therefore needs
`spago build` first: this gate is not standalone. Type names still come from
`src/React.purs`, types having nothing to import. An upstream value is satisfied
only by a PSFlow value. The behavioral checks still run in Node, in seconds,
without mounting or opening a browser.
_Avoid_: Layer 0, the API diff, `parity:api`

**Function parity** (the `Test.Parity.*` modules under `spago test`):
The parity gate at the grain of one call: a pure function's return value,
against the `@psflow/oracle` bundle, over QuickCheck-generated inputs. It
explores inputs no fixture will produce, which is why the net does not subsume
it.
_Avoid_: Layer 1, the oracle tests, the numeric gate

**System parity** (`npm run parity:system`):
The parity gate at the grain of a whole mounted app — the **net**. The audit
bucket named `system` and this gate name coincide deliberately. It builds both
bundles, drives the **corpus** against each side twice, writes every **trace**
to `parity/system/traces/`, and diffs the runs it reads back off disk. Its
corpus today is **mount-only baselines**, one per **fixture**; the rest arrives
with the corpus ticket. Red is its expected state while the divergence backlog
is being worked — a failing run is recording what the two implementations do,
and the answer is a fix or a **region**, never a looser comparison.
_Avoid_: Layer 2, the e2e gate

**Conformance test suite** (`npm run test:conformance`):
The five `generic-*.spec.ts` files: upstream's own framework-parameterized e2e
specs, ported. Not a coarser rung of the parity ladder but a different
instrument — it encodes upstream's **asserted intent**, a different source of
truth from upstream's behaviour, which is why a net covering the same fixtures
does not retire it.
_Avoid_: Layer 2, the generic specs, e2e

**Smoke test suite** (`npm run test:smoke`):
`smoke.spec.ts`: liveness — the `pageerror` trap and the no-console-errors
session — plus the hand-authored interaction assertions that have not been
retired yet. Retirement is recorded **per test**, as a header comment naming
the exact condition, rather than per file: four of its tests retire on the
net's `dom` section and `node drag fires onNodesChange` retires on
`callbacks`, and not before — it is the repo's only callback assertion.
Writing those comments is part of the retirement work
([#61](https://github.com/jonbae/PSFlow/issues/61)); the file does not carry
them yet.
_Avoid_: Layer 2, the e2e suite

**Outside the scheme**:
Two browser specs are not gates in the five-gate sense and get their own
Playwright projects rather than a home inside one. `node-props.spec.ts`
(`npm run test:node-props`) is a PSFlow-specific guard on the `NodeProps`
record, and retires when the net's `props` section is green (#61).
`screenshot.spec.ts` asserts nothing at all and only writes an artifact. The
census names them as gates on individual rows because *something* would go red;
neither is one of the five.

`parity:boundary` is likewise not one of the five gates, but the census names
its mount check as row-level JS-surface proof for the crossings it directly
exercises. In that scoped use, `boundary` means “this census entry would make
the boundary mount check go red,” not “boundary is a sixth gate.”

**Unit tests**:
The PSFlow-only modules under `spago test` — `Test.Properties`,
`Test.System.Utils.Store`, `Test.React.Store.Reduce`,
`Test.React.Hook.VisibleIds`, and `Test.Main`'s inline assertions. Recorded
explicitly as **outside the gate scheme**: they prove PSFlow's internals are
self-consistent, which is a different claim from "PSFlow matches xyflow".
_Avoid_: the test suite, the PureScript tests

**Gate self-tests** (`npm run test:surface`, `test:census`, `test:compare`,
`test:harness`, `test:ci`):
`node --test` over an instrument's *own* logic — surface parity's shape and
allowlist modules, the census generator and its staleness logic, system parity's
comparison core, the net harness and the driver's registries, and the gates
workflow's agreement with README's table plus the baseline vendoring script it
runs. Outside the gate
scheme for the same reason the **unit tests** are:
they prove an instrument does what it claims, which is a different claim from "PSFlow
matches xyflow". A red one means the instrument is broken, not the port.
_Avoid_: the parity tests, the gate tests (when a gate itself is meant)

**Layer**:
Retired. The numbering encoded concentric containment (Layer 2 ⊃ Layer 1 ⊃
Layer 0) that the census disproved — function parity proves 26 exports system
parity never observes — and it collapsed two different orderings, granularity
and cost, onto one axis. Closed tickets keep their original wording; this table
is the mapping.

| was | is | script |
|---|---|---|
| Layer 0 | surface parity | `parity:api` → `parity:surface` |
| Layer 1 (`Test.Parity.*` only) | function parity | `spago test`, unchanged |
| Layer 2, the five `generic-*` specs | conformance test suite | `test:smoke` → `test:conformance` |
| Layer 2, `smoke.spec.ts` | smoke test suite | `test:smoke` |
| the net | system parity | `parity:system` |
| audit buckets `layer0` / `layer1` / `layer2` | `surface` / `function` / `conformance` | — |
| audit bucket `system` | unchanged — it already named the gate | — |
| census gates `L0` / `L0-props` / `L1` | `surface` / `surface-props` / `function` | — |
| census gates `L2` / `L2-indirect` | `<suite>:<spec>` / `<suite>-indirect:<spec>` | — |

`build:oracle` is unchanged and `@psflow/oracle` stays a proper noun: renaming
the package would churn FFI imports for no clarity gain.

**Stage**:
A step of the boundary staging (1–4), counted in **converters**. Orthogonal to
gates, not a synonym: a stage says how much of the surface has **crossed**, a
gate says what would go red. Stages 2–4 deliberately open a
crossed-but-ungated window, and saying "stage" where "layer" used to appear
does not fix anything. In practice each stage has closed its own window in the
same commit, because `parity:boundary` mounts what the stage crossed and the
census counts that as a JS-surface gate; the window is what would open if a
stage landed converters without one.
_Avoid_: layer, phase, tier

### Baselines and upstream

**Baseline** / **parity baseline**:
The vendored `xyflow/` checkout plus the exact-pinned `@xyflow/*`
devDependencies. Unqualified "baseline" always means this one. Bumping it is
the atomic procedure in README.
_Avoid_: the vendored tree (when the pin is also meant), the pin

**Trace baseline**:
The persisted recorded values a system-parity run diffs against. Always
written in full — never bare "baseline". Both baselines get bumped, both get
re-recorded, and both **fail stale**; they are otherwise unrelated.
_Avoid_: baseline, golden, snapshot

**Upstream**:
Four senses, and a sentence must make clear which. Conflating them is how the
dual-run spike came to measure the published build against source-derived
findings without anyone noticing.

| sense | is | who reads it |
|---|---|---|
| vendored source | the `xyflow/` checkout | all three parity gates |
| published build | `node_modules/@xyflow/*` | nothing — a version pin the repo must not import |
| running behaviour | the vendored source, mounted and driven | system parity |
| asserted intent | `xyflow/examples/react/src/generic-tests/` | the conformance test suite |

**System parity runs vendored source**, which is what keeps all three parity
gates on one artifact with one bump procedure.

**Oracle**:
Not a common noun. `@psflow/oracle` is the bundle — a proper noun, and the
`build:oracle` script's object; "the oracle bundle" and "the oracle's shape"
refer to it and are fine. "Differential oracle" is the technique. What is
dropped is the **role**-sense — *the thing whose answer is taken as correct* —
which is now carried by **parity**, said explicitly by three gate names.
Without that written down, the next reader sees two suites over one fixture set
and deletes one.
_Avoid_: the oracle gate, oracle tests, oracled (as a verb for "gated by
function parity")

### The changelog audit

**Row**:
One upstream pull request, as recorded in the changelog audit. Each row states
what PSFlow did about that upstream change.
_Avoid_: entry, PR (when the audit record is meant rather than the pull request)

**Census entry**:
One line of the export census — one **export**. Never a "row": a row is one
upstream pull request, and the two count different things. An export can be
driven while every conditional behavior inside it goes unexercised, so the two
counts are reported separately and never summed.
_Avoid_: census row, coverage row

**Bucket**:
The label a row carries, naming what proves that behavior — or, for the ungated
buckets, what does not. Every bucket is one of three kinds: **covered**, which
must cite evidence; **gap**, which must name a ticket or a plan; and
**accepted**, which must give a reason. A covered bucket that names a gate uses
the gate's own name — `surface`, `function`, `conformance`, `system` — because
the bucket key and the gate name are deliberately the same word. The remaining
covered buckets (`docs`, `ts-only`, `unit`) name something other than a gate.
_Avoid_: verdict, status, category

**Ported-ungated**:
A gap bucket: PSFlow implements the change, no gate exercises it, and nothing
is planned.

**Gate-pending**:
A gap bucket: PSFlow implements the change, no gate exercises it, and a named
gate is the plan. Names the target gate, the scenario or test that will prove
it, and — where the target is the net — the boundary stage that unblocks it.
_Avoid_: net-pending, planned, todo

**Accepted-ungated**:
An accepted bucket: PSFlow implements the change and nothing will ever gate it,
by deliberate decision. Carries the written reason.
_Avoid_: wontfix, ignored

**Not-ported**:
A gap bucket: the behavior is absent from PSFlow, wholly or in the part that
matters.

**System**:
A covered bucket: the dual-run net proves the behavior. Cites the test. Same
word as the **system parity** gate, on purpose.

### The dual-run net

**The net**:
The harness that mounts upstream xyflow and PSFlow side by side, drives both
through identical scripted interactions, and diffs the results. Called *dual-run*
because neither side is a hand-written expectation.
_Avoid_: the harness (which is the capture half alone), the diff suite

**Fixture**:
One flow definition — nodes, edges, and the props handed to `ReactFlow` — as a
data file both implementations import. Never contains test code. An **example
driver** carries its fixture inside the component instead, which is why it is
imported unmodified rather than twinned. They live in two roots — upstream's
vendored `generic-tests/` and `parity/system/fixtures/` for PSFlow's own — so
that the vendored tree stays byte-identical and a bump stays `rm -rf` and
re-vendor.
_Avoid_: test data, flow config, page

**Driver**:
The React component that mounts a fixture. Each driver serves both sides,
bundled twice; only the import target differs, so a driver difference can never
be mistaken for a library difference. There are two, and one page routes to
both: `parity/driver/src/Flow.tsx`, which takes a fixture as data, and one
**example driver**.
_Avoid_: harness, wrapper, app

**Example driver**:
A driver imported **unmodified** from upstream's `examples/`, rather than
twinned. It declares its own flow inline, so it is its own **fixture** — which
is what puts it under the make-hand-translation-impossible bar that `Flow.tsx`
escapes. There is one, `examples/ColorMode/index.tsx`, and it exists because
upstream has no props fixture for the conformance suite's props spec to drive.
Its route is upstream's own (`#/examples/color-mode`), never a fixture route.
_Avoid_: example page, bespoke page, example fixture

**Corpus**:
The complete set of scenarios the net drives.
_Avoid_: test suite, scenario list

**Scenario**:
A named entry in the corpus: one fixture plus the sequence of actions driven
against it. Named semantically, never by sequence number — a gate cites scenarios
by name, and numbers shift when the corpus is trimmed.
_Avoid_: test case, spec

**Conformance seed**:
The scenarios **lifted** from upstream's own end-to-end suite — its interaction
sequences, transcribed with every assertion dropped. One of the corpus's sources,
beside the derived **mount-only baselines**; the others are the test-debt
scenarios and the hole-closing scenarios after them. Say *the seed* only where
the corpus is already in view.
_Avoid_: the ported tests, the conformance suite (which is a **gate**, and drives
PSFlow alone), the baseline

**Lifted**:
Of a scenario: transcribed from an upstream spec as a **one-time fork**, never a
mirror. Drift between the spec and the scenario is legitimate — the spec asserts
upstream's expectations against PSFlow alone, while the scenario drives both
sides and asserts nothing — so a changed spec asks for the scenario to be
**re-affirmed** and never re-synced. Silent drift is not legitimate, which is
what the **fork register** exists to prevent.
_Avoid_: copied, ported, synced, mirrored

**Fork register**:
`parity/system/corpus/fork.json`: every test and hook in the forked spec files,
against a hash of its own source and the scenarios lifted from it. Its outcomes
are *affirmed*, *moved* (re-affirm), *stale*, *unregistered* (a bump added a
test nobody decided about) and *unlifted* (a seed scenario with no origin
recorded). An entry that lifts nothing carries a written reason, the way a
**region** does — `scenarios: []` is how "covered by the mount-only baseline"
and "nobody got round to it" both look. Not a **region**: a region claims a
difference a comparison reported, where this claims a correspondence to
something outside the repo.
_Avoid_: region, manifest, the fork (for the file)

**Re-affirm**:
To read what changed and decide the entry still says something true, then stamp
the new value. What a **moved** region and a **moved** fork entry both ask for,
and deliberately not what an automatic refresh does: `--record` and `--affirm`
restamp, and neither checks the claim. On a baseline bump the re-affirm set is
the behavioural changelog, and its size is the bump's measured cost.
_Avoid_: re-sync, update, refresh, accept

**Action**:
One step in a scenario. The primitives are pointer, key, wheel, touch and
imperative call; everything else is a gesture composed from them.
_Avoid_: step, command, interaction (when a single step is meant)

**Action vocabulary**:
The frozen object a scenario is handed: the closed primitive tier and the open
gesture tier, and nothing else — no page, no side, no library handle, no
imperative return value. Say **vocabulary**, never *driver object*, even though
the corpus ticket wrote it that way: a **driver** here is the React component
that mounts a fixture, and one sentence cannot carry both. It is what makes
"a scenario has no way to learn which side it is running against" a structural
fact rather than a rule.
_Avoid_: driver object, actions API, helpers

**Harness**:
The **capture** half of the net, `parity/system/harness/`: it drives one
scenario against one side and returns a trace. Narrower than **the net**, which
is capture and compare together, and not a **driver**, which is a React
component. Say which is meant — "the harness" for the whole net is what the
entries above rule out, and this is the sense that survives.
_Avoid_: the net (when only capture is meant), runner, driver

**Gesture**:
A named composition of primitive actions — dragging a node, drawing a selection
box, completing a connection. Written once and reused, so no scenario re-encodes
how a drag works.
_Avoid_: macro, helper

**Trace**:
Everything one run recorded, as JSON: returned by **capture**, written to disk,
and read back by compare. One trace per side per scenario, divided into
sections. The disk is not incidental — it is what lets a revised noise policy
re-diff every trace ever captured in seconds, without a browser.
_Avoid_: snapshot, capture (the step, not what it produced), result

**Section**:
One division of a trace, each observing a different mechanism.
_Avoid_: mode, channel

**Driving log**:
The section recording what was done *to* the page rather than how it responded:
per action, the target, whether it resolved, the box it resolved to, and what was
dispatched. Compared ahead of the other sections, because inputs that differ make
output differences uninterpretable.
_Avoid_: stimulus, input, actions

**Call log**:
The in-page accumulation the `callbacks` section is read off — what the page did
*back*, where the **driving log** is what was done to it. The two are a pair, so
a sentence with both in view has to say which; inside the module that is about
one of them, a bare "the log" is that one. It lives in the page because a call
leaves nothing behind to read afterwards, and its arguments are serialized at the
moment of the call because xyflow mutates what it hands a handler. A page that
published none **fails the capture**, rather than recording an empty section that
would compare clean against the other side's.
_Avoid_: the log (where the driving log is also in view), the callback trace, the
event log

**Capture**:
Two senses, and both are load-bearing. As a *step*, it is the half of the net
that drives a scenario and produces a **trace** — the sense **Harness** carries.
As a *count*, it is one numbered drive of one scenario against one side, which
is the trace envelope's `capture` field: each side is captured twice, and
`capture: 2` names the second. A sentence must make clear which; "capture 1" and
"the capture step" both do.
_Avoid_: run (for the count — a run is all four), snapshot, execution

**Run** (of system parity):
One scenario, two sides, two **captures** each — four traces, read in one order.
The four go into `compare.mjs` in any order and are grouped by the side each
records.
_Avoid_: comparison, pass (of the net), execution

**Self-consistency**:
A side's two **captures** compared **against itself**, before the two sides are
compared at all: a recorded **trace baseline** is meaningless if traces are not
reproducible. A side disagreeing with itself is its own failure class, and it is
the one comparison no **region** may claim — a region says the two
implementations differ for a stated reason, and there is no such statement about
a side differing from itself. The **driving log** takes part with no tolerance:
it never reaches the normalizer, which is how sub-pixel box wobble is caught.
Every other section normalizes as usual.
_Avoid_: flake check, stability check, reproducibility test

**Consequence**:
Of a difference: it sits in a section the diverging **driving log** has made
unreadable, so it is a reading of two runs that were not one experiment. Named
in the report and **never suppressed** — capture-everything applies to a failed
run as much as to a passing one, and a real divergence is exactly what would be
hiding underneath. Says nothing about whether the difference is real; only that
it cannot yet be attributed, which is what distinguishes it from a **claimed**
difference.
_Avoid_: symptom, knock-on, downstream difference

**Probe**:
A component that renders nothing and exists only to report what hooks return and
what props it was handed. A node-level probe replaces a node type rather than
wrapping it. In parity prose a bare "probe" is always this component — never the
throwaway investigative script the hole-driven-development agents run to falsify
an assumption about the domain, which is a **scratch script** and lives in
`.hdd/scratch/`, not in the repo.
_Avoid_: spy, instrument, shim; and "probe" for a one-off investigative script

**Falsification probe**:
Always written in full, because a bare "probe" is the component above. A check
that feeds one side of a comparison a deliberately wrong input and asserts the
comparison reports a difference. It ships beside the green claim it backs, runs
with it, and drives **the same comparator** — a probe that hand-rolls its own
comparison proves that comparison and not the one in service. A green
differential result is equally what a comparator that inspects nothing, an
oracle wired to the wrong export, or a projection that discarded the
interesting field would produce, so the green means nothing until the same
machinery has been shown to go red. `parity/boundary/drift.mjs` and
`Test.Parity.Util` each name their runner `falsify`.
_Avoid_: negative test, sanity check, canary

**Normalization**:
The content-blind half of the noise policy: rules that may delete a field by name
or reorder one, and may never collapse two distinct values into one. A rule
consults a field's name and position, never its value — which is why no tolerance
rule can be written as one. A deleted field is unobserved, not passing.
_Avoid_: cleaning, canonicalization, tolerance

**Region**:
A claim over the differences normalization does not touch: a pattern carrying a
written reason, plus a ticket where the difference is a known bug. Its three
outcomes are *rides free* (it claimed what it recorded), *moved* (it claimed
different values, and someone must re-affirm that they are still the same cause)
and *stale*. Recording values under a region is cheap; recording cannot create
one. The register is `parity/system/regions.json`; surface parity's allowlist is
the same concept with a second implementation, and the stale rule applies to it
too.
_Avoid_: waiver, exception, allowlist entry (when a region is meant)

**Allowlist**:
The second implementation of **Region**, in `parity/surface/allowlist.json`:
one concept, two files, because both turn a known difference from a failure
into a recorded, reviewed fact so that red stays reserved for what is new. Say
which one is meant — an allowlist entry is not a region. The stale rule holds
on both: an entry that no longer corresponds to a real difference fails.
_Avoid_: region (when the surface-parity file is meant), waiver, exception

**Claimed**:
Of a difference: some region's pattern covers it, so it is someone's stated
decision rather than a failure. An unclaimed difference fails the run.
_Avoid_: allowed, ignored, expected

**Weakening**:
A relaxation of the **callbacks** comparison for one callback along one **axis**
— `count` or `order` — carrying a written reason, in
`parity/system/weakenings.json`. Not a third implementation of **Region**: a
region claims a difference *the comparison reported* and records the values it
claimed, while a weakening changes what the comparison asserts and records
nothing. That is exactly why there is no `arguments` weakening — an argument
that differs has a path, so it is a region's to claim. Reserved for the
callbacks section; nothing else in the trace has an axis to relax.
_Avoid_: region, waiver, tolerance, exception

**Axis** (of a weakening):
Which of the three things the callbacks comparison asserts — order, count,
interleaving — a **weakening** lets go. Deliberately not `kind`, which is
regions' word for what sort of claim a region is; the two registers are
different mechanisms and a shared field name would read as a shared taxonomy.
_Avoid_: kind, type, mode

**Stale**:
Of an entry in any register — region, allowlist entry, weakening, fork entry,
witness, hole, census entry, manifest — it no longer corresponds to anything
real, and therefore fails.
The inversion is deliberate and repo-wide: entries bite when they stop being true
instead of accumulating silently, which is what makes a register a gate rather
than a record.
_Avoid_: outdated, unused, orphaned

**Reachable**:
Of a behavior: it lands in one of the snapshot's sections, so the net is capable
of observing it.

**Driven**:
Of a behavior: some scenario actually performs the actions that make it happen.
Coverage requires both driven and reachable; reachable alone proves nothing.
_Avoid_: exercised, covered (when only reachability is meant)

**Settled**:
Of a page: it has stopped changing, established by polling until consecutive
snapshots agree. Each side settles on its own clock.

**Gesture complete**:
Of a scripted interaction: it has finished, including releasing the pointer.
Distinct from settled — a scenario whose last action leaves the pointer down
settles mid-gesture, which is the only way transient state is observed.

**Witness**:
The rule joining a captured trace back to an export it proves was driven — a name
mapping for most sections, a selector for `dom`. A witness is evaluated against a
run that actually happened, which is what stops coverage from being a claim. Which
kind an export takes follows the section the census puts it in, never the register
entry. The register is `parity/system/coverage/witnesses.json`, and an export with
no witness fails: a **hole** does not stand in for one, because the two say
different things — "the corpus does not drive this" and "here is what driving it
would look like".
_Avoid_: matcher, assertion, expectation

**Hole**:
An export the corpus does not drive, recorded with a written reason in
`parity/system/coverage/holes.json`. A hole is a legitimate resting state; an
*undeclared* hole fails, and a hole over an export something did drive fails as
**stale**. The register is machine-readable because other work is derived from it
rather than deciding again: boundary stage 4 takes the components no fixture
mounts, and probed-variant selection takes the uncovered `hooks` and `props`
exports.
_Avoid_: gap (reserved for audit buckets), uncovered, todo

**Name** (of a witness):
What the runtime called something a section recorded — a handler's name, an api
query key or call name, a probe id, a hook's name. Not always a handler: the
`NodeChange` and `EdgeChange` members all ride on one handler, so a change's own
discriminant is a name too, written `onNodesChange:position`. Witnessing
`NodeAddChange` by the handler alone would count it driven the moment a mount
fired one dimension change.
_Avoid_: token, key, identifier
