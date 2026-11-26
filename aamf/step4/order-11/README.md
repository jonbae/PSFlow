# Step 4, order 11: current reconciliation

**Complete, 2026-11-16 UTC.** All 171 certified upstream units have current
dispositions and evidence: **170 Reuse, 1 Accepted difference**, with zero
Add evidence, Fix behavior or Finish conversion rows. All 18 profiles were
reviewed against Steps 3 and 4 through order 10, at PSFlow
`ad56dd3d27a06e54e26f235abda9c1466876c67c`. The upstream baseline remains
React 12.11.0 / system 0.0.77.

The two outputs are the [unit/profile map](../../../AAMF_STEP2_MAPPING.md)
and [current JSON review](../../step2/reconciliation.json).
[profiles.json](profiles.json) is the reviewed input: each profile names its
completed work and the evidence that replaced its original gap labels.
Reuse means retain the implementation with that evidence; it does not claim
exhaustive equivalence of every branch.

## What changed

| Disposition | Step 2 input | Current review |
|---|---:|---:|
| Reuse | 42 | 170 |
| Add evidence | 99 | 0 |
| Fix behavior | 25 | 0 |
| Finish conversion | 4 | 0 |
| Accepted difference | 1 | 1 |

The source hashes, symbols, accounting, import consumers, caller observations
and primary PureScript destinations are retained. Current store/flow-member
converter modules are added to the relevant units, and paired and directly
imported FFI context is recomputed from current module imports. All source
and target paths are checked. The old symbol-call appendix stays explicitly
partial diagnostic context; the certified import audit remains separate.

The CSS/SVG ambient declarations in `react/src/custom.d.ts` retain D02's
precise exclusion: no runtime PureScript body is needed. This does not accept
different DOM or styles; Order I's package supplies upstream's stylesheets
and reachable declarations.

## Existing limits and separately owned work

Issues [207](https://github.com/jonbae/PSFlow/issues/207) (an extra custom-node
render at mount) and [208](https://github.com/jonbae/PSFlow/issues/208)
(a render after in-place selection) remain open work in the recorded review.
The JSON lists both and marks the affected units with `knownIssues`.
Four browser contract cases hold issue 207's exact difference and fail as
stale once fixed. This refresh neither accepts nor closes either difference.

The existing compatibility scope remains explicit: the store's residual write
differences, the React peer range, the styles warning, and the permanent
surface-shape exceptions. The JSON points to their existing contracts,
including [distribution/gaps.mjs](../../../distribution/gaps.mjs). The
recorded review also listed four store write exclusions; the later JavaScript
store compatibility work retires them, and the declarations name what still
differs. It also listed default-edge keys outside the declared type, custom
keys on internally rebuilt uncontrolled nodes, and module formats. The
default-edge follow-up merges every key, the uncontrolled-node follow-up keeps
the consumer's fields on rebuilt nodes, and the UMD build serves CommonJS, AMD
and classic scripts, so all three exclusions retire and the JSON no longer
lists them.
The recorded review had one declared coverage hole,
`UnselectNodesAndEdgesParams`. The subsequent store-action witness retires it
through `api.storeCalls` and four `store-unselect-*` scenarios; the current
[coverage report](../../../parity/system/coverage.md) records 156 of 156 driven.
No new exclusion, region or allowlist is introduced.

## Historical pilot preservation

The original `aamf/step2/reconciliation.json` is preserved byte for byte as
[pilot-reconciliation.json](../../step2/pilot-reconciliation.json), with its
original SHA-256:

```text
c3f6e1349865e8289755a588a8b5f5e6a0b4f371f48d28e0b7a2a24c649c1539
```

The Step 2 checksum manifest follows that rename; only its README's checksum
is refreshed for the artifact guide update. The checkpoint, runtime archive,
selected runtime graph and logs are unchanged. The inspector now copies the
pilot input under its archival name, preventing a later historical audit from
overwriting the current map.

The current map is **version 2, review-only, with zero tasks**. The Step 2
adapter accepts only version 1, so the current review cannot accidentally
queue or resume W01. Its `psflowCommit`, runtime hashes and evidence hashes
describe the new review. The historical pilot keeps its original revision,
task, target snapshot and mapping digest. No AAMF agent or migration phase
was run for this refresh.

## Regeneration and verification

Run from the repository root with Node 22:

```sh
node tools/aamf/refresh-reconciliation.mjs
node tools/aamf/refresh-reconciliation.mjs --check
node --test tools/aamf/reconciliation.test.mjs
(cd aamf/step2 && shasum -a 256 -c SHA256SUMS)
```

The script validates all inputs before writing either output. It rejects
scope loss, stale source hashes, changed package pins, mismatched import
consumers, missing PureScript destinations, broken evidence paths/anchors,
unknown unit overrides and unowned pending dispositions. Check mode also
compares both generated outputs, the complete runtime and the evidence hashes.
The reviewed code revision must be an ancestor of the checkout.

The five fault-injection tests verify stable regeneration and rejection of
missing units, changed source, unowned conversion work, broken evidence
anchors, runtime/evidence drift, stale output, queued tasks, changed pilot
input and changed Markdown ownership. They also prove the current map is
rejected by the actual Step 2 runtime validator. All pass.

Checks run for this order with Node 22.18.0, PureScript 0.15.16 and Spago 1.0.4:

| Check | Result |
|---|---|
| Refresh, `--check`, repeated generation | 171 units, 18 profiles, zero tasks; 240 runtime and 63 evidence file hashes |
| `node --test tools/aamf/reconciliation.test.mjs` | 5/5 pass, including the rejection cases above |
| Step 2 `SHA256SUMS` | Every entry passes; original pilot bytes also match the pre-refresh Git blob |
| `spago build`, `npm run build:oracle` | Passed; build has zero warnings/errors; oracle bytes unchanged (esbuild reports the existing missing vendored tsconfig bases) |
| `npm run parity:surface`, then `spago test` | Passed from fresh output; stage 5, 68 crossed and zero passthroughs |
| `npm run parity:fork` | Passed; 54 source units affirmed |
| `git diff --check`, runtime/oracle/parity diff | Passed; no changes to those artifacts |

This task changes reconciliation data, its script/tests and documentation.
It does not change the runtime, package, oracle, corpus, traces or comparison
policy. The recorded Order 10 checkpoint remains 153/153 system scenarios,
155/156 driven exports and one declared hole; this task does not claim a new
browser capture. Step 4 order 12, the procedure for the next baseline, remains
open.
