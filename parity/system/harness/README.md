# The net harness — the capture step

**Capture** drives one **scenario** against one side and returns a **trace**.
Its counterpart, **compare**, reads a **run**'s four stored traces — two sides,
two captures each — and reports what differs; they are separate steps by design,
and `../README.md` says why, along with the trace format both halves agree on.

Vocabulary is `CONTEXT.md`. Terms in **bold** are defined there.

| | |
|---|---|
| `scenario.mjs` | `defineScenario`, `runScenario` — the envelope, the mount, the trace |
| `vocabulary.mjs` | the two tiers merged into the object a scenario is handed |
| `actions.mjs` | the **closed** primitive tier |
| `gestures.mjs` | the **open-by-addition** gesture tier |
| `driving.mjs` | the **driving log** |
| `serialize.mjs` | what a callback was handed, as trace content — the one module that runs *in* the page |
| `port.mjs` | the only file that knows what a browser is |
| `fake-port.mjs` | its double, which everything above is tested against |
| `pending.mjs` | the sections capture does not fill yet, declared |
| `live.spec.mjs` | the harness against a real page |

```sh
npm run test:harness       # the harness's own unit tests — no browser
npm run test:harness:live  # the browser self-test (needs dist/psflow.js)
```

`parity:system` — the gate that captures and then compares — is not here. It
arrives with `dom` capture ([#51](https://github.com/jonbae/PSFlow/issues/51)),
for the reason the last section of this file gives.

---

## One driver, bundled twice

Both sides load **the same page**, `parity/driver/index.html`, and differ in one
thing: the `?side=` parameter deciding whether `@xyflow/react` resolved to
ps-flow's `index.js` or to the vendored upstream source. A **driver** difference
can therefore never be mistaken for a library difference.

That parameter is the *only* place a side appears. It is not in the trace's
sections, only in its envelope, which is not compared — a side name inside a
compared section would differ on every scenario at once for a reason that has
nothing to do with either library.

Upstream cannot supply the page. Its own `index.tsx` globs only beneath the
vendored tree, so it cannot see a PSFlow-authored fixture; and its app is vite
plus a path router where this is a static server plus a hash router, wrapping
the flow in different container markup. That last one is not cosmetic — the
container's box feeds `fitView`, which feeds the viewport transform, which feeds
everything — which is why *both* runs load this page rather than one of them
loading upstream's app. Upstream's vendored `Flow.tsx` and `index.tsx` are
reference material that never executes.

## What a scenario is

```js
defineScenario({
  id: "drag-node-release",              // semantic, never a sequence number
  route: "/tests/generic/nodes/general", // the driver's hash path
  touch: false,                          // declared; see below
  async run(actions) {
    await actions.dragNode('.react-flow__node[data-id="Node-1"]', { dx: 100, dy: 40 });
  },
});
```

**The scenario is handed the action vocabulary and nothing else, and nothing
comes back.** Not "should not look" — there is nothing to look at: thirteen
frozen functions closing over a port the scenario cannot reach, every one of
them resolving to `undefined`. No page, no URL, no bundle name, no library
handle.

Discarding the return value is the part that is easy to get wrong. The tiers
beneath the vocabulary do return the driving entry they recorded — `gestures.mjs`
needs the last dispatched point to walk a drag without drifting — but an entry
carries **the box that side resolved**, and geometry is exactly what differs
between the two: the spike's whole finding was a zoom gap. A scenario handed one
could branch on the side as surely as if it had been told its name. `call` is
the same case one step further on, and its answer goes into the trace rather
than back to the caller.

A scenario that branched on which implementation it was driving would silently
invalidate every comparison the net ever makes, so the aperture is closed rather
than discouraged.

Ids are semantic because a gate cites them by name: `gate-pending` fails if the
scenario it names is missing, and sequential numbers age badly in a list that
gets inserted into and trimmed from.

## The two tiers

**Primitives — closed.** `pointerDown`, `pointerMove`, `pointerUp`, `key`,
`wheel`, `touch`, `call`. Extending this set is a decision.

**Gestures — open by addition.** `dragNode`, `selectionBox`, `connect`, `pan`,
`pinch`, `arrowKeyNudge`, each a pure composition of primitives. Adding one is a
reviewable act, not a scenario detail.

Scenarios reach for the gesture tier by default and drop to primitives only when
the scenario is *about* an unusual input sequence — a gesture interrupted
mid-flight, most often, which by construction no gesture can express.

Closing the bottom tier is what makes a scenario's actions statically readable,
which is what coverage derivation depends on
([#57](https://github.com/jonbae/PSFlow/issues/57)). Rejected: a declarative
action DSL (needs an interpreter plus an escape hatch, and buys nothing the two
tiers don't) and free-form Playwright code (leaves the vocabulary open).

### Targeting, and the two flavours of offset

Actions name their target by **selector**, and each side resolves it against its
own render. Absolute coordinates were rejected: a `fitView` or layout divergence
would make one side miss the node entirely, turning the spike's 2.2e-2 zoom gap
into a total-miss cascade on every scenario at once.

An offset is from the box's **centre** by default and from its `topLeft` on
request — the second is what a sequence lifted from upstream's own specs is
written in.

A `null` target means *relative to where the pointer already is*, which is what a
mid-drag move needs: the thing being dragged follows the pointer, so a
target-relative move would chase what it is dragging. `touch` has no such form —
its points always name a target and are **resolved afresh on every call**, which
is right for the pinch it exists for and a trap for a touch drag.

## The driving log

Selector-relative targeting costs one thing: **the pointer follows a
divergence**. If the two sides place a node five pixels apart, both drags
succeed and the DOM diff looks clean, while the two runs were not the same
experiment. The driving log is what recovers that — a seventh section carrying
no exports, recording per action the target, whether it resolved, the box it
resolved to, and what was dispatched.

Three rules, all load-bearing:

- **Compared ahead of the other sections, as its own failure class.** If the
  inputs differed, the outputs differing tells you nothing new. It does not
  suppress the other sections — capture-everything still applies — it changes
  the order and framing of the report: `REPORT_ORDER` in `../compare/index.mjs`
  leads with it, and the sections after it are labelled *consequence of the
  driving divergence* rather than dropped.
- **An unresolved target is recorded and skipped, never thrown.** Driving
  continues, and downstream actions may fail to resolve too. A missing element
  is one of the most interesting divergences available; left alone it would
  surface as a Playwright timeout, which reads as a flake.
- **It participates in self-consistency with no tolerance applied**
  (`../compare/consistency.mjs`). A side whose resolved boxes wobble between its
  own two captures fails against *itself*. Those sub-pixel differences are not
  noise to be tolerated: they are the measured-DOM-dimensions question asked in
  the cheapest and most legible form it has. What capture owes that check is
  that a box is recorded **exactly as measured** — nothing here rounds a
  coordinate, and a gesture's steps are drift-corrected against their own
  dispatched points so that a step count cannot show up as a fractional
  coordinate — that `capture` is an envelope field, so one side's two runs are
  distinguishable, and that **each capture starts on a document of its own**.
  The last of those is the check's first finding: a capture reuses the page, so
  a second capture navigates to the URL the page is already on, which is a
  same-document navigation. Nothing reloaded, and capture 2 opened on the flow
  capture 1 had already dragged a hundred pixels along. `runScenario` blanks the
  page before it navigates.

**The mount is a driving action.** Navigating to the route is something done
*to* the page, and recording it that way means a side that never renders a flow
reads as an unresolved first action followed by a scenario whose every action is
also unresolved — a finding — rather than as a thrown timeout. The box it
resolves to is the container measurement `fitView` is computed from, so it lands
in the section that carries no tolerance.

## The argument serializer

`serialize.mjs` turns a live JavaScript value into the JSON the `callbacks`
section carries. It is the one module here that runs **in the page** rather than
driving one from outside, which is why it imports nothing: the in-page call log
([#54](https://github.com/jonbae/PSFlow/issues/54)) bundles it into the driver.

The rule is the noise policy's: **serialize every enumerable own property,
blacklist only reference-typed fields.** The second half's *only* is the sharper
one — a whitelist of interesting fields is a hand-authored reading of what
xyflow passes, and a field nobody thought to ask for is a field that can differ
forever. What gets dropped is a value that *is* an identity: a DOM node, a
function, a React fiber, where the two sides could not agree even in principle
since each rendered its own. Their kind survives; only the identity goes.

That rule is what catches **a synthetic event where a native one is expected**. A
React synthetic event carries its fields as enumerable own properties; a native
event carries them on its prototype, so it has none at all. No shape check and no
DOM diff can see the difference — both are `object`, and neither leaves a mark on
the page. The class name is recorded for the case one step further on: without
it, a `MouseEvent` where a `PointerEvent` belongs would serialize to `{}` on both
sides and compare clean.

Everything JSON cannot carry gets a marker rather than a flattening —
`undefined` against `null`, `NaN`, `-0`, a cycle, a graph deeper than the limit,
a getter that threw. Each is a difference the file would otherwise stop carrying,
and `diff.mjs` compares with `Object.is`.

## Touch, and why it is declared

`Input.dispatchTouchEvent` through `page.context().newCDPSession(page)`. The
Playwright config is Chromium-only with a single project, so this needs no new
browser target and no config change, and under the two-tier vocabulary it lands
as one more primitive.

It has one precondition, measured rather than assumed: **emulation must be on
before the document loads.** Turned on afterwards, `ontouchstart in window`
stays false and every dispatched touch is accepted and ignored — the same touch
drag that walks a node 80 pixels with emulation enabled before `goto` moves it
nothing when enabled after.

So `touch: true` is a scenario's declared capability. Enabling it everywhere
would be symmetric across the two sides and therefore sound, but it would
quietly narrow the whole net to a touch-capable browser — every scenario taking
xyflow's touch code paths because two scenarios needed them. A scenario that
reaches for `touch` without declaring it **fails**, because the alternative is a
driving log full of perfectly-shaped actions that did nothing, on both sides,
comparing clean.

## Tested at two seams

Everything above the port is plain composition, and is tested against
`fake-port.mjs` with no browser: canned boxes in, a list of what was dispatched
out. What a gesture *is* — a named sequence of primitives — is exactly what the
driving log makes legible, so the assertions are the decompositions themselves.

That leaves one claim a double cannot make: that the port's dispatch paths reach
a real renderer. `live.spec.mjs` makes it — a selector resolving to a box, a
gesture moving what it grabbed, a key reaching a focused element, CDP touch
driving upstream's node — and asserts nothing about ps-flow against upstream.
`port.test.mjs` holds the double and the real port to the same method set, so a
double that drifts is caught by a node test rather than by a browser run failing
strangely.

## What capture fills, and what it does not

The trace is seven sections. **Five carry exports, totalling 156**; two carry
none. The shape is `../README.md`'s, written out across four closed issues
before either half existed — this is the same table with a column for how much
of it capture reaches today.

| Section | Exports | Captured here |
|---|---:|---|
| `dom` | 64 | `page` only — the element tree is [#51](https://github.com/jonbae/PSFlow/issues/51) |
| `callbacks` | 47 | no — the serializer is here, the in-page log is [#54](https://github.com/jonbae/PSFlow/issues/54) |
| `hooks` | 27 | no — needs probes, [#59](https://github.com/jonbae/PSFlow/issues/59) |
| `api` | 14 | `calls` only, and empty until the bridge exists; `queries` is #59 |
| `props` | 4 | no — needs probes, #59 |
| `console` | 0 | yes, plus uncaught errors |
| `driving` | 0 | yes — this ticket |

The five gaps are declared in `pending.mjs` with the issue that lands each.

The register behaves like every other register here: **an entry that stops
corresponding to reality fails.** Land `dom` capture and leave its entry behind,
and the next capture goes red naming the entry rather than shipping a trace
whose declared-empty section is now full.

That declaration is not a substitute for the sections. Two traces whose `dom` is
`null` on both sides compare clean and mean nothing, which is why `parity:system`
is not a gate until those entries are gone — the gate command lands with `dom`
capture, not here.

Also elsewhere: **settling** (polling until consecutive snapshots agree, each
side on its own clock) and **self-consistency** are #51 and #43. This harness
waits for the flow to mount and no longer.
