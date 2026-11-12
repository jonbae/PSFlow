# Order E completion

Order E is complete: keyboard announcements, focus panning, callback ordering
and gesture reproducibility are validated. The fresh Linux checkpoint captures
all 107 scenarios: **105 pass and 2 fail**, with **zero self-inconsistent
scenarios and zero driving divergences**. The remaining two failures are the
flow/node probes for G/H store, connection and node-prop compatibility. Coverage
remains **128/156 driven, 28 declared holes**, with 50 separate behavior-debt rows.
G–I and overall Step 3 completion remain open.

See `execution.json`, `diagnosis.json`, `checks.json`, `candidate-verification.json`
and `case-retirement.json` for exact results. `before-canonical-checkpoint.tar.gz`
contains the preceding 430 canonical files; `before-runtime.tar.gz` preserves
owned source, tests and harness files. All original evidence paths survive.

The final frozen runtime is identified by `validation-inputs.json` and archived
in `validation-runtime.tar.gz`; `runtime-integrity.json` verifies its contents.
The capture environment is the image in `linux-image-inspect.json`, with the
locked Playwright version and a separate Linux dependency volume. Start Docker
Desktop and build PureScript before reproducing:

```sh
node parity/system/linux.mjs npm run test:harness:live
node parity/system/linux.mjs npm run parity:system
```

The final full 47-case Linux live run passed 46 and hit one runner execution
deadline before comparison. That same three-capture drag check passed after
raising multi-capture execution deadlines; all 47 checks are validated across
the full run and affected-check rerun. No settling/action/comparison limit changed.
Original failures, including mechanical build/probe issues, remain preserved.

`before`, `paused-actions`, `mount-step`, `activity`, `wheel-drain`,
`navigation-gate`, and `candidate` are historical diagnostic captures, separate
from the final Linux captures in `final`. Their probe scripts describe those
intermediate protocols; they are not alternate product implementations. The
first focus probe failed its pointer-modality precondition upstream and is not
counted as a product red. The first audit incorrectly treated deliberately
excluded pre-existing `.claude/` files as new; the final audit uses the same
exclusion as the starting snapshot and never owns or edits that surface.

The official comparator and all original sections remain unchanged. Four
deliberate restored-defect probes are rejected. No PR was merged/cherry-picked
and no migration agent was invoked.
