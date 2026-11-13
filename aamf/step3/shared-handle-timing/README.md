# Shared handle bounds and viewport-end scheduling

User-requested resolution of the two dominant shared differences in the prior
full corpus. `task.json` records ownership and the agreed public seams;
`diagnosis.json` records hypotheses, red/green commands and findings.

The handle fix adapts only the relevant source/test changes from open PR195.
It preserves a missing measured side as null through shared types, storage and
JavaScript conversion. Explicit user handles still provide both arrays, and
strict/loose resolution folds missing sides as upstream does. No PR was merged
or cherry-picked; its stacked keyboard work is not part of this task.

The callback fix restores the source end-handler timer: zero delay normally,
150 ms while scrolling, cancellation of an earlier pending end in either case.
No fit-view promise, React effect, fixture or comparator change is needed.
A native task/microtask regression failed before the correction, then passed.
Real d3 transforms and both timer paths also agree with executing pinned source.
The old source-shape dispatch checks now separate turns because upstream
coalesces back-to-back ends; the new differential tests verify coalescing.

`candidate/` holds 24 raw captures: two independent rounds of the handle-only,
order-only and combined mount scenarios. All six full comparisons pass and
both sides reproduce across rounds. `verify-candidates.mjs` also restores each
defect in copied traces and proves the unchanged official comparator rejects it.

`before-inputs.json`, `before-source.tar.gz`, the two additional before-handler
files and `before-SHA256SUMS` preserve the exact starting state. The original
430 canonical files are archived in `before-canonical-checkpoint.tar.gz` and
must match their starting hashes. The complete new wave is captured separately
and classified against that archive by `summarize-wave.mjs`.

Build, surface, function/unit and boundary validation results are recorded in
`checks.json`. `validation-inputs.json` freezes source, apparatus and compiled
JavaScript before captures. No AAMF migration agent was invoked.

The complete wave now passes 99/107 scenarios, with eight failures (four
self-inconsistent). This is 87 fewer failed scenarios than the preserved
95-failure checkpoint. Reproducible handle rows and the 71 initial ordering
inversions are zero. The one remaining controlled-viewport order row produces
both orders in unchanged upstream across the 12 independent follow-up captures;
its full-wave failure remains recorded. All 41 conformance and two smoke tests
pass, as do build/surface/function/boundary, 119 boundary checks and changelog.
`case-retirement.json` and `controlled-order-diagnosis.json` give exact details.
