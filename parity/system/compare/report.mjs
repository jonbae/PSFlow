// The comparison report — what a comparison run says to a human.
//
// Two audiences and one shape: a maintainer reading a failing run wants the
// unclaimed differences grouped by section in report order, and a maintainer
// doing a baseline bump wants the region verdicts, because the regions whose
// content *moved* are the behavioural changelog.

import { DRIVING } from "../trace-format.mjs";
import { CONSEQUENCE, REPORT_ORDER, isDriving } from "./index.mjs";
import { formatPath } from "./paths.mjs";
import { OUTCOME, regionsWith } from "./regions.mjs";

const MAX_VALUE = 160;

const renderValue = (value) => {
  if (value === undefined) return "—";
  const text = typeof value === "string" ? value : JSON.stringify(value);
  const oneLine = text.replace(/\|/g, "\\|").replace(/\n/g, "⏎");
  return oneLine.length > MAX_VALUE ? oneLine.slice(0, MAX_VALUE - 1) + "…" : oneLine;
};

const sideLabel = ({ side, capture, baseline }) => `${side} (capture ${capture}, baseline ${baseline})`;

const KIND_NOTE = {
  changed: "differs",
  "left-only": "left only",
  "right-only": "right only",
  order: "ordered differently",
};

const differenceTable = (differences, leftColumn, rightColumn) => [
  `| path | kind | ${leftColumn} | ${rightColumn} |`,
  "|---|---|---|---|",
  ...differences.map(
    (d) => `| \`${formatPath(d.path)}\` | ${KIND_NOTE[d.kind]} | ${renderValue(d.left)} | ${renderValue(d.right)} |`
  ),
];

/**
 * The whole run: both sides against themselves, then the two sides against each
 * other. Self-consistency is rendered first because it is read first — a side
 * that is not reproducible makes every cross-side difference unattributable, and
 * a maintainer who reads the comparison table without knowing that is reading
 * noise as a finding.
 */
export const renderRunReport = (run) => {
  const lines = [`# System parity run — ${run.scenario}`, ""];

  if (run.ok) {
    lines.push("**Passed.** Both sides reproduced themselves, and the two sides agree everywhere unclaimed.", "");
  } else {
    lines.push(`**Failed:** ${run.failures.map((f) => f.class).join(", ")}.`, "");
  }

  lines.push(
    "## Self-consistency",
    "",
    "Each side is captured twice and compared against itself **before** the sides are compared at all: a",
    "recorded trace baseline is meaningless if traces are not reproducible. The driving log takes part with",
    "no tolerance applied — it never reaches the normalizer at all — so a side whose resolved boxes wobble",
    "between its own captures fails against itself.",
    "",
    "| side | captures | verdict | differences |",
    "|---|---|---|---|"
  );
  for (const side of run.consistency) {
    lines.push(
      `| ${side.side} | ${side.captures.join(", ")} | ${side.consistent ? "reproduced" : "**disagrees with itself**"} | ${side.differences.length} |`
    );
  }
  lines.push("");

  const inconsistent = run.consistency.filter((side) => !side.consistent);
  for (const side of inconsistent) {
    lines.push(
      `### ${side.side} disagrees with itself`,
      "",
      ...differenceTable(side.differences, `capture ${side.captures[0]}`, `capture ${side.captures[1]}`),
      ""
    );
  }

  if (inconsistent.length) {
    lines.push(
      `**${inconsistent.map((c) => c.side).join(" and ")} did not reproduce.** The comparison below ran anyway —`,
      "capture-everything applies to a failed run as much as to a passing one — but a difference it reports",
      "cannot yet be attributed to either implementation. Fix the reproducibility, then read it.",
      ""
    );
  }

  lines.push("---", "", renderReport(run.comparison));
  return lines.join("\n");
};

