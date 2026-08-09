# The driver — one page, bundled once per side

The **driver** is the React component that mounts a **fixture**. There is one,
in PSFlow's tree, and it is bundled twice: the two bundles differ in exactly
one thing, what `@xyflow/react` resolves to. A driver difference can therefore
never be mistaken for a library difference.

Vocabulary is `CONTEXT.md`; **driver** and **fixture** are defined there. The
gate names below are not — the ladder is still numbered in the glossary, and
renaming it is [gate vocabulary #31](https://github.com/jonbae/PSFlow/issues/31).

| | |
|---|---|
| `src/Flow.tsx` | the driver: a twin of upstream's `generic-tests/Flow.tsx` |
| `src/entry.tsx` | the page: route → fixture, a twin of upstream's `generic-tests/index.tsx` |
| `index.html` | the container, whose box feeds `fitView` |
| `build.mjs` | the bundle, the alias, and the provenance check |
| `dist/psflow.js` | generated, and committed — see below |

```sh
npm run build:driver                        # spago build, then the psflow bundle
node parity/driver/build.mjs --side upstream   # the net's other run
```

## Who uses it

Today, the conformance suite — upstream's own e2e specs, ported. Two of them
(`generic-nodes`, `generic-pane`) run against this page and therefore enter
through **the JS surface**; the rest still enter through the compiled
`Example.Main`, and move over with their fixtures
([node-toolbar #47](https://github.com/jonbae/PSFlow/issues/47),
[edges #48](https://github.com/jonbae/PSFlow/issues/48),
[ColorMode #34](https://github.com/jonbae/PSFlow/issues/34)). The old door is
deleted once they all have
([#50](https://github.com/jonbae/PSFlow/issues/50)).

Next, **the net**, which drives this same page on both sides
([#35](https://github.com/jonbae/PSFlow/issues/35)), which is what the
`--side upstream` bundle is for. Upstream's own vendored `Flow.tsx` and
`index.tsx` become reference material that never executes.

## Why the driver is ours and the fixtures are not

The bar that governs **fixtures** is *make hand-translation impossible*, and it
is absolute: hand-translating them is what poisoned the dual-run spike's diff.
So the fixture files are imported **byte-unmodified** from the vendored tree —
`build.mjs` globs them, nothing rewrites them, and a baseline bump stays a
delete and re-vendor.

That bar does **not** govern the driver. A driver mistake shows up identically
on both sides; a **boundary module** mistake is a real bug the net exists to
catch. Which is why generating the driver would be over-engineering, and why
this one is hand-written against upstream's file with its differences named in
its header.

Upstream cannot supply the page either way. Its `index.tsx` globs only beneath
its own tree, so it structurally cannot see a PSFlow-authored fixture; and its
app is vite plus a path router where this is a static server plus a hash
router. That last one is not cosmetic — the container's box feeds `fitView`,
which feeds the viewport transform, which feeds everything — so both of the
net's runs load *this* page rather than one of them loading upstream's app.

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

**Nothing fails when you don't.** A bundle that predates `output/` leaves both
specs green about code that is gone, which is a **stale** register in every
sense the glossary means — and unlike the allowlists and regions, this one has
no gate behind it. Its banner records the baseline and the fixture count, so a
bundle left behind by a bump *says* so to a reader, but saying is not failing.
`oracle/index.js` carries the identical gap, which is why closing it is one
mechanism for both rather than something to bolt onto this directory.
