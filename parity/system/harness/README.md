# The net harness — the capture step

**Capture** drives one **scenario** against one side and returns a **trace**.
Its counterpart, **compare**, reads a **run**'s four stored traces — two sides,
two captures each — and reports what differs; they are separate steps by design,
and `../README.md` says why, along with the trace format both halves agree on.

Vocabulary is `CONTEXT.md`. Terms in **bold** are defined there.

| | |
|---|---|
| `scenario.mjs` | `defineScenario`, `runScenario` — the envelope, the mount, the settle, the trace |
| `vocabulary.mjs` | the two tiers merged into the object a scenario is handed |
| `actions.mjs` | the **closed** primitive tier |
| `gestures.mjs` | the **open-by-addition** gesture tier |
| `driving.mjs` | the **driving log** |
| `dom.mjs` | the `dom` section — the second module that runs *in* the page |
| `settle.mjs` | polling until consecutive snapshots agree, on the page's own clock |
| `call-log.mjs` | the `callbacks` section — the in-page log the driver accumulates into |
| `serialize.mjs` | what a callback was handed, as trace content — the third one that runs in the page |
| `port.mjs` | the only file that knows what a browser is |
| `fake-port.mjs` | its double, which everything above is tested against |
| `pending.mjs` | the sections capture does not fill yet, declared |
| `live.spec.mjs` | the harness against a real page |

```sh
npm run test:harness       # the harness's own unit tests — no browser
npm run test:harness:live  # the browser self-test (needs dist/psflow.js)
```

`parity:system` — the gate that captures and then compares — is not here; it is
`../net.mjs`, the one place the two halves meet.

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
  page before it navigates. The **pointer** is the same finding one layer out —
  it belongs to the browser rather than the document, so it survives that
  blanking too — and it stayed invisible until the call log could see the
  boundary events it caused. `runScenario` parks it as well; see below.

**The mount is a driving action.** Navigating to the route is something done
*to* the page, and recording it that way means a side that never renders a flow
reads as an unresolved first action followed by a scenario whose every action is
also unresolved — a finding — rather than as a thrown timeout. The box it
resolves to is the container measurement `fitView` is computed from, so it lands
in the section that carries no tolerance.

## The in-page call log

Callbacks are the one class of behaviour with **no other witness**. A handler
that never fires leaves the DOM identical, every other section agreeing, and an
end-state net passing green — which is why the boundary staging crossed them
first, and why the comparison that reads this section is the strictest one the
net has.

`call-log.mjs` is the capture half. It runs **in the page**, bundled into the
driver rather than handed to `page.evaluate` as source, and it does two things:
wraps a handler so that calling it records the call, and holds what it recorded
until the harness reads it back through `port.callbacks()`.

**The arguments are serialized at the moment of the call.** Not at the end, and
this is not an optimisation. xyflow hands a handler objects it goes on to
*mutate* — a node's `position` during a drag, a connection state as the pointer
moves — and synthetic events whose fields are gone by the time the page settles.
A log holding references would answer with the end state of every argument it was
ever handed, which is what the other six sections already say.

**The log is read as a section of the end-state snapshot**, after the settle that
produces `dom`. That is what keeps one snapshot per scenario — the alternative
was checkpointing mid-interaction — while still catching a handler that never
fired.

### Every callback prop is installed — when the net asks

A fixture sets three or four handlers; upstream's `ReactFlowProps` declares 49.
The 45 nobody sets are the interesting ones: a handler no page passes fires on
*neither* side, so the two traces agree about it forever. So the driver installs
every one of them (`parity/driver/src/callbacks.ts`), each wrapping whatever the
fixture itself set.

**But only when the URL asks** — `?observe=callbacks`, which `driverUrl` adds and
nothing else does. Installing a callback prop is not free: three of upstream's
are *presence*-sensitive rather than return-value sensitive, and `onReconnect` is
the loud one — passing it at all renders a reconnect anchor per edge endpoint,
twenty-two elements the edges fixture never asked for. That is symmetric across
the net's two sides and harmless to it, but the **conformance test suite** drives
this same page, and what it is for is upstream's *asserted intent* against
upstream's own unmodified fixture. A spec failing because the driver had quietly
added props would be blamed on ps-flow.

