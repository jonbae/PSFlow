# ps-flow

A PureScript port of `@xyflow/react`. Vocabulary — surfaces, gates, baselines,
the dual-run net — is [`CONTEXT.md`](CONTEXT.md); this file is what to run.

## Build

```sh
npm run build:driver   # spago build + esbuild bundles the browser driver page (see its README)
npm run build:oracle   # regenerate oracle/index.js, the @psflow/oracle bundle
```

## The five gates

Three of them are **parity** gates — one technique at three grains, comparing
PSFlow against *executing* upstream. Two are **test suites** — collections of
written tests. The difference is not coarseness, it is instrument: delete
`xyflow/` from the machine and the three parity gates become impossible, having
nothing to compare against, while conformance and smoke still run and still
mean something.

| Gate | Command | What it compares |
|---|---|---|
| **surface parity** | `npm run parity:surface` | exported *values*, shapes and selected JS-barrel behavior, plus prop members, against vendored upstream |
| **function parity** | `spago test` | pure-function return values, against the `@psflow/oracle` bundle |
| **conformance test suite** | `npm run test:conformance` | upstream's own e2e specs, ported — upstream's *asserted intent* |
| **smoke test suite** | `npm run test:smoke` | liveness, plus the hand-authored interaction assertions not yet retired |
| **system parity** | `npm run parity:system` | a mounted app's whole end-state trace, against vendored upstream mounted beside it |

`spago test` is deliberately broader than function parity: it also runs the
**unit tests**, the PSFlow-only modules that prove the internals are
self-consistent. Those are outside the gate scheme — a different claim from
"PSFlow matches xyflow". "Function parity green" collapsing to "`spago test`
green" is stricter than needed, never weaker.

Two browser specs sit outside the scheme as well:

```sh
npm run test:node-props   # PSFlow-only NodeProps guard; retires on the net's props section
npx playwright test --config examples/react-smoke/playwright.config.ts --project=screenshot
# writes parity/driver/dist/smoke.png
```

**Ordering.** Surface parity green is a hard precondition — its failures are
interop-shaped and shadow every other gate at once. Everything else is
*interpretation* order: while a cheaper gate is red, do not trust a system
parity divergence, but nothing blocks. A red function parity may not touch the
fixtures at all.

**Surface parity needs `spago build` first**, and hard-fails on missing
compiled output rather than falling back. It **imports** `index.js` rather than
reading it — a regex over the file proves a line of text exists, not that the
binding resolves — which is also what lets it compare `typeof`, arity and React
wrapper kind across every export. The cost, accepted in ticket 041: the
cheapest gate is no longer standalone.

The gate also deep-compares the eight frozen enum objects and calls the
seventeen pure functions once through `index.js` with the same inputs as the
vendored upstream bundle. This catches JS-boundary failures that `typeof` and
arity cannot, especially a labelled record where upstream returns a positional
array. Known differences are keyed by export *and difference class*; every one
names its retiring boundary stage and fails as stale when it stops matching.

