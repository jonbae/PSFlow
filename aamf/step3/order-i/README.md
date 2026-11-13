# Order I evidence

Order I builds the package a JavaScript or TypeScript consumer installs: one
ES module bundled from `index.js`, upstream's declarations with ps-flow's gaps
written in, and upstream's stylesheets. It also fixes the two runtime
differences the declarations exposed. See
[the results](../../../AAMF_STEP3_RESULTS.md#order-i-completion-november-13-utc)
for what changed and what is excluded.

The starting commit is `6ebf1f19` (`step 3 order H`). Every run used Node 22.18.0,
PureScript 0.15.16 and Spago 1.0.4 on the host, and the Linux runner's locked
Playwright 1.60.0 image for browser checks.

## Files

| File | What it records |
|---|---|
| `red.sh` | Rebuilds the starting commit's `Boundary.Chrome` and `IsomorphicLayoutEffect` modules, runs the new boundary test and the updated mount check against them, and restores the final sources. |
| `red-build.log`, `red-declared-minimum.log`, `red-mount.log` | That rebuild, and the two checks against it: 43 of 61 declared-minimum checks fail, on `<Panel />` and on 42 server-render warnings, and the mount check fails on `<Panel />`'s default. |
| `falsify.sh`, `falsify.log` | Three defects introduced into an installed package, each turned red by its `parity:package` check: the `setState` overlay removed, relative specifiers without `.js`, and a layout effect on the server. |
| `build.log` through `changelog.log` | The PureScript build, the rebuilt oracle and driver bundles, `spago test`, and the surface, boundary, harness, comparison, coverage, census, CI, audit, fork and changelog checks on the final code. |
| `package-build.log`, `package-check.log`, `package-tests.log` | `npm run build:package`, `npm run parity:package` and `npm run test:package` on the final code. |
| `conformance.log`, `smoke.log` | The browser suites in the Linux runner. |
| `system.log`, `wave-summary.json`, `summarize.mjs` | The final full Linux net from this task's final code, its per-scenario outcome, and the script that wrote that outcome from the report: 115/115 pass, 230/230 sides reproduce. The report and coverage file are byte-identical to Order H's; the traces differ only in 1,391 event `timeStamp` values. |
| `before-checkpoint.tar.gz` | The Order H checkpoint's report, coverage file and traces, from the starting commit, which the final wave replaces. |
| `record.sh`, `checks.jsonl` | The script that ran each final check, and each check's command, UTC start and end, exit code and log. |

The package checks and `falsify.sh` ran again after the wave, following two
edits to `distribution/`: the declaration header's line wrapping and the check's
cleanup on exit. Their logs and `checks.jsonl` entries are from that second
run; no source the wave bundled changed.

The canonical report, coverage file and traces under `parity/system` are this
task's final wave. `dist/` is gitignored; `npm run build:package` rebuilds it.
