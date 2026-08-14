// Where a run's four traces live on disk (#51).
//
// The disk is not incidental. A **trace** is captured, written out, and *read
// back* before it is diffed — even on the run that just captured it — because
// that is the seam the whole comparison half is built on: a revised noise policy
// re-diffs every trace ever captured in seconds without opening a browser, and a
// baseline bump re-diffs stored traces of one baseline against another into a
// behavioural changelog. A gate that compared in-memory objects and wrote copies
// out afterwards would let the two drift, and the copies are the artifact.
//
// Reading back also runs every trace through `validateTrace` on the way in, so
// the format is enforced against what was actually persisted rather than against
// what capture believed it had.

import { existsSync, readdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

import { SIDES } from "../../driver/sides.mjs";
import { readTrace } from "../trace-format.mjs";

/** Each side is captured twice — self-consistency is what a trace baseline rests on. */
export const CAPTURES = [1, 2];

export class TraceStoreError extends Error {
  constructor(message) {
    super(message);
    this.name = "TraceStoreError";
  }
}

/**
 * `mount-baseline--nodes-general.psflow.capture1.json`.
 *
 * Named after the envelope it carries rather than numbered, so a directory
 * listing is readable and a scenario's four files sort together.
 */
export const traceName = (scenario, side, capture) => `${scenario}.${side}.capture${capture}.json`;

/** The four file names one run writes, in the order a run is captured. */
export const runNames = (scenario) =>
  SIDES.flatMap((side) => CAPTURES.map((capture) => traceName(scenario, side, capture)));

export const writeTrace = (dir, trace) => {
  const path = join(dir, traceName(trace.scenario, trace.side, trace.capture));
  writeFileSync(path, JSON.stringify(trace, null, 2) + "\n");
  return path;
};

/**
 * Reads back one run's four traces, in any order — `compareRun` groups them by
 * the side each one records.
 *
 * A missing file is a hard error rather than a run of three: three traces
 * compare as "self-consistency was not checked on one side", which is a check
 * that quietly proved less than its name.
 */
export const readRun = (dir, scenario) =>
  runNames(scenario).map((name) => {
    const path = join(dir, name);
    // Asked before reading, because `readTrace` reports an absent file as a
    // trace that could not be parsed — true, and not the thing that went wrong.
    if (!existsSync(path)) {
      throw new TraceStoreError(
        `${path} is missing — a run is two captures of each of the two sides, and this one has fewer. ` +
          `Capture it (\`npm run parity:system\`) rather than comparing what is there.`
      );
    }
    return readTrace(path);
  });

/**
 * The scenarios `dir` holds traces for, read off the file names.
 *
 * This is how `--compare-only` finds its work: re-diffing stored traces must
 * not need the vendored checkout, or the traces being committed would buy
 * nothing on a clean clone and a bumped baseline could not re-diff the previous
 * one's traces — which is the whole reason they are in the repository.
 */
export const storedScenarios = (dir) =>
  [
    ...new Set(
      readdirSync(dir)
        .filter((name) => name.endsWith(".json"))
        .map((name) => name.split(".")[0])
    ),
  ].sort();

/**
 * Trace files in `dir` that no scenario in the corpus claims.
 *
 * A trace left behind by a renamed or deleted scenario is **stale** in exactly
 * the sense every register here uses: it stops corresponding to anything real,
 * and it would sit in the repo being read as a recorded divergence long after
 * the scenario that produced it stopped existing.
 */
export const orphanedTraces = (dir, scenarios) => {
  const claimed = new Set(scenarios.flatMap((scenario) => runNames(scenario.id)));
  return readdirSync(dir)
    .filter((name) => name.endsWith(".json") && !claimed.has(name))
    .sort();
};
