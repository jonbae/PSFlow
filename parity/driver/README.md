# The drivers — one page, bundled once per side

A **driver** is the React component that mounts a **fixture**. There are two,
and the page below serves both; it is bundled twice, and the two bundles differ
in exactly one thing, what `@xyflow/react` resolves to. A driver difference can
therefore never be mistaken for a library difference.

Vocabulary is `CONTEXT.md`; **driver**, **fixture** and the gate names below are
all defined there.

| | |
|---|---|
| `src/Flow.tsx` | the fixture driver: a twin of upstream's `generic-tests/Flow.tsx` |
| `src/entry.tsx` | the page: route → fixture or example driver, a twin of upstream's `generic-tests/index.tsx` |
| `index.html` | the container, whose box feeds `fitView`, and the `?side=` switch |
| `registry.mjs` | the fixture glob over two roots, and the collision it can hit |
| `build.mjs` | the two registries, the bundle, the alias, and the provenance check |
| `dist/psflow.js` | generated, and committed — see below |

```sh
npm run build:driver                        # spago build, then the psflow bundle
node parity/driver/build.mjs --side upstream   # the net's other run
npm run test:harness                        # includes registry.mjs's own tests
```

## `?side=`, and why it is a parameter

`index.html` imports `dist/psflow.js` or `dist/upstream.js` according to
`?side=`, defaulting to `psflow` — so the conformance suite's URLs, which carry
no query, are unchanged. An unknown side renders an error and throws rather than
mounting nothing, because a page that quietly rendered no flow would leave every
gate downstream comparing two runs of the same library and reporting green.

A parameter rather than a second HTML file: the container above the mount point
is what feeds `fitView`, and two files could drift. The net's runs must differ
in the library and in nothing else.

## Two kinds of route

`#/tests/generic/…` is a **fixture**: data, handed to `Flow.tsx`. That is what
upstream's `generic-tests/index.tsx` serves and what four of the five
conformance specs drive. Fixtures are globbed from **two roots** — the vendored
`generic-tests/` and `parity/system/fixtures/`, where ps-flow authors its own —
into one flat route space, so a file in the second landing on a vendored
fixture's path would shadow it and every spec driving that route would keep
passing against something else. `registry.mjs` fails on the collision rather
than letting one win. Its second root is empty until the corpus lands
([#55](https://github.com/jonbae/PSFlow/issues/55)); emptiness only fails in the
aggregate, which would be a page answering every route with a 404.

`#/examples/…` is an **example driver**: a whole component of upstream's,
imported unmodified and mounted as it stands. `generic-props.spec.ts` needs
one, because upstream has no props fixture to twin — its own props spec drives
its `examples/ColorMode` page, so PSFlow's port drives upstream's own
`examples/ColorMode/index.tsx`, through this page, on the JS surface.

Example drivers are **written down** in `build.mjs` rather than globbed, unlike
the fixtures. Upstream's `examples/` holds dozens of directories, most of them
importing exports that have not crossed, and one unresolved import is a link
error that stops the page building for every route at once. Adding an entry is
therefore a decision about the crossing set, not a discovery — which is why
`build.mjs` states the count it is refusing to glob rather than this file
repeating it.

That import list is not free. `ColorMode/index.tsx` pulls `useNodesState` and
`useEdgesState` into boundary stage 1 from stage 3, and its line 56 is
`setEdges(eds => addEdge(params, eds))` — the unrun-thunk shape the whole
boundary effort started from. Nothing in a browser executes that line yet: the
props spec never draws a connection, so what holds the fix is `parity:boundary`,
which calls the setter itself. The driver is why the crossing had to happen, not
what proves it.

## Who uses it

Today, the conformance suite — upstream's own e2e specs, ported. Three of them
(`generic-nodes`, `generic-pane`, `generic-props`) run against this page and
therefore enter through **the JS surface**; the rest still enter through the
compiled `Example.Main`, and move over with their fixtures
([node-toolbar #47](https://github.com/jonbae/PSFlow/issues/47),
[edges #48](https://github.com/jonbae/PSFlow/issues/48)). The old door is
deleted once they all have
([#50](https://github.com/jonbae/PSFlow/issues/50)).

Next, **the net**, whose capture harness drives this same page on both sides
through `?side=` (`parity/system/harness/`), which is what the `--side upstream`
bundle is for. Upstream's own vendored `Flow.tsx` and `index.tsx` become
reference material that never executes.

## Why one driver is ours and the other is not

The bar that governs **fixtures** is *make hand-translation impossible*, and it
is absolute: hand-translating them is what poisoned the dual-run spike's diff.
So the fixture files are imported **byte-unmodified** from the vendored tree —
`build.mjs` globs them, nothing rewrites them, and a baseline bump stays a
delete and re-vendor. The ColorMode driver is imported the same way and for the
same reason: it *is* its own fixture, with the flow's nodes and edges declared
inside it, so translating it by hand would be translating a fixture by hand.

That bar does **not** govern `Flow.tsx`. A driver mistake shows up identically
on both sides; a **boundary module** mistake is a real bug the net exists to
catch. Which is why generating that driver would be over-engineering, and why
it is hand-written against upstream's file with its differences named in its
header.

Upstream cannot supply the page either way. Its `index.tsx` globs only beneath
its own tree, so it structurally cannot see a PSFlow-authored fixture, and it
cannot see upstream's own `examples/` either; and its app is vite plus a path
router where this is a static server plus a hash router. That last one is not
cosmetic — the container's box feeds `fitView`, which feeds the viewport
transform, which feeds everything — so both of the net's runs load *this* page
rather than one of them loading upstream's app.

## The alias, and why the build checks its own output

`@xyflow/react` is one module specifier, so the alias **cannot be applied
selectively**. That is the point rather than a limitation: without it, a
fixture's own custom node component would import upstream's `Handle` and render
it inside PSFlow's flow, and the run would mean nothing.

It also makes the alias the entire gate — and an alias that quietly stopped
being applied would leave every conformance spec passing, against upstream,
reporting green about PSFlow. So `build.mjs` reads its own output back before
writing it, and fails if the bundle does not contain the library the requested
side names, or contains the other one as well. esbuild writes a `// <path>`
comment above every module it inlines, which is what makes the question
answerable at all.

## Why `dist/psflow.js` is committed

The vendored `xyflow/` tree is **not** in git, and the fixtures come from it.
Without the committed bundle the conformance suite could not run from a fresh
clone — the same reason `oracle/index.js` is committed.

Rebuild it after changing `src/`, after re-vendoring `xyflow/`, and before
reading a conformance failure as a real one.

**Nothing fails when you don't.** A bundle that predates `output/` leaves every
spec that loads it green about code that is gone, which is a **stale** register
in every sense the glossary means — and unlike the allowlists and regions, this
one has no gate behind it. Its banner records the baseline and the two
registries' sizes, so a bundle left behind by a bump *says* so to a reader, but
saying is not failing.
`oracle/index.js` carries the identical gap, which is why closing it is one
mechanism for both rather than something to bolt onto this directory.