export const renderReport = (result) => {
  const { left, right, unclaimed, outcomes, deleted } = result;
  const lines = [
    `# Comparison report — ${result.scenario}`,
    "",
    `${sideLabel(left)} against ${sideLabel(right)}.`,
    "",
  ];

  const stale = regionsWith(outcomes, OUTCOME.stale);
  const moved = regionsWith(outcomes, OUTCOME.moved);

  if (result.ok) {
    lines.push(
      result.differences.length
        ? `**No unclaimed differences.** All ${result.differences.length} the run found are claimed by a region.`
        : "**No unclaimed differences.** The two traces agree everywhere.",
      ""
    );
  } else {
    const parts = [];
    // Named apart from the rest, and first: "the inputs differed" is a different
    // finding from "the outputs differed", and reading it as the second one is
    // how two different experiments get filed as a behavioural difference.
    const drivingUnclaimed = unclaimed.filter(isDriving);
    if (drivingUnclaimed.length) parts.push(`${drivingUnclaimed.length} driving divergence(s)`);
    if (unclaimed.length - drivingUnclaimed.length) {
      parts.push(`${unclaimed.length - drivingUnclaimed.length} unclaimed difference(s)`);
    }
    if (stale.length) parts.push(`${stale.length} stale region(s)`);
    if (moved.length) parts.push(`${moved.length} region(s) needing re-affirmation`);
    lines.push(`**Failed:** ${parts.join(", ")}.`, "");
  }

  // The driving log is the receipt for the input side. When it differs, the two
  // sides were not driven the same way, and every other difference below is a
  // reading of two different experiments — which is worth saying *before* the
  // tables, and is not worth deleting them over.
  if (result.driving.diverged) {
    lines.push(
      "**The inputs differed.** The driving log records what was done *to* each side — the target, whether",
      "it resolved, the box it resolved to — and it does not agree. Selectors resolve against each side's",
      "own render, so the pointer follows a divergence: two sides that place a node five pixels apart both",
      "drag successfully while the two runs were not one experiment. Until the log agrees, every section",
      `below it is a **${CONSEQUENCE}**. None of them is suppressed —`,
      "a real divergence is exactly what would be hiding down there.",
      ""
    );
    // A region may claim a driving difference, and then the run passes. It is
    // still two experiments: the claim decides what fails, never what is
    // readable, and a green run whose sections are consequences has to say so.
    if (!result.driving.differences.some((d) => unclaimed.includes(d))) {
      lines.push(
        "Every difference in the log is claimed by a region, so the run does not fail on it. That is a",
        "decision about pass and fail and not about attribution: the sections below are consequences either",
        "way.",
        ""
      );
    }
  }

  if (unclaimed.length) {
    lines.push("## Unclaimed differences", "");
    for (const section of REPORT_ORDER) {
      const inSection = unclaimed.filter((d) => d.path[0] === section);
      if (!inSection.length) continue;
      const note = result.driving.diverged && section !== DRIVING ? ` — ${CONSEQUENCE}` : "";
      lines.push(
        `### ${section} (${inSection.length})${note}`,
        "",
        ...differenceTable(inSection, left.side, right.side),
        ""
      );
    }
  }

  if (outcomes.length) {
    lines.push("## Regions", "");
    lines.push("| region | kind | status | claimed | reason | ticket |", "|---|---|---|---|---|---|");
    for (const { region, status, claimed } of outcomes) {
      lines.push(
        `| \`${region.id}\` | ${region.kind} | ${status} | ${claimed.length} | ${region.reason} | ${region.ticket ?? "—"} |`
      );
    }
    lines.push("");
    if (stale.length) {
      lines.push(
        "A region that claims nothing has outlived its cause — the divergence was fixed, or the scenario",
        "stopped exercising it. Delete it rather than leaving it to rot.",
        ""
      );
    }
    if (moved.length) {
      lines.push(
        "A region whose content moved needs re-affirming, not re-syncing: someone has to look at the new",
        "values and decide they are still the same cause. `--record` writes them back once they have.",
        ""
      );
    }
  }

  const deletedCount = deleted.left.length + deleted.right.length;
  if (deletedCount) {
    lines.push("## Normalization", "");
    lines.push(`${deletedCount} field(s) deleted by name and therefore **unobserved** — not passing:`, "");
    const byRule = new Map();
    for (const { path, rule } of [...deleted.left, ...deleted.right]) {
      if (!byRule.has(rule.at)) byRule.set(rule.at, { rule, paths: new Set() });
      byRule.get(rule.at).paths.add(formatPath(path));
    }
    for (const { rule, paths } of byRule.values()) {
      lines.push(`- \`${rule.at}\` (${paths.size}) — ${rule.reason}`);
    }
    lines.push("");
  }

  return lines.join("\n");
};
