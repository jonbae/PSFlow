// Coverage — two counts, in different currencies, reported separately and never
// summed (#57).
//
// **Export coverage** counts exports. **Behavior coverage** counts conditional
// behaviors *within* an export. Summing them would let an export driven once
// absorb every untested condition inside it, which is the test-debt ticket's
// central finding and the reason the two live in one file with a rule between
// them rather than in one number.
//
// ## Export coverage is derived, never declared
//
// The 156 export-bearing census entries, each joined back to the traces by a
// **witness** (`witness.mjs`). An export counts as **driven** only if it appears
// in a trace that actually ran — the register cannot make it true by saying so.
//
// Four outcomes per entry, and two of them fail:
//
//   * **driven** — some captured trace held the witness
//   * **hole** — nothing did, and `holes.json` says why. A hole is a legitimate
//     resting state: failing on holes *themselves* was rejected, because the net
//     would be red from day one and stay red for months, which trains people to
//     ignore it
//   * **undeclared** — nothing did, and nothing says why. This is the failure
//     the whole mechanism exists for
//   * **unwitnessed** — no rule joins this export to a trace at all, so nothing
//     could ever report it either way. A hole does not stand in for a witness:
//     one says "the corpus does not drive this", the other says "here is what
//     driving it would look like", and a bump that adds an export needs both
//
// Both registers go **stale** in the sense every register here uses. A witness
// naming an export the census no longer carries claims something that is not
// there; a hole over an export something did drive carries a reason that stopped
// being true — the entry biting the run once its cause is fixed, rather than
// rotting silently.
//
// ## Termination
//
// > The corpus is done when every one of the 156 export-bearing entries is
// > either driven or a deliberately declared hole.
//
// A condition, not a target number — and it deliberately admits a small corpus
// with many written-down holes as a legitimate resting state, which is what
// makes it reachable at all. It is what green means here, so the number to watch
// is the hole count: that is the debt, written down.

import { normalize } from "../compare/normalize.mjs";
import { SECTIONS_WITH_EXPORTS, WitnessError, compileWitness } from "./witness.mjs";

/**
 * The census mechanism each export-bearing section is named by.
 *
 * The join runs through the census rather than through a list of its own: the
 * 156 *are* census entries, and the census already fails when an export appears
 * or vanishes without being classified. A second list would let a bump
 * under-count in silence, which is precisely what deriving is for.
 */
export const SECTION_OF_MECHANISM = Object.freeze({
  "dual-run-dom": "dom",
  "dual-run-callback": "callbacks",
  "dual-run-hook": "hooks",
  "dual-run-api": "api",
  "dual-run-props": "props",
});

/** What an entry did. Only the first two pass. */
export const OUTCOME = Object.freeze({
  driven: "driven",
  hole: "hole",
  undeclared: "undeclared",
  unwitnessed: "unwitnessed",
});

export class CoverageError extends Error {
  constructor(message) {
    super(message);
    this.name = "CoverageError";
  }
}

/**
 * The export-bearing census entries, as `{ export, section }`, in section order
 * and then alphabetically.
 *
 * `classification` is `parity/census/classification.json`, read rather than
 * listed: "which exports the net can observe" is the census's answer, and a
 * second copy of it is how a bump under-counts.
 */
export const exportEntries = (classification) =>
  Object.entries(classification)
    .filter(([name]) => !name.startsWith("_"))
    .flatMap(([name, [, mechanism]]) => {
      const section = SECTION_OF_MECHANISM[mechanism];
      return section ? [{ export: name, section }] : [];
    })
    .sort(
      (a, b) =>
        SECTIONS_WITH_EXPORTS.indexOf(a.section) - SECTIONS_WITH_EXPORTS.indexOf(b.section) ||
        a.export.localeCompare(b.export)
    );

/**
 * Checks the hole register's shape. Throws; nothing here is a finding.
 *
 * **One entry per reason, covering as many exports as the reason covers** — the
 * same shape a **region** has, where one pattern claims many differences. The
 * alternative, one entry per export, writes the same sentence out once for every
 * export it is true of: thirteen copies of "no fixture mounts the component"
 * that a later edit can put out of step with each other, which is the class of
 * quiet disagreement this repo builds registers to prevent.
 *
 * The rule with an argument behind it is the reason itself: "the corpus has not
 * reached it yet" and "nothing can ever drive it" are the same absence, and
 * telling them apart is the whole value of writing a hole down.
 */
