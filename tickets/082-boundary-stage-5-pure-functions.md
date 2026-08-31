# 082 — Boundary stage 5: the fourteen pure functions

## Why this ticket exists

[#62](https://github.com/jonbae/PSFlow/issues/62) — boundary stage 4 — carried
one open question beside its own work:

> **fourteen of the seventeen pure-function exports have no scheduled conversion
> in any stage**, including this one. They are identity aliases today and six are
> actively broken from JavaScript. Surface parity's call-and-compare covers them
> in the meantime but is not a substitute for converting them. Someone should
> decide whether a fifth stage is warranted.

## The decision (2026-08-31): yes, and stage 4 is what settles it

**A fifth stage is warranted.** The argument that decides it is not "fourteen
exports are left" — an unconverted export that nobody can reach is a fair thing
to leave written down. It is that **stage 4 made them reachable, and made them
the first thing a consumer hits.**

Stage 4 crossed `edgeTypes`. A JavaScript consumer can now register a custom
edge component, which is upstream's normal way to draw an edge. The first line
of such a component, in upstream's own documented example, is:

```jsx
const [edgePath, labelX, labelY] = getBezierPath({
  sourceX, sourceY, sourcePosition, targetX, targetY, targetPosition,
});
```

Against ps-flow that line does two wrong things at once. `getBezierPath` still
consumes PureScript `Position` constructors, so the `sourcePosition` string the
crossed `edgeTypes` just handed the component **throws** before the call
returns; and if it did return, the destructuring would bind `undefined` three
times, because ps-flow answers with a labelled record where upstream answers
with a positional array.

So the fourteen are not a tidy-up. They are the other half of what stage 4
delivered, and until they cross, `edgeTypes` is a prop a consumer can set and
not use.

### What is left, measured rather than assumed

Surface parity **calls all seventeen** through `index.js` with the same inputs
as the vendored upstream bundle, so this list is a measurement and not a
reading. Twelve differ, in three classes, and each has an entry in
`parity/surface/allowlist.json` naming this stage:

| class | exports | what a caller sees |
|---|---|---|
| `call-convention` | `getConnectedEdges`, `getIncomers`, `getOutgoers`, `getNodesBounds`, `getViewportForBounds`, `reconnectEdge` | the next curried function instead of the answer |
| `positional-array-return` | `getBezierEdgeCenter`, `getEdgeCenter`, `getSimpleBezierPath`, `getStraightPath` | a labelled record where upstream returns an array |
| `throw-vs-return` | `getBezierPath`, `getSmoothStepPath` | a throw, on the enum strings the JS surface itself publishes |

The remaining two of the fourteen, `isNode` and `isEdge`, agree on shape and on
every call surface parity makes — they are unconverted and currently
indistinguishable from converted, which is exactly what a call-and-compare is
for. `applyNodeChanges`, `applyEdgeChanges` and `addEdge` are the three that
crossed in stage 1, because a controlled flow's own change handlers call them.

#62 counted **six actively broken from JavaScript**. That count is not
re-derived here — what is re-derived is the table above, which surface parity
measures on every run, and it is the table the work is scoped against.

## Scope

- Uncurry the six `call-convention` exports to upstream's single call, and
  return upstream's value rather than the next function.
- Return positional arrays from the four `positional-array-return` exports.
- Accept the JS enum strings in `getBezierPath` and `getSmoothStepPath`, through
  `Boundary.Enums` like every other crossing, rather than PureScript
  constructors.
- Move the fourteen from `passthrough` to `crossed` in the manifest and set
  `stage: 5`.
- Delete their entries from `parity/surface/allowlist.json` — all five `shapes`
  entries and all twelve `behavior.functions` ones. The allowlist is the
  per-stage progress ledger, so "stage 5 is done" means deleting them leaves
  surface parity green.

## What this stage does *not* need

A new gate. Surface parity's call-and-compare already exercises all seventeen
against the vendored upstream on every run, so the conversion lands with its
proof already in place — which is the opposite of stages 1–4, each of which had
to bring a mount check along. That is also why this stage was safe to defer: the
differences were being measured the whole time, and the twelve entries in the
allowlist are what that measurement wrote down.

## Acceptance criteria

- [ ] The six curried exports take upstream's arguments in one call
- [ ] The four labelled-record returns are positional arrays
- [ ] `getBezierPath` and `getSmoothStepPath` accept the JS enum strings
- [ ] The boundary manifest reads `stage: 5` with an empty `passthrough`
- [ ] The twelve `behavior.functions` and five `shapes` allowlist entries are
      deleted and surface parity is green
- [ ] A custom edge component registered through `edgeTypes` can call
      `getBezierPath` and draw with what it returns, checked by
      `parity/boundary/mount.mjs` where stage 4 left the `edgeTypes` crossing

## Blocked by

Nothing. Stage 4 (#62) has landed.
