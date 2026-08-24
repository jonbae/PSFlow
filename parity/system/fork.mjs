// The fork staleness gate — the command (`npm run parity:fork`, #55).
//
//   node parity/system/fork.mjs [--affirm]
//
//     --affirm  restamp the entries whose forked spec **moved** with its new
//               hash and this checkout's baseline. It cannot create an entry
//               and it cannot delete one: a test a bump added stays
//               unregistered, and an entry whose test is gone stays stale,
//               until someone writes down what to do about it. The same line
//               `compare.mjs --record` draws for regions, in the same place.
//
// The mechanism, the five outcomes and why the seed is a fork rather than a
// mirror are all in `corpus/fork.mjs`; this file reads the vendored specs, the
// register and the corpus, and says what it found.
//
// It runs standalone and it runs as `net.mjs`'s first step, which is where it
// earns its keep: capturing a hundred and twenty traces against a corpus whose
// relation to upstream is in question produces an artifact that has to be
// thrown away once the question is answered. `--compare-only` skips it, because
// re-diffing stored traces needs no vendored checkout at all.
//
// Exit codes: 0 the register is affirmed, 1 it is not, 2 it could not be read —
// a missing vendored spec, a malformed entry, a spec whose units cannot be told
// apart.

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { collectFixtures, collectComponents, directComponents, fixtureRoots, routeSpace } from "../driver/registry.mjs";
import { posix, relative, sep } from "node:path";
import { buildCorpus } from "./corpus/index.mjs";
import {
  ForkError,
  affirmFork,
  forkOutcomes,
  readUnits,
  renderForkFailures,
  renderForkSummary,
} from "./corpus/fork.mjs";
import { seedScenarios } from "./corpus/seed.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");

export const FORK_REGISTER = join(here, "corpus", "fork.json");

const readJson = (path) => JSON.parse(readFileSync(path, "utf8"));

const repoRelative = (file) => relative(repoRoot, file).split(sep).join(posix.sep);

/**
 * The upstream source the seed reads an assumption out of, hashed whole:
 * every **vendored** fixture, and every **example driver**.
 *
 * Derived from the driver's own two registries rather than listed, the same way
 * the mount-only baselines are — a fixture a bump adds then arrives as an
 * *unregistered* unit and asks to be decided about, instead of joining the page
 * silently. ps-flow's own fixture root is left out on purpose: the register is
 * about drift under a baseline bump, and this repo's own files do not drift
 * under one.
 */
export const dependedSources = (components = collectComponents(directComponents(repoRoot))) => {
  // Only the vendored root. `routeSpace` merges both, and ps-flow's own
  // fixtures have no business in a register about drift under a baseline bump.
  const [vendored] = fixtureRoots(repoRoot);

  return [
    ...collectFixtures([vendored]).map(({ file }) => repoRelative(file)),
    ...components.filter(({ kind }) => kind === "example-driver").map(({ file }) => repoRelative(file)),
  ];
};

/**
 * Reads the register against the vendored source and the corpus.
 *
 * Exported so `net.mjs` runs the same check this command does, rather than a
 * second reading of the same files that could drift from it — and takes the
 * `corpus` it has already built, since assembling it twice in one run would be
 * two answers where the gate needs one.
 */
export const checkFork = ({ corpus } = {}) => {
  const register = readJson(FORK_REGISTER);
  const { fixtures, components } = routeSpace(repoRoot);
  const scenarios = corpus ?? buildCorpus(fixtures, components);

  return {
    register,
    outcomes: forkOutcomes(register.forked, readUnits(repoRoot, { sources: dependedSources(components) }), {
      scenarioIds: scenarios.map((s) => s.id),
      seedIds: seedScenarios.map((s) => s.id),
    }),
  };
};

/** The gate's own words, so `net.mjs` says exactly what the command says. */
export const reportFork = (outcomes) =>
  outcomes.ok ? renderForkSummary(outcomes) : ["the fork register is not affirmed.", ...renderForkFailures(outcomes)].join("\n");

const main = () => {
  const affirming = process.argv.slice(2).includes("--affirm");
  const { register, outcomes } = checkFork();

  if (affirming) {
    const baseline = readJson(join(repoRoot, "xyflow/packages/react/package.json")).version;
    const forked = affirmFork(register.forked, outcomes, baseline);
    const restamped = forked.filter((entry, i) => entry !== register.forked[i]);

    if (!restamped.length) {
      console.log("nothing moved — no entry needed re-affirming.");
    } else {
      writeFileSync(FORK_REGISTER, JSON.stringify({ ...register, forked }, null, 2) + "\n");
      console.log(
        `re-affirmed ${restamped.length} entr(ies) against ${baseline}:\n` +
          restamped.map((e) => `  ${e.test}\n    lifted: ${e.scenarios.join(", ") || "(nothing)"}`).join("\n") +
          `\nRead each one's new spec before you commit this: re-affirming says the lifted scenario still ` +
          `drives what it should, and nothing here checked that.`
      );
    }

    // Re-read, so what is reported is the register as it now stands. An entry
    // that was stale or unregistered is untouched by affirming and still fails.
    const { outcomes: after } = checkFork();
    console.log(reportFork(after));
    return after.ok ? 0 : 1;
  }

  console.log(reportFork(outcomes));
  return outcomes.ok ? 0 : 1;
};

if (resolve(process.argv[1] ?? "") === resolve(fileURLToPath(import.meta.url))) {
  try {
    process.exit(main());
  } catch (e) {
    console.error(e instanceof ForkError || e instanceof SyntaxError ? e.message : e);
    process.exit(2);
  }
}
