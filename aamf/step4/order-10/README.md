# Step 4, order 10: type contract evidence

**Complete, 2026-11-16 UTC.** The review is
[`AAMF_TYPE_CONTRACT_REVIEW.md`](../../../AAMF_TYPE_CONTRACT_REVIEW.md). Every
member of the 14 E02 units has a reviewed disposition, and every guard,
default and absence branch a JavaScript consumer reaches is compared with
upstream. The comparison found 20 gaps, G1 to G20, fixed in 21 commits. Two
older differences that aren't type contracts are filed as issues.

The starting point is PSFlow commit `14338761`, the merge of Step 4 row 9's
caller fixes, against the fixed `@xyflow/react` 12.11.0 and `@xyflow/system`
0.0.77 baseline. This task uses PSFlow's own gates with the AAMF inventory as
context; it does not run an autonomous AAMF migration.

## The two contract suites

| Suite | What it runs | Starting commit | Final |
|---|---|---|---|
| [`chrome-contracts.test.mjs`](../../../parity/boundary/chrome-contracts.test.mjs) | A server render of each chrome component's and `<Handle />`'s markup, one value of one field per case | 119 of 307 differ | 317 of 317 pass |
| [`flow-contracts.test.mjs`](../../../parity/boundary/flow-contracts.test.mjs) | `<ReactFlow />` in Chromium through [`browser/harness.mjs`](../../../parity/boundary/browser/harness.mjs), one page per side; state, lookups, DOM, callbacks and console after mount and after driving | 52 of 442 differ | 456 of 456 pass, four as a known difference |

The starting results are the cases as first committed, run at that commit:
[`chrome-contracts-before.txt`](chrome-contracts-before.txt) and
[`flow-contracts-before.txt`](flow-contracts-before.txt). The final results
are [`chrome-contracts-after.txt`](chrome-contracts-after.txt) and
[`flow-contracts-after.txt`](flow-contracts-after.txt). Cases added while
fixing a gap, such as `NaN` sizes, the `ControlButton` click, the `Handle`
press and the minimap gestures, were each run red before their fix.

### What keeps a green run honest

- The browser suite's falsification case mounts different props on the two
  sides, and the test requires its results to differ.
- The harness refuses a bundle whose provenance is wrong: the ps-flow page
  must contain `output/Boundary/`, and the upstream page must not.
- Each case compares everything a consumer reads back, whole: no member of the
  state, no lookup entry, no DOM attribute and no console line is filtered.
  The only normalizations are the net's own: class tokens and style
  declarations sorted, attributes compared as a set, and a DOM event's
  `timeStamp` deleted.
- The four `useHandleConnections` cases are held to one stated difference,
  owned by [an issue](https://github.com/jonbae/PSFlow/issues/207), and fail
  as stale once it goes.

### Sampling in the browser

Two first drafts of cases read a value mid-animation, and both were changed
rather than tolerated. d3's double-click zoom is a transition, so that case
waits 600 ms before it reads. Auto-pan moves the viewport each frame while a
held connection is near the edge, so the held-connection cases turn
`autoPanOnConnect` off and release the connection after reading. Repeated runs
of each match.

## The change shapes

[`change-shapes-probe.mjs`](change-shapes-probe.mjs) calls `applyNodeChanges`
and `applyEdgeChanges` with 53 change shapes on both sides, including
fractional, negative, `NaN` and infinite `index` values, each `setAttributes`
form and each optional member left out. All 53 match, as
[its output](change-shapes-probe.txt) records, so `changes.ts` needed no new
test. Run it with `node aamf/step4/order-10/change-shapes-probe.mjs` after
`spago build`.

## Gates

Run at the final commit with PureScript 0.15.16 and Spago 1.0.4.

| Check | Result |
|---|---|
| `spago build`, `spago test` | Passed |
| `npm run parity:surface` | Passed; ps-flow publishes one more type, `MiniMapNodeAttribute` |
| `npm run parity:boundary` | Passed; the drift pairs name four new rest fields |
| `npm run test:boundary` | 1,029 of 1,029; 213 at Order I |
| `test:surface`, `test:harness`, `test:compare`, `test:coverage`, `test:census`, `test:ci`, `test:audit` | 30, 281, 109, 39, 5, 38 and 96 passed |
| `npm run build:package`, `parity:package`, `test:package` | Built; 10 of 10; 8 of 8 |
| Conformance and smoke, local | 41 of 41 and 2 of 2 |
| Linux full net, `node parity/system/linux.mjs npm run parity:system` after `npm run build:driver` | 153 of 153 scenarios pass, every side reproducing itself; coverage 155 of 156 driven, 1 declared hole. The report and coverage file are unchanged, and the only trace values that changed are 1,443 event `timeStamp`s, so the refreshed traces aren't committed |
