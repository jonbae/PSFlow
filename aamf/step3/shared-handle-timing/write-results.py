from pathlib import Path
import json,datetime
p=Path('aamf/step3/shared-handle-timing');ret=json.loads((p/'case-retirement.json').read_text());old=ret['previous'];new=ret['current'];checks=json.loads((p/'checks.json').read_text())
for name in ['build-end-timing','surface','function-and-unit','boundary','boundary-tests','driver','verify-candidates','conformance','smoke','changelog']:
 assert any(c['name']==name and c['exitCode']==0 for c in checks),name
assert (new['passed'],new['failed'],new['handleDifferences'],new['initialMeasurementOrderScenarios'])==(99,8,0,0)
now=datetime.datetime.now(datetime.timezone.utc).isoformat()
task=json.loads((p/'task.json').read_text());task['status']='complete (two shared production defects); broader Step3 remains open';task['completedAt']=now
(p/'task.json').write_text(json.dumps(task,indent=2)+'\n')
execution={'status':task['status'],'completedAt':now,'aamfInvoked':False,'productionChanges':{'handleBounds':'Optional measured sides survive storage and JS conversion as null; explicit handles retain arrays; strict/loose readers preserve upstream empty-side behavior. Relevant PR195 changes adapted without merging/cherry-picking stacked commits.','endHandler':'Always clear prior end timer and queue a new one: 0 ms normally, 150 ms for scrolling. No callback sorting/suppression or fit-view/React scheduling change.'},'redEvidence':['red-handles.log','red-end-timing.log'],'greenEvidence':['green-handles.log','green-end-timing.log','verify-candidates.log'],'mechanismTests':{'handleChecks':9,'nativeEndTiming':'Native task/microtask order, real d3 transform/measurement order, both timer cancellation paths and original event identity, compared with pinned executing source.'},'candidateCaptures':{'rawTraces':24,'scenarios':3,'roundsPerScenario':2,'allFullComparisonsPass':True,'bothSidesAgreeAcrossRounds':True,'handleAndOrderFaultsRejectedByOfficialComparator':True},'fullWave':{'previous':old,'current':new,'fewerFailedScenarios':old['failed']-new['failed'],'rawTraces':428,'canonicalPriorArchiveFiles':430,'comparisonPolicyChanged':False,'fixturesChanged':False,'coverageRegisterChanged':False},'controlledOrderFollowup':{'rawTraces':12,'independentRounds':3,'upstreamMeasurementBeforeEnd':2,'upstreamEndBeforeMeasurement':4,'psflowMeasurementBeforeEnd':5,'psflowEndBeforeMeasurement':1,'upstreamUnstablePairs':2,'psflowUnstablePairs':1,'conclusion':'Full-wave pair agreement did not establish a deterministic source order. Independent unchanged upstream produces both orders. The canonical full-wave failure remains recorded; wider controlled-viewport reproducibility remains open.'},'checks':{'build':'pass','surface':'pass','functionAndUnit':'pass','boundary':'pass','boundaryTests':119,'driver':'pass','conformance':{'passed':41,'failed':0},'smoke':{'passed':2,'failed':0},'changelog':'pass','fullSystem':{'passed':99,'failed':8}},'coverage':{'driven':128,'exportBearing':156,'declaredHoles':28,'undeclaredHoles':0,'separateBehaviorDebt':50},'remaining':['Keyboard aria-live announcement','JS store hooks plus useConnection/node-prop probe differences','Controlled-viewport order reproducibility','Full-wave four unstable scenarios','Remaining Step3 G/H/I contracts and witnesses']}
(p/'execution.json').write_text(json.dumps(execution,indent=2)+'\n')
q=Path('AAMF_PORTING_PLAN.md');s=q.read_text().replace('**Step 3 is in progress, updated 2026-11-11.**','**Step 3 is in progress, updated 2026-11-12 UTC.**',1)
a=s.index('The final native-frame checkpoint captures all 107 scenarios:');b=s.index('\n\n**H / bounded W13',a)
s=s[:a]+'''The shared handle-bound and viewport-end scheduling fixes are now complete.
The fresh full wave captures all 107 scenarios: **99 pass and 8 fail**, with
**4 self-inconsistent** experiments and no driving divergence. Reproducible
handle-bound differences fall from 100 across 82 scenarios to zero; the 71
shared initial callback-order inversions also fall to zero. One controlled-
viewport order row remains in the full wave; independent repeats show both
orders in unchanged upstream as well as PSFlow. Coverage remains **128/156
with 28 declared holes**. Wider E reproducibility, G store/default-edge
compatibility, H's other witnesses and I distribution remain open.
''' +s[b:]
s=s.replace('| System report | [Fresh native-frame checkpoint](parity/system/report.md): 95 of 107 scenarios failed, 5 self-inconsistent | Cluster only reproducible observations. The previous initialization-observation checkpoint is', '| System report | [Fresh shared-fix checkpoint](parity/system/report.md): 8 of 107 scenarios failed, 4 self-inconsistent | The preceding 95-failure checkpoint is [preserved](aamf/step3/shared-handle-timing/before-canonical-checkpoint.tar.gz). Cluster only reproducible observations. The earlier initialization-observation checkpoint is')
s=s.replace('The final full wave has 5 unstable scenarios; bounded initialization/native-frame driving is implemented and all 25 live harness checks pass.', 'The current full wave has four self-inconsistent scenarios; independent controlled-viewport repeats also vary. The shared end-handler timer is fixed. The earlier initialization/native-frame checkpoint passed all 25 live harness checks.')
q.write_text(s)
q=Path('AAMF_STEP3_RESULTS.md');s=q.read_text().replace('**Step 3 is in progress, updated 2026-11-11.**','**Step 3 is in progress, updated 2026-11-12 UTC.**',1)
s=s.replace('geometry/resize numeric correction is also implemented. The last complete\nfull-net checkpoint has **95/107 failed** scenarios and **5 self-inconsistent** experiments.', 'geometry/resize numeric correction is also implemented. The two shared handle-\nbound and viewport-end scheduling defects are fixed. The fresh complete\nfull-net checkpoint has **99 passed / 8 failed** scenarios and **4 self-inconsistent** experiments.')
s+='''

## Shared handle bounds and viewport-end scheduling (November 12 UTC)

Both shared production defects identified in the preceding recount are fixed.
The [task evidence](aamf/step3/shared-handle-timing/) preserves the starting
source, red/green regressions, all raw captures and the exact prior checkpoint.
No AAMF migration agent was invoked; this is the reviewed PSFlow workflow.

The shared `NodeHandleBounds` model now preserves a missing measured side as
`Nothing`, which crosses as `null`. Explicit user-defined handles still give
both arrays, including empty arrays. Strict and loose handle readers fold
missing sides as upstream does. This adapts only the relevant source/tests from
[PR195](https://github.com/jonbae/PSFlow/pull/195), which remains open. Its stacked
keyboard changes were not applied and no PR was merged or cherry-picked.
Nine measurement/conversion/handle-resolution checks were red before the fix
and are now green.

The end handler now always uses upstream's timer, with delay zero normally and
150 ms when scrolling. It cancels a previous pending end on either path. The
old inline non-scroll call caused viewport completion to precede the measurement
callback. The new regression executes the pinned upstream handler alongside the
port on native task/microtask queues and through real d3 transforms. Both timer
paths preserve cancellation and original event identity. The old dispatch test
keeps source-event coverage on separate turns; the new differential explicitly
checks same-turn coalescing. No fit-view/store/React scheduling change was made.

Three mounted scenarios isolate handle-only, order-only and combined failures.
Both independent rounds pass the full unmodified comparator and reproduce
across rounds: **24 raw focused traces**, six passing complete comparisons.
Restoring `[]` for a null side or restoring the old callback order in copied
traces makes that same official comparator fail.

The new full wave captures **428 raw traces / 107 scenarios**:

| Measure | Previous checkpoint | Shared-fix checkpoint |
|---|---:|---:|
| Passing scenarios | 12 | **99** |
| Failing scenarios | 95 | **8** |
| Self-inconsistent scenarios | 5 | 4 |
| Reproducible failed scenarios within this wave | 90 | 4 |
| Scenarios with reproducible handle-bound differences | 82 | **0** |
| Reproducible handle-bound difference rows | 100 | **0** |
| Scenarios with callback-order differences | 72 | 1 |
| Shared initial measurement/end inversions | 71 | **0** |

There are **87 fewer failing scenarios**. The one remaining callback-order row
is `pan-after-controlled-viewport-change`, previously self-inconsistent. Its
full-wave pair happened to agree, but three independent follow-up rounds show
both orders in unchanged upstream: measurement first in two captures and end
first in four. PSFlow also produces both orders. Two upstream pairs and one
PSFlow pair are self-inconsistent. All **12 follow-up raw traces** are retained;
this does not replace or relabel the full-wave result. Wider E reproducibility
work remains open.

The full wave's other three reproducible failures are the keyboard aria-live
announcement and the two flow/node probes (store-hook refusals, connection and
node-prop differences). Its four self-inconsistent scenarios are
`drag-node-autopan`, `wheel-zoom-from-identity-viewport`,
`drag-node-reports-changes` and `ctrl-wheel-pinches-with-panonscroll`. The latter
varies upstream on the presence of an end callback. Cross-side findings from
unstable experiments remain excluded from implementation triage.

Build, surface parity, full function/unit tests, boundary checks, **119 boundary
tests**, **41/41 conformance**, **2/2 smoke** and changelog audit pass. Coverage is
unchanged: **128/156 driven, 28 declared holes, zero undeclared**, with 50 separate
behavior-debt rows. No comparator, normalization, tolerance, callback register,
fixture or coverage register was changed. The old 430-file canonical checkpoint
is preserved in `before-canonical-checkpoint.tar.gz`; the source/runtime hashes
identify the new experiment precisely.
'''
q.write_text(s)
q=Path('aamf/step3/README.md');s=q.read_text();s+='''

## Shared handle bounds and viewport-end scheduling

`shared-handle-timing/` records the two shared production fixes, adapted PR195
source patches, native timing regression and comparison against executing
pinned source. Nine handle checks pass. Zero/150 ms end scheduling and
cancellation match source, including real d3 transforms and event identity.
All six full comparisons of the three focused scenarios pass across independent
rounds, and both restored-defect faults are rejected by the official comparator.

The fresh full checkpoint is **99 passed / 8 failed** over 107 scenarios, down
from 95 failed. Reproducible handle-bound differences and the 71 shared initial
callback inversions are gone. One controlled-viewport order row remains; its
12 independent follow-up traces prove unchanged upstream produces both orders.
The full wave still records its original failure. Four full-wave scenarios are
self-inconsistent; broader timing, keyboard, store/probe and Step3 G/H/I work
remains open. Coverage stays at 128/156 driven and 28 holes.

The old 430 canonical files are preserved and hash-verified in
`before-canonical-checkpoint.tar.gz`. `validation-inputs.json` freezes the source,
apparatus and compiled code before captures; `validation-outputs.json` identifies
the final canonical outputs. The runtime archive and integrity/audit metadata
preserve this new checkpoint. Build/surface/function/boundary, 119 boundary
checks, 41 conformance, two smoke and changelog validation pass. See
[execution.json](shared-handle-timing/execution.json) and its exact command
receipts. No policy/register/fixture change or AAMF migration-agent run occurred.
''';q.write_text(s)
q=p/'README.md';s=q.read_text();s+='''
The complete wave now passes 99/107 scenarios, with eight failures (four
self-inconsistent). This is 87 fewer failed scenarios than the preserved
95-failure checkpoint. Reproducible handle rows and the 71 initial ordering
inversions are zero. The one remaining controlled-viewport order row produces
both orders in unchanged upstream across the 12 independent follow-up captures;
its full-wave failure remains recorded. All 41 conformance and two smoke tests
pass, as do build/surface/function/boundary, 119 boundary checks and changelog.
`case-retirement.json` and `controlled-order-diagnosis.json` give exact details.
''';q.write_text(s)
print('Recorded both shared fixes and the full 99-pass/8-failure checkpoint')
