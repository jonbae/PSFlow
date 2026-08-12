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

## Empty, for now

The corpus is built by
[#55](https://github.com/jonbae/PSFlow/issues/55); the harness that drives it
([#35](https://github.com/jonbae/PSFlow/issues/35)) only opened this root. An
empty root is legitimate — the registry only fails when *every* root is empty,
which would build a page answering every route with a 404.
