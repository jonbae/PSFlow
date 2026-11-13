# Order H evidence

Order H adds a witness for every coverage hole upstream can fire, fixes the
differences the flow-node probes and the new witnesses found, and moves the
numeric call sites W13 named to `Math.min` and `Math.max` semantics. See
[the results](../../../AAMF_STEP3_RESULTS.md#order-h-completion-november-12-utc)
for what changed and what is excluded.

The starting commit is `f8cefb3d` (`step 3 order G`). Every run used Node 22.18.0,
PureScript 0.15.16 and Spago 1.0.4 on the host, and the Linux runner's locked
Playwright 1.60.0 image for browser checks.

## Files

| File | What it records |
|---|---|
| `red-js-entry-at-head.log` | `parity/boundary/references.test.mjs` and `numeric.test.mjs` run against the starting commit's build: all 7 ps-flow checks fail and every upstream control passes. `getNodesBounds` already matched and stays as a guard. |
| `red-smoothstep-js-entry-before-fix.log` | `numeric.test.mjs` before the smoothstep change: the bend size drops upstream's `NaN`. |
| `red-closest-handle-before-fix.log` | `spago test` with the original `XYHandle.Utils` and `Geometry`: the closest-handle check fails on a `NaN` distance. |
| `red-bounding-box-monoid-before-fix.log` | `spago test` with only the original `Geometry`: the monoid fails at case 90 of 784. |
| `red-drag-handlers-report.md`, `red-drag-handlers.log` | `handlers-keep-consumer-keys` without the dragged-node link: the three drag payloads lack the consumer's `owner` key. |
| `probe-click-report.md`, `probe-wheel-report.md` and their logs | The two flow-node probes passing after the probe fixes, before the coverage work. |
| `targeted/` | One net run per new or changed scenario, with `run.sh`, the script that ran them, superseded by the final wave. The reconnect and default-options captures first failed, on the event `onConnectStart` received and on `pathOptions`; their passing reruns overwrote those reports. |
| `first-wave.log`, `first-wave-checks.jsonl` | A full Linux net and its gates before the drag-payload fix: all 115 scenarios passed. Kept as its own experiment. |
| `build.log` through `changelog.log` | The PureScript build, the rebuilt oracle and driver bundles, `spago test`, and the surface, boundary, harness, comparison, coverage, census, fork and changelog checks on the final code. |
| `conformance.log`, `smoke.log` | The browser suites in the Linux runner. |
| `system.log`, `wave-summary.json` | The final full Linux net from this task's final code, and its per-scenario outcome: 115/115 pass, 230/230 sides reproduce. |
| `post-wave-bundle.diff` | Four comment and import-order edits made after the wave started. The wave's bundle, rebuilt from the sources before them, reproduces its hash; against the final bundle only four error-message line numbers in `Boundary.Flow` differ. |
| `before-checkpoint.tar.gz` | The Order G checkpoint's report, coverage file and 428 traces, from the starting commit, which the final wave replaces. |
| `record.sh`, `checks.jsonl` | The script that ran each final check, and each check's command, UTC start and end, exit code and log. |

The canonical report, coverage file and traces under `parity/system` are this
task's final wave.
