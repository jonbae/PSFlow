# Bounded H/W13 numeric semantics

The task is complete for shared General geometry, resize constraints and the
controller's child-extent aggregation. Step 3 and the wider numeric audit remain
open. See `task.json`, `execution.json` and `checks.json` for exact scope and
commands. No AAMF migration agent was invoked.

Four production-path regressions were red before their corrections. The final
function/unit suite passes 15,934 exact source comparisons and 66 controller
cases. Build, surface, boundary checks, 119 boundary tests, 41 conformance tests
and two smoke tests pass. PureScript owns the numeric decisions; no production
JavaScript was added. `probe-results.json` identifies non-red diagnostic runs.

The 24 raw browser traces in `final/` are two independent rounds of three
scenarios. Resize and viewport-helper scenarios reproduce within/across rounds,
retain their exact prior full-comparator findings (two unresolved differences),
and pass the source resize-receipt witness and fault check. Wheel zoom is
upstream self-inconsistent in both rounds; its onMoveEnd receipt varies and its
cross-side findings remain excluded. The strict all-scenario verification is
red. `verify-browser-all.mjs` preserves that original strict script;
`verify-browser.mjs` also permits explicit scenario selection for the separately
named stable-scenario check. No subsequent drive replaces the failed captures.

`before-inputs.json`, `before-source.tar.gz`, `before-resizer-test.js` and
`before-SHA256SUMS` preserve the starting state and prior seal. The entire prior
canonical wave remains unchanged. `validation-inputs.json` freezes the final
runtime used for these captures and browser suites; `validation-runtime.tar.gz`
archives source/tests, compiled JS, apparatus, prior canonical traces, pinned
vendor sources, locks and stylesheet assets. `runtime-integrity.json` verifies
2,183 input hashes in that archive. `source-audit.json` checks ownership, prior
evidence, all 171 vendor hashes and the unchanged 430 canonical files.

The previous full-wave result is still 95/107 failed with five unstable
scenarios. This bounded task does not establish a new whole-corpus failure
count or change coverage (128/156 driven and 28 holes).
