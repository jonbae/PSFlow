# System parity — the trace format and the comparison core

**System parity** is the dual-run net: it mounts upstream `@xyflow/react` and
PSFlow side by side, drives both through one identical scripted corpus, and
diffs the results. Neither side is a hand-written expectation, which is what
makes it prove xyflow rather than a reading of it.

The net has two halves, and they are deliberately separate steps:

| Step | What it does | Where it is |
|---|---|---|
| **capture** | drives a scenario against one side and returns a trace | `harness/` — five of the seven sections still to come, see below |
| **compare** | reads a run's four stored traces and reports what differs | `compare/`, and `compare.mjs` |

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
  "traceFormat": 1,                            // bumped when the shape changes
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

There is no timestamp anywhere in a trace. The net is deliberately blind to
performance (each side settles on its own clock), and a recorded time would
break self-consistency on every run.

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
| `api` | 14 | imperative queries called during capture, and mutator returns |
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
  // Arguments serialize every enumerable own property, blacklisting only
  // reference-typed fields (#19 §6) — issue #44 builds that serializer.
  "callbacks": [ { "name": "onNodesChange", "args": [ [ { "id": "1", "type": "dimensions" } ] ] } ],

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

**1. Each side against itself** (`compare/consistency.mjs`). A side disagreeing
with itself is its own failure class, and it is read first because it invalidates
everything after it: a cross-side difference between two sides that are not
reproducible cannot be attributed to either implementation.

**2. The driving log across the sides.** The same argument one level down —
inputs that differed make output differences uninterpretable.

**3. Everything else**, claimed by regions as usual.

**Nothing earlier suppresses anything later.** Capture-everything is the rule the
whole net is built on, and a run whose first two steps failed still reports the
third in full — the real divergence may well be down there, and a report that
stopped at the first bad news would hide it. What the earlier steps buy is
*framing*: the report says which findings are readings and which are
**consequences** of a run that was not one experiment.

### Self-consistency

Same machinery as the cross-side comparison — normalize, then diff — with two
deliberate differences.

- **No regions.** A region is a claim about the two implementations disagreeing.
  There is no such thing as a claim that a side disagrees with itself, and
  inventing one would turn the only check that can see non-reproducibility into
  one more register of forgiven differences.
- **The driving log carries no tolerance.** It is diffed straight off the two
  traces and **never handed to the normalizer at all**, so no rule that could be
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

Everything else compares positionally, which is what `callbacks` needs — there,
position *is* the identity.

### Normalization — may delete or reorder, may never collapse

The test is **content-blindness**: a rule may consult a field's name and its
position, never its value.

- **`delete`** removes a named field from both sides regardless of value. A
  deleted field counts as **unobserved** in coverage, not as passing, and the
  report says so. The list is near-empty: the spike went looking for
  React-internal churn and found none.
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
node parity/system/compare.mjs <trace.json × 4> [--out report.md] [--record]
node parity/system/compare.mjs <left.json> <right.json> [--out report.md] [--record]
npm run test:compare       # the comparison core's own unit tests — no browser
npm run test:harness       # the capture half's, likewise
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
region gone stale — `2` a run that could not be interpreted at all: a malformed
trace, an illegal normalization rule, a region missing its reason, traces that
are not two captures of each of two sides. A run that cannot be interpreted is
never a pass.

`parity:system` — the gate that captures and then compares — does not exist yet.
It waits on `dom` capture ([#51](https://github.com/jonbae/PSFlow/issues/51)):
two traces whose `dom` is `null` on both sides compare clean and mean nothing,
so wiring the two halves together before then would build a gate that cannot go
red.

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

## Not built here

- **Settling** — polling until consecutive snapshots agree, each side on its own
  clock — and the `dom` element tree, which is what makes the two halves a gate:
  [#51](https://github.com/jonbae/PSFlow/issues/51).
- **Callback sequence comparison** and argument serialization —
  [#44](https://github.com/jonbae/PSFlow/issues/44).
- **The `hooks`, `props` and `api.queries` sections**, which need probes —
  [#59](https://github.com/jonbae/PSFlow/issues/59).
- **The corpus itself** — the conformance seed, the test-debt scenarios and the
  fork staleness gate — [#55](https://github.com/jonbae/PSFlow/issues/55).
- **Witnesses, holes and the coverage artifact** —
  [#57](https://github.com/jonbae/PSFlow/issues/57).
