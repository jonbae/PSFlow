# System parity — the trace format and the comparison core

**System parity** is the dual-run net: it mounts upstream `@xyflow/react` and
PSFlow side by side, drives both through one identical scripted corpus, and
diffs the results. Neither side is a hand-written expectation, which is what
makes it prove xyflow rather than a reading of it.

The net has two halves, and they are deliberately separate steps:

| Step | What it does | Where it is |
|---|---|---|
| **capture** | drives a scenario against one side and returns a complete seven-section trace | `harness/` |
| **compare** | reads a run's four stored traces and reports what differs | `compare/`, and `compare.mjs` |
| **the corpus** | what gets driven: the scenarios, and where each one came from | `corpus/` |
| **coverage** | which exports the traces prove were driven, and which are deliberately declared holes | `coverage/`, and `coverage.mjs` |
| **the gate** | the only place they meet: build, capture the corpus, persist, diff, cover | `net.mjs` and `net/` |

Capture records **everything** observable; everything the noise policy forgives
lives in compare. That keeps a capture whitelist from smuggling hand-authored
assertions into the recording — deciding in advance which of xyflow's behaviours
are allowed to be a bug is the failure this whole effort exists to avoid. It also
means revising the noise policy re-runs the comparison in seconds against every
trace ever captured, and that a bumped baseline re-diffs stored traces into a
behavioural changelog.

Vocabulary is `CONTEXT.md`. Terms in **bold** below are defined there.

---

## The trace format

