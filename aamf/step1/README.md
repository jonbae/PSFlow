# Step 1 evidence — 2026-11-09

This directory preserves the completed bounded upstream inventory required by
[Step 1 of the porting plan](../../AAMF_PORTING_PLAN.md#step-1-use-aamf-for-a-bounded-upstream-inventory).
The completion checklist is in [AAMF_STEP1_RESULTS.md](../../AAMF_STEP1_RESULTS.md).

The earlier November 7 temporary workspace no longer exists. These are fresh
November 9 outputs from the same pinned source and AAMF revisions, including the
maintained Lore compatibility fixes. Their availability does not depend on
keeping `/tmp` intact.

| Artifact | Purpose |
|---|---|
| [inventory.json](inventory.json) | All 171 scoped files, hashes, symbol/reference counts, and accounting in the graph |
| [task-graph.json](task-graph.json) | Full task graph, cyclic groups, and compilation units, with portable paths |
| [dependency-summary.json](dependency-summary.json) | AAMF's dependency-summary representation |
| [index-health.json](index-health.json) | Index certification report, with portable paths |
| [imports.json](imports.json) | Independent source import/re-export resolution audit; 689 declarations, zero unresolved |
| [review.json](review.json) | Graph checks, scope counts, cycles, and limitations |
| [integrity.json](integrity.json) | Source/target before-and-after hashes and database digest |
| [execution.json](execution.json) | Exact revisions, CLI flags, timing, and exit codes |
| [compatibility-patches.json](compatibility-patches.json) | Original and patched Lore distribution hashes |
| [migrate.log](migrate.log), [status.txt](status.txt) | CLI output and completed checkpoint status |
| [tests.log](tests.log) | All 13 compatibility regression tests passing |
| [runtime.tar.gz](runtime.tar.gz) | Unmodified certified database, structured checkpoint, raw planning artifacts, full health report, and original snapshot manifests |
| [SHA256SUMS](SHA256SUMS) | Artifact checksums |

The public JSON replaces absolute source/target/workspace prefixes with
`xyflow`, `PSFlow`, and `<workspace>`. It is a portable review projection, not
runtime state. Original scope hashes still identify the original runtime paths;
the unmodified certificate and checkpoint are inside `runtime.tar.gz`. Do not
substitute the portable graph for AAMF's structured checkpoint output.

The archive omits dependencies and analysis configurations. Configurations
remain in the isolated workspace, as required by the plan. The new workspace is
`/private/tmp/psflow-aamf-step1-20261109/`, project `psflow-step1-20261109`.

With Node 22 and that workspace present, regenerate the review artifacts from
the PSFlow repository with:

```sh
node tools/aamf/inspect-step1.mjs /private/tmp/psflow-aamf-step1-20261109 aamf/step1
```

This inspector reads the successful runtime state, validates the real index,
checks the structured task output, audits source imports with the pinned SCIP
TypeScript parser, and checks source/target integrity. It neither launches a
later phase nor edits the runtime graph. The archive and checksums preserve the
completed snapshot; refreshing the JSON requires refreshing those as well.

Four duplicate-symbol groups remain warnings. Lore still has no import records:
the separate module-resolution audit does not add those edges to Lore or prove
the imported symbols' API compatibility. All generated target paths still use
`.purescript`; mapping them into existing `.purs` modules belongs to Step 2.
