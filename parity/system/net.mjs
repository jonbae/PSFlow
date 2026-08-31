// System parity — the gate (`npm run parity:system`, #51).
//
//   node parity/system/net.mjs [--compare-only] [--scenario <id>] [--out <path>]
//
//     --compare-only  re-diff the stored traces; no build, no browser, and no
//                     vendored checkout needed — which is what a revised noise
//                     policy asks, and what re-diffs one baseline's stored
//                     traces against the next
//     --scenario      one scenario by id, rather than the whole corpus
//     --out           write the report somewhere else as well
//
// The **net**: upstream and ps-flow mounted side by side on the same unmodified
// fixtures, through the same driver bundled twice, both settled on their own
// clocks, both captured twice, all four traces written to disk, and the run read
// back off disk and diffed.
//
// This is the command the two halves were built apart for. `harness/` drives one
// scenario against one side and produces a trace; `compare/` reads a run's four
// traces and reports what differs; neither knows the other exists, and this file
// is the only place they meet. It waited on `dom` capture for a reason worth
// keeping in view: two traces whose sections are empty on both sides compare
// clean and mean nothing, and a gate that cannot go red is worse than no gate.
//
// **The corpus** is `corpus/`: a mount-only baseline per fixture, derived from
// the driver's own registries rather than written down, plus the **conformance
// seed** — upstream's forty-three end-to-end tests transcribed as interaction
// sequences with their assertions dropped. The baselines are the cheapest
// scenario there is and the one the dual-run spike ran when it found an
// entirely unlisted missing export; the seed is what drives anything at all.
//
// The seed is a **one-time fork**, and `corpus/fork.mjs` is what keeps it from
// going quietly stale: every upstream test is registered against the scenarios
// lifted from it and a hash of its own source, and a bump that rewrites one
// fails, naming the scenarios to re-affirm.
//
// **It runs vendored upstream**, never the published package: both bundles are
// rebuilt here, and `parity/driver/build.mjs` reads its own output back and
// fails if the library in it is not the one the side names. That check is the
// whole gate — an alias that quietly stopped being applied would leave the net
// comparing ps-flow against itself and reporting green.
//
// **Coverage is its last step**, and it is derived rather than declared: every
// export-bearing census entry is joined back to the traces just written by a
// **witness**, and `coverage.md` says which the corpus reached and which are
// deliberately declared holes. It runs after the comparison because it reads the
// traces off disk like everything else here, and it fails the run on an
// undeclared hole — the residue nobody wrote down — never on a hole itself.
//
// Exit codes: 0 clean, 1 the run went red — a side that disagrees with itself,
// a driving divergence, an unclaimed difference, a stale region or weakening, a
// stored trace no scenario claims, an export nothing drove and nothing declared
// — 2 a run that could not be interpreted at all: a malformed trace, an illegal
// normalization rule, a missing vendored checkout, a corpus that could not be
// derived. A run that cannot be interpreted is never a pass.

import { chromium } from "@playwright/test";
import { spawn } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, posix, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

import { RegistryError, routeSpace } from "../driver/registry.mjs";
import { SIDES } from "../driver/sides.mjs";
import { WeakeningError } from "./compare/callbacks.mjs";
import { ConsistencyError } from "./compare/consistency.mjs";
import { ComparisonError } from "./compare/index.mjs";
import { NormalizationError } from "./compare/normalize.mjs";
import { RegionError } from "./compare/regions.mjs";
import { RunError, compareRun } from "./compare/run.mjs";
import { COVERAGE, checkCoverage, reportCoverage, writeCoverage } from "./coverage.mjs";
import { CoverageError } from "./coverage/coverage.mjs";
import { WitnessError } from "./coverage/witness.mjs";
import { ForkError } from "./corpus/fork.mjs";
import { CorpusError, assertRetirementsResolve, buildCorpus } from "./corpus/index.mjs";
import { checkFork, reportFork } from "./fork.mjs";
import { SettleError } from "./harness/settle.mjs";
import { runScenario } from "./harness/scenario.mjs";
import { serveDirectory } from "./net/server.mjs";
import { renderNetReport, netOk } from "./net/summary.mjs";
import { CAPTURES, TraceStoreError, orphanedTraces, readRun, storedScenarios, writeTrace } from "./net/traces.mjs";
import { TraceFormatError } from "./trace-format.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");

