// What a whole net run says to a human (#51).
//
// `compare/report.mjs` renders **one** run — one scenario, four traces — and it
// is the detail. This is the one above it: the corpus is many scenarios, and a
// maintainer opening the report wants to know which of them failed and how
// before reading any of them.
//
// The order is the same argument the comparison itself makes one level down. A
// side that did not reproduce itself invalidates its own run, and a driving log
// that diverged makes the sections after it consequences rather than readings —
// so the summary names the failure *classes* per scenario rather than a count of
// differences, because a count says nothing about whether the run was one
// experiment.
//
// Nothing is suppressed. Every scenario's full report follows the table, failed
// or not: capture-everything applies to a failed run as much as to a passing
// one, and a real divergence is exactly what would be hiding under a run whose
// inputs differed.

import { renderRunReport } from "../compare/report.mjs";

/** A net run passes when every scenario's run does. */
export const netOk = (runs) => runs.every((run) => run.ok);

const classesOf = (run) => (run.ok ? "—" : [...new Set(run.failures.map((f) => f.class))].join(", "));

// Both halves: what the two sides differed on, and what a side differed from
// itself on. A scenario whose only differences were a side against itself would
// otherwise read as zero, which is the one failure class that invalidates the
// rest of its own row.
const differencesIn = (run) =>
  run.comparison.unclaimed.length + run.consistency.reduce((n, side) => n + side.differences.length, 0);

/**
 * The whole corpus: a verdict, a table of scenarios, then every run's own report
 * in full.
 *
 * `baseline` is the vendored upstream version the traces were captured against —
 * theirs, not the checkout's, since a re-diff is often reading traces from an
 * older one. `captured` says whether this run drove a browser or re-diffed
 * traces already on disk, because a report that did not say which would let a
 * stored-trace comparison be read as a fresh measurement of the current code.
 * `orphans` are stored traces no scenario in the corpus claims.
 */
export const renderNetReport = (runs, { baseline, captured = true, tracesDir = null, orphans = [] } = {}) => {
  const failed = runs.filter((run) => !run.ok);
  const lines = [
    "# System parity",
    "",
    `The dual-run net over ${runs.length} scenario(s), against vendored \`@xyflow/react\` ${baseline}.`,
    "",
    captured
      ? "Captured by this run: both sides mounted the same unmodified fixtures through the same driver, bundled twice."
      : "**Re-diffed from stored traces.** No browser ran; this compares the traces already on disk, which is what a" +
        " revised noise policy or a bumped baseline asks. It says nothing about code changed since they were captured.",
    "",
  ];

  if (failed.length) {
    lines.push(
      `**${failed.length} of ${runs.length} scenario(s) failed.**`,
      "",
      "A failing net is the expected state while the divergence backlog is being worked: the scenarios below",
      "are recording what the two implementations actually do, and a difference is fixed in the port or",
      "claimed by a region — never by loosening what the net looks at.",
      ""
    );
  } else if (!orphans.length) {
    lines.push("**Passed.** Every scenario reproduced itself on both sides, and the two sides agree everywhere unclaimed.", "");
  }

  lines.push(
    "| scenario | verdict | failure classes | differences |",
    "|---|---|---|---|",
    ...runs.map(
      (run) => `| \`${run.scenario}\` | ${run.ok ? "passed" : "**failed**"} | ${classesOf(run)} | ${differencesIn(run)} |`
    ),
    ""
  );

  // Stale in the sense every register here uses: it stops corresponding to
  // anything real. Reported beside the runs rather than instead of them —
  // nothing earlier suppresses anything later — and it fails the run on its own.
  if (orphans.length) {
    lines.push(
      `**${orphans.length} stored trace(s) belong to no scenario in the corpus.** A scenario was renamed or`,
      "removed and its traces stayed. Delete them: a stored trace nobody captures again is read as a recorded",
      "divergence forever.",
      "",
      ...orphans.map((name) => `- \`${name}\``),
      ""
    );
  }

  if (tracesDir) {
    lines.push(
      `Every trace behind this report is on disk under \`${tracesDir}\` — four per scenario, two sides captured`,
      "twice each. They are the artifact: re-diffing them costs seconds and no browser.",
      ""
    );
  }

  for (const run of runs) {
    lines.push("---", "", renderRunReport(run), "");
  }

  return lines.join("\n");
};
