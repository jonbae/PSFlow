# PSFlow

A PureScript port of `@xyflow/react`, built so that JS/TS consumers of a library
they already use gain confidence in it. This glossary fixes the vocabulary used
across the parity effort, where several ordinary words carry precise meanings.

## Language

### Surfaces and gating

**JS surface**:
The public API as reached through `index.js` — the door the package bundles,
and the one the audience this repo exists for comes through.
_Avoid_: primary surface, the shim, the public API (unqualified)

**Package**:
What `npm pack` publishes from `dist/`: `index.js` bundled with the compiled
PureScript it reaches, upstream's declarations with ps-flow's gaps written in,
and upstream's stylesheets. `npm run parity:package` holds it to the JS surface;
`distribution/README.md` says how it is built.
_Avoid_: the bundle (the driver has two), the build

**PureScript surface**:
The public API as reached through the `React` module — the door PureScript
consumers come through. Supported, but incidental to the destination.
_Avoid_: incidental surface, the barrel, the internals

**Boundary module**:
The PureScript module standing between the internals and the JS surface,
exposing public values in JS-native shapes while preserving the PureScript
surface. Its conversions are compiler-checked.
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

**Shape**:
Of an export, what a JavaScript caller sees before calling: `typeof`, arity
(`Function.length`), and the React wrapper chain (`memo`, `forwardRef`). Not
the value's contents — deep-equalling the enum objects and calling the pure
functions are separate claims. Compared across the whole JS surface and
deliberately not scoped to the **crossed** set, because a gate bounded by the
conversion plan is invisible-by-construction outside it.
_Avoid_: signature, type (a shape is neither), interface

**Manifest**:
The boundary module's machine-readable partition of public values into those
that have **crossed** and those passing through raw. It records conversion
status, independently of whether an export is **gated**.
_Avoid_: the export list, the crossing table

**Converter**:
One translation between a PureScript type and its JS-native shape, in
`src/Boundary/`. The **unit of work** in the boundary staging — the 68 exports
collapse onto a handful of shared types, and the flow-props record is largely
indivisible, so a stage is measured in converters and not in exports.
_Avoid_: adapter, marshaller, codec (reserved for the enum string tables)

### The gates

**Gate**:
Something that goes red. There are five, and each is named for what its red
means. Never numbered — see *Layer* below. Other things in this repo also go
red without being one of the five: `parity:boundary`, `parity:changelog`,
`parity:fork`, `test:surface`, `test:boundary`, `test:compare`,
`test:harness`, `test:harness:live`, `test:census`, `test:coverage`,
`test:audit`, `test:ci`, and the **unit tests**. Each entry below says where it
sits.
_Avoid_: check, suite (when a gate is meant)

**The four cheap gates**:
The four gates other than **system parity**, grouped by their lower per-run
cost. All five run in per-PR CI; this collective names the four that precede
the net, not the complete CI schedule.
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

**Surface parity**:
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

**Function parity**:
The parity gate at the grain of one call: a pure function's return value,
against the `@psflow/oracle` bundle, over QuickCheck-generated inputs. It
explores inputs no fixture will produce, which is why the net does not subsume
it.
_Avoid_: Layer 1, the oracle tests, the numeric gate

**System parity**:
The parity gate over a mounted app, using **the net** to compare the two sides'
reproducible traces within each scenario's declared experiment. It passes
against the current baseline; a red run is a regression or a claim requiring
review.
_Avoid_: Layer 2, the e2e gate

**Conformance test suite**:
The five `generic-*.spec.ts` files: upstream's own framework-parameterized e2e
specs, ported. Not a coarser rung of the parity ladder but a different
instrument — it encodes upstream's **asserted intent**, a different source of
truth from upstream's behaviour, which is why a net covering the same fixtures
does not retire it.
_Avoid_: Layer 2, the generic specs, e2e

