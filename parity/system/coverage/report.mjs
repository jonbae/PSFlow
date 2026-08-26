// The coverage artifact — what the net says about what it reached (#57).
//
// Its own file (`parity/system/coverage.md`), with the census carrying only a
// pointer. A census *column* was rejected: `parity/census/build.mjs` generates
// from static classification and runs standalone, and feeding it trace-derived
// coverage would make the census unbuildable until someone had run the entire
// net — a far heavier prerequisite than the `spago build` surface parity
// already reluctantly took on.
//
// Everything here is a function of the outcomes, so the artifact cannot say
// anything the join did not find. The one rule it enforces in prose is the one
// no number can enforce on its own: **the two counts are never summed**, and
// the sentence saying why is printed between them rather than left to a reader
// who has only the totals in view.

import { SECTIONS_WITH_EXPORTS } from "./witness.mjs";
import { OUTCOME } from "./coverage.mjs";

const TERMINATION =
  "The corpus is done when every one of the export-bearing entries is **either driven or a deliberately " +
  "declared hole** — a condition, not a target number. It deliberately admits a small corpus with many " +
  "written-down holes as a legitimate resting state, which is what makes it reachable at all.";

const NEVER_SUMMED =
  "**The two counts below are in different currencies and are never summed.** Export coverage counts " +
  "exports; behavior coverage counts conditional behaviors *within* an export. A total would let an " +
  "export driven once absorb every untested condition inside it.";

const esc = (text) => String(text ?? "").replace(/\|/g, "\\|");

/**
 * How an export was reached, or where to read why it was not.
 *
 * A hole's reason is written once, in the register's own section below, rather
 * than in both tables: eighty-odd paragraphs printed twice is a document nobody
 * reads to the end of, and the reason is the part that has to be read.
 */
const evidenceOf = (entry) => {
  if (entry.outcome === OUTCOME.driven) {
    const [first, ...rest] = entry.drivenBy;
    return rest.length ? `\`${first}\` +${rest.length} more` : `\`${first}\``;
  }
  if (entry.outcome === OUTCOME.hole) {
    return entry.hole.ticket ? `declared — [issue](${entry.hole.ticket})` : "declared — no issue owns it";
  }
  if (entry.outcome === OUTCOME.unwitnessed) return "**no witness** — nothing could report this either way";
  return "**undeclared** — nothing drove it and no hole says why";
};

const witnessOf = (entry) => (entry.witness ? `\`${esc(entry.witness.describe)}\`` : "—");

const sectionRows = (outcomes) =>
  SECTIONS_WITH_EXPORTS.map((section) => {
    const here = outcomes.exports.filter((e) => e.section === section);
    const count = (outcome) => here.filter((e) => e.outcome === outcome).length;
    return {
      section,
      total: here.length,
      driven: count(OUTCOME.driven),
      holes: count(OUTCOME.hole),
      undeclared: count(OUTCOME.undeclared),
      unwitnessed: count(OUTCOME.unwitnessed),
    };
  }).filter((row) => row.total > 0);

/**
 * One line for a run that passed — the same shape `renderForkSummary` gives the
 * fork register, and printed by both the command and the net.
 */
export const renderCoverageSummary = (outcomes, behavior) =>
  `coverage: ${outcomes.counts.driven} of ${outcomes.counts.total} export-bearing entries driven, ` +
  `${outcomes.counts.holes} declared hole(s), across ${outcomes.scenarios.length} scenario(s) that ran — ` +
  `and ${behavior.counts.declared} hand-declared behavior(s), counted apart.`;

