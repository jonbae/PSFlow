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
**accepted**, which must give a reason.
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
A covered bucket: the dual-run net proves the behavior. Cites the test.

### The dual-run net

**The net**:
The harness that mounts upstream xyflow and PSFlow side by side, drives both
through identical scripted interactions, and diffs the results. Called *dual-run*
because neither side is a hand-written expectation.
_Avoid_: the harness, the diff suite

**Fixture**:
One flow definition — nodes, edges, and the props handed to `ReactFlow` — as a
data file both implementations import. Never contains test code.
_Avoid_: test data, flow config, page

**Driver**:
The React component that mounts a fixture. One driver serves both sides, bundled
twice; only the import target differs, so a driver difference can never be
mistaken for a library difference.
_Avoid_: harness, wrapper, app

**Corpus**:
The complete set of scenarios the net drives.
_Avoid_: test suite, scenario list

**Scenario**:
A named entry in the corpus: one fixture plus the sequence of actions driven
against it. Named semantically, never by sequence number — a gate cites scenarios
by name, and numbers shift when the corpus is trimmed.
_Avoid_: test case, spec

**Action**:
One step in a scenario. The primitives are pointer, key, wheel, touch and
imperative call; everything else is a gesture composed from them.
_Avoid_: step, command, interaction (when a single step is meant)

**Gesture**:
A named composition of primitive actions — dragging a node, drawing a selection
box, completing a connection. Written once and reused, so no scenario re-encodes
how a drag works.
_Avoid_: macro, helper

**Trace**:
Everything one run recorded, written to disk. One trace per side per scenario,
divided into sections.
_Avoid_: snapshot, capture, result

**Section**:
One division of a trace, each observing a different mechanism.
_Avoid_: mode, channel

**Driving log**:
The section recording what was done *to* the page rather than how it responded:
per action, the target, whether it resolved, the box it resolved to, and what was
dispatched. Compared ahead of the other sections, because inputs that differ make
output differences uninterpretable.
_Avoid_: stimulus, input, actions

**Probe**:
A component that renders nothing and exists only to report what hooks return and
what props it was handed. A node-level probe replaces a node type rather than
wrapping it.
_Avoid_: spy, instrument, shim

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

**Claimed**:
Of a difference: some region's pattern covers it, so it is someone's stated
decision rather than a failure. An unclaimed difference fails the run.
_Avoid_: allowed, ignored, expected

**Stale**:
Of an entry in any register — region, allowlist entry, witness, hole, census
entry, manifest — it no longer corresponds to anything real, and therefore fails.
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
run that actually happened, which is what stops coverage from being a claim.
_Avoid_: matcher, assertion, expectation

**Hole**:
An export the corpus does not drive, recorded with a written reason. A hole is a
legitimate resting state; an *undeclared* hole fails.
_Avoid_: gap (reserved for audit buckets), uncovered, todo
