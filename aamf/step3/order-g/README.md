# Order G evidence

Order G closes the JavaScript compatibility gaps that Step 3 named: the store
hooks that threw, the thirteen refused `defaultEdgeOptions` members, and the
edge and node members those depend on. See
[the results](../../../AAMF_STEP3_RESULTS.md#order-g-completion-november-12-utc)
for what changed and what is excluded.

The starting commit is `5766fbb1` (`step 3 A-F`). Every run used Node 22.18.0,
PureScript 0.15.16 and Spago 1.0.4 on the host, and the Linux runner's locked
Playwright 1.60.0 image for browser checks.

## Files

| File | What it records |
|---|---|
| `red-js-entry-at-head.log` | The two new JS-entry test files, as they stood before the falsy-label case was added, run against the starting commit's build: 17 of 18 checks fail. The per-edge marker check already passed and stays as a guard. |
| `store-tests.log`, `edge-fields-tests.log` | The same files passing against this build. |
| `spago-test.log` | The full PureScript suite, including `Test.Boundary.DefaultEdgeOptions`. |
| `boundary.log`, `boundary-tests.log` | `npm run parity:boundary` and `npm run test:boundary`. |
| `build.log`, `oracle.log`, `driver.log` | The PureScript build and the two rebuilt bundles the browser checks load. |
| `surface.log`, `test-*.log` | Surface parity, and the surface, harness, comparison, coverage and census suites. |
| `fork.log`, `changelog.log` | The fork register and changelog audit. |
| `conformance.log`, `smoke.log` | The browser suites in the Linux runner. |
| `probe-wheel-report.md`, `probe-click-report.md` and their logs | The two flow-probe scenarios after the store crossed, before the full wave. |
| `first-wave-report.md`, `first-wave-coverage.md`, `first-wave.log` | A full Linux net before the falsy-label fix: 105/107 pass, the same two probes fail. Kept as its own experiment. |
| `system.log`, `wave-summary.json` | The final full Linux net from this task's final code, and its per-scenario outcome. |
| `before-checkpoint.tar.gz` | The Order E checkpoint's report, coverage file and 428 traces, from the starting commit, which the final wave replaces. |
| `checks.jsonl` | Each final command, its UTC start and end, its exit code and its log. |

The canonical report, coverage file and traces under `parity/system` are this
task's full wave.