Forgetting to ask is not left to discipline. The driver reports what it wrapped
on every mount, `[]` included, and the three states are three different findings:
`null` is a route with no fixture driver on it, a list is a page that can report
calls, and `[]` is a fixture driver that wrapped nothing — the URL lost the
parameter — which **fails the capture**. `live.spec.mjs` measures both halves:
that an unasked page wraps nothing, and that asking puts the anchors on the
page.

Which props those are is **derived from the vendored `ReactFlowProps`** with the
TypeScript compiler, at driver build time (`parity/driver/callbacks.mjs`). This
is the driver's one derived list, and the exception to "a driver mistake shows up
identically on both sides": a handler missing from it is the one mistake the
dual-run design cannot see through. A prop is a callback exactly when its type is
callable, which no name pattern can decide — `onError`, `isValidConnection` and
`shouldResize` share none.

Two things the derivation cannot decide are written down beside it, and both
**fail stale** the way every register here does:

- **`onInit` is not installed.** Its argument is the imperative
  `ReactFlowInstance`, which ps-flow refuses at mount until stage 3
  ([#56](https://github.com/jonbae/PSFlow/issues/56)) — installing it would fail
  every scenario on one side rather than observing anything. It is a **hole** in
  this section, with the reason written where the coverage artifact
  ([#57](https://github.com/jonbae/PSFlow/issues/57)) can read it.
- **What an installed-but-unset handler answers.** For most props *absent* and
  *present returning undefined* are the same instruction to the library. For
  `onBeforeDelete` and `isValidConnection` they are not — the library reads the
  return value, and `undefined` is falsy — so those two answer `true`, which is
  what upstream does with the prop absent. Observing a deletion must not stop it
  happening.

### An absent log fails the capture

Not "records an empty section". A page that published no log is a driver bundle
built before the log existed, and the empty section it would produce compares
clean against the other side's equally empty one — the silent pass the whole net
exists to remove. Same for a call the serializer refused: the section is compared
as an exact sequence, so a call missing from it is not a shorter sequence but an
unreadable one, and the `SerializationError` is raised by the harness reading the
log rather than thrown inside a library's own event dispatch, where it would
change what the page does.

### The parked pointer

The cursor belongs to the browser, not to the document, so it survives the
navigation that starts each capture. That was invisible until callbacks were
observed: capture 2 of a drag mounted its flow *under* a pointer capture 1 had
left inside the flow, and the browser fired the boundary events from there —
`onPaneMouseEnter` ahead of the mount, carrying coordinates a hundred pixels
along, where capture 1 recorded it when the drag first moved.

So `runScenario` parks the pointer off-viewport on the blank document, between
the two navigations. No page sees the move, and it is not a driving action for
the same reason blanking the page is not one: nothing was done to the flow. With
it, upstream reproduces a whole drag — call log included — across four captures;
without it, one in three disagreed with itself.

## The argument serializer

`serialize.mjs` turns a live JavaScript value into the JSON the `callbacks`
section carries. It runs **in the page** rather than driving one from outside,
which is why it imports nothing beyond what the log beside it hands over: both
are bundled into the driver.

The rule is the noise policy's: **serialize every enumerable own property,
blacklist only reference-typed fields.** The second half's *only* is the sharper
one — a whitelist of interesting fields is a hand-authored reading of what
xyflow passes, and a field nobody thought to ask for is a field that can differ
forever. What gets dropped is a value that *is* an identity: a DOM node, a
function, a React fiber, where the two sides could not agree even in principle
since each rendered its own. Their kind survives; only the identity goes.

A React **element** is not one of those and is not blacklisted. It is plain data
— `type`, `key`, `props` — and node `data` routinely carries one, so dropping it
would put every element in a flow under a single marker. The fiber behind it
(`_owner`) still goes.

That rule is what catches **a synthetic event where a native one is expected**. A
React synthetic event carries its fields as enumerable own properties; a native
event carries them on its prototype, so it has none at all. No shape check and no
DOM diff can see the difference — both are `object`, and neither leaves a mark on
the page. The class name is recorded for the case one step further on: without
it, a `MouseEvent` where a `PointerEvent` belongs would serialize to `{}` on both
sides and compare clean.

Everything JSON cannot carry gets a marker rather than a flattening —
`undefined` against `null`, `NaN`, `-0`, a cycle, a getter that threw. Each is a
difference the file would otherwise stop carrying, and `diff.mjs` compares with
`Object.is`.

A graph deeper than the ceiling is the one case that **throws** instead. A marker
there would put two different subgraphs under one value and make them compare
equal — a collapse, which the noise policy forbids outright and which nothing
downstream could see, since `assertNoCollapse` only ever sees what capture
already wrote. The ceiling is there to keep a pathological graph off the stack,
not to decide anything, so reaching it is a question for a person.

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
| `dom` | 64 | yes — the element tree and the page state, both settled first |
| `callbacks` | 47 | yes — every call the driver's installed handlers saw, serialized as it was made |
| `hooks` | 27 | no — needs probes, [#59](https://github.com/jonbae/PSFlow/issues/59) |
| `api` | 14 | `calls` only, and empty until the bridge exists; `queries` is #59 |
| `props` | 4 | no — needs probes, #59 |
| `console` | 0 | yes, plus uncaught errors |
| `driving` | 0 | yes |

The three gaps are declared in `pending.mjs` with the issue that lands each.

The register behaves like every other register here: **an entry that stops
corresponding to reality fails.** `dom`'s entry was deleted when its capture
landed, and had it been left behind the next capture would have gone red naming
the entry rather than shipping a trace whose declared-empty section was now full.

That declaration is not a substitute for the sections. Two traces whose sections
are empty on both sides compare clean and mean nothing, which is why the gate
waited for `dom`: it carries 64 of the 156 and is nearly the whole of what a
mount-only scenario observes. `callbacks` is the one section where that trap has
a second door — a page can publish no log at all, and every capture would then
record an empty section rather than a missing one — which is why an absent log
**fails the capture** instead of being recorded as a gap.

## Settling

**Settled** is defined by observation, never by a duration: `settle.mjs` polls
the `dom` section until consecutive snapshots agree, and there is no wall-clock
constant in the file. A fixed wait is a bet that one implementation is not
slower than the other, and losing it silently is the worst outcome available —
the slow side gets captured mid-mount and every section diverges at once, which
reads as a library that renders nothing like the other rather than as a harness
that did not wait. **Each side settles on its own clock**; nothing here compares
the two, and that a slow side and a fast side reach the same end state is
precisely the claim the net makes.

Between polls the harness asks the port to `tick`: two animation frames and then
a turn of the task queue. Two, because that is the order the work lands in — a
frame runs its animation callbacks, lays out, and *then* runs the resize
observers xyflow measures nodes with, so the second frame is the first that can
see what the first caused.

`runScenario` settles **twice**, and both are load-bearing. Before the scenario
acts, because selectors resolve against each side's own render and an action
driven at a flow still mounting aims at a layout about to move — and the box it
resolves lands in the section that carries no tolerance. And before the capture,
where the snapshot two polls agreed on *is* the `dom` section, never a fresh read
afterwards. Settled is not **gesture complete**: a scenario whose last action
leaves the pointer down settles mid-gesture, which is the only way transient
state is observable.

A page that never settles **throws** at the poll ceiling. Capturing anyway would
record a snapshot known to be mid-flight, and every alternative to throwing is a
fixed timeout wearing a different hat.

`live.spec.mjs` is where that stops being a design and becomes a measurement: a
real mount settles, and one side reproduces its whole `dom` section across two
captures of the same scenario.
