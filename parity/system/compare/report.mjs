// The comparison report — what a comparison run says to a human.
//
// Two audiences and one shape: a maintainer reading a failing run wants the
// unclaimed differences grouped by section in report order, and a maintainer
// doing a baseline bump wants the region verdicts, because the regions whose
// content *moved* are the behavioural changelog.

import { REPORT_ORDER } from "./index.mjs";
import { formatPath } from "./paths.mjs";

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

const differenceTable = (differences, left, right) => [
  `| path | kind | ${left.side} | ${right.side} |`,
  "|---|---|---|---|",
  ...differences.map(
    (d) => `| \`${formatPath(d.path)}\` | ${KIND_NOTE[d.kind]} | ${renderValue(d.left)} | ${renderValue(d.right)} |`
  ),
];

export const renderReport = (result) => {
  const { left, right, unclaimed, outcomes, deleted } = result;
  const lines = [
    `# Comparison report — ${result.scenario}`,
    "",
    `${sideLabel(left)} against ${sideLabel(right)}.`,
    "",
  ];

  const stale = outcomes.filter((o) => o.status === "stale");
  const moved = outcomes.filter((o) => o.status === "moved");

  if (result.ok) {
    lines.push("**No unclaimed differences.** Every difference the run found is claimed by a region.", "");
  } else {
    const parts = [];
    if (unclaimed.length) parts.push(`${unclaimed.length} unclaimed difference(s)`);
    if (stale.length) parts.push(`${stale.length} stale region(s)`);
    if (moved.length) parts.push(`${moved.length} region(s) needing re-affirmation`);
    lines.push(`**Failed:** ${parts.join(", ")}.`, "");
  }

  if (unclaimed.length) {
    lines.push("## Unclaimed differences", "");
    for (const section of REPORT_ORDER) {
      const inSection = unclaimed.filter((d) => d.path[0] === section);
      if (!inSection.length) continue;
      lines.push(`### ${section} (${inSection.length})`, "", ...differenceTable(inSection, left, right), "");
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
