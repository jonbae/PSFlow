# 081 — The interaction corpus

Resolution asset for [The interaction corpus: which interactions does the net
drive?](https://github.com/jonbae/PSFlow/issues/26). Vocabulary is in
`CONTEXT.md`, which this ticket extended with **fixture**, **driver**,
**corpus**, **action**, **gesture**, **trace**, **section**, **driving log**,
**probe**, **witness**, **hole** and **census entry**.

Specified only. Building the corpus, the helper module and the coverage artifact
is execution.

## What a scenario is made of

A scenario is code, composed from a **closed set of named helpers** in two tiers:

- **Primitive tier** — `pointerDown` / `pointerMove` / `pointerUp`, `key`,
  `wheel`, `touch`, `call`. Fixed; extending it is a decision.
- **Gesture tier** — `dragNode`, `selectionBox`, `connect`, `pan`, `pinch`,
  `arrowKeyNudge`, built from primitives. Open by addition; adding one is a
  reviewable act, not a scenario detail.

Scenarios reach for the gesture tier by default and drop to primitives only when
the scenario is *about* an unusual input sequence — which is most of the
mid-gesture cases below.

This settles the question the observation ticket left open (*are keyboard input,
selection boxes and viewport gestures separate kinds or compositions?*): they are
**compositions promoted to named kinds**. The vocabulary is closed at the
primitive tier and open-by-addition above it.

**The scenario function is handed a driver, never the side's identity.** With no
way to learn whether it is running against upstream or PSFlow, a scenario cannot
branch on the side — the failure mode that would silently invalidate every
comparison is made unreachable rather than merely discouraged.

Rejected: a declarative action DSL (needs an interpreter plus an escape hatch,
and buys nothing the two tiers don't already give) and free-form Playwright code
(leaves the vocabulary open, so no scenario's actions are statically readable —
which the coverage mechanism below depends on).

## Targeting: selector-relative, with the resolution recorded

Actions name their target by selector; **each side resolves it against its own
render**. Absolute coordinates were rejected: any `fitView` or layout divergence
would make one side miss the node entirely, turning the spike's 2.2e-2 zoom gap
into a total-miss cascade on every scenario at once.

The cost of selector-relative targeting is that **the pointer follows the
divergence** — if the two sides place a node five pixels apart, both drags
succeed and the DOM diff looks clean, while the two runs were not the same
experiment. That is what the **driving log** exists to recover.

### The driving log

A seventh trace section, recording per action: the target, whether it resolved,
the box it resolved to, and the coordinates or keys actually dispatched. It
carries no exports — it is the receipt for the input side.

- **Compared ahead of the other sections, as its own failure class.** A driving
  divergence is reported first and frames the rest as consequences. Same shape
  the noise-policy ticket gave self-consistency and the Layer 0 values ticket
  gave surface parity: if the inputs differed, the outputs differing tells you
  nothing new. It does not suppress the other sections — capture-everything still
  applies — it changes the order and framing of the report.
- **An unresolved target is recorded, never thrown.** The action is skipped and
  driving continues; downstream actions may also fail to resolve, and the trace
  keeps recording. A missing element is one of the most interesting divergences
  available, and left alone it would surface as a Playwright timeout — which
  reads as a flake.
- **It participates in the self-consistency check.** A side whose resolved boxes
  wobble between its own two captures fails against itself. The sub-pixel
  differences this catches are not noise to be tolerated: they are the
  measured-DOM-dimensions question the `getViewportForBounds` ticket narrowed
  *Measurement and rounding* down to, and no tolerance is applied, per the noise
  policy's rule that normalization may never collapse two distinct values into
  one. Non-reproducible measurement surfaces as "PSFlow disagrees with itself" —
  the cheapest and most legible form it can take — rather than as intermittent
  cross-side diffs.

## The trace after this ticket

Seven sections. **Five carry exports, totalling 156**; two carry none.

| Section | Exports | Added / amended by |
|---|---:|---|
| `dom` | 64 | observation ticket; page-level state added by the test-debt ticket |
| `callbacks` | 47 | observation ticket |
| `hooks` | 27 | observation ticket |
| `api` | 14 | observation ticket |
| `props` | 4 | observation ticket |
| `console` | 0 | test-debt ticket |
| `driving` | 0 | this ticket |

`values` (8) left for surface parity per the gate-topology ticket. The remaining
54 of 210 are the oracle's 26, the 20 type-only entries, and those 8.

**Hand-off hazard worth naming:** the trace's shape is now defined across four
closed tickets. Anyone building the net has to reconstruct it from all of them —
which is why it is written out here in one table, and why the gate-mechanics
issue should carry it forward into the harness's own documentation.

## One driver, bundled twice

Both sides run **the same driver from PSFlow's tree**, differing only in whether
`@xyflow/react` resolves to the vendored upstream or is aliased to `index.js`
(the alias the boundary-module ticket already established).

Forced by two facts. Upstream's vendored `index.tsx` globs only `./**/*.ts`
beneath `xyflow/`, so it structurally cannot see the PSFlow-authored fixtures
below. And upstream's app is vite + react-router where PSFlow's is a static
server + hash router, wrapping the flow in different container markup — not
cosmetic, because the container's box feeds `fitView`, which feeds the viewport
transform, which feeds everything, injecting a divergence into precisely the
measurement question still in the map's fog.

The driver is **harness, not fixture**, and the same reasoning that governs
fixtures governs it: a harness divergence is noise, not a bug the net exists to
catch. Consequence: upstream's vendored `Flow.tsx` and `index.tsx` become
**reference material that never executes**.

## Where fixtures live

PSFlow-authored fixtures go in **PSFlow's own tree** (`parity/system/fixtures/`),
same `flowConfig` default-export shape as upstream's, with the driver globbing
two roots instead of one.

The test-debt ticket found that adding a fixture is free because upstream's
`Flow.tsx` already renders all four chrome components on config keys and
`index.tsx` globs the directory — but that glob lives in vendored code, and the
gate-topology ticket established that system parity runs vendored source as the
baseline. Dropping fixtures there would leave `xyflow/` permanently diffed
against the published package. Keeping it byte-identical means a bump is
`rm -rf` and re-vendor with no merge, which is the property the baseline-bump fog
item depends on.

## What the corpus contains

Four sources.

**1. The conformance seed (~20 scenarios).** The 41 `generic-*` tests' interaction
sequences, transcribed — assertions dropped. Known-drivable, already written
against the fixtures the shared-fixture ticket chose, and the net observes far
more per interaction than the specs assert.

Not one scenario per test. Many of those 41 mount the same fixture and assert
different attributes of a *static* render — "classes get applied", "styles get
applied", "hidden=true hides edge", "aria-label is working", "interactionWidth is
working" all just load the page and check an attribute. One mount-and-settle
against `edges/general.ts` compares the entire DOM and covers all five at once,
plus everything nobody thought to assert. So:

> **One mount-only baseline scenario per fixture, plus one scenario per distinct
> interaction sequence** — and the mount-only baseline is a **general rule for
> every fixture in the corpus**, including the PSFlow-authored ones. It is the
> cheapest scenario there is, needs no action vocabulary at all, and it is what
> the spike actually did to find `EdgeLabelOptions` missing.

**A one-time fork, explicitly not a mirror.** The conformance specs and the
scenarios lifted from them are allowed to drift: the spec's job is to assert
upstream's expectations against PSFlow alone, the scenario's job is to drive both
sides. Drift between them is not a defect. (Consequence for a baseline bump: a
bump that changes upstream's specs leaves the lifted scenarios untouched, so they
can quietly go stale — recorded on the baseline-bump fog item.)

**2. The test-debt scenarios (30).** From the test-debt ticket, renamed below.

**3. The retirement debt (~9).** The 8 hand-authored parity assertions in
`smoke.spec.ts` and `node-props.spec.ts`, whose retirement the gate-topology
ticket made conditional on the net covering them. Not optional — without these
the retirements never happen.

**4. Hole-closing scenarios**, until the termination condition below.

## How coverage is measured

Two counts, in different currencies, **reported separately and never summed** —
the test-debt ticket's central finding.

### Export coverage — derived from real traces

An export counts as driven when it **appears in a trace that actually ran**. The
join is a **witness** per export:

- `callbacks` / `hooks` / `api` / `props` — a **name-mapping table** from runtime
  name to export name. Not always 1:1: `NodeMouseHandler` is the type behind
  `onNodeClick`, `onNodeMouseEnter` and several more, so the table is many-to-one
  in places.
- `dom` (64) — a **witness selector** each (`MiniMap` is driven if the section
  contains `.react-flow__minimap`).

Roughly one hand-written line per export either way — about the same authoring
cost as simply declaring coverage, which makes the choice purely about
trustworthiness. A derived number can be *wrong* (a selector matches something
the scenario didn't really drive); a declared number can be *fiction* and stay
green forever. Something has to have appeared in a captured trace.

Subject to the same staleness discipline as everything else on this map: an
export with no witness, or a witness naming an export that no longer exists,
fails — which is what makes a baseline bump surface new exports instead of
silently under-counting.

### Behavior coverage — hand-declared

Stays exactly where the test-debt ticket put it: `gate-pending` naming a
scenario, failing if the scenario is absent from the corpus. Cannot be derived —
"drag while autopan is ongoing" appears as no token in any trace.

### Where it lives

**A separate artifact generated by the net** (`parity/system/coverage.md`), with
the census carrying only a pointer to it.

Rejected: a new census column. `parity/census/build.mjs` generates from static
`classification.json` and runs standalone; feeding it trace-derived coverage
would make the census unbuildable until someone had run the entire net — a far
heavier prerequisite than the `spago build` the Layer 0 values ticket already
reluctantly added to surface parity.

## Holes, and when the corpus is done

**A hole is recorded; an *undeclared* hole fails.** Same shape as the noise
policy's regions and the Layer 0 values ticket's allowlist: the gap between
reachable and driven is written down with a reason per entry, and an entry that
no longer corresponds to anything fails as stale. A bump that introduces an
export with neither a scenario nor a hole entry goes red.

Failing on holes *themselves* was rejected: the net would be red from day one and
stay red for months, which trains people to ignore it.

> **Termination: the corpus is done when every one of the 156 export-bearing
> entries is either driven or a deliberately declared hole** — no undeclared
> residue.

A condition rather than a target number, and it deliberately admits a small
corpus with many written-down holes as a legitimate resting state. That is what
makes it reachable at all.

## Probed variants

**Selective, not universal.** A probed variant is driven only for scenarios whose
coverage claim needs `hooks` or `props`.

The cost multiplies: ~60 scenarios × 2 sides × 2 captures (the noise policy's
self-consistency) is already ~240 runs; a universal probed variant doubles it to
~480, spending the largest multiplier on the two smallest sections — 31 exports
that do not need 60 scenarios' worth of stimulus to reach.

Which scenarios get probed is itself **derived, not hand-picked**: the hole list
names the uncovered `hooks` and `props` exports, and probed variants are added
until they are covered.

## Touch input

**Paid for, via CDP.** `Input.dispatchTouchEvent` through
`page.context().newCDPSession(page)` — the Playwright config is Chromium-only
with a single project, so this needs no new browser target and no config change,
and under the two-tier vocabulary it lands as one more gesture helper.

The rows justify it: `nowheel` failing means the page zooms when it should not —
a visible user-facing break, and precisely the class with no DOM residue, where
what is observed is that a browser default *did not happen*. If the helper turns
out not to reproduce a real pinch faithfully, falling back to `accepted-ungated`
later costs only the helper.

## Scenario ids

Scenarios are named **semantically**. The test-debt ticket's `S1`–`S30` are about
to become identifiers a gate depends on (`gate-pending` fails if the named
scenario is missing), and sequential numbers age badly in a list that gets
inserted into and trimmed from — delete one and either every reference shifts or
there is a permanent gap.

`tickets/080-test-debt-dispositions.md` keeps the `S`-numbers as a cross-reference
so its concentration-risk analysis still reads.

| Was | Id | Rows |
|---|---|---|
| S1 | `drag-node-release` | #5684 |
| S2 | `drag-node-escape-mid-gesture` | #5803 |
| S3 | `drag-node-autopan` | #5450 |
| S4 | `drag-node-no-select-on-drag` | #5682 |
| S5 | `drag-child-expand-parent` | #5043 |
| S6 | `selection-box-from-node` | #5551 |
| S7 | `selection-box-then-click-node` | #5593, #5727 |
| S8 | `selection-box-mid-gesture` | #5362 |
| S9 | `arrow-key-selected-node` | #4862 |
| S10 | `flow-props-change-after-mount` | #5769, #5733, #5368 |
| S11 | `connect-handle-to-handle` | #5704, #5578, #5042, #5428 |
| S12 | `connect-then-keyboard-move` | #5635 |
| S13 | `connect-second-touch-point` | #5480 |
| S14 | `probe-node-connections` | #4949 |
| S15 | `viewport-helpers-with-options` | #5723, #5722, #5012 |
| S16 | `pan-gesture-complete` | #5547 |
| S17 | `fitview-onnodeschange-variants` | #5132, #5127, #5120 |
| S18 | `uncontrolled-update-node` | #5249 |
| S19 | `keyboard-focus-node` | #4991 |
| S20 | `minimap-all-nodes-hidden` | #5546, #5692 |
| S21 | `minimap-custom-mask-colors` | #5139 |
| S22 | `controls-horizontal` | #5153 |
| S23 | `panel-center-positions` | #5252 |
| S24 | `background-custom-bgcolor` | #5259 |
| S25 | `flow-custom-testid` | #4844 |
| S26 | `custom-edge-baseedge-path` | #4855 |
| S27 | `pinch-over-nowheel-node` | #5512, #5148 |
| S28 | `selection-box-touch` | #5638 |
| S29 | `drag-unmeasured-node` | #5052 |
| S30 | `mount-in-display-none` | #5455 |

The four concentration-risk scenarios the test-debt ticket flagged keep their
warning under the new names: `connect-handle-to-handle` (4 rows),
`flow-props-change-after-mount`, `viewport-helpers-with-options` and
`fitview-onnodeschange-variants` (3 each). `flow-props-change-after-mount` stays
the sharpest — its three StoreUpdater rows are reachable only because callbacks
compare as an exact sequence.
