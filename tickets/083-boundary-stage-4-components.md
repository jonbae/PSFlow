# 083 — Boundary stage 4: the components no fixture mounts

Issue [#62](https://github.com/jonbae/PSFlow/issues/62). This file is the
ticket's first acceptance criterion discharged — "the hole list is read and
these criteria are rewritten against it" — and the record of what happened
against the rewritten ones.

## What the issue asked for, and why it could not be started as written

> **Acceptance criteria below are provisional.** This stage is **governed by
> the corpus's hole list**, not by stage sequencing — which component crosses,
> and whether all ~14 are warranted, is determined by which exports remain
> undriven when the coverage artifact reaches its termination condition.
> Rewrite the criteria against the real hole list before starting.

The issue named ~14 components by hand: `EdgeText`, `ViewportPortal`,
`EdgeLabelRenderer`, `NodeResizer`, `NodeResizeControl`, `EdgeToolbar`,
`ControlButton`, and the five built-in edge components. Read against
`parity/system/coverage/holes.json` and `src/Boundary.js`'s manifest, that list
is wrong in both directions.

**Two of the named components had already crossed.** `NodeResizer` and
`NodeResizeControl` came forward into stage 2, because their three lifecycle
handlers are callback props and a callback cannot cross without the record it
hangs off (`src/Boundary/Resizer.purs` says so). They are in the hole register,
and will stay there until a fixture resizes — but that is a fixture, not a
converter, and nothing about stage 4 touches it.

**Four components the issue did not name were still `passthrough`**:
`MiniMapNode`, `ReactFlowProvider`, `ReactFlowWithRef` and `BaseEdge`.
(`ReactFlowWithRef` no longer exists. It crossed here, as this ticket records,
and [#27](https://github.com/jonbae/PSFlow/issues/27) then deleted it by giving
`<ReactFlow />` the ref it was published to supply. The count of fourteen is
what stage 4 crossed, and stays.) None is
in the hole register, and `BaseEdge` is recorded as *driven* in
`parity/system/coverage.md` — so a set derived from the hole list alone would
have left the manifest's `passthrough` holding four components beside the
fourteen pure functions, which is a set no sentence describes. That is why the
rewritten criteria are stated against `passthrough` and use the hole list to
say which members of it are undriven, rather than the other way round.

**The hole register also names a prop, not only components.** `EdgeTypes` is a
hole with a reason that is not about a fixture at all:

> no fixture passes an edgeTypes map, so no edge carries a type outside the
> built-in set.

No fixture *could*. `edgeTypes`' values are the consumer's own components, so
crossing it needs an outbound converter for the props record ps-flow hands
them, and that record is the built-in edge components' own. So the prop and the
components are one piece of work, which is what `src/Boundary.purs`'s own
staging note had said all along: "the components no fixture mounts, and with
them the two props that hand a consumer's own component its props record."

## The rewritten criteria

Stage 4's set is **everything `passthrough` still held that is not a pure
function** — fourteen components — **plus the three props whose values are
components the consumer wrote**. The hole register governs it in two ways: it
says which of the fourteen the corpus does not drive (seven of them, on the day
this landed: the four non-default built-in edges, `EdgeToolbar`,
`EdgeLabelRenderer` and `ViewportPortal`), and it is what kept the resizer pair
out.

- [x] The hole list is read and these criteria are rewritten against it — this
      file, plus the six hole entries annotated with what stage 4 did and did
      not change about them (four it crossed exports from, two it deliberately
      did not)
- [x] All fourteen remaining `passthrough` components cross with JS-native
      signatures: `EdgeText`, `BaseEdge`, the five built-in edges,
      `EdgeToolbar`, `ControlButton`, `MiniMapNode`, `EdgeLabelRenderer`,
      `ViewportPortal`, `ReactFlowProvider`, `ReactFlowWithRef`
- [x] The three consumer-component props cross: `edgeTypes`,
      `connectionLineComponent`, `MiniMap.nodeComponent` — emptying the last of
      the deferred-prop tables
- [x] Wrapper-kind divergence resolved in both directions: `memo` added to
      `Background`, `Controls`, `MiniMap` and `EdgeText`; dropped from
      `BaseEdge` and `ControlButton`; `forwardRef` added to `Panel` and
      `Handle`, with the ref actually reaching the element
- [x] The boundary manifest reads `stage: 4`, 55 crossed, 14 passthrough — and
      every name left in `passthrough` is a pure function
- [x] Surface parity is green, with the eight wrapper-kind allowlist entries
      deleted rather than re-worded
- [x] `parity/boundary/mount.mjs` mounts all fourteen, so the stage closes its
      own crossed-but-ungated window: the census reports 0
- [x] A decision is recorded on the fourteen pure functions — ticket
      [082](082-boundary-stage-5-pure-functions.md): a fifth stage **is**
      warranted, and stage 4 is what settles it

## Resolution (2026-08-31)

Green: `parity:surface`, `parity:boundary` (216 checks), `spago test`,
`test:conformance` (41), `test:smoke` (2), `parity:changelog`, `parity:fork`,
`parity:coverage`, the census, and the six gate self-tests that pass on this
checkout.

Coverage is unchanged at **124 of 156 driven, 32 declared holes** — which is
the point. Crossing is not driving. Every hole stage 4 read is still open, and
what changed is that closing one is now a fixture rather than a converter.

### Three things the crossing found

**`<Panel />` and `<Handle />` accepted a `ref` and dropped it.** The
surface-parity allowlist recorded this as a wrapper-kind divergence, which
undersells it: a plain function component has nowhere to put a ref, so the
value was discarded in silence. Both are `forwardRef` now, and `PanelProps` /
`HandleProps` gained an `innerRef` — spelled that way because React strips
`ref` out of any props record before the component sees it. The mount gate
checks the element carries it, because a shape comparison cannot.

**`<StepEdge />` crashed on its own `pathOptions`.** `React.Edge.Step` shared
`React.Edge.SmoothStep`'s factory through an `unsafeCoerce`, and the two
records' `pathOptions` differ by two members. The factory reads both, which in
PureScript is a `Maybe` bind on `undefined`. Nothing had ever passed one,
because nothing could call the component from JavaScript. Fixed by widening the
way upstream does.

**The four bending edges required the two handle sides.** Upstream defaults them
in its parameter list (`sourcePosition = Position.Bottom`,
`targetPosition = Position.Top`), so its own documented example — four
coordinates and nothing else — renders. The first crossing made them required
and the mount gate froze that; caught in review, and the crossing now supplies
upstream's defaults, exactly as `<Handle />`'s do.