// Fixed, not switchable by flag: a run must not be able to compare against a
// laxer noise policy than the committed one.
const NORMALIZATION = join(here, "normalization.json");
const REGIONS = join(here, "regions.json");
const WEAKENINGS = join(here, "weakenings.json");

const TRACES = join(here, "traces");
const REPORT = join(here, "report.md");

// One viewport, both sides. The container's box feeds `fitView`, which feeds the
// viewport transform, which feeds everything — so the two runs differ in the
// library and in nothing else, down to the window they are measured in.
const VIEWPORT = { width: 1280, height: 720 };

const readJson = (path) => JSON.parse(readFileSync(path, "utf8"));

// ── Arguments ──────────────────────────────────────────────────────────────

class NetError extends Error {
  constructor(message) {
    super(message);
    this.name = "NetError";
  }
}

const argv = process.argv.slice(2);
const flag = (name) => argv.includes(name);

// A flag whose value went missing is a usage error, never a default. `--scenario`
// with nothing after it would otherwise run the whole corpus, silently, which is
// the opposite of what was asked for.
const value = (name) => {
  const at = argv.indexOf(name);
  if (at === -1) return null;
  const given = argv[at + 1];
  if (given === undefined || given.startsWith("--")) throw new NetError(`${name} needs a value`);
  return given;
};

// ── Building the two bundles ───────────────────────────────────────────────

const build = (side) =>
  new Promise((done, failed) => {
    const child = spawn(process.execPath, [join(repoRoot, "parity/driver/build.mjs"), "--side", side], {
      cwd: repoRoot,
      stdio: ["ignore", "pipe", "pipe"],
    });
    let said = "";
    child.stdout.on("data", (chunk) => (said += chunk));
    child.stderr.on("data", (chunk) => (said += chunk));
    child.on("error", failed);
    child.on("close", (code) =>
      code === 0
        ? done(said.trim().split("\n").at(-1))
        : failed(new NetError(`the ${side} bundle did not build:\n${said.trim()}`))
    );
  });

// Both, every run. A stale bundle is the one failure this gate cannot see from
// the inside: it would measure the code it was built from and report green
// about the code in the tree. Rebuilding costs under a second and removes the
// question — which is not true of the *committed* `dist/psflow.js`, whose
// staleness README still names as an open gap.
const buildBoth = async () => {
  if (!existsSync(join(repoRoot, "output"))) {
    throw new NetError(
      `no compiled PureScript at ${join(repoRoot, "output")} — the ps-flow bundle is built from it, so ` +
        `there is nothing to measure. Run \`spago build\` first.`
    );
  }
  for (const side of SIDES) console.log(await build(side));
};

// ── Capture ────────────────────────────────────────────────────────────────

/**
 * Drives every scenario against both sides, twice each, and writes the traces.
 *
 * A fresh context per side per scenario: touch emulation is a page-level
 * capability a scenario declares, and one that leaked into the next scenario
 * would put the whole corpus on a touch-capable browser to serve the scenarios
 * that asked. The **two captures of one side share a page** by design — that is
 * the case `runScenario`'s blank-first navigation exists for.
 */
const captureCorpus = async (scenarios, { origin, baseline }) => {
  const browser = await chromium.launch();
  mkdirSync(TRACES, { recursive: true });

  try {
    for (const scenario of scenarios) {
      for (const side of SIDES) {
        const context = await browser.newContext({ baseURL: origin, viewport: VIEWPORT });
        const page = await context.newPage();
        try {
          for (const capture of CAPTURES) {
            const trace = await runScenario(page, scenario, { side, capture, baseline });
            writeTrace(TRACES, trace);
          }
        } finally {
          await context.close();
        }
      }
      console.log(`captured ${scenario.id}`);
    }
  } finally {
    await browser.close();
  }
};

