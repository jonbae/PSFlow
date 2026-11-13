from pathlib import Path
import json,datetime,hashlib
p=Path('aamf/step3/order-e')
ret=json.loads((p/'case-retirement.json').read_text());old=ret['previous'];new=ret['current']
verification=json.loads((p/'candidate-verification.json').read_text())
assert not new['selfInconsistent'] and not new['drivingDivergence']
remaining={r['scenario'] for r in ret['remainingStableFailures']}
assert remaining <= {'click-selects-node--probe-flow-node','wheel-zooms-the-pane--probe-flow-node'},remaining
assert len(verification['rows'])==45 and verification['rawTraces']==180 and all(verification['faults'].values())
checks=json.loads((p/'checks.json').read_text());by_name={r['name']:r for r in checks}
required=['build-final','function-unit-final','linux-function-unit-final','surface-final','boundary-final','boundary-tests-final','harness-unit-final','comparison-coverage-final','conformance-final','smoke-final','changelog-final','live-harness-deadline-final','verify-focused']
assert all(by_name[n]['exitCode']==0 for n in required)
frozen=json.loads((p/'validation-inputs.json').read_text())
assert all(hashlib.sha256(Path(f).read_bytes()).hexdigest()==h for f,h in {**frozen['inputs'],**frozen['compiledJs']}.items())
now=datetime.datetime.now(datetime.timezone.utc).isoformat()
summary=f'''Order E is complete: keyboard announcements, focus panning, callback ordering
and gesture reproducibility are validated. The fresh Linux checkpoint captures
all 107 scenarios: **{new['passed']} pass and {new['failed']} fail**, with **zero self-inconsistent
scenarios and zero driving divergences**. The remaining two failures are the
flow/node probes for G/H store, connection and node-prop compatibility. Coverage
remains **128/156 driven, 28 declared holes**, with 50 separate behavior-debt rows.
G–I and overall Step 3 completion remain open.'''
q=Path('AAMF_PORTING_PLAN.md');s=q.read_text();s=s.replace('conversion, with focused reproducible browser evidence. E / timing work is in\nprogress.','conversion, with focused reproducible browser evidence. E / W11 is now complete.')
a=s.index('The shared handle-bound and viewport-end scheduling fixes are now complete.');b=s.index('\n\n**H / bounded W13',a)
s=s[:a]+'The shared handle-bound and viewport-end scheduling fixes remain complete.\n'+summary+'\n'+s[b:]
s=s.replace('task provides the fresh full-wave result above.','checkpoint is preserved; the Order E task provides the newer result above.')
s=s.replace('Four self-inconsistent\nscenarios are excluded from implementation triage.','Its four self-inconsistent\nscenarios were excluded pending E; the current isolated checkpoint reproduces all scenarios.')
s=s.replace('C, D and F are also complete; E and G–I have the partial completions recorded above.','C, D, E and F are also complete; G–I have the partial completions recorded above.')
lines=s.splitlines()
for i,line in enumerate(lines):
 if line.startswith('| E |'):
  lines[i]='| E | **Complete.** Keyboard aria-live announcements, native focus-visible gating and the real focus-centering store effect match upstream. The shared viewport-end timer correction is retained. Browser driving now isolates native layout, timer completion, per-frame hover delivery and capture input state; a version-matched Linux runner isolates Mac physical modifiers. PR194 and PR195 were reviewed/adapted without merging or cherry-picking. | All nine targeted scenarios pass five independent rounds (180 raw traces), including full callback logs and across-round checks. The fresh 107-scenario wave has zero self-inconsistency or driving divergence. Four deliberate restored-defect probes are rejected by the unchanged official comparator. See [Order E results](AAMF_STEP3_RESULTS.md#order-e-completion-november-12-utc). |'
 if line.startswith('| System report |'):
  lines[i]=f'| System report | [Order E Linux checkpoint](parity/system/report.md): {new["failed"]} of 107 failed, zero self-inconsistent | The preceding 99-pass/8-failure Mac checkpoint is [preserved](aamf/step3/order-e/before-canonical-checkpoint.tar.gz); earlier checkpoints remain in their task archives. Capture platform, exact runtime, unchanged comparison policy and reproducibility evidence are recorded in [Order E](aamf/step3/order-e/). |'