/** What went wrong, as lines. Empty when both registers are clean. */
export const renderCoverageFailures = (outcomes, behavior) => {
  const said = [];

  const undeclared = outcomes.exports.filter((e) => e.outcome === OUTCOME.undeclared);
  if (undeclared.length) {
    said.push(
      `${undeclared.length} export(s) are undeclared holes: no captured trace held their witness, and no entry`,
      `in coverage/holes.json says why. Drive one, or write down why the corpus does not:`,
      ...undeclared.map((e) => `  ${e.export} (${e.section}) — witness: ${e.witness.describe}`)
    );
  }

  const unwitnessed = outcomes.exports.filter((e) => e.outcome === OUTCOME.unwitnessed);
  if (unwitnessed.length) {
    said.push(
      `${unwitnessed.length} export(s) have no witness in coverage/witnesses.json, so nothing could report them`,
      `driven or undriven. This is what a baseline bump that adds an export looks like:`,
      ...unwitnessed.map((e) => `  ${e.export} (${e.section})`)
    );
  }

  if (outcomes.staleWitnesses.length) {
    said.push(
      `${outcomes.staleWitnesses.length} witness(es) name an export the census no longer carries — removed by a`,
      `bump, or re-classified onto a mechanism the net cannot observe:`,
      ...outcomes.staleWitnesses.map((name) => `  ${name}`)
    );
  }

  if (outcomes.staleHoles.length) {
    said.push(
      `${outcomes.staleHoles.length} hole(s) no longer correspond to anything: something drove the export after`,
      `all, or it left the surface. Delete the entry — a hole is a written reason, and this one stopped being`,
      `true:`,
      ...outcomes.staleHoles.map((hole) => `  ${hole.export} — ${hole.reason}`)
    );
  }

  if (behavior.unnamed.length) {
    said.push(
      `${behavior.unnamed.length} gate-pending row(s) name no scenario, so nothing joins them to the corpus:`,
      ...behavior.unnamed.map((pr) => `  #${pr}`)
    );
  }

  if (behavior.dangling.length) {
    said.push(
      `${behavior.dangling.length} gate-pending row(s) name a scenario the corpus does not hold. The name means`,
      `nothing until it does — write the scenario, or change the row:`,
      ...behavior.dangling.map(({ pr, scenario }) => `  #${pr} → ${scenario}`)
    );
  }

  return said;
};

/**
 * The artifact.
 *
 * `baseline` is the vendored version the traces were captured against — theirs,
 * not the checkout's, for the same reason the net's own report reads it out of
 * the traces: coverage is very often derived from stored traces of an older
 * baseline, and a header naming the current checkout would misreport it.
 */
