// System parity — the gate (`npm run parity:system`, #51).
//
//   node parity/system/net.mjs [--compare-only] [--scenario <id>] [--out <path>]
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
// **The corpus is mount-only baselines**, one per fixture, derived from the
// fixture registry rather than written down (`corpus/mount-baselines.mjs`). No
// action vocabulary at all — which is the cheapest scenario there is, and the
// one the dual-run spike ran when it found an entirely unlisted missing export.
//
// **It runs vendored upstream**, never the published package: both bundles are
// rebuilt here, and `parity/driver/build.mjs` reads its own output back and
// fails if the library in it is not the one the side names. That check is the
// whole gate — an alias that quietly stopped being applied would leave the net
// comparing ps-flow against itself and reporting green.
//
// Exit codes: 0 clean, 1 a scenario failed — a side that disagrees with itself,
// a driving divergence, an unclaimed difference, a stale register — 2 a run that
// could not be interpreted at all. A run that cannot be interpreted is never a
// pass.

import { chromium } from "@playwright/test";
import { spawn } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { RegistryError, collectFixtures, fixtureRoots } from "../driver/registry.mjs";
import { SIDES } from "../driver/sides.mjs";
import { WeakeningError } from "./compare/callbacks.mjs";
import { ConsistencyError } from "./compare/consistency.mjs";
import { ComparisonError } from "./compare/index.mjs";
import { NormalizationError } from "./compare/normalize.mjs";
import { RegionError } from "./compare/regions.mjs";
import { RunError, compareRun } from "./compare/run.mjs";
import { CorpusError, mountBaselines } from "./corpus/mount-baselines.mjs";
import { SettleError } from "./harness/settle.mjs";
import { runScenario } from "./harness/scenario.mjs";
import { serveDirectory } from "./net/server.mjs";
import { renderNetReport, netOk } from "./net/summary.mjs";
import { CAPTURES, TraceStoreError, orphanedTraces, readRun, writeTrace } from "./net/traces.mjs";
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

const argv = process.argv.slice(2);
const flag = (name) => argv.includes(name);
const value = (name) => {
  const at = argv.indexOf(name);
  return at === -1 ? null : argv[at + 1];
};

const compareOnly = flag("--compare-only");
const only = value("--scenario");
const out = value("--out");

class NetError extends Error {
  constructor(message) {
    super(message);
    this.name = "NetError";
  }
}

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

const main = async () => {
  const vendored = join(repoRoot, "xyflow/packages/react/package.json");
  if (!existsSync(vendored)) {
    throw new NetError(
      `no vendored upstream at ${vendored}. System parity runs **vendored source**, not the published ` +
        `package — that is what keeps all three parity gates on one artifact with one bump procedure. ` +
        `Re-vendor \`xyflow/\` and try again.`
    );
  }
  const baseline = readJson(vendored).version;

  const fixtures = collectFixtures(fixtureRoots(repoRoot));
  const corpus = mountBaselines(fixtures);
  const scenarios = only ? corpus.filter((s) => s.id === only) : corpus;
  if (!scenarios.length) {
    throw new NetError(
      `no scenario named ${JSON.stringify(only)}. The corpus is:\n` + corpus.map((s) => `  ${s.id}`).join("\n")
    );
  }

  if (compareOnly) {
    console.log(`re-diffing ${scenarios.length} scenario(s) from stored traces — no browser`);
  } else {
    await buildBoth();
    const server = await serveDirectory(repoRoot);
    try {
      await captureCorpus(scenarios, { origin: server.origin, baseline });
    } finally {
      await server.close();
    }
  }

  // A trace whose scenario no longer exists is **stale** in the sense every
  // register here uses: it stops corresponding to anything real, and it would
  // sit in the repo being read as a recorded divergence long after the scenario
  // that produced it was renamed away. Only asked of a whole-corpus run — a
  // `--scenario` run has not captured the others and is not evidence about them.
  if (!only && existsSync(TRACES)) {
    const orphans = orphanedTraces(TRACES, corpus);
    if (orphans.length) {
      throw new NetError(
        `${orphans.length} trace file(s) under ${relative(repoRoot, TRACES)} belong to no scenario in the corpus:\n` +
          orphans.map((name) => `  ${name}`).join("\n") +
          `\nA scenario was renamed or removed and its traces stayed. Delete them — a stored trace nobody ` +
          `captures again is read as a recorded divergence forever.`
      );
    }
  }

  // Read back off disk, always — including on the run that just wrote them.
  // The stored traces are the artifact the comparison half is built around, and
  // a gate that diffed its in-memory copies would let the two drift.
  const rules = readJson(NORMALIZATION).rules;
  const regions = readJson(REGIONS).regions;
  const weakenings = readJson(WEAKENINGS).weakenings;

  const runs = scenarios.map((scenario) =>
    compareRun(readRun(TRACES, scenario.id), { rules, regions, weakenings })
  );

  const report = renderNetReport(runs, {
    baseline,
    captured: !compareOnly,
    tracesDir: relative(repoRoot, TRACES),
  });
  writeFileSync(REPORT, report.endsWith("\n") ? report : report + "\n");
  if (out) writeFileSync(out, report.endsWith("\n") ? report : report + "\n");

  const failed = runs.filter((run) => !run.ok);
  console.log(
    failed.length
      ? `\n${failed.length} of ${runs.length} scenario(s) failed:\n` +
          failed.map((run) => `  ${run.scenario}: ${[...new Set(run.failures.map((f) => f.class))].join(", ")}`).join("\n") +
          `\n\nThe report is ${relative(repoRoot, REPORT)}.`
      : `\nall ${runs.length} scenario(s) passed. The report is ${relative(repoRoot, REPORT)}.`
  );

  return netOk(runs) ? 0 : 1;
};

// A run that cannot be interpreted is its own outcome, and never a pass. The
// errors below are the ones this gate knows how to say out loud; anything else
// is a bug here and keeps its stack rather than being dressed up as a bad run.
const INTERPRETABLE = [
  NetError,
  TraceFormatError,
  TraceStoreError,
  RegistryError,
  CorpusError,
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