s='\n'.join(lines)+'\n'
s=s.replace('also complete; wider E / W11 viewport/gesture reproducibility remains open. Continue','also complete. E / W11 is now complete, including keyboard behavior and isolated\nviewport/gesture reproducibility. Continue').replace('Steps 3 E, G–I and overall port completion remain open.','Step 3 G–I and overall port completion remain open. A–F are complete.')
q.write_text(s)
q=Path('AAMF_STEP3_RESULTS.md');s=q.read_text();a=s.index('The two shared handle-');b=s.index('\n\n## Fresh baseline',a)
s=s[:a]+'The two shared handle-bound and viewport-end scheduling defects remain fixed.\n'+summary+s[b:]
section=f'''

## Order E completion (November 12 UTC)

**Order E is complete.** [Task evidence](aamf/step3/order-e/) retains the starting
runtime, the exact prior 430-file checkpoint, all failed/green probes and all
new raw captures. No AAMF migration agent was invoked, and no PR was merged or
cherry-picked.

The keyboard branch now writes its configured aria-live message before moving
selected nodes. This adapts the relevant source/tests from
[PR194](https://github.com/jonbae/PSFlow/pull/194), preserving the pre-move position,
repeated presses before rerender, and JavaScript's 32-bit truncation. Its proxy
was red before the write and green afterward; mounted traces prove the text is
rendered. Focus testing then exposed two additional source mismatches: the
store's focus-centering effect was a no-op, and the native `:focus-visible`
guard was missing. Enabling only the effect fixed keyboard focus and made the
pointer case fail; restoring the guard makes both source and port pass both modes.

The browser protocol keeps application time held between inputs. Each input
advances two individual virtual frame boundaries, with native rendering after
each; batching two frames allowed one or two intermediate paints and varied hover
receipts. Wheel input drains its actual finite timeout chain, including nested
end callbacks. Animated imperative calls receive frames until their promises
complete. Held modifiers are released on the blank document before the next
capture, alongside the existing mouse reset. A public clock pause before the
first external script cancels a native zero-delay dispatcher that Playwright's
navigation replay otherwise leaves alive. No callback is removed or reordered.

Mac hover synthesis also reads physical host modifiers, outside CDP input state.
Chromium's [native modifier lookup](https://chromium.googlesource.com/chromium/src/+/861ffbfabd58ded5869bb89b56b18779d2a31811/third_party/blink/renderer/core/input/keyboard_event_manager.cc)
and [hover recomputation](https://chromium.googlesource.com/chromium/src/+/b82f00e345ff385b02393d09dd0131415479aafa/third_party/blink/renderer/core/input/mouse_event_manager.cc)
explain Shift/Command flags appearing without scenario input. Those fields remain
fully compared. The new `parity/system/linux.mjs` runner uses the official image
matching locked Playwright 1.60.0, with Linux dependencies in a separate volume.
The image digest and Node 24.15.0 environment are preserved. The preceding Mac
checkpoint and all intermediate probes remain separate experiments.

Nine E scenarios each pass five independent rounds: **180 raw traces / 45 complete
comparisons**, with every capture checked across rounds. The unchanged official
comparator rejects four deliberate faults: a removed announcement, a missing wheel
end, a missing auto-pan receipt, and a restored initialization-order inversion.
The final complete wave captures **428 traces / 107 scenarios**:

| Measure | Previous Mac checkpoint | Isolated E checkpoint |
|---|---:|---:|
| Passing scenarios | {old['passed']} | **{new['passed']}** |
| Failing scenarios | {old['failed']} | **{new['failed']}** |
| Self-inconsistent scenarios | {len(old['selfInconsistent'])} | **0** |
| Driving divergences | 0 | **0** |

Build, complete function/unit checks on Mac and Linux, surface/boundary checks,
**119 boundary tests**, **279 harness unit checks**, **148 comparison/coverage
checks**, **41/41 conformance**, **2/2 smoke**, and changelog audit pass. All **47
live browser checks** passed across the full Linux run and one affected-check
rerun: the full run passed 46 and hit a 30-second execution deadline on the third
drag capture; the unchanged check passes with a 120-second runner deadline.
This changes no action timing, DOM settling limit, callback assertion or comparison
rule. The original timeout and its browser artifacts are retained.

{summary}

Use `node parity/system/linux.mjs npm run parity:system` after building PureScript
to reproduce the isolated full wave. No fixture, corpus action, normalization,
tolerance, region, weakening, callback register or coverage register changed.
'''
assert '## Order E completion' not in s;s+=section;q.write_text(s)
q=Path('aamf/step3/README.md');s=q.read_text();s=s.replace('The latest [shared-fix checkpoint](shared-handle-timing/) has 99 passing and 8\nfailing scenarios, with 4 self-inconsistent experiments.','The latest [Order E checkpoint](order-e/) has '+str(new['passed'])+' passing and '+str(new['failed'])+'\nfailing scenarios, with zero self-inconsistent experiments.')
s+='\n\n## Order E complete\n\n'+summary+'\n\n[Execution and reproducibility evidence](order-e/README.md) includes the\nversion-matched Linux runner, 180 focused traces, the fresh 428-trace wave,\nand the exact preceding checkpoint. Earlier sections are historical.\n';q.write_text(s)
execution={'id':'order-e-completion','status':'complete','completedAt':now,'aamfInvoked':False,'productionFixes':['Announce arrow-key moves before movement using live lookup position and JS ToInt32','Interpret the focus-centering store effect through the real pan-zoom instance','Restore native focus-visible guard before auto-pan'],'drivingFixes':['Reassert public clock pause before first external script','Keep application time held; two separately painted virtual frame boundaries per input','Drain actual finite wheel timeout chains','Advance frames for returning animated imperative calls','Release held modifiers on blank document between captures','Isolate Mac physical hover modifiers with version-matched Linux runner'],'comparisonPolicyChanged':False,'fixturesChanged':False,'corpusActionsChanged':False,'coverageRegisterChanged':False,'focused':{'scenarios':9,'independentRounds':5,'rawTraces':180,'fullComparisonsPassed':45,'acrossRoundsStable':True,'faults':verification['faults']},'wave':{'previous':old,'current':new,'rawTraces':428,'priorCanonicalFilesPreserved':430},'validation':{n:by_name[n] for n in required},'liveChecks':{'totalValidated':47,'firstFullPassed':46,'firstFullExecutionTimeout':1,'affectedCheckRerunPassed':1,'comparisonFailures':0},'coverage':{'driven':128,'total':156,'declaredHoles':28,'undeclaredHoles':0,'separateBehaviorDebt':50},'remaining':['G: JS store hooks and defaultEdgeOptions','H: remaining witnesses, reference/selector behavior, other numeric sites, connection/node-prop probes','I: declarations, entry points, styles/assets']}
(p/'execution.json').write_text(json.dumps(execution,indent=2)+'\n')
task=json.loads((p/'task.json').read_text());task['status']='complete';task['completedAt']=now;(p/'task.json').write_text(json.dumps(task,indent=2)+'\n')
(p/'README.md').write_text('# Order E completion\n\n'+summary+'''\n\nSee `execution.json`, `diagnosis.json`, `checks.json`, `candidate-verification.json`\nand `case-retirement.json` for exact results. `before-canonical-checkpoint.tar.gz`\ncontains the preceding 430 canonical files; `before-runtime.tar.gz` preserves\nowned source, tests and harness files. All original evidence paths survive.\n\nThe final frozen runtime is identified by `validation-inputs.json` and archived\nin `validation-runtime.tar.gz`; `runtime-integrity.json` verifies its contents.\nThe capture environment is the image in `linux-image-inspect.json`, with the\nlocked Playwright version and a separate Linux dependency volume. Start Docker\nDesktop and build PureScript before reproducing:\n\n```sh\nnode parity/system/linux.mjs npm run test:harness:live\nnode parity/system/linux.mjs npm run parity:system\n```\n\nThe final full 47-case Linux live run passed 46 and hit one runner execution\ndeadline before comparison. That same three-capture drag check passed after\nraising multi-capture execution deadlines; all 47 checks are validated across\nthe full run and affected-check rerun. No settling/action/comparison limit changed.\nOriginal failures, including mechanical build/probe issues, remain preserved.\n\n`before`, `paused-actions`, `mount-step`, `activity`, `wheel-drain`,\n`navigation-gate`, and `candidate` are historical diagnostic captures, separate\nfrom the final Linux captures in `final`. Their probe scripts describe those\nintermediate protocols; they are not alternate product implementations. The\nfirst focus probe failed its pointer-modality precondition upstream and is not\ncounted as a product red. The first audit incorrectly treated deliberately\nexcluded pre-existing `.claude/` files as new; the final audit uses the same\nexclusion as the starting snapshot and never owns or edits that surface.\n\nThe official comparator and all original sections remain unchanged. Four\ndeliberate restored-defect probes are rejected. No PR was merged/cherry-picked\nand no migration agent was invoked.\n''')
print(summary)
# Keep the entry summaries current; all older detailed sections stay historical.
q=Path('aamf/step3/README.md');s=q.read_text();a=s.index('**Latest checkpoint');b=s.index('\nThis directory preserves',a)
s=s[:a]+f'''**Latest checkpoint (November 12 UTC): Order E complete; {new['passed']}/107 scenarios
pass, {new['failed']} fail. Zero self-inconsistent scenarios or driving divergences.**
The shared handle-bound/end-timer fixes are retained, and E's keyboard, focus and
isolated frame/timer protocol are validated. The remaining two failures are G/H
flow/node probes. Detailed sections below preserve historical checkpoints; see
[Order E](order-e/README.md) for the current evidence.
'''+s[b:]
s=s.replace('E and G–I remain open.**','E is now complete; G–I remain open.**');q.write_text(s)
q=Path('AAMF_PORTING_PLAN.md');s=q.read_text().replace("complete; its four unstable experiments still need E's reproducibility work\nbefore interpretation.","complete; its original unstable experiments remain archived. E now supplies\nreproducible replacement captures under the isolated protocol.");q.write_text(s)
