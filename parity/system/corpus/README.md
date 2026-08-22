# The corpus — every scenario the net drives

A **scenario** is one fixture plus the sequence of actions driven against it,
under a semantic id. The **corpus** is all of them. `harness/` drives one against
one side and produces a **trace**; `compare/` reads a run's four traces; this
directory says *what* gets driven.

Vocabulary is `CONTEXT.md`. Terms in **bold** are defined there.

| | |
|---|---|
| `index.mjs` | the assembly, and the id no two sources may both claim |
| `routes.mjs` | how a registry key becomes a route and a scenario id |
| `mount-baselines.mjs` | source 1 — one mount-only scenario per **fixture**, derived |
| `seed.mjs` | source 2 — the **conformance seed**, upstream's suite transcribed |
| `fork.mjs` | the fork staleness gate, and `fork.json` its register |
| `reserved.mjs` | the thirty ids the test-debt scenarios are already promised |

```sh
npm run parity:fork    # the fork register against the vendored specs
npm run test:harness   # this directory's unit tests, among the harness's own
npm run parity:system  # the gate: build, capture the corpus, persist, diff
```

`tickets/081-interaction-corpus.md` names four sources. Two exist: the derived
baselines and the seed. The test-debt scenarios ([#59]) and the hole-closing
scenarios after them are the other two.

---

## Source 1 — the mount-only baselines

Navigate to a fixture's route, let the page settle, capture. **No action
vocabulary at all**, which makes it the cheapest scenario there is, and it is
the one the dual-run spike ran when it found an entirely unlisted missing
export: a mounted flow is a very large observation, and 64 of the trace's 156
exports land in `dom`, where a mount alone puts them.

**Mount-only is a general rule for every fixture**, ps-flow's own included,
which is why these are *derived from the driver's own registries* rather than
written down. A hand-listed corpus and a globbed registry drift into a fixture
the page serves and the net never mounts — a hole nothing reports, because
neither list knows the other exists. Adding a fixture adds its baseline.

The **example driver** gets one too. It declares its own flow inline rather than
being handed one, so it *is* a fixture; the two ps-flow **contract** components
the page also serves are not, and `parity/driver/registry.mjs` is where that
distinction is recorded, in the same list the build reads.

## Source 2 — the conformance seed

Upstream's own end-to-end suite, transcribed with **every assertion dropped**.
Forty-one `generic-*` tests drive the four vendored fixtures and two more drive
the example driver. What is lifted is the interaction sequences: they are
known-drivable, they are written against fixtures that already exist, and the
net observes far more per interaction than any of those specs assert.

**Not one scenario per test.** Many of the forty-three check one attribute of a
*static* render — "classes get applied", "hidden=true hides edge", "aria-label is
working" — and one mount-and-settle against `edges/general.ts` compares the
entire DOM, covering all of them at once plus everything nobody thought to
assert. The rule is one mount-only baseline per fixture plus **one scenario per
distinct interaction sequence**, which comes to twenty-five.

### Two transpositions every lift makes

**Absolute destinations become offsets.** Upstream drags to `(500, 500)` and
`(2000, 2000)`. Targeting here is selector-relative by design — a `fitView`
divergence would otherwise make one side miss its target entirely, turning a
2e-2 zoom gap into a total-miss cascade — so a move to a window coordinate
becomes a delta of comparable size. The *shape* of the gesture is what survives,
and the shape is what the scenario is for.

**The waits go, not only the assertions.** Several upstream tests interleave
`expect(...)` with the driving, waiting for an element before pressing on it.
That is the harness's job here: `runScenario` settles before the scenario acts,
on the page's own clock, and an element that still does not resolve is recorded
and driven past rather than thrown.

### Ids

Semantic, and they say what the lifted spec was about rather than which fixture
they run against — the route beside each already says that. They also avoid the
thirty names `reserved.mjs` holds. That collision would be easy to make and
invisible afterwards: upstream's "dragging a node" *is* `drag-node-release` in
outline and its "connecting two nodes" *is* `connect-handle-to-handle`, and
`gate-pending` only ever asks whether the name is in the corpus — a seed
scenario holding one would report a changelog row as driven that nothing drove.
[#59] decides, when it gets there, whether a seed scenario already covers a row.

---

## The fork staleness gate

The seed is a **one-time fork, and deliberately not a mirror**. A spec asserts
upstream's expectations against ps-flow alone; the scenario lifted from it
drives both sides and asserts nothing. Drift between them is legitimate, and
re-syncing would be the wrong instinct.

**Silent drift is not legitimate.** A bump that rewrites one of those specs
leaves the lifted scenario untouched, and it goes stale with nothing whatever to
notice: it still drives, both sides still answer, the trace still compares. That
is the first bump cost on the map with no mechanical detector, and it is built
here because the seed is what creates the hazard.

`fork.json` registers **every unit** of the five forked spec files — each `test`,
and each `beforeEach`-style hook — against a hash of its own source and the
scenarios lifted from it.

| Outcome | What it means |
|---|---|
| **affirmed** | the unit's source is the one the entry recorded |
| **moved** | it changed: **re-affirm**, never re-sync |
| **stale** | the entry names a unit the spec no longer holds |
| **unregistered** | the spec holds a unit no entry names — a bump added a test |
| **unlifted** | a seed scenario no entry names, so nothing can detect its drift |

**Hooks are units** because upstream's `goto` lives in one. A bump that moved a
fixture's route would change no test's text at all, and every scenario in that
describe would quietly start mounting a 404.

**A not-lifted entry is the ordinary case**, not an exception: eighteen of the
forty-eight are, most because their fixture's mount-only baseline compares the
whole DOM where the test compares one attribute. It carries a written reason,
exactly as a **region** does and for the same purpose — `scenarios: []` is how
"covered by the baseline" and "nobody got round to it" both look, and telling
those apart is the whole value of the register.

Two entries decline for a different reason worth reading: upstream's two
`autoPan` tests hold the pointer at the viewport edge for 500ms and assert the
viewport moved. The net records no time anywhere and each side settles on its
own clock, so how far it moved would be a function of elapsed frames — the
scenario could not reproduce itself across its own two captures and would fail
self-consistency on both sides rather than measure anything. The behaviour keeps
its reserved scenario `drag-node-autopan`, which needs a way to express a dwell
that the action vocabulary does not have.

### Re-affirming

```sh
node parity/system/fork.mjs --affirm
```

Restamps the entries whose spec **moved** with its new hash and this checkout's
baseline. **It cannot create an entry and it cannot delete one** — the same line
`compare.mjs --record` draws for regions, in the same place: re-recording what a
decision already covers is cheap, and making the decision is a reviewed change
to the file. A test a bump added stays unregistered, and an entry whose test is
gone stays stale, until someone writes down what to do about it.

Affirming does not check that the lifted scenario still drives what it should.
Nothing can; that is the reading the gate exists to *ask for*.

### What the hash is deliberately blind to

The unit's source text, line endings normalized and nothing else — not the
interactions it drives. Extracting *those* would be a second implementation of
the transcription, and one that could only ever be as right as the reading that
produced the scenario. The hash asks a smaller, answerable question: **did this
change at all?** A reformat re-affirms everything, which is a cheap false
positive; a rewritten drag that no hash noticed would be an expensive false
negative.

Per unit rather than per file, so a bump that rewrites one test asks for one
scenario to be re-affirmed instead of the whole spec's worth.

### Where it runs

`net.mjs` runs it before the browser, and a register that is not affirmed fails
the run without capturing. That is the one place in the gate where something
earlier stops something later, and it is a precondition rather than a suppressed
comparison — no capture has happened yet to suppress. Capturing a hundred and
twenty traces against a corpus whose relation to upstream is in question
produces an artifact that has to be thrown away the moment the question is
answered. `--compare-only` skips it, because re-diffing stored traces needs no
vendored checkout at all.

[#59]: https://github.com/jonbae/PSFlow/issues/59
