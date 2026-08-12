# ps-flow

A PureScript port of `@xyflow/react`. Vocabulary — surfaces, gates, baselines,
the dual-run net — is [`CONTEXT.md`](CONTEXT.md); this file is what to run.

## Build

```sh
npm run build:smoke    # spago build + esbuild bundles examples/react-smoke
npm run build:driver   # spago build + esbuild bundles parity/driver (see its README)
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
| **surface parity** | `npm run parity:surface` | export names and prop members, against the vendored upstream's TypeScript |
| **function parity** | `spago test` | pure-function return values, against the `@psflow/oracle` bundle |
| **conformance test suite** | `npm run test:conformance` | upstream's own e2e specs, ported — upstream's *asserted intent* |
| **smoke test suite** | `npm run test:smoke` | liveness, plus the hand-authored interaction assertions not yet retired |
| **system parity** | — | a mounted app's whole end-state trace. Does not exist yet |

`spago test` is deliberately broader than function parity: it also runs the
**unit tests**, the PSFlow-only modules that prove the internals are
self-consistent. Those are outside the gate scheme — a different claim from
"PSFlow matches xyflow". "Function parity green" collapsing to "`spago test`
green" is stricter than needed, never weaker.

Two browser specs sit outside the scheme as well:

```sh
npm run test:node-props   # PSFlow-only NodeProps guard; retires on the net's props section
npx playwright test --config examples/react-smoke/playwright.config.ts --project=screenshot
```

**Ordering.** Surface parity green is a hard precondition — its failures are
interop-shaped and shadow every other gate at once. Everything else is
*interpretation* order: while a cheaper gate is red, do not trust a system
parity divergence, but nothing blocks. A red function parity may not touch the
fixtures at all.

## Checks that are not gates in that sense

```sh
npm run parity:boundary   # boundary module — outbound drift + deferred props refused
npm run parity:changelog  # 12.3.5→12.11.0 changelog audit; gates on unbucketed PRs
npm run test:compare      # node --test over the system-parity comparison core
npm run test:harness      # node --test over its capture half and the driver's registries and sides
npm run test:harness:live # the net harness against a real page — a browser, but no parity claim
```

`parity:boundary` is two staleness checks over `src/Boundary/`. `drift.mjs`
compares each crossed record's PureScript label set against its JS-shaped one,
live from source, because the outbound direction has no compiler check and the
repo's generators vary too few fields for a round-trip property to find an
omission. `mount.mjs` enters through `index.js` — the only door the boundary
module is gated on — and makes five claims: that a fully converted prop set
mounts and arrives JS-shaped, that every prop the boundary has not crossed yet
is refused rather than ignored, that the graph utilities a driver calls are
callable from JavaScript with their round trip closing, that three of the four
chrome components mount with no props at all and the fourth names the prop
upstream declares required, and that `useNodesState` / `useEdgesState` return
upstream's 3-tuple with a setter that runs. It needs `spago build` first and
hard-fails on missing compiled output.

`parity:changelog` measures what a baseline bump costs, not what detects a
divergence.

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

1. update the vendored `xyflow/` checkout,
2. re-pin both devDependencies to the new versions,
3. `npm run build:oracle` (commit the regenerated `oracle/index.js`),
4. `npm run build:driver` (commit the regenerated `parity/driver/dist/psflow.js`
   — it inlines upstream's fixture files and the ColorMode example, so a bump
   changes it),
5. `npm run parity:surface` and `npm run parity:changelog` — the audit will fail
   on every PR the bump introduced until each is bucketed in
   `parity/changelog-audit/verdicts.json`.

`xyflow/` is gitignored, so `parity:surface`, `parity:changelog`, `build:oracle`
and `build:driver` all require it present and hard-fail on a clean clone. The
committed artifacts (`parity/surface/report.md`,
`parity/changelog-audit/report.md`, `oracle/index.js`,
`parity/driver/dist/psflow.js`) are what survive without it.