export const validateHoles = (holes) => {
  if (!Array.isArray(holes)) throw new CoverageError("the hole register must be an array");

  const covered = new Map();
  holes.forEach((hole, i) => {
    const at = `hole ${i} (${hole?.exports?.[0] ?? "no export"})`;
    if (!Array.isArray(hole?.exports) || hole.exports.length === 0) {
      throw new CoverageError(`${at}: needs at least one export — an entry covering nothing says nothing`);
    }
    for (const name of hole.exports) {
      if (typeof name !== "string" || name === "") throw new CoverageError(`${at}: every export must be a name`);
      // Two reasons for one export is two answers to one question, and the join
      // would silently take whichever came first.
      if (covered.has(name)) throw new CoverageError(`${at}: ${name} is already covered by hole ${covered.get(name)}`);
      covered.set(name, i);
    }
    if (typeof hole.reason !== "string" || hole.reason === "") {
      throw new CoverageError(`${at}: needs a written reason — an unexplained hole is a dumping ground`);
    }
  });

  return holes;
};

const compileRegister = (witnesses, sectionOf) => {
  if (!Array.isArray(witnesses)) throw new WitnessError("the witness register must be an array");

  const compiled = new Map();
  const stale = [];
  witnesses.forEach((entry, i) => {
    if (typeof entry?.export !== "string" || entry.export === "") throw new WitnessError(`witness ${i}: needs an export`);
    if (compiled.has(entry.export) || stale.includes(entry.export)) {
      throw new WitnessError(`witness for ${entry.export}: duplicate entry`);
    }
    const section = sectionOf.get(entry.export);
    if (section) compiled.set(entry.export, compileWitness(entry, section));
    else stale.push(entry.export);
  });

  return { compiled, stale };
};

/**
 * The export-bearing entries against the two registers and the traces that
 * actually ran.
 *
 * `traces` are `{ scenario, sections }` — every capture of every side, because
 * an export driven on one side and not the other is still one the corpus
 * reached, and holding the two sides to each other is the *comparison's* job.
 *
 * `rules` is the noise policy's normalization ruleset, applied before a witness
 * is asked anything: a field the policy deletes counts as **unobserved** in
 * coverage rather than as passing, which is a sentence in `normalization.json`
 * that would otherwise be true only by luck.
 */
export const coverageOutcomes = (entries, { witnesses, holes, traces, rules = [] }) => {
  validateHoles(holes);
  const sectionOf = new Map(entries.map(({ export: name, section }) => [name, section]));
  const { compiled, stale } = compileRegister(witnesses, sectionOf);
  const declared = new Map(holes.flatMap((hole) => hole.exports.map((name) => [name, hole])));

  const observed = traces.map(({ scenario, sections }) => ({ scenario, sections: normalize(sections, rules).value }));

  const exports = entries.map(({ export: name, section }) => {
    const witness = compiled.get(name) ?? null;
    const hole = declared.get(name) ?? null;
    const drivenBy = witness
      ? [...new Set(observed.filter(({ sections }) => witness.holdsIn(sections)).map(({ scenario }) => scenario))].sort()
      : [];

    const outcome = !witness
      ? OUTCOME.unwitnessed
      : drivenBy.length
        ? OUTCOME.driven
        : hole
          ? OUTCOME.hole
          : OUTCOME.undeclared;

    return { export: name, section, witness, hole, drivenBy, outcome };
  });

  // Stale in two ways, and both are the entry no longer corresponding to
  // anything: the export left the surface, or something drove it after all. An
  // *unwitnessed* export's hole is neither — nothing could have reported it
  // driven, so the missing witness is the finding to fix and the hole is not
  // yet wrong.
  //
  // Named per export rather than per entry, because an entry covers as many as
  // its reason covers: a resizer scenario landing makes the entry wrong about
  // the five exports it now drives and still right about nothing else, and
  // "split this entry" is only actionable if it says which.
  const byExport = new Map(exports.map((entry) => [entry.export, entry]));
  const staleHoles = holes
    .map((hole) => ({
      hole,
      exports: hole.exports.filter((name) => {
        const entry = byExport.get(name);
        return !entry || entry.outcome === OUTCOME.driven;
      }),
    }))
    .filter(({ exports: stale }) => stale.length > 0);

  const tally = (outcome) => exports.filter((e) => e.outcome === outcome).length;
  const counts = {
    total: exports.length,
    driven: tally(OUTCOME.driven),
    holes: tally(OUTCOME.hole),
    undeclared: tally(OUTCOME.undeclared),
    unwitnessed: tally(OUTCOME.unwitnessed),
  };

  return {
    exports,
    staleWitnesses: stale,
    staleHoles,
    counts,
    scenarios: [...new Set(observed.map(({ scenario }) => scenario))].sort(),
    // Every entry driven or deliberately holed — the corpus's termination
    // condition, evaluated rather than asserted.
    terminated: counts.driven + counts.holes === counts.total,
    ok: counts.undeclared === 0 && counts.unwitnessed === 0 && stale.length === 0 && staleHoles.length === 0,
  };
};

