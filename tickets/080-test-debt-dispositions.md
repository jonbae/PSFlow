# 080 — Dispositions for the 57 test-debt rows

Resolution asset for [Fate of the 57 test-debt rows under the
net](https://github.com/jonbae/PSFlow/issues/21). Supersedes the open questions
in [076](076-test-debt-drag-selection-store.md),
[077](077-test-debt-connection-handle-keyboard.md),
[078](078-test-debt-viewport-fitview-rendering.md) and
[079](079-test-debt-component-chrome.md); those four keep their per-row research
notes, this file holds the fates.

Vocabulary is in `CONTEXT.md`. Bucket keys named here are **specified, not
applied** — [Gate mechanics](https://github.com/jonbae/PSFlow/issues/32) edits
`parity/changelog-audit/audit.mjs` and `verdicts.json`.

## The five rules

1. **Coverage by the net requires *driven*, not merely *reachable*.** A row is
   covered when its behavior lands in a snapshot section **and** a named
   scenario performs the actions that produce it. Reachability alone is the
   assumption this ticket exists to prevent.
2. **The cheapest gate that can see a class of root cause owns it.** Pure
   functions go to function parity or a unit test even where the net could
   reach them, per the rule set in [How the dual-run net relates to the existing
   gates](https://github.com/jonbae/PSFlow/issues/20).
3. **Structural blindness is recorded, not worked around.** Behavior the net
   cannot observe in principle — render counts, animation paths — is bucketed
   `accepted-ungated` with a written reason, not chased with bespoke assertions.
4. **A planned gate is a gap, never a covered bucket.** `gate-pending` names the
   target gate and the scenario; it fails the audit if either is missing, and
   later if the named scenario is absent from the corpus.
5. **Scenarios are shared where the condition is shared.** Grouping is the
   saving; the cost is concentration, so every scenario lists the rows riding
   on it.

## Summary

| Fate | Rows |
|---|---:|
| `gate-pending` → system (the net) | 42 |
| `gate-pending` → function parity | 3 |
| `gate-pending` → unit | 5 |
| `accepted-ungated` | 3 |
| `not-ported` | 1 |
| `n/a` | 1 |
| `ported-ungated`, re-homed to another ticket | 2 |
| **Total** | **57** |

The 42 net-bound rows collapse onto **30 scenarios**. Combined with not having
to author expected values — the comparison is against real xyflow — this is the
answer to the ticket's question: 57 hand-written tests become 30 scripted
scenarios with no expectations in them.

## Scenarios (42 rows → 30 entries)

Handed to [The interaction corpus](https://github.com/jonbae/PSFlow/issues/26).
"Stage" is the boundary-module stage from
[Boundary module](https://github.com/jonbae/PSFlow/issues/28) that must land
before the scenario can be driven through `index.js`.

> **The `S`-numbers below are superseded as identifiers.** The corpus names
> scenarios semantically, because `gate-pending` cites a scenario by name and
> sequential numbers shift when the corpus is trimmed.
> [081](081-interaction-corpus.md) holds the canonical ids and the `S`-number
> cross-reference; the numbers survive here only so the concentration-risk
> analysis below still reads.

| # | Scenario | Rows | Section | Stage |
|---|---|---|---|---|
| S1 | Drag a node mid-canvas and release | #5684 | callbacks | 2 |
| S2 | Drag a node, abort mid-gesture (Escape), **end with pointer down** | #5803 | dom, callbacks | 2 |
| S3 | Drag a node to the pane edge until autopan starts | #5450 | callbacks | 2 |
| S4 | Drag with `selectNodesOnDrag: false` | #5682 | callbacks | 2 |
| S5 | Drag a child node inside a parent with `expandParent` | #5043 | dom | 1 |
| S6 | Start a selection box with the pointer down over a node | #5551 | dom | 1 |
| S7 | Draw a selection box, then click a single node | #5593, #5727 | dom | 1 |
| S8 | Selection box in progress — **ends mid-gesture** | #5362 | dom | 1 |
| S9 | Arrow-key a selected node | #4862 | dom, page scroll | 1 |
| S10 | Change flow props after mount | #5769, #5733, #5368 | callbacks | 2 |
| S11 | Drag from handle to handle to connect | #5704, #5578, #5042, #5428 | callbacks | 2 |
| S12 | Start a connection, then move the node by keyboard | #5635 | dom, callbacks | 2 |
| S13 | Second touch point during an active connection | #5480 | callbacks | 2 |
| S14 | Node probe reporting `useNodeConnections` | #4949 | hooks | 3 |
| S15 | Viewport helpers called with options | #5723, #5722, #5012 | api | 3 |
| S16 | Pan gesture, start to finish | #5547 | callbacks | 2 |
| S17 | `fitView` with `onNodesChange` undefined / returning early / uncontrolled | #5132, #5127, #5120 | dom, callbacks | 2 |
| S18 | Uncontrolled flow mutated via `updateNode` | #5249 | api, callbacks | 3 |
| S19 | Focus a node by keyboard | #4991 | dom | 1 |
| S20 | MiniMap mounted with every node hidden | #5546, #5692 | dom | 4 → 1 |
| S21 | MiniMap with custom mask and node colors | #5139 | dom | 4 → 1 |
| S22 | Controls in horizontal orientation | #5153 | dom | 4 → 1 |
| S23 | Panel positioned top-center and bottom-center | #5252 | dom | 4 → 1 |
| S24 | Background with a custom `bgColor` | #5259 | dom | 4 → 1 |
| S25 | ReactFlow given a custom `data-testid` | #4844 | dom | 1 |
| S26 | Custom edge rendering `BaseEdge` with path attributes | #4855 | dom | 4 → 1 |
| S27 | Pinch gesture over a node marked `nowheel` | #5512, #5148 | page zoom | 1 |
| S28 | Selection box driven by touch input | #5638 | dom | 1 |
| S29 | Drag a node that was never measured | #5052 | console | 1 |
| S30 | Mount inside a wrapper with `display: none` | #5455 | console | 1 |

### Concentration risk

Four scenarios carry three or four rows each and are the ones to review if the
corpus is ever trimmed: **S11** (4), **S10**, **S15** and **S17** (3 each). S10
is the sharpest — it carries the three StoreUpdater rows that
[076](076-test-debt-drag-selection-store.md) identifies as its highest-risk,
where PSFlow deliberately diverges structurally (one `useEffect` per tracked
prop against upstream's single effect). Those rows are reachable **only**
because callbacks compare as an exact sequence — order, count and interleaving —
per [Noise policy](https://github.com/jonbae/PSFlow/issues/19). A weaker
callback projection would make all three invisible.

### Stimulus risks

- **S27** needs a native pinch gesture, outside the pointer-and-imperative-call
  vocabulary. Chrome DevTools Protocol can synthesize one; if that proves too
  expensive, #5512 and #5148 fall back to `accepted-ungated`.
- **S13** needs multi-touch, same class of risk.
- **S28** is covered indirectly: both sides load the same upstream stylesheet,
  so equality of the class attribute implies equality of the computed
  `touch-action`. The snapshot records attributes, not computed styles.

### Two amendments to the snapshot

Both belong to [What does the dual-run net observe, and
when?](https://github.com/jonbae/PSFlow/issues/18), amended here:

- **A seventh `console` section.** #5052 and #5455 change what is *printed*, not
  what is rendered — no DOM, no callback, no hook value. Playwright's console
  capture makes these observable for near-nothing. Upstream's warnings are part
  of what a developer experiences, so dropping them silently is a divergence.
  Expect this section to lean on the noise policy's region mechanism more than
  the others.
- **Enumerated page-level state in the `dom` section**: container `scrollTop` /
  `scrollLeft` and `visualViewport.scale`, and nothing further without a
  decision. Needed by S9 and S27, where what changed is that a *browser default
  does not happen* — there is no element or attribute recording it. Enumerated
  rather than defined by a rule, so the section's boundary stays sharp.

## Rows not going to the net

### Function parity — 3 rows

Pure functions over inputs; the oracle sees them at lower cost and higher
resolution than a browser run. All three are also entry-list candidates for the
under-population found by
[the gate topology ticket](https://github.com/jonbae/PSFlow/issues/20) (26
census exports against 18 entries).

| PR | Change | Lives in |
|---|---|---|
| #5266 | Connection snapping for handles larger than `connectionRadius` | `src/System/XYHandle/Utils.purs` |
| #5550 | Prevent child nodes of different parents overlapping | `src/System/XYDrag/Utils.purs` |
| #4929 | Selection accounts for selectability of connected edges | `src/System/Utils/Store.purs` |

### Unit — 5 rows, 2 tests

| PR | Change | Test |
|---|---|---|
| #5090, #5118, #5263, #4880 | Which DOM nodes count as input-like | **One** predicate test over `isInputDOMNode` in `src/System/Utils/Dom.purs`, covering the node kinds all four PRs touched |
| #5515 | Id parsing of static handles | Parsing test against `src/React/Handle.purs` |

Existing coverage of the predicate is indirect only — `test/Test/Main.purs:195`
asserts `elementSelectionKeys`.

### `accepted-ungated` — 3 rows

| PR | Change |
|---|---|
| #5629 | Prevent unnecessary re-render in `FlowRenderer` |
| #5497 | Skip eager node render when dimensions and handles are predefined |
| #4875 | Prevent unnecessary edge rerenders when resizing |

**Reason:** all three are upstream *performance* changes, correctness-neutral by
intent. The net is deliberately blind to performance — each side settles on its
own clock, so PSFlow re-rendering more still passes. Gating render counts means
asserting an implementation detail of React that upstream does not test itself.

### `not-ported` — 1 row

**#5276 — `ease` / `interpolate` on all viewport-altering functions.** Filed as
`ported-ungated`, i.e. ported and correct. It is not. The `interpolate` option
*is* threaded (`src/System/XYPanZoom.purs:247-251` selects linear against
smooth), but completion is not: `setViewportImpl` calls `resolve` immediately
(line 253), with the comment at line 234-236 stating outright that "d3-zoom's
interpolate APIs aren't exercised in the test harness." Upstream's `setViewport`
returns a Promise that settles when the transition **finishes**; PSFlow's `Aff`
settles when it **starts**, so `await fitView()` means different things on the
two sides.

Bucketed by its worst fact, since the audit is keyed one entry per upstream PR
and cannot hold a split verdict. Recorded on [Parity divergences found by the
dual-run spike](https://github.com/jonbae/PSFlow/issues/22). Note the net could
not have caught this: it compares end states, and both sides arrive at the same
viewport regardless of the path taken to get there.

**This makes the true test-debt count 56, not 57.**

### `n/a` — 1 row

**#4846 — `expandParent` with immer / immutable helpers.** An upstream refactor
of how mutation is expressed. PSFlow's data structures are already immutable, so
the change has no analogue to port or to test.

### Re-homed — 2 rows

Stay `ported-ungated` with a ticket reference; the work belongs elsewhere.

| PR | Change | Owner |
|---|---|---|
| #5472 | Remove `dangerouslySetInnerHTML` from `domAttributes` | [074](074-node-edge-domattributes-ariarole.md) — PSFlow cannot spread `domAttributes` at all, so the vulnerability being removed does not exist here. Re-bucket when 074 lands. |
| #4826 | Forward ref of the div inside Panel | [ReactFlow does not accept a ref](https://github.com/jonbae/PSFlow/issues/27) — one `forwardRef` deferral, already documented at `NodeWrapper.purs:28` and `EdgeWrapper.purs:25`. |

## Corrections to the four source tickets

- **[079](079-test-debt-component-chrome.md) suggests #5139 and #5259 may be
  `n/a`** on the grounds that they are stylesheet behavior and PSFlow ships no
  CSS. They are not. `MiniMap.purs:133-141` and `Background.purs:86-89` both
  *emit inline CSS custom properties* — `--xy-minimap-mask-background-color-props`,
  `--xy-background-color-props` — into the style attribute. That is
  PSFlow-authored DOM, squarely in the `dom` section. Only #5638 is genuinely
  stylesheet-only, and it is reachable through class-name equality.
- **[078](078-test-debt-viewport-fitview-rendering.md) calls #5276 "the row most
  worth attention."** Correct, but not as test debt — see `not-ported` above.
- **The fixture set is not a constraint.** Both the shared-fixture decision's
  "unmodified upstream fixtures" and the assumption that chrome components are
  unreachable turn out to be non-binding: `Flow.tsx:32-35` already renders
  `Controls`, `Panel`, `MiniMap` and `Background` conditionally on config keys,
  and `index.tsx:5` globs `./**/*.ts`. Adding a scenario is adding one file that
  both sides import, which carries no translation risk — the risk that decision
  guarded against was two copies drifting apart.