A **trace** is everything one run of one side recorded, as JSON. One trace per
side per **scenario** per capture. The shape was decided across four closed
issues ([#18](https://github.com/jonbae/PSFlow/issues/18) observation,
[#19](https://github.com/jonbae/PSFlow/issues/19) noise policy,
[#21](https://github.com/jonbae/PSFlow/issues/21) test debt,
[#26](https://github.com/jonbae/PSFlow/issues/26) corpus) and is written out
here so nobody has to reconstruct it from them. It is enforced by
`trace-format.mjs`, which hard-fails on anything it does not recognise.

### Envelope

```jsonc
{
  "traceFormat": 2,                            // bumped when the shape changes
  "scenario": "mount-baseline--nodes-general", // semantic id, never a number
  "side": "upstream" | "psflow",
  "capture": 1,                                // each side is captured twice (#19 §8)
  "baseline": "12.11.0",                       // the vendored upstream version
  "sections": { … }                            // all seven, always
}
```

The envelope is not compared — it identifies the run. Comparing two traces of
different scenarios is a hard error rather than a difference: two scenarios are
not two runs of one experiment.

The net records no time of its own, anywhere in a trace. It is deliberately
blind to performance — each side settles on its own clock — and a recorded time
would break self-consistency on every run. One time value does *arrive*: a DOM
event's own `timeStamp`, on every serialized event argument in `callbacks`. It
breaks self-consistency exactly as predicted, which is why normalization deletes
it (see the delete rule below); nothing writes one.

### The seven sections

Five carry exports, totalling 156; two carry none. A section is **always
present** — an absent section would otherwise compare as "nothing differed
there", which is the print-instead-of-fail mistake this repo has already paid
for twice.

| Section | Exports | Contents |
|---|---:|---|
| `dom` | 64 | the full subtree under `.react-flow`, plus enumerated page-level state |
| `callbacks` | 47 | every handler firing, in order, with serialized arguments |
| `hooks` | 27 | what each **probe** saw its hooks return |
| `api` | 14 | queries snapshotted after settling, and imperative mutator returns |
| `props` | 4 | the props object each node/edge probe was handed |
| `console` | 0 | what the page printed |
| `driving` | 0 | the **driving log**: what was done *to* the page |

```jsonc
{
  // ── dom ──────────────────────────────────────────────────────────────────
  // A nested element tree, recorded positionally and *compared* by key.
  // `page` is enumerated page-level state: two upstream behaviours turn on a
  // browser default (scroll, pinch-zoom) *not* happening, and that is only
  // observable here.
  "dom": {
    "page": { "scrollX": 0, "scrollY": 0, "visualViewportScale": 1 },
    "root": {
      "tag": "div",
      "attrs": { "class": "react-flow", "data-id": "…" },  // every attribute, values always strings
      "text": "Node 1",                                    // this element's own text, optional
      "children": [ /* elements */ ]
    }
  },

  // ── callbacks ────────────────────────────────────────────────────────────
  // An exact sequence: order, count and interleaving all compare (#19 §5).
  // Accumulated in the page as the calls happen — `harness/call-log.mjs`, which
  // the driver bundles — because a handler leaves no residue to read afterwards.
  // Arguments serialize every enumerable own property, blacklisting only
  // reference-typed fields (#19 §6) — `harness/serialize.mjs`.
  "callbacks": [
    { "name": "onNodesChange", "args": [ [ { "id": "1", "type": "dimensions" } ] ] },
    { "name": "useOnViewportChange", "args": [ { "x": 0, "y": 0, "zoom": 1 } ], "probe": true }
  ],

  // ── hooks ────────────────────────────────────────────────────────────────
  // Keyed by probe id, then by hook name.
  "hooks": { "flow-probe": { "useViewport": { "x": 0, "y": 0, "zoom": 1 } } },

  // ── api ──────────────────────────────────────────────────────────────────
  // Queries are trace content; mutators are driving actions whose return
  // value is recorded. `toObject()` is the richest single observation the net
  // has — the library's own serialisation of the whole flow.
  "api": {
    "queries": { "toObject": { "nodes": [], "edges": [], "viewport": {} } },
    "calls": [ { "method": "zoomIn", "args": [], "result": null } ]
  },

  // ── props ────────────────────────────────────────────────────────────────
  "props": { "node-probe#1": { "id": "1", "type": "probe", "selected": false } },

  // ── console ──────────────────────────────────────────────────────────────
  // What the page printed, plus what it threw: an uncaught exception is not a
  // console message to Playwright, and would otherwise be in no section at all.
  "console": [ { "level": "warn", "text": "…" }, { "level": "pageerror", "text": "…" } ],

  // ── driving ──────────────────────────────────────────────────────────────
  // The receipt for the input side. Targets resolve against each side's own
  // render, so the pointer *follows* a divergence; this is what recovers it.
  // An unresolved target is recorded and skipped, never thrown.
  // All five fields are required — `target`, `box` and `dispatched` nullable,
  // since an imperative call has no target and an unresolved one has no box.
  // The `mount` is an action like any other: navigating to the route is done
  // *to* the page, and its box is the container measurement fitView uses.
  "driving": [
    { "index": 0, "action": "mount", "target": ".react-flow", "resolved": true,
      "box": { "x": 0, "y": 0, "width": 800, "height": 600 },
      "dispatched": { "route": "/tests/generic/nodes/general" } },
    { "index": 1, "action": "pointerDown", "target": ".react-flow__node[data-id='1']",
      "resolved": true, "box": { "x": 75, "y": 25, "width": 150, "height": 36 },
      "dispatched": { "x": 150, "y": 43, "button": "left" } }
  ]
}
```

`dispatched` is shaped by the action: `{ x, y }` for a move, `{ x, y, button }`
for a press or release, `{ key, action }` for a key, `{ x, y, deltaX, deltaY }`
for a wheel, `{ type, points }` for a touch — whose points carry their own
resolution, because one box could not stand for several — and `{ method, args }`
for an imperative call.

---

## How comparison works

A **run** is one scenario, two sides, **two captures each** — four traces, read in
one order, and the order is an interpretation order rather than a pipeline
(`compare/run.mjs`).

Every trace still carries all seven sections. Comparison first selects the
experiment declared by the scenario variant: a plain scenario reads all seven;
`flow-node` reads the exact tagged hook-callback receipts plus `hooks`, `api`,
`props`, and `console`; `edge` and `connection-line` read `props` and `console`.
Ordinary flow callbacks remain captured but belong to the plain experiment, so
replacement-graph effects do not contaminate the hook callback question. Each
hook-option callback gets its own mechanically selected source scenario and
probe run, so its exact count and order are preserved without interleaving
independent subscriptions. This is not a noise tolerance: a probe replaces a node or edge
and is therefore a different rendering by design. Its DOM and
pointer-resolution receipt are persisted for audit, while the probe variant
answers only the hook/API/props question it was generated to answer.

**1. Each side against itself** (`compare/consistency.mjs`). A side disagreeing
with itself is its own failure class, and it is read first because it invalidates
everything after it: a cross-side difference between two sides that are not
reproducible cannot be attributed to either implementation.

**2. The driving log across the sides, in plain scenarios.** The same argument
one level down — inputs that differed make output differences uninterpretable.

**3. Everything else**, claimed by regions as usual.

**Nothing earlier suppresses anything later within the selected experiment.**
Capture-everything is the rule the whole net is built on, and all seven sections
remain persisted even when a probe variant compares only its declared level. A
run whose first two steps failed still reports the selected third step in full —
the real divergence may well be down there, and a report that stopped at the
first bad news would hide it. What the earlier steps buy is *framing*: the report
says which findings are readings and which are **consequences** of a run that was
not one experiment.

### Self-consistency

Same machinery as the cross-side comparison — normalize, then diff — with two
deliberate differences.

- **No regions.** A region is a claim about the two implementations disagreeing.
  There is no such thing as a claim that a side disagrees with itself, and
  inventing one would turn the only check that can see non-reproducibility into
  one more register of forgiven differences.
- **In a plain scenario, the driving log carries no tolerance.** It is diffed
  straight off the two traces and **never handed to the normalizer at all**, so no rule that could be
  written — not one aimed at it, not a `**` one that would reach it on the way
  past — can forgive a difference there. A side whose resolved boxes wobble
  between its own two captures fails against itself, down to the last sub-pixel.
  That is the measured-DOM-dimensions question asked in the cheapest available
  form, of each implementation separately rather than of the pair — and it is the
  only place it *can* be asked without tolerance, because across two sides a box
  differing by 1e-5 is a finding somebody has to judge, while within one side
  there is nothing to judge.

Every **other** section normalizes exactly as it does across the sides. Class
token order is as much noise within one side as between two, and a check that
refused the whole ruleset would be red for reasons the noise policy has already
settled.

The cross-side comparison then reads **capture 1 of each side**, which is only
meaningful because the check above read both.

### The comparison itself

`compare/index.mjs` runs five steps, and the order is the design.

**1. Validate the envelopes.** Both traces must be the same scenario.

**2. Normalize both sides** with one content-blind ruleset
(`normalization.json`).

**3. Check nothing collapsed.** A value that differed before normalization and
agrees after it fails the run, unless the two were reorderings of one another.

**4. Diff section by section**, keyed rather than positional.

**5. Claim what is left** with hand-written regions (`regions.json`). Anything
unclaimed fails.

Step 4 has one section that compares differently, and it is the one that needs
to: `callbacks`.

### The driving log is read first

`driving` leads the report, and when it differs the report says so **before** the
tables: the two sides were not driven the same way, so every other difference is
a reading of two different experiments. Sections after it are labelled
*consequence of the driving divergence*, and none of them is dropped — a real
divergence is exactly what would be hiding underneath.

A region *can* claim a driving difference, which is a decision about pass and
fail. It still cannot make the sections after it readable, so the framing turns
on the difference existing rather than on it going unclaimed.

### Keyed, never positional

DOM children are paired by their own identity — `data-id` where the element
carries one, `id` otherwise, and `tag[n]` among like-tagged siblings that carry
neither. The spike hit the reason: one node-ordering difference shifted ~30
lines by itself, drowning the real differences underneath.

Ordering stays observable. Pairing by key is not ignoring order: a keyed pairing
that finds the same keys in a different sequence reports exactly one `order`
difference at the parent, carrying both sequences.

Everything else compares positionally, which is what a call's *arguments* need —
there, position is the identity.

### Callbacks — an exact sequence

Callbacks are compared more strictly than anything else in the trace, and the
reason is structural rather than a matter of taste: **they leave no residue in
end state.** If PSFlow never fires a handler the DOM is identical, every other
section agrees, and an end-state net passes green. The call log is the only place
the absence is visible.

That log is the capture half's — `harness/call-log.mjs`, bundled into the driver
and accumulated **in the page** as the calls happen, then read as one section of
the same end-state snapshot. Three things about it decide what this comparison
can say, and all three are `harness/README.md`'s: the arguments are serialized at
the moment of the call, because xyflow mutates what it hands a handler; the
driver installs **every** callback prop upstream declares, because a handler no
fixture set fires on neither side and would compare clean for ever; and it does
so only when the URL asks, because installing one changes what the page renders
and the other browser gates drive the same page.

So order, count and interleaving are all compared (`compare/callbacks.mjs`), and
it stays legible by **pairing** calls before asking the three questions
separately. Calls of different names never pair, so the question is only asked
within one name; there, occurrence is the identity — the second `onNodesChange`
against the second — except where the two sides made the same calls in a
different sequence, which pairs by argument instead so that a reorder surfaces as
a reorder rather than as two invented argument differences.

- **count** — a call with no partner is `left-only` or `right-only` at its own
  index. A missing call and a duplicated one are one question asked from the two
  sides.
- **order** — the paired calls' sequences are compared as sequences. The same
  calls in a different order is exactly one `order` difference carrying both.
- **arguments** — each pair is diffed under the call's index.

Pairing is not keying in the sense the section above means it: nothing about
order is forgiven, it is asserted one line down. Paths stay positional —
`callbacks/3/args/0/dimensions/width` addresses the trace itself. Without the
pairing, dropping the third call of five reports one missing entry plus every
later call as an *argument* difference, and those read as findings about what the
two libraries pass.

A name where a reorder and an argument change happened at once pairs by
occurrence and reports the arguments. Nothing is hidden; the reorder is simply
not separable from the change without guessing which call became which.

Arguments arrive already serialized, by the rule that keeps every enumerable own
property and blacklists only reference-typed fields (`harness/serialize.mjs`).
That is what catches a synthetic event where a native one is expected, which no
shape check and no DOM diff can see.

**Weakening** relaxes one axis for one callback, in `weakenings.json`:

| Field | |
|---|---|
| `callback` | the handler name |
| `axis` | `count` or `order` — regions' word is `kind`, and this is not regions' taxonomy |
| `reason` | required |
| `ticket` | where a bug stays someone's problem |

There is no `arguments` axis, deliberately. An argument that differs has a path,
so a **region** claims it — recording the values, and making someone re-affirm
them when they move. A weakening records nothing, so an `arguments` axis would
leave a whole handler's payload unobserved for as long as the entry survived.

The two axes are not quite independent, and the seam is worth knowing. A call
only one side made has no position on the other, so it cannot take part in an
order comparison at all — which means a `count` weakening also drops that call's
*unpaired* occurrences from the interleaving check. The calls that do pair still
compare their order exactly, and there is no stricter reading available:
comparing the position of a call one side never made is not a question with an
answer.

A weakening that forgives nothing **fails as stale**, and it is judged on what it
alone forgives, so two overlapping entries cannot each ride on the other's back.
`--record` does not touch this file: there are no values to write back. And no
weakening reaches self-consistency — a side is held to reproducing its own call
log exactly, whatever the two sides are allowed to differ on between them.

Three audit rows in the `flow-props-change-after-mount` scenario are reachable
**only** because this comparison is exact. If an entry ever appears in
`weakenings.json`, check those first.

### Normalization — may delete or reorder, may never collapse

The test is **content-blindness**: a rule may consult a field's name and its
position, never its value.

- **`delete`** removes a named field from both sides regardless of value. A
  deleted field counts as **unobserved** in coverage, not as passing, and the
  report says so. The list is one rule long: the spike went looking for
  React-internal churn and found none, and what did eventually earn an entry is
  a **clock** — a DOM event's `timeStamp`, which reaches the trace on every
  serialized event argument and differs between a side's own two captures.
  Neither implementation computes it; the browser stamps it. Deleting is the
  only mechanism that can reach it, since self-consistency is the one comparison
  no region and no weakening may claim.
- **`sort`** reorders `tokens` (whitespace-separated, e.g. `class`) or
  `declarations` (`;`-separated, e.g. `style`). Tokenizing means separator
  whitespace stops being content — `class="a  b"` and `class="a b"` compare
  equal, and that is the one thing sorting costs. Nothing inside a token is
  touched. A `style` whose property list repeats a name is left **unsorted**,
  because there the later declaration wins and order is semantic.

There is no third rule kind, and an unknown kind is a hard error. That is
deliberate: a tolerance rule cannot distinguish "upstream rounded its output"
from "PSFlow computed a different number" — both look like digits differing. The
spike's `75` against `75.00017302302994` is exactly that case, and it is not
float formatting: upstream's x really is 75 and PSFlow's layout math really
accumulated 1.7e-4 of error. A `±0.001` rule would not answer that question, it
would delete it, for every coordinate, permanently, in a config nobody re-reads.

`assertNoCollapse` is the backstop that keeps this true of the *implementation*
rather than only of the config: on every run, any value pair that differed before
normalization and agrees after it must be a reordering **under the rule that
touched it**, judged with that rule's own tokenizer — so two values that merely
happen to be anagrams, `translate(75px, 25px)` and `translate(25px, 75px)`, do
not pass for one another, and a value no rule touched can never legally agree.

### Regions — everything normalization does not claim

A region is a pattern carrying a written reason, and a ticket where the
difference is a known bug.

| Field | |
|---|---|
| `id` | unique, cited by reports |
| `kind` | `intentional` (permanent) or `known-divergence` (needs `ticket`) |
| `reason` | required — an unexplained region is a dumping ground |
| `ticket` | required for `known-divergence` |
| `path` | path pattern; `*` is one segment, `**` is any number |
| `scenario` | scenario the region applies to, `*` for all |
| `affirmedAgainst` | the baseline version it was last affirmed against |
| `recorded` | the differences it claimed when last recorded |

A difference is claimed by the **first** region whose pattern matches it, so no
two regions can share one justification.

Three outcomes per region, and two of them fail:

- **rides free** — it claimed what it recorded.
- **stale** — it claimed nothing. Someone fixed the divergence and left the
  entry behind, or the scenario stopped exercising it. Entries bite when they
  stop corresponding to reality rather than accumulating silently.
- **moved** — it claimed different values than it recorded. Re-affirm it: look
  at the new values and decide they are still the same cause. On a baseline bump
  the set of moved regions **is** the behavioural changelog, and its size is the
  bump's measured cost.

**Re-recording is cheap; re-recording cannot create a region.** `--record`
refreshes the values of regions that moved and stamps them with this run's
baseline. It never adds one — an unclaimed difference is still unclaimed after
recording, and still fails. Claiming a new *class* of difference is a reviewed
change to `regions.json`.

---

## Commands

```sh
npm run parity:system                      # the gate: build both bundles, capture, persist, diff
node parity/system/net.mjs --compare-only  # re-diff the stored traces — seconds, no browser
node parity/system/net.mjs --scenario mount-baseline--nodes-general

npm run parity:fork                        # the fork register against the vendored specs
node parity/system/fork.mjs --affirm       # restamp the entries whose forked spec moved

npm run parity:coverage                    # the coverage artifact, from the stored traces — no browser

node parity/system/compare.mjs <trace.json × 4> [--out report.md] [--record]
node parity/system/compare.mjs <left.json> <right.json> [--out report.md] [--record]
npm run test:compare       # the comparison core's own unit tests — no browser
npm run test:coverage      # the witness language, the join and the artifact, likewise
npm run test:harness       # the capture half's, the corpus's and the gate's, likewise
npm run test:harness:live  # the harness against a real page
```

The four traces go in **any order** — they are grouped by the side each one
records, so a run assembled wrong fails as a run assembled wrong rather than
comparing a side against the wrong thing and reporting it as a finding.

The two-trace form compares exactly those two: the narrower question, and what a
baseline bump asks when it re-diffs stored traces of one side against another
baseline. Its report says that self-consistency went **unchecked**, because a
form that quietly skipped a check is how a gate ends up proving less than its
name.

Exit codes: `0` clean, `1` differences the noise policy does not claim — a side
that disagrees with itself, a driving divergence, an unclaimed difference, a
region or a callback weakening gone stale — `2` a run that could not be
interpreted at all: a malformed trace, an illegal normalization rule, a region
missing its reason, traces that are not two captures of each of two sides. A run
that cannot be interpreted is never a pass.

## The gate

`parity:system` is the only place the two halves meet (`net.mjs`). One run, in
order:

1. **Both bundles are rebuilt**, every time. A stale bundle is the one failure
   this gate cannot see from the inside — it would measure the code it was built
   from and report green about the code in the tree. `parity/driver/build.mjs`
   reads its own output back and fails if the library in it is not the one the
   side names, which is what stops the two runs from being two runs of one
   library.
2. **The fork register is checked** (`corpus/fork.mjs`), before the browser.
   The **conformance seed** is a one-time fork of upstream's own suite, and a
   bump that rewrites one of those specs — or reorders a fixture the seed reads
   an assumption out of — leaves the lifted scenario driving perfectly while it
   no longer corresponds to anything upstream tests. A
   register that is not affirmed fails the run without capturing — the one place
   in this gate where something earlier stops something later, and a
   precondition rather than a suppressed comparison, since no capture has
   happened yet to suppress.
3. **The corpus is assembled** (`corpus/`): one **mount-only baseline** per
   **fixture**, derived from the driver's own registries rather than written
   down, so a fixture cannot join the driver page without joining the net; plus
   the conformance seed's twenty-five interaction scenarios.
4. **Each scenario is captured four times** — two sides, two **captures** each,
   a fresh browser context per side, the two captures of one side sharing a page
   the way `runScenario` expects.
5. **Every trace is written to `traces/`** and **read back off disk** before it
   is diffed, on the run that just wrote it. The stored traces are the artifact
   the whole compare half is built around; a gate that diffed its in-memory
   copies would let the two drift.
6. **Each run is compared** by `compare/run.mjs`, and the report is
   `report.md` — a verdict per scenario, then every run's report in full.
7. **Coverage is derived** from the traces just read back (`coverage/`), and the
   artifact is `coverage.md`. It is reported beside the comparison and never
   instead of it, and it fails the run on residue — an export nothing drove and
   nothing declared — never on a hole itself.

Exit codes are the compare step's: `0` clean, `1` a scenario failed or coverage
found residue, `2` a run that could not be interpreted.

`--compare-only` skips steps 1–5 and re-diffs what is on disk. That is what a
revised noise policy asks, and it is the reason the traces are committed: a
bumped baseline re-diffs the *previous* baseline's stored traces into a
behavioural changelog, which is impossible if they only existed on the machine
that captured them.

### It is red, and that is the plan

The first run found nine classes of divergence across five fixtures — among them
an `aria-describedby` ps-flow never emits, edge path coordinates carrying 2e-5
of accumulated error, and node DOM order sorted rather than in insertion order.

The `callbacks` section (#54) added its own on the run that landed it, from a
**mount alone**: upstream fires `onMoveStart` and `onMove` where ps-flow fires
neither, ps-flow fires a second `onSelectionChange` / `onViewportChange` /
`onMoveEnd` where upstream fires one, its `NodeChange` objects carry six fields
holding `undefined` that upstream's do not, and it reports an `onError("002")`
upstream never raises. None of it leaves a mark on the page, which is the whole
reason the section exists.

**The list lives on the divergence backlog**
([#22](https://github.com/jonbae/PSFlow/issues/22)), not here, and deliberately:
a second copy in the repository would be a register with no gate behind it,
rotting quietly as each one is fixed. What the repository holds is the evidence
— `report.md` and the traces under `traces/`, both regenerated by every run.

They are **recorded and not fixed**: the fixing phase could not be specified
before the divergence set existed.

What red must never be answered with is a looser comparison. A difference is
fixed in the port, or claimed by a **region** in `regions.json` with a written
reason and a ticket — and a region that stops claiming anything fails as stale,
so the register cannot quietly become a list of things nobody looks at.

The **driving log** agrees everywhere, which is what makes these readings rather
than **consequences**. Both sides also reproduced themselves on every scenario
until the call log landed; **ps-flow no longer does**. It fires the same calls in
different interleavings between its own two captures of one scenario — where
upstream reproduces its order exactly, drag included — and that is its own
failure class, the one no **region** and no **weakening** may claim. It is on the
divergence backlog with the rest, and until it is fixed the cross-side callback
differences beneath it are read with that in mind.

## Coverage — witnesses, holes and termination

`coverage/`, and `coverage.md` beside this file. **Two counts, in different
currencies, reported separately and never summed.** Export coverage counts
exports; behavior coverage counts conditional behaviors *within* an export.
A total would let an export driven once absorb every untested condition inside
it, which is exactly what the test-debt ticket found.

**Export coverage is derived, never declared.** Each of the 156 export-bearing
census entries carries a **witness** — the rule joining a captured trace back to
the export it proves was driven — and an export counts as driven only if some
trace that actually ran holds it. That costs about what declaring would, roughly
one hand-written line per export either way, so the choice is purely about
trustworthiness: a derived number can be *wrong*, where a declared one can be
*fiction* and stay green forever.

Two kinds, decided by the section the census puts the export in, never by the
register entry:

| Section | Witness | Example |
|---|---|---|
| `dom` (64) | a **selector** | `MiniMap` — `.react-flow__minimap` |
| `callbacks` / `hooks` / `api` / `props` (92) | a **name mapping** | `NodeMouseHandler` — `onNodeClick`, `onNodeMouseEnter`, and four more |

The mapping is many-to-one in both directions. One handler type sits behind
several props, and — because twelve of the `callbacks` exports are members of the
`NodeChange` / `EdgeChange` unions and every one of them rides on `onNodesChange`
or `onEdgesChange` — a **name** can be a change's own discriminant rather than a
handler's name: `onNodesChange:position`. Witnessing `NodeAddChange` by the
handler alone would count it driven the moment a mount fired one dimension
change.

The selector language is a closed, tiny subset of CSS: compounds separated by
whitespace, where a compound is `*` or a tag with any number of `.class`,
`[attr]`, `[attr=value]`, `[attr~=value]` and `[attr*=value]`. Whitespace is the
descendant combinator and it is the only one — it exists for one recurring shape.
`GraphView` draws `.react-flow__viewport-portal` and
`.react-flow__edgelabel-renderer` whether or not anything is portaled into them,
so a selector on either container would witness the export for every fixture that
mounts a flow at all; `.react-flow__viewport-portal *` asks the question the
export is about.

A witness is evaluated against the **normalized** trace, so a field the noise
policy deletes counts as **unobserved** in coverage rather than as passing — a
sentence `normalization.json` already carried, made true by construction rather
than by luck.

### Four outcomes, and two of them fail

| Outcome | Means |
|---|---|
| **driven** | some captured trace held the witness |
| **hole** | nothing did, and `coverage/holes.json` says why |
| **undeclared** | nothing did, and nothing says why — the failure the whole mechanism exists for |
| **unwitnessed** | no rule joins the export to a trace at all, so nothing could report it either way |

A **hole is a legitimate resting state.** Failing on holes themselves was
rejected: the net would be red from day one and stay red for months, which trains
people to ignore it. What fails is the residue.

A hole does not stand in for a witness, and the two registers are different
claims: one says "the corpus does not drive this", the other says "here is what
driving it would look like". A bump that adds an export needs both, which is why
an export with a hole and no witness still fails.

Both registers go **stale** in the sense every register here uses. A witness
naming an export the census no longer carries claims something that is not there;
a hole over an export something did drive carries a reason that stopped being
true — the entry biting the run once its cause is fixed, rather than rotting
silently.

### Termination

> The corpus is done when every one of the 156 export-bearing entries is **either
> driven or a deliberately declared hole**.

A condition rather than a target number, and it deliberately admits a small
corpus with many written-down holes as a legitimate resting state — which is what
makes it reachable at all. It is what green means here, so the number to watch is
the hole count: that is the debt, written down. `coverage.md` states the
condition and evaluates it on every run.

Today: **124 of 156 driven, 32 declared holes, no residue.** Selective probe
variants drove every issue-59 hook and props witness plus the read-only API
snapshot; the remaining debt is components no fixture mounts and imperative
interactions no scenario drives ([#60]). The first of those was two problems
wearing one label until boundary stage 4 ([#62]) separated them: those
components could not be mounted from JavaScript *and* nothing mounted them.
Stage 4 fixed the first, deliberately and on its own — so every one of those
holes is still open, and closing one is now a fixture rather than a converter.

### The hole list is machine-readable

`coverage/holes.json` is read by other work, not only by people. Boundary stage 4
([#62]) took the components no fixture mounts from it and crossed them —
selection by register rather than by hand, which is why `EdgeToolbar` and the
four non-default built-in edges are in that stage's set at all and why the two
resizer components, already crossed, were left alone. Issue 59 used the same
query to generate `corpus/probe-plan.json` from its hook, API and props holes.
The artifact preserves those retired hole inputs; every build joins them through
the current census and witness register to derive the runtime names. That keeps
the variants after the live holes go stale without turning the result into a
hand-maintained list. The smallest mechanically valid source scenarios are
cloned, so probe cost stays explicit rather than multiplying the whole corpus.

### Behavior coverage stays hand-declared

It cannot be derived: "drag while autopan is ongoing" appears as no token in any
trace, and no selector matches a condition. A `gate-pending` row in the changelog
audit names the gate that will prove the behavior and the scenario that will
drive it, and what is checkable here is the join — **the name means nothing until
the corpus holds that scenario**, which is the rule ticket 080 wrote down and
[#58] implemented. Fifty rows declare one today.

The name space the join runs against is wider than the corpus, and that is the
part worth reading twice. `corpus/reserved.mjs` holds thirty ids for the
test-debt scenarios ([#60]), gated so no other source may take one, and a row
against a reserved id **resolves**: the corpus has committed to the name, and the
guarantee that no seed scenario can quietly satisfy it is what makes the
commitment worth anything. So `coverage.md` counts and prints the two apart —
forty-two rows are waiting on someone to write the scenario at all, and none is
merely waiting on a run. A row naming an id in neither is the failure, and it is
the only mechanical difference between a plan and a name somebody typed wrong.

### Where it lives, and why not in the census

A separate artifact, with the census carrying a pointer and nothing else. A
census column was rejected: `parity/census/build.mjs` generates from static
classification and runs standalone, and feeding it trace-derived coverage would
make the census unbuildable until someone had run the entire net — a far heavier
prerequisite than the `spago build` surface parity already reluctantly took on.
The join runs the other way: coverage reads the census's `Mechanism` column to
decide which 156 of the 210 exports the net can observe at all, so a bump that
adds an export fails the census first and coverage second.

It runs as the net's last step and standalone. Standalone is not a convenience —
the traces are committed, so editing a witness or writing down a hole and
regenerating the artifact costs milliseconds and no browser, where re-capturing
the corpus costs a hundred and twenty drives of a real page.

That is also why it is the one `parity:*` script that survives a clean clone. It
prefers the corpus and falls back to the scenarios the stored traces name,
because the traces committed for `--compare-only` are runs that happened and that
is exactly what coverage is a claim about. The fallback is never silent: only the
corpus can say a stored trace belongs to no scenario any more, so a run that had
to do without it says so in the console and in the artifact.

[#58]: https://github.com/jonbae/PSFlow/issues/58
[#59]: https://github.com/jonbae/PSFlow/issues/59
[#60]: https://github.com/jonbae/PSFlow/issues/60
[#62]: https://github.com/jonbae/PSFlow/issues/62

## Tested at this seam

Trace files on disk are the highest seam at which the net's own logic can be
tested, and the whole comparison core is plain functions over stored traces. The
unit tests run against hand-written fixture traces in `compare/fixtures/` with
no browser, no boundary module and no driver. They are the one place in this
effort where hand-authored expectations are correct: the subject under test is
the comparison logic, not xyflow.

The capture half has the same shape one level down: everything above the page
port is plain composition, tested against a double, and the browser sees only
the claim a double cannot make. `harness/README.md`.

The gate itself splits the same way. What it decides — how a run's four traces
are named and read back, what makes a stored trace an orphan, what a whole-corpus
report says — is `net/traces.mjs` and `net/summary.mjs`, tested with no browser;
what is left in `net.mjs` is the doing.

Coverage is the same shape again, one seam further out: the witness language, the
join and the artifact are plain functions over traces (`coverage/`, and
`npm run test:coverage`), and `coverage.mjs` is the file reading. Its tests are
about the *instrument* — that an undeclared hole fails, that a stale hole fails —
never about the registers, which are content and go red on their own.

## Not built here

- **The rest of the corpus** — the hole-closing scenarios, until the termination
  condition `coverage/` evaluates on every run. What is here is the mount-only
  baselines, the conformance seed, the thirty test-debt scenarios
  ([#60](https://github.com/jonbae/PSFlow/issues/60)), the retirement debt
  ([#61](https://github.com/jonbae/PSFlow/issues/61)) and the probe variants
  derived from issue 59's retired holes; `corpus/` has its own README.