// ── Behavior coverage ──────────────────────────────────────────────────────
// The second count, and the one that stays hand-declared. It cannot be derived:
// "drag while autopan is ongoing" appears as no token in any trace, and no
// selector matches a condition. So it lives where the test-debt ticket put it —
// a `gate-pending` row in the changelog audit, naming the gate that will prove
// the behavior and the scenario that will drive it.
//
// What is checkable here is the join, and it is the rule ticket 080 wrote down
// and deferred: **the name means nothing until the corpus holds it.** A row
// naming a scenario nobody wrote reads as a plan and counts as coverage.
//
// The bucket itself is not implemented in `parity/changelog-audit/audit.mjs`
// yet — that is #58 — so this reads zero rows today and says so rather than
// pretending the count is meaningful.

const isRow = (name) => !name.startsWith("_");

/**
 * The `gate-pending` rows of the changelog audit, against the corpus.
 *
 * Never summed with export coverage, and never rendered beside it without the
 * sentence saying so: an export driven once would otherwise absorb every
 * untested condition inside it.
 */
export const behaviorCoverage = (verdicts, { scenarioIds = [] } = {}) => {
  const known = new Set(scenarioIds);
  const pending = Object.entries(verdicts)
    .filter(([name, row]) => isRow(name) && row?.bucket === "gate-pending")
    .map(([pr, row]) => ({ pr, gate: row.gate ?? null, scenario: row.scenario ?? null }))
    .sort((a, b) => a.pr.localeCompare(b.pr));

  const unnamed = pending.filter((row) => !row.scenario).map((row) => row.pr);
  const dangling = pending
    .filter((row) => row.scenario && !known.has(row.scenario))
    .map(({ pr, scenario }) => ({ pr, scenario }));

  const byGate = {};
  for (const { gate } of pending) byGate[gate ?? "unnamed"] = (byGate[gate ?? "unnamed"] ?? 0) + 1;

  return {
    rows: pending,
    unnamed,
    dangling,
    counts: { declared: pending.length, byGate },
    ok: unnamed.length === 0 && dangling.length === 0,
  };
};

/**
 * The holes a run found, optionally in one section — the query the rest of the
 * map derives from rather than reading the register and guessing.
 *
 * Boundary stage 4 ([#62]) asks for the `dom` holes, which are the components no
 * fixture mounts; probed-variant selection ([#59]) asks for `hooks` and `props`,
 * because a probed variant doubles the corpus's captures and is worth spending
 * only on exports a hole actually names. Both ask the *run*: the register alone
 * carries no section, and deriving one from a ticket link would be a second
 * reading of the census that could disagree with the first.
 *
 * Each entry is the export's own outcome, so `entry.hole` is the register entry
 * and `entry.hole.reason` is what someone wrote down about it.
 */
export const holesIn = (outcomes, section = null) =>
  outcomes.exports.filter((entry) => entry.outcome === OUTCOME.hole && (!section || entry.section === section));
