// The coverage artifact — the command (`npm run parity:coverage`, #57).
//
//   node parity/system/coverage.mjs [--out <path>]
//
//     --out  write the artifact somewhere else as well
//
// Coverage is **derived from runs that actually happened**: it reads the traces
// already on disk, joins each export back to them through a **witness**, and
// writes `coverage.md`. The mechanism, the four outcomes and the termination
// condition are in `coverage/coverage.mjs`; this file reads the registers, the
// census, the corpus and the stored traces, and says what it found.
//
// It runs standalone and it runs as the net's last step. Standalone is not a
// convenience: the traces are committed, so editing a witness or writing down a
// hole and regenerating the artifact costs milliseconds and no browser, where
// re-capturing the corpus costs a hundred and twenty drives of a real page.
//
// **The census carries a pointer to this and nothing else.** A census column
// was rejected: `parity/census/build.mjs` generates from static classification
// and runs standalone, and feeding it trace-derived coverage would make the
// census unbuildable until someone had run the entire net.
//
// Exit codes: 0 both registers are affirmed, 1 they are not — an undeclared
// hole, an export with no witness, a stale witness or hole, a `gate-pending`
// row naming a scenario the corpus does not hold — 2 it could not be read at
// all: a malformed register, a trace that is not a trace, a corpus that could
// not be derived.

import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, posix, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

import { RegistryError, routeSpace } from "../driver/registry.mjs";
import { NormalizationError } from "./compare/normalize.mjs";
import { CoverageError, behaviorCoverage, coverageOutcomes, exportEntries } from "./coverage/coverage.mjs";
import { renderCoverage, renderCoverageFailures, renderCoverageSummary } from "./coverage/report.mjs";
import { WitnessError } from "./coverage/witness.mjs";
import { CorpusError, RESERVED, buildCorpus } from "./corpus/index.mjs";
import { TraceStoreError, readRun, storedScenarios } from "./net/traces.mjs";
import { TraceFormatError } from "./trace-format.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");

export const WITNESSES = join(here, "coverage", "witnesses.json");
export const HOLES = join(here, "coverage", "holes.json");
export const COVERAGE = join(here, "coverage.md");

const TRACES = join(here, "traces");
const NORMALIZATION = join(here, "normalization.json");
const CLASSIFICATION = join(repoRoot, "parity/census/classification.json");
const VERDICTS = join(repoRoot, "parity/changelog-audit/verdicts.json");

const readJson = (path) => JSON.parse(readFileSync(path, "utf8"));
const posixPath = (path) => path.split(sep).join(posix.sep);

/**
 * The traces that actually ran, for the scenarios the corpus still holds.
 *
 * Scoped to the corpus on purpose: a trace left behind by a renamed scenario is
 * **stale**, and letting one witness an export would be coverage derived from a
 * run whose scenario no longer exists. The net fails such a trace outright; here
 * it is simply not read.
 */
const capturedTraces = (scenarioIds) => {
  const stored = new Set(existsSync(TRACES) ? storedScenarios(TRACES) : []);
  const captured = scenarioIds.filter((id) => stored.has(id));

  return {
    captured,
    uncaptured: scenarioIds.filter((id) => !stored.has(id)),
    traces: captured.flatMap((id) => readRun(TRACES, id)),
  };
};

/**
 * The corpus, or — on a clean clone — the scenarios the stored traces name.
 *
 * The fallback is the same argument that commits the traces in the first place:
 * re-diffing must work without the vendored checkout, or committing them would
 * buy nothing. Coverage is a claim about runs that happened, and the traces
 * *are* those runs. It is never silent, because the two answers are not the
 * same: the corpus can hold a scenario nobody captured, and only the corpus can
 * say a stored trace no longer belongs to one.
 */
const scenarioSpace = () => {
  try {
    const { fixtures, components } = routeSpace(repoRoot);
    return { ids: buildCorpus(fixtures, components).map((scenario) => scenario.id), from: "the corpus" };
  } catch (e) {
    if (!(e instanceof RegistryError)) throw e;
    if (!existsSync(TRACES)) throw e;
    return { ids: storedScenarios(TRACES), from: "the stored traces — no vendored checkout to assemble the corpus from" };
  }
};