// ── The run ────────────────────────────────────────────────────────────────

/**
 * The corpus, and the vendored version it will be captured against.
 *
 * Only a capturing run needs either. `--compare-only` takes its scenarios off
 * the stored trace files instead, and its baseline out of the traces
 * themselves — re-diffing must work on a clean clone, or committing the traces
 * would buy nothing and a bumped baseline could not re-diff the previous one's.
 */
const workFor = (compareOnly) => {
  if (compareOnly) {
    if (!existsSync(TRACES)) throw new NetError(`nothing stored under ${relative(repoRoot, TRACES)} to re-diff`);
    return { scenarios: storedScenarios(TRACES).map((id) => ({ id })), corpus: null };
  }

  const vendored = join(repoRoot, "xyflow/packages/react/package.json");
  if (!existsSync(vendored)) {
    throw new NetError(
      `no vendored upstream at ${vendored}. System parity runs **vendored source**, not the published ` +
        `package — that is what keeps all three parity gates on one artifact with one bump procedure. ` +
        `Re-vendor \`xyflow/\` and try again, or re-diff what is already stored with --compare-only.`
    );
  }

  const { fixtures, components } = routeSpace(repoRoot);
  // Assembly first, then the claim made *about* the assembled corpus: every
  // scenario a **retirement** names has to be one the corpus holds. It is not
  // part of `buildCorpus` because it is a property of the real registry rather
  // than of the assembly — a caller building a two-fixture corpus to test the
  // assembly is making no claim about a retirement, and failing it there would
  // say otherwise. It runs before the fork check for the same reason the fork
  // check runs before the browser: the assertions it stands in for are already
  // deleted, so a citation that has stopped resolving is coverage the repo
  // believes it has, and no number of captured traces answers that.
  const corpus = assertRetirementsResolve(buildCorpus(fixtures, components));
  return { scenarios: corpus, corpus, baseline: readJson(vendored).version };
};

/**
 * The version every trace in the run was captured against.
 *
 * Read out of the traces rather than off the vendored tree, because a
 * `--compare-only` run is very often re-diffing traces from a *different*
 * baseline than the one checked out — which is exactly what turns a bump into a
 * behavioural changelog, and exactly the case a header naming the current
 * checkout would misreport.
 */
const baselineOf = (runs) => {
  const found = [...new Set(runs.flatMap((run) => [run.comparison.left.baseline, run.comparison.right.baseline]))];
  return found.join(" and ");
};

const withTrailingNewline = (text) => (text.endsWith("\n") ? text : text + "\n");

// `report.md` is a committed artifact, so a path inside it may not depend on
// which host rendered it: a Windows run would otherwise rewrite the line on
// every capture and a POSIX run would rewrite it back. The same normalization
// `registry.mjs` applies to a fixture's route key, for the same reason.
const posixPath = (path) => path.split(sep).join(posix.sep);

