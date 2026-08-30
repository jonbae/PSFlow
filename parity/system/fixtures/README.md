# PSFlow-authored fixtures — the driver's second root

A **fixture** is one flow definition — nodes, edges, and the props handed to
`ReactFlow` — as a data file both implementations import. Never test code.
Upstream ships four, under `xyflow/examples/react/src/generic-tests/`; anything
the corpus needs that upstream does not already have goes **here**, and
`parity/driver/build.mjs` globs both roots into one registry.

The split exists so the vendored tree stays byte-identical. System parity runs
vendored *source* as its baseline, so a fixture dropped into `xyflow/` would
leave that tree permanently diffed against the published package, and a
baseline bump would stop being `rm -rf` and re-vendor with no merge.

## Shape

Same default-export `flowConfig` as upstream's, because the same `Flow.tsx`
mounts both:

```ts
export default {
  flowProps: { fitView: true, nodes: [ … ], edges: [ … ] },
  panelProps: { … },      // optional — the four chrome components render on
  backgroundProps: { … }, // their config key being present at all
  controlsProps: { … },
  minimapProps: { … },
};
```

`.ts` only. A fixture's own `components/*.tsx` are imported *by* it and are not
routes.

The route is the path below this directory, so `resize/general.ts` is
`#/tests/generic/resize/general` — **one flat route space shared with the
vendored root**. A file here landing on a vendored fixture's path would shadow
it, and every spec driving that route would keep passing against something
else, so `collectFixtures` fails on the collision rather than letting one win.

## A fixture here joins the net by existing

The **corpus** derives one **mount-only baseline** per fixture from this same
registry (`parity/system/corpus/mount-baselines.mjs`), across both roots. So a
file dropped in here is mounted by `parity:system` on both sides and diffed the
next time the gate runs, with no second list to remember — which is what makes
"mount-only is a general rule for every fixture" structural rather than a habit.

What it does *not* get automatically is a scenario that drives anything. That is
a hand-written act in `parity/system/corpus/`, which has its own README.

## What is here

Eighteen flows, one per condition no vendored fixture sets, written for the
thirty test-debt scenarios ([#60]). Grouped by what the condition is *about*
rather than by which scenario drives it — several are driven by more than one,
and a fixture named after its first scenario would read wrongly the moment a
second arrived.

| | The condition it sets |
|---|---|
| `chrome/panels.ts` | two panels at once, `top-center` and `bottom-center` |
| `chrome/controls.ts` | `Controls` laid out horizontally |
| `chrome/minimap-colors.ts` | every `MiniMap` colour, the mask one carrying opacity |
| `chrome/minimap-hidden-nodes.ts` | a `MiniMap` over a flow with every node hidden |
| `chrome/background.ts` | a `Background` given an explicit `bgColor` |
| `edges/base-edge-path.ts` | a custom edge handing `BaseEdge` path attributes |
| `fitview/uncontrolled.ts` | uncontrolled, with no change handlers at all |
| `flow/custom-testid.ts` | a custom `data-testid` on `<ReactFlow>` |
| `flow/display-none.ts` | a container that is hidden *after* it mounted |
| `flow/props-change.ts` | a dozen tracked props that change after the mount |
| `nodes/autopan.ts` | a drag that reaches the edge, with a bounded pan |
| `nodes/connections.ts` | a node whose handles carry several edges each |
| `nodes/expand-parent.ts` | a child that pushes its parent open as it is dragged |
| `nodes/no-select-on-drag.ts` | `selectNodesOnDrag: false` |
| `nodes/nowheel.ts` | a `nowheel` node big enough to pinch on |
| `nodes/tall.ts` | a flow taller than the window, so the page can scroll |
| `nodes/unmeasured.ts` | controlled, with dimension changes never applied back |
| `viewport/helpers.ts` | a flow that snaps, so a no-options helper says something |

Each file's own header says why it is shaped the way it is, and several of those
are the interesting half — `nodes/autopan.ts` in particular, which is where the
question ticket 081 left open about expressing a *dwell* is settled.

### `shared/graph.tsx`, and why it is not `.ts`

Most of these start from the same four nodes and two edges, which are upstream's
`nodes/general.ts` without its six special-case nodes: every lifted scenario
already aims at `.react-flow__node` first-match and at `Node-1` through
`Node-4`, and a fixture here that invented its own ids would read differently
from the seed scenario beside it for nothing.

It is a **`.tsx`** because the registry globs `**/*.ts` across both roots and
turns every match into a route. A shared `.ts` helper would be mounted as a
fixture, have a mount-only baseline derived for it, and fail on the page for
having no default export. That is the same reason upstream's `components/` are
`.tsx`, arrived at from the other direction.

## The driver grew two knobs for these

Both are declared by a fixture and inert unless one asks, so every scenario
written before them drives the same component it always did.
`parity/driver/src/Flow.tsx` carries the full reasoning; in short:

- **the four chrome props may be a list**, because one upstream row is a claim
  about two panels at once and a scenario mounts one route;
- **`afterMount` props are merged in when the driver's one control is pressed**,
  because the StoreUpdater rows are about what happens when a tracked prop
  *changes* and nothing in the closed action vocabulary can change one.

And a rule rather than a third knob: **change handlers, and the `nodes` and
`edges` props they feed, are installed only for a fixture that supplies
`flowProps.nodes`**. An uncontrolled fixture handed `onNodesChange` would flip
itself to controlled on its first change.

[#60]: https://github.com/jonbae/PSFlow/issues/60