**System parity is red, and that is where it is meant to be.** It mounts
upstream and ps-flow on the same unmodified fixtures, settles each on its own
clock, captures each twice, and diffs the `dom` section; its first run found
nine classes of divergence, listed on the divergence backlog
([#22](https://github.com/jonbae/PSFlow/issues/22)) rather than fixed. A
difference is answered by a fix in the port or by a **region** in
`parity/system/regions.json` — never by loosening what the net looks at. It
builds both driver bundles itself, so it cannot measure code that is not in the
tree, and needs `spago build` first for the ps-flow side. Its detail is
`parity/system/README.md`; the report is `parity/system/report.md` and the
traces behind it are committed under `parity/system/traces/`.

```sh
npm run parity:system                    # build both bundles, capture the corpus, diff
node parity/system/net.mjs --compare-only  # re-diff the stored traces — seconds, no browser
node parity/system/net.mjs --scenario mount-baseline--nodes-general
```

## Checks that are not gates in that sense

```sh
npm run parity:boundary   # boundary module — outbound drift + deferred props refused
npm run parity:changelog  # 12.3.5→12.11.0 changelog audit; gates on unbucketed PRs
npm run test:surface      # node --test over surface parity's shape and allowlist logic
npm run test:census       # node --test over the standalone census generator and its staleness logic
npm run test:compare      # node --test over the system-parity comparison core
npm run test:harness      # node --test over its capture half and the driver's registries and sides
npm run test:harness:live # the net harness against a real page — a browser, but no parity claim
npm run test:ci           # node --test over the gates workflow and the baseline vendoring script
```

`parity:boundary` is two staleness checks over `src/Boundary/`. `drift.mjs`
compares each crossed record's PureScript label set against its JS-shaped one,
live from source, because the outbound direction has no compiler check and the
repo's generators vary too few fields for a round-trip property to find an
omission. `mount.mjs` enters through `index.js` — the only door the boundary
module is gated on — and makes six claims: that a fully converted prop set
mounts and arrives JS-shaped, that every prop the boundary has not crossed yet
is refused rather than ignored, that the graph utilities a driver calls are
callable from JavaScript with their round trip closing, that three of the four
chrome components mount with no props at all and the fourth names the prop
upstream declares required, that `<Handle />` and `<NodeToolbar />` mount inside
a consumer's own node component with `<Handle />` taking upstream's defaults for
the two props ps-flow's record makes required, and that `useNodesState` /
`useEdgesState` return upstream's 3-tuple with a setter that runs. It needs
`spago build` first and hard-fails on missing compiled output.

`parity:changelog` measures what a baseline bump costs, not what detects a
divergence.

`test:ci` is the gates workflow's self-test: it holds `.github/workflows/gates.yml`
to the five-gate table above — the four cheap gates each run once, under the
command this file documents, with surface parity first and system parity absent —
and covers the baseline vendoring script CI runs. Editing either file without the
other goes red.

## Continuous integration

`.github/workflows/gates.yml` runs **the four cheap gates on every pull
request**: surface parity, function parity, the conformance test suite and the
smoke test suite, in that order, each failing the pull request check when it is
red. `spago test` is the whole PureScript suite, so that step is stricter than
function parity alone — never weaker.

**Surface parity runs first and blocks.** It is the only hard precondition, so
when it is red the three gates after it do not run and the run's summary says
why they were withheld rather than leaving them skipped in silence. Everything
below it is interpretation order.

**System parity is not in the per-PR workflow.** Its per-run cost is not
knowable until the corpus exists — a floor of ~60 scenarios, which at two sides
by two captures is ~240 captures, each settling on its own clock — and
multiplying the two is what answers the per-PR / nightly / bump-only question.
Until that measurement exists, a schedule would be a guess; and while the
divergence backlog is being worked, a per-PR run that is red on purpose would
train everyone to ignore a red pull request check.

CI vendors the parity baseline itself, since `xyflow/` is gitignored:

```sh
node .github/scripts/vendor-baseline.mjs   # resolves the tag from the exact pins below
```

It reads the exact-pinned `@xyflow/*` devDependencies, downloads that release
tag's source tarball into `xyflow/`, and fails if the extracted tree disagrees
with either pin — the tag names the react version only, so the system version is
checked rather than assumed. It refuses to touch an existing `xyflow/`: a bump
is a delete and re-vendor, never a merge.

CI then rebuilds `oracle/index.js` and `parity/driver/dist/psflow.js` before
running anything. Both are committed so a fresh clone works without the
vendored tree, and **nothing fails when they are left stale** — a bundle
predating `output/` leaves every spec green about code that is gone. CI has the
vendored tree anyway, so rebuilding costs seconds and the gates measure the
commit rather than the last artifact someone rebuilt by hand.

## The parity baseline

The parity baseline is the **vendored** `xyflow/` checkout — currently
`@xyflow/react` 12.11.0 / `@xyflow/system` 0.0.77. All three parity gates read
from it; no JavaScript in this repo imports `@xyflow/*` from `node_modules`, and
`parity/driver/build.mjs` fails if a bundle picks any up. The two browser pages
do link upstream's stylesheets from there, which is what the exact pin below
makes safe.

The `@xyflow/react` / `@xyflow/system` devDependencies are exact-pinned to those
same versions. They are a **parity baseline pin, not build dependencies** — they
exist so the declared version can never silently disagree with what the gates
actually measure. Do not add a caret: a floating range would let `npm install`
drift the declared baseline away from the vendored one without any gate noticing.

Bumping the baseline is one atomic change:

1. re-pin both devDependencies to the new versions,
2. `rm -rf xyflow && node .github/scripts/vendor-baseline.mjs` — the checkout is
   resolved *from* the pin, which is what keeps the two halves of the baseline
   one change rather than two, and is how CI gets its copy,
3. `npm run build:oracle` (commit the regenerated `oracle/index.js`),
4. `npm run build:driver` (commit the regenerated `parity/driver/dist/psflow.js`
   — it inlines upstream's fixture files and the ColorMode example, so a bump
   changes it),
5. `npm run parity:surface` and `npm run parity:changelog` — the audit will fail
   on every PR the bump introduced until each is bucketed in
   `parity/changelog-audit/verdicts.json`,
6. `npm run parity:system` (commit the re-captured `parity/system/traces/` and
   `report.md`). Diff the traces against their previous versions before you
   commit them: what upstream's own render changed under the bump is visible
   there and nowhere else.

`xyflow/` is gitignored, so `parity:surface`, `parity:changelog`,
`build:oracle`, `build:driver` and `parity:system` all require it present and
hard-fail on a clean clone. The committed artifacts (`parity/surface/report.md`,
`parity/changelog-audit/report.md`, `oracle/index.js`,
`parity/driver/dist/psflow.js`, `parity/system/report.md` and the traces under
`parity/system/traces/`) are what survive without it.

The traces are committed for a reason beyond a clean clone: re-diffing a
**stored** trace of one baseline against a trace of the next is what turns a
bump into a behavioural changelog, and that comparison is impossible if the
older traces only ever existed on the machine that captured them.