const main = async () => {
  const compareOnly = flag("--compare-only");
  const only = value("--scenario");
  const out = value("--out");

  const { scenarios: all, corpus, baseline } = workFor(compareOnly);
  const scenarios = only ? all.filter((s) => s.id === only) : all;
  if (!scenarios.length) {
    throw new NetError(
      `no scenario named ${JSON.stringify(only)}. There is:\n` + all.map((s) => `  ${s.id}`).join("\n")
    );
  }

  if (compareOnly) {
    console.log(`re-diffing ${scenarios.length} scenario(s) from stored traces — no browser`);
  } else {
    // Before the browser, and the one place in this file where something
    // earlier stops something later. It is not a suppressed comparison — no
    // capture has happened yet to suppress — it is a precondition, the same
    // kind as the vendored checkout above. Capturing a hundred and twenty
    // traces against a corpus whose relation to upstream is in question
    // produces an artifact that has to be thrown away the moment the question
    // is answered, and re-affirming is a decision rather than a repair.
    const { outcomes } = checkFork({ corpus });
    console.log(reportFork(outcomes));
    if (!outcomes.ok) return 1;

    await buildBoth();
    const server = await serveDirectory(repoRoot);
    try {
      await captureCorpus(scenarios, { origin: server.origin, baseline });
    } finally {
      await server.close();
    }
  }

  // Read back off disk, always — including on the run that just wrote them.
  // The stored traces are the artifact the comparison half is built around, and
  // a gate that diffed its in-memory copies would let the two drift.
  const rules = readJson(NORMALIZATION).rules;
  const regions = readJson(REGIONS).regions;
  const weakenings = readJson(WEAKENINGS).weakenings;

  const runs = scenarios.map((scenario) => compareRun(readRun(TRACES, scenario.id), { rules, regions, weakenings }));

  // A trace whose scenario no longer exists is **stale** in the sense every
  // register here uses: it stops corresponding to anything real, and it would
  // sit in the repo being read as a recorded divergence long after the scenario
  // that produced it was renamed away. Asked only where there is a corpus to
  // ask it of, and only of a whole-corpus run — a `--scenario` run has not
  // captured the others and is no evidence about them. Asked *after* the
  // comparison, and reported beside it rather than instead of it: nothing
  // earlier suppresses anything later, here as everywhere else in the net.
  const orphans = corpus && !only ? orphanedTraces(TRACES, corpus) : [];

  const report = renderNetReport(runs, {
    baseline: baselineOf(runs),
    captured: !compareOnly,
    tracesDir: posixPath(relative(repoRoot, TRACES)),
    orphans,
  });
  writeFileSync(REPORT, withTrailingNewline(report));
  if (out) writeFileSync(out, withTrailingNewline(report));

  // Derived from the traces just read back, and reported beside the comparison
  // rather than instead of it — nothing earlier suppresses anything later, here
  // as everywhere else in the net. A `--scenario` run still covers the whole
  // stored corpus: coverage is a claim about the runs that happened, and the
  // other scenarios' traces happened too.
  const covered = checkCoverage(corpus ? { corpus } : { scenarioIds: all.map((scenario) => scenario.id) });
  writeCoverage(covered);

  const failed = runs.filter((run) => !run.ok);
  const said = [];
  if (failed.length) {
    said.push(
      `${failed.length} of ${runs.length} scenario(s) failed:`,
      ...failed.map((run) => `  ${run.scenario}: ${[...new Set(run.failures.map((f) => f.class))].join(", ")}`)
    );
  } else {
    said.push(`all ${runs.length} scenario(s) passed.`);
  }
  if (orphans.length) {
    said.push(
      `${orphans.length} stored trace(s) belong to no scenario in the corpus:`,
      ...orphans.map((name) => `  ${name}`),
      `A scenario was renamed or removed and its traces stayed. Delete them — a stored trace nobody`,
      `captures again is read as a recorded divergence forever.`
    );
  }
  said.push(reportCoverage(covered));
  said.push(
    `The report is ${relative(repoRoot, REPORT)} and the coverage artifact is ${relative(repoRoot, COVERAGE)}.`
  );
  console.log("\n" + said.join("\n"));

  return netOk(runs) && !orphans.length && covered.outcomes.ok && covered.behavior.ok ? 0 : 1;
};

// A run that cannot be interpreted is its own outcome, and never a pass. The
// errors below are the ones this gate knows how to say out loud; anything else
// is a bug here and keeps its stack rather than being dressed up as a bad run.
const INTERPRETABLE = [
  NetError,
  ForkError,
  TraceFormatError,
  TraceStoreError,
  RegistryError,
  CorpusError,
  CoverageError,
  WitnessError,
  SettleError,
  NormalizationError,
  RegionError,
  WeakeningError,
  ComparisonError,
  ConsistencyError,
  RunError,
  SyntaxError,
];

try {
  process.exit(await main());
} catch (e) {
  console.error(INTERPRETABLE.some((E) => e instanceof E) ? e.message : e);
  process.exit(2);
}
