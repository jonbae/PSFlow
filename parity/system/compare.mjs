// System parity — the compare step (#40, #43).
//
//   node parity/system/compare.mjs <four traces> [options]     one whole run
//   node parity/system/compare.mjs <two traces> [options]      cross-side only
//
//     --out <path>   also write the report to a file
//     --record       write refreshed values back into the regions whose content
//                    moved, and stamp them with this run's baseline. It cannot
//                    create a region: an unclaimed difference is still unclaimed
//                    after recording, and still fails.
//
// **A run is four traces**: two sides, two captures each, in any order — they
// are grouped by the side each one records. Both sides are checked against
// themselves before the two sides are compared, because a recorded trace baseline is
// meaningless if traces are not reproducible.
//
// The two-trace form is the narrower question — these two traces, compared —
// and it is what a baseline bump asks when it re-diffs stored traces of one
// side against another baseline. It says in its own report that self-consistency
// went unchecked, because a form that quietly skipped a check is how a gate ends
// up proving less than its name.
//
// Exit codes: 0 clean, 1 differences the noise policy does not claim (a side
// that disagrees with itself, a driving divergence, an unclaimed difference, a
// region or a callback weakening gone stale), 2 the run could not be interpreted
// at all — a malformed trace, an illegal normalization rule, a region missing
// its reason, traces that are not two captures of each of two sides.

import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { TraceFormatError, readTrace } from "./trace-format.mjs";
import { WeakeningError } from "./compare/callbacks.mjs";
import { ConsistencyError } from "./compare/consistency.mjs";
import { ComparisonError, compareTraces } from "./compare/index.mjs";
import { NormalizationError } from "./compare/normalize.mjs";
import { RegionError, recordRegions } from "./compare/regions.mjs";
import { renderReport, renderRunReport } from "./compare/report.mjs";
import { RunError, compareRun } from "./compare/run.mjs";

// The ruleset and the two registers are fixed, not switchable by flag: a run
// must not be able to compare against a laxer noise policy than the committed
// one. The comparison core takes all three as arguments, so its own tests supply
// theirs directly rather than pointing this script somewhere else.
const here = dirname(fileURLToPath(import.meta.url));
const NORMALIZATION = join(here, "normalization.json");
const REGIONS = join(here, "regions.json");
const WEAKENINGS = join(here, "weakenings.json");

const readJson = (path) => JSON.parse(readFileSync(path, "utf8"));

const argv = process.argv.slice(2);
const flags = new Set(argv.filter((a) => a.startsWith("--")));
const outIndex = argv.indexOf("--out");
const out = outIndex === -1 ? null : argv[outIndex + 1];
const positional = argv.filter((a, i) => !a.startsWith("--") && !(outIndex !== -1 && i === outIndex + 1));

if (![2, 4].includes(positional.length) || (flags.has("--out") && (!out || out.startsWith("--")))) {
  console.error(
    "usage: node parity/system/compare.mjs <trace.json × 4> [--out report.md] [--record]\n" +
      "       node parity/system/compare.mjs <left.json> <right.json> [--out report.md] [--record]\n" +
      "\n" +
      "A run is two captures of each of the two sides, in any order. The two-trace form compares\n" +
      "exactly those two and does not check self-consistency."
  );
  process.exit(2);
}

// The two forms differ in one thing: whether self-consistency was checkable.
// Both hand back `{ ok, render }` so the recording and reporting below is
// written once — and so the narrower form cannot quietly acquire a cheaper
// definition of passing.
const compare = (traces, { rules, regions, weakenings }) => {
  if (traces.length === 4) {
    const run = compareRun(traces, { rules, regions, weakenings });
    return { ok: run.ok, comparison: run.comparison, render: () => renderRunReport(run) };
  }
  const [left, right] = traces;
  const comparison = compareTraces(left, right, { rules, regions, weakenings });
  return {
    ok: comparison.ok,
    comparison,
    render: () =>
      [
        renderReport(comparison),
        "",
        "## Self-consistency",
        "",
        "**Not checked.** This was two traces compared against each other, and a run is two captures of",
        "each side. Neither side is known to reproduce itself here, so a difference above cannot yet be",
        "attributed to either implementation.",
        "",
      ].join("\n"),
  };
};

try {
  const traces = positional.map(readTrace);
  const rules = readJson(NORMALIZATION).rules;
  const regions = readJson(REGIONS).regions;
  // Not touched by `--record`: a weakening holds no values, so there is nothing
  // a run could write back into it. It forgave something or it is stale.
  const weakenings = readJson(WEAKENINGS).weakenings;

  let result = compare(traces, { rules, regions, weakenings });

  if (flags.has("--record")) {
    // Stamped with the baseline of the trace that read right — the same one the
    // comparison itself used, whichever form assembled it.
    const rerecorded = recordRegions(regions, result.comparison, { baseline: result.comparison.right.baseline });
    writeFileSync(REGIONS, JSON.stringify({ ...readJson(REGIONS), regions: rerecorded }, null, 2) + "\n");
    // Re-run rather than re-deciding here: what a passing run *is* belongs to
    // the comparison core, and an unclaimed difference has to still fail.
    result = compare(traces, { rules, regions: rerecorded, weakenings });
  }

  const report = result.render();
  console.log(report);
  if (out) writeFileSync(out, report.endsWith("\n") ? report : report + "\n");

  process.exit(result.ok ? 0 : 1);
} catch (e) {
  // A run that cannot be interpreted is its own outcome, and never a pass. The
  // errors below are the ones this script knows how to say out loud; anything
  // else is a bug here and keeps its stack rather than being dressed up as a
  // malformed trace.
  const known = [
    TraceFormatError,
    NormalizationError,
    RegionError,
    WeakeningError,
    ComparisonError,
    ConsistencyError,
    RunError,
    SyntaxError,
  ];
  console.error(known.some((E) => e instanceof E) ? e.message : e);
  process.exit(2);
}