export const renderCoverage = (
  outcomes,
  behavior,
  { baseline, scenariosFrom = "the corpus", tracesDir = null, registersDir = null } = {}
) => {
  const { counts } = outcomes;
  const lines = [
    "# Coverage — what the net reached, and what it deliberately did not",
    "",
    "_Generated by `npm run parity:coverage`, and by the net itself on every run. Edit the two registers" +
      " under `coverage/`, not this file._",
    "",
    `Derived from ${outcomes.scenarios.length} scenario(s) whose traces are on disk, captured against vendored` +
      ` \`@xyflow/react\` ${baseline}.`,
    "",
    ...(scenariosFrom === "the corpus"
      ? []
      : [
          `**Scenarios came from ${scenariosFrom}.** The corpus is the better answer where it can be` +
            " assembled — only it can say a stored trace belongs to no scenario any more — but the traces are" +
            " committed precisely so this works without one.",
          "",
        ]),
    "**Coverage here is derived, never declared.** An export counts as driven only if it appeared in a trace" +
      " that actually ran, joined back to the export by a **witness** — a selector for `dom`, a name mapping" +
      " for the other four sections. A derived number can be *wrong*; a declared one can be *fiction* and stay" +
      " green forever.",
    "",
    NEVER_SUMMED,
    "",
  ];

  lines.push("## Termination", "", TERMINATION, "");
  lines.push(
    outcomes.terminated
      ? `**The condition holds.** ${counts.driven} driven + ${counts.holes} declared holes = all ` +
          `${counts.total} export-bearing entries; nothing is undeclared residue.`
      : `**The condition does not hold.** ${counts.undeclared} entr(ies) are undeclared holes and ` +
          `${counts.unwitnessed} have no witness at all, out of ${counts.total}.`,
    ""
  );

  lines.push(
    "## Export coverage",
    "",
    `**${counts.driven} of ${counts.total} export-bearing entries driven**, ${counts.holes} declared holes, ` +
      `${counts.undeclared} undeclared, ${counts.unwitnessed} unwitnessed.`,
    "",
    "| Section | Exports | Driven | Declared holes | Undeclared | No witness |",
    "|---|---:|---:|---:|---:|---:|",
    ...sectionRows(outcomes).map(
      (r) => `| \`${r.section}\` | ${r.total} | ${r.driven} | ${r.holes} | ${r.undeclared} | ${r.unwitnessed} |`
    ),
    `| **total** | **${counts.total}** | **${counts.driven}** | **${counts.holes}** | **${counts.undeclared}** |` +
      ` **${counts.unwitnessed}** |`,
    ""
  );

  if (outcomes.staleWitnesses.length) {
    lines.push(
      `**${outcomes.staleWitnesses.length} witness(es) are stale** — they name an export the census no longer` +
        " carries:",
      "",
      ...outcomes.staleWitnesses.map((name) => `- \`${name}\``),
      ""
    );
  }
  if (outcomes.staleHoles.length) {
    lines.push(
      `**${outcomes.staleHoles.length} hole(s) are stale** — something drove the export after all, or it left` +
        " the surface:",
      "",
      ...outcomes.staleHoles.map((hole) => `- \`${hole.export}\` — ${esc(hole.reason)}`),
      ""
    );
  }

  lines.push(
    "## Behavior coverage",
    "",
    "Hand-declared, and not derivable: \"drag while autopan is ongoing\" appears as no token in any trace, and" +
      " no selector matches a condition. A `gate-pending` row in the changelog audit names the gate that will" +
      " prove the behavior and the scenario that will drive it, and the name means nothing until the corpus" +
      " holds that scenario.",
    ""
  );
  if (behavior.counts.declared === 0) {
    lines.push(
      "**No rows declare one yet.** The `gate-pending` bucket is named in the glossary but is not implemented" +
        " in `parity/changelog-audit/audit.mjs` — that is" +
        " [#58](https://github.com/jonbae/PSFlow/issues/58). Until it lands this count is zero because nothing" +
        " has been declared, which is a different statement from zero behaviors being covered.",
      ""
    );
  } else {
    lines.push(
      `**${behavior.counts.declared} behavior(s) declared**, ` +
        Object.entries(behavior.counts.byGate)
          .map(([gate, n]) => `${n} awaiting \`${gate}\``)
          .join(", ") +
        ".",
      "",
      "| PR | Target gate | Scenario | In the corpus |",
      "|---|---|---|---|",
      ...behavior.rows.map(
        (row) =>
          `| ${row.pr} | ${row.gate ?? "—"} | ${row.scenario ? `\`${row.scenario}\`` : "**unnamed**"} | ` +
          `${behavior.dangling.some((d) => d.pr === row.pr) ? "**no**" : "yes"} |`
      ),
      ""
    );
  }

  lines.push(
    "## Every export-bearing entry",
    "",
    "The witness is printed beside each one so a wrong witness can be read and disputed: a selector that" +
      " matches something the scenario did not really drive is the way a derived number goes wrong, and it is" +
      " only findable if the rule is visible.",
    "",
    "| Export | Section | Outcome | Witness | Driven by / why not |",
    "|---|---|---|---|---|",
    ...outcomes.exports.map(
      (entry) =>
        `| \`${entry.export}\` | ${entry.section} | ${entry.outcome} | ${witnessOf(entry)} | ${evidenceOf(entry)} |`
    ),
    ""
  );

  const holes = outcomes.exports.filter((e) => e.outcome === OUTCOME.hole);
  if (holes.length) {
    // Grouped by the reason itself, in the order the reasons first appear. The
    // register is written one entry per export, but a reason covers as many as
    // it covers — eight edge components go undriven for one sentence, and
    // printing that sentence eight times is a document nobody reads the end of.
    const byReason = new Map();
    for (const entry of holes) {
      const key = `${entry.hole.reason} ${entry.hole.ticket ?? ""}`;
      if (!byReason.has(key)) byReason.set(key, { hole: entry.hole, exports: [] });
      byReason.get(key).exports.push(entry.export);
    }

    lines.push(
      "## The declared holes",
      "",
      "Machine-readable in `coverage/holes.json`, which is what boundary stage 4 and probed-variant selection" +
        " are both derived from: the uncovered `hooks` and `props` exports name themselves here rather than" +
        " being hand-picked. One entry per export there; grouped by reason here, because a reason covers as" +
        " many exports as it covers.",
      "",
      ...[...byReason.values()].flatMap(({ hole, exports }) => [
        `- ${exports.map((name) => `\`${name}\``).join(", ")}` +
          `${exports.length > 1 ? ` **(${exports.length})**` : ""} — ${hole.reason}` +
          `${hole.ticket ? ` [issue](${hole.ticket})` : ""}`,
        "",
      ])
    );
  }

  if (tracesDir) {
    lines.push(
      `Every trace this reads is on disk under \`${tracesDir}\` — four per scenario, two sides captured twice` +
        " each. Coverage costs milliseconds over them and needs no browser.",
      ""
    );
  }
  if (registersDir) lines.push(`The registers are \`${registersDir}/witnesses.json\` and \`${registersDir}/holes.json\`.`, "");

  return lines.join("\n");
};