/**
 * The registers read against the census, the corpus and the stored traces.
 *
 * Exported so the net runs the same check this command does, rather than a
 * second reading of the same files that could drift from it — and takes the
 * `corpus` it has already built, since assembling it twice in one run would be
 * two answers where the gate needs one.
 */
export const checkCoverage = ({ corpus, scenarioIds } = {}) => {
  const given = scenarioIds ?? corpus?.map((scenario) => scenario.id);
  const { ids, from } = given ? { ids: given, from: "the corpus" } : scenarioSpace();
  const { captured, uncaptured, traces } = capturedTraces(ids);

  const outcomes = coverageOutcomes(exportEntries(readJson(CLASSIFICATION)), {
    witnesses: readJson(WITNESSES).witnesses,
    holes: readJson(HOLES).holes,
    traces,
    rules: readJson(NORMALIZATION).rules,
  });

  return {
    outcomes,
    // The reserved ids come from the register rather than from `ids`, and on
    // purpose: a `gate-pending` row against a scenario nobody has written is
    // still a resolved plan, and it stays resolved on a clean clone where `ids`
    // is the stored traces rather than the corpus.
    behavior: behaviorCoverage(readJson(VERDICTS), { scenarioIds: ids, reservedIds: Object.keys(RESERVED) }),
    uncaptured,
    // Theirs, not the checkout's: coverage is very often derived from stored
    // traces of an older baseline, and naming the current checkout would
    // misreport what was measured.
    baseline: [...new Set(traces.map((trace) => trace.baseline))].join(" and ") || "no captured trace",
    captured,
    scenariosFrom: from,
  };
};

/** The command's own words, so the net says exactly what this says. */
export const reportCoverage = ({ outcomes, behavior, uncaptured, scenariosFrom }) => {
  const said = outcomes.ok && behavior.ok
    ? [renderCoverageSummary(outcomes, behavior)]
    : ["coverage is not affirmed.", ...renderCoverageFailures(outcomes, behavior)];

  if (scenariosFrom !== "the corpus") said.push(`Scenarios came from ${scenariosFrom}.`);

  if (uncaptured.length) {
    said.push(
      `${uncaptured.length} scenario(s) in the corpus have no stored trace, so nothing they would have driven`,
      `counts here. Capture them (\`npm run parity:system\`):`,
      ...uncaptured.map((id) => `  ${id}`)
    );
  }

  return said.join("\n");
};

const withTrailingNewline = (text) => (text.endsWith("\n") ? text : text + "\n");

/** Writes the artifact. Shared with the net, which regenerates it every run. */
export const writeCoverage = (checked, { out = null } = {}) => {
  const report = withTrailingNewline(
    renderCoverage(checked.outcomes, checked.behavior, {
      baseline: checked.baseline,
      scenariosFrom: checked.scenariosFrom,
      tracesDir: posixPath(relative(repoRoot, TRACES)),
      registersDir: posixPath(relative(repoRoot, join(here, "coverage"))),
    })
  );
  writeFileSync(COVERAGE, report);
  if (out) writeFileSync(out, report);
  return COVERAGE;
};

// A flag whose value went missing is a usage error, never a default — the same
// reading `net.mjs` gives its own flags, for the same reason: `--out` with
// nothing after it would otherwise write the artifact to its default place and
// report success at having done what was asked.
const value = (argv, name) => {
  const at = argv.indexOf(name);
  if (at === -1) return null;
  const given = argv[at + 1];
  if (given === undefined || given.startsWith("--")) throw new CoverageError(`${name} needs a value`);
  return given;
};

const main = () => {
  const argv = process.argv.slice(2);
  const checked = checkCoverage();
  const written = writeCoverage(checked, { out: value(argv, "--out") });

  console.log(reportCoverage(checked));
  console.log(`The artifact is ${relative(repoRoot, written)}.`);
  return checked.outcomes.ok && checked.behavior.ok ? 0 : 1;
};

const INTERPRETABLE = [
  CoverageError,
  WitnessError,
  CorpusError,
  NormalizationError,
  TraceFormatError,
  TraceStoreError,
  SyntaxError,
];

if (resolve(process.argv[1] ?? "") === resolve(fileURLToPath(import.meta.url))) {
  try {
    process.exit(main());
  } catch (e) {
    console.error(INTERPRETABLE.some((E) => e instanceof E) ? e.message : e);
    process.exit(2);
  }
}
