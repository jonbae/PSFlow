spago test

npm run build:smoke    # spago build + esbuild bundles examples/react-smoke
npm run build:driver   # spago build + esbuild bundles parity/driver (see its README)
npm run test:smoke     # playwright runs examples/react-smoke/tests/*.spec.ts

## Parity

npm run parity:api        # Layer 0 — export + prop-member surface diff vs upstream
npm run parity:boundary   # boundary module — outbound drift + deferred props refused
npm run parity:changelog  # 12.3.5→12.11.0 changelog audit; gates on unbucketed PRs
npm run build:oracle      # regenerate oracle/index.js (Layer 1 differential oracle)

`parity:boundary` is two staleness checks over `src/Boundary/`. `drift.mjs`
compares each crossed record's PureScript label set against its JS-shaped one,
live from source, because the outbound direction has no compiler check and the
repo's generators vary too few fields for a round-trip property to find an
omission. `mount.mjs` enters through `index.js` — the only door the boundary
module is gated on — and makes three claims: that a fully converted prop set
mounts and arrives JS-shaped, that every prop the boundary has not crossed yet
is refused rather than ignored, and that the graph utilities a driver calls are
callable from JavaScript with their round trip closing. It needs `spago build`
first and hard-fails on missing compiled output.

The parity baseline is the **vendored** `xyflow/` checkout — currently
`@xyflow/react` 12.11.0 / `@xyflow/system` 0.0.77. Both Layer 0 (surface) and
Layer 1 (numeric) read from it; no JavaScript in this repo imports `@xyflow/*`
from `node_modules`, and `parity/driver/build.mjs` fails if a bundle picks any
up. The two browser pages do link upstream's stylesheets from there, which is
what the exact pin below makes safe.

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
   — it inlines upstream's fixture files, so a bump changes it),
5. `npm run parity:api` and `npm run parity:changelog` — the audit will fail on
   every PR the bump introduced until each is bucketed in
   `parity/changelog-audit/verdicts.json`.

`xyflow/` is gitignored, so `parity:api`, `parity:changelog`, `build:oracle` and
`build:driver` all require it present and hard-fail on a clean clone. The
committed artifacts (`parity/layer0-api/report.md`,
`parity/changelog-audit/report.md`, `oracle/index.js`,
`parity/driver/dist/psflow.js`) are what survive without it.