**Smoke test suite**:
`smoke.spec.ts`: **liveness, and nothing else** — the `pageerror` trap and the
no-console-errors session. It was ten tests; the other eight were the repo's
densest hand-authored parity assertions and retired into the net
([#61](https://github.com/jonbae/PSFlow/issues/61)). It runs against a
**driver** now rather than the ps-flow contract page it used to mount: the flow
is `parity/system/fixtures/flow/chrome-defaults.ts`, so the page whose liveness
is checked is the page the net drives.
_Avoid_: Layer 2, the e2e suite

**Retirement**:
Recorded **per test, never per file**, in
`parity/system/corpus/retirement-debt.mjs`: each entry names the spec, the exact
test title, what it proved, the trace **section** the re-report lands in, and the
scenario that does it. Per test because one of the eight, `node drag fires
onNodesChange`, was the only callback assertion on either surface, and a
file-level retirement would have dropped it with nothing saying so. Three things
go red: a citation resolving to no scenario fails the net, a retired title still
present as a `test(` call in its spec fails `test:harness`, and a cited scenario
whose stored traces are empty in the section it retires into fails there too.
The same file's `LIVENESS` holds the tests that did **not** retire, each with the
title it had before, so that every title in the split is accounted for and a
rename cannot read as a deletion. Nothing retires for redundancy — only what the
net *re-reports*.
_Avoid_: deprecation, removal, cleanup

**Outside the scheme**:
Checks and artifacts outside the five named gates: unit tests, gate self-tests,
boundary and package checks, the changelog audit, and the assertion-free
screenshot artifact. A census entry may cite a boundary check as JS-surface
evidence without making it a sixth gate.

**Unit tests**:
The PSFlow-only assertions under `spago test`, outside the gate scheme because
they establish internal consistency rather than agreement with upstream.
_Avoid_: the test suite, the PureScript tests

**Gate self-tests**:
`node --test` over an instrument's *own* logic — surface parity's shape and
allowlist modules, the PureScript record reader both boundary checks share, the
census generator and its staleness logic, system parity's comparison core and
its coverage join, the net harness, the corpus's registers — including the
**retirement** one, which is where a retired assertion still running beside the
net is caught — and the driver's registries, the audit's bucket rules, and the
gates workflow's agreement with README's table plus the baseline vendoring
script it runs. Outside the gate
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
An increment of boundary conversion, counted in **converters** rather than
exports: stages 1–4 cover the fixture-facing surface, callbacks, instance/hooks
and remaining components, and stage 5 covers the remaining pure functions.
A stage records what has **crossed**; a gate records what would go red.
_Avoid_: phase, tier

### Baselines and upstream

**Baseline**:
The vendored `xyflow/` checkout plus the exact-pinned `@xyflow/*`
devDependencies, also called the parity baseline. Unqualified "baseline"
always means this one. Bumping it is
the atomic procedure in README.
_Avoid_: the vendored tree (when the pin is also meant), the pin

**Trace baseline**:
Persisted recorded trace values used for later comparison or re-diffing.
Always written in full, to distinguish them from the vendored-source and
package-pin **baseline**.
_Avoid_: golden, snapshot

**Upstream**:
Four senses, and a sentence must make clear which. Conflating them is how the
dual-run spike came to measure the published build against source-derived
findings without anyone noticing.

| sense | is | who reads it |
|---|---|---|
| vendored source | the `xyflow/` checkout | all three parity gates |
| published build | `node_modules/@xyflow/*` | no parity gate. The boundary tests' upstream side, the driver page's stylesheets, and the package's stylesheets and declaration cross-check |
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

**Bucket**:
The label a row carries, naming what proves that behavior — or, for the ungated
buckets, what does not. Every bucket carries a **kind**, and three of the four
say what the row owes: **covered**, which must cite evidence; **gap**, which
must name a ticket or a plan; and **accepted**, which must give a reason. The
fourth is `n/a`'s own, and is not a kind in that sense — a change with no PSFlow
analogue is neither proven nor unproven and owes nothing. A covered bucket that
names a gate uses the gate's own name — `surface`, `function`, `conformance`,
`system` — because the bucket key and the gate name are deliberately the same
word. The remaining covered buckets (`docs`, `ts-only`, `unit`) name something
other than a gate.
_Avoid_: verdict, status, category

**Ported-ungated**:
A gap bucket: PSFlow implements the change, no gate exercises it, and nothing
is planned.

**Gate-pending**:
A gap bucket: PSFlow implements the change, no gate exercises it, and a named
gate is the plan. Names the target gate — which is the covered bucket the row
will graduate into — the scenario or test that will prove it, and, where the
target is the net, the boundary **stage** that unblocks it. A named scenario has
to resolve against the corpus's **name space** or the audit fails: a typo, an
invention and a plan are otherwise the same three words in a JSON file.
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
The apparatus that mounts upstream xyflow and PSFlow side by side, drives both
through identical scripted interactions, and diffs the results. Called *dual-run*
because neither side is a hand-written expectation.
_Avoid_: the diff suite

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
_Avoid_: wrapper, app

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

**Name space**:
Every id a scenario may be cited by: written scenario ids together with
**reserved ids**, including any not yet written. Citation resolution and
evidence that a scenario ran are separate claims.
_Avoid_: the scenario list

**Reserved id**:
A scenario id held for its designated corpus source, whether or not that source
has written it yet. Reservation makes a citation resolve; only a captured
scenario can establish that a behavior was driven.
_Avoid_: placeholder, stub, planned scenario

**Conformance seed**:
The scenarios **lifted** from upstream's own end-to-end suite — its interaction
sequences, transcribed with every assertion dropped. One of the corpus's sources,
beside the derived **mount-only baselines**; the others are the test-debt
scenarios, the **retirement debt**, and subsequent hole-closing scenarios.
Say *the seed* only where the corpus is already in view.
_Avoid_: the ported tests, the conformance suite

**Mount-only baseline**:
A scenario that mounts one fixture and observes its settled state without
further interactions. The corpus derives one for every fixture, including
example drivers.

**Retirement debt**:
The corpus source and register accounting for each hand-authored assertion
handed over to the net. A completed retirement still needs this record to
identify the scenario and observation that replaced it.

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
_Avoid_: the fork (for the file)

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
_Avoid_: runner

**Gesture**:
A named composition of primitive actions — dragging a node, drawing a selection
box, completing a connection. Written once and reused, so no scenario re-encodes
how a drag works.
_Avoid_: macro, helper

**Trace**:
The complete recorded observation of one **capture**, divided into seven
sections and persisted for comparison. A run contains four traces: two
captures of each side of one scenario.
_Avoid_: snapshot, result

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
_Avoid_: snapshot, execution

**Run**:
One scenario, two sides, two **captures** each — four traces, read in one order.
The four go into `compare.mjs` in any order and are grouped by the side each
records.
_Avoid_: comparison, pass (of the net), execution

**Self-consistency**:
A side's two **captures** compared **against itself**, within the scenario's
declared comparison experiment and before the two sides are compared at all: a
recorded **trace baseline** is meaningless if traces are not reproducible. A
plain scenario's experiment is all seven sections; a probe scenario's is the
hook/API/props level it was generated to observe, while its complete trace is
still persisted. A side disagreeing with itself is its own failure class, and it
is the one comparison no **region** may claim — a region says the two
implementations differ for a stated reason, and there is no such statement about
a side differing from itself. In a plain scenario the **driving log** takes part
with no tolerance: it never reaches the normalizer, which is how sub-pixel box
wobble is caught. Every other selected section normalizes as usual.
_Avoid_: flake check, stability check, reproducibility test

**Consequence**:
Of a difference in the selected experiment: it sits in a section the diverging
**driving log** has made unreadable, so it is a reading of two runs that were not
one experiment. Named in the report and **never suppressed within that
experiment** — capture-everything applies to a failed run as much as to a
passing one, and a real divergence is exactly what would be hiding underneath.
Says nothing about whether the difference is real; only that it cannot yet be
attributed, which is what distinguishes it from a **claimed** difference.
_Avoid_: symptom, knock-on, downstream difference

**Probe**:
A component that renders nothing and exists only to report what hooks return and
what props it was handed. A node-level probe replaces a node type rather than
wrapping it. A callback installed as a hook option is tagged in the exact
**call log**, so the probe experiment can select its receipts without mixing
in ordinary flow callbacks caused by the replacement graph. Independent hook
callback subscriptions get separate mechanically derived probe scenarios, so
their exact receipt sequences do not interleave. In parity prose a bare "probe"
is always this component — never the
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
A system-parity claim over differences left after normalization: a pattern
carrying recorded values, a written reason and a ticket when it names a known
bug. Its outcomes are *rides free* for unchanged values, *moved* for values
requiring re-affirmation, and *stale* when it claims nothing; recording cannot
create a claim.
_Avoid_: waiver, exception, allowlist entry (when a region is meant)

**Allowlist**:
The surface-parity register of reviewed export, shape, behavior and prop-member
differences. It applies the same noise-policy principle as a **region** at the
export surface: an accepted difference needs a reason, and an entry claiming
nothing fails as **stale**.
_Avoid_: waiver, exception

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
_Avoid_: waiver, tolerance, exception

**Axis**:
The aspect of callback comparison a **weakening** relaxes: `count` or `order`.
A count weakening also excludes unpaired occurrences from interleaving;
arguments remain compared.
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

### Export coverage

**Export census**:
The classification of every public upstream export by its kind, observation
mechanism and the gates that reach it on each surface. Its static attribution
is separate from trace-derived coverage.

**Census entry**:
One export in the **export census**, independently of how many conditional
behaviors it contains. Export and changelog-row counts measure different things
and are never summed.
_Avoid_: census row, coverage row

**Spec attribution**:
The explicit association of a census entry with a spec that exercises it on a
named surface. A boundary manifest records that an export has crossed; spec
attribution supplies the separate claim that a browser spec gates it.

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
An export-bearing census entry the corpus does not drive, recorded with a
written reason; one reason may account for several entries. A declared hole
passes, an undeclared one fails, and a declaration over an entry now driven or
absent from the census fails as **stale**.
_Avoid_: gap (reserved for audit buckets), uncovered, todo

**Name**:
What the runtime called something a section recorded — a handler's name, an api
query key or call name, a probe id, a hook's name. Not always a handler: the
`NodeChange` and `EdgeChange` members all ride on one handler, so a change's own
discriminant is a name too, written `onNodesChange:position`. Witnessing
`NodeAddChange` by the handler alone would count it driven the moment a mount
fired one dimension change.
_Avoid_: token, key, identifier
